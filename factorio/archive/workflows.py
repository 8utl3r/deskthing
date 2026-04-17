#!/usr/bin/env python3
"""
Factorio NPC Workflows

Reusable workflows for common NPC tasks. These execute programmatically
without LLM involvement - the LLM only chooses which workflow to run.
"""

import time
import json
from typing import Dict, List, Optional, Tuple, Callable


class Workflow:
    """Base class for NPC workflows."""
    
    def __init__(self, name: str, description: str):
        self.name = name
        self.description = description
    
    def execute(self, controller, agent_id: str, params: Dict) -> Dict:
        """
        Execute the workflow.
        
        Returns:
            Dict with 'success' (bool) and 'message' (str) keys
        """
        raise NotImplementedError


class GatherResourceWorkflow(Workflow):
    """
    Gather a specific resource: walk to it, mine it, store it in chest.
    
    Params:
        - resource_name: Name of resource to gather (e.g., "iron-ore", "copper-ore")
        - count: Optional amount to mine (default: mine until depleted or inventory full)
    """
    
    def __init__(self):
        super().__init__(
            name="gather_resource",
            description="Walk to a resource, mine it, and store it in a chest"
        )
    
    def execute(self, controller, agent_id: str, params: Dict) -> Dict:
        resource_name = params.get('resource_name', params.get('resource', ''))
        count = params.get('count')
        
        if not resource_name:
            return {'success': False, 'message': 'No resource_name specified'}
        
        # Step 1: Find the resource
        reachable = controller.get_reachable_entities(agent_id)
        if not reachable:
            return {'success': False, 'message': 'Could not get reachable entities'}
        
        resources = reachable.get('resources', [])
        target_resource = None
        target_pos = None
        
        for r in resources:
            if r.get('name', '').lower() == resource_name.lower():
                target_resource = r
                pos = r.get('position', {})
                if isinstance(pos, dict):
                    target_pos = (pos.get('x', 0), pos.get('y', 0))
                break
        
        if not target_resource:
            return {'success': False, 'message': f'Resource {resource_name} not found in reachable area'}
        
        # Step 2: Walk to resource
        if target_pos:
            result = controller.execute_action(agent_id, 'walk_to', {'x': target_pos[0], 'y': target_pos[1]})
            if isinstance(result, str) and 'error' in result.lower():
                return {'success': False, 'message': f'Failed to walk to resource: {result}'}
            
            # Wait for agent to arrive
            max_wait = 30  # seconds
            waited = 0
            while controller.is_agent_busy(agent_id) and waited < max_wait:
                time.sleep(0.5)
                waited += 0.5
            
            if waited >= max_wait:
                return {'success': False, 'message': 'Timeout waiting for agent to reach resource'}
        
        # Step 3: Mine the resource
        mine_params = {'resource': resource_name}
        if count:
            mine_params['count'] = count
        
        result = controller.execute_action(agent_id, 'mine_resource', mine_params)
        if isinstance(result, str) and 'error' in result.lower():
            return {'success': False, 'message': f'Failed to mine resource: {result}'}
        
        # Step 4: Wait for mining to complete or inventory to fill
        max_wait = 60  # seconds
        waited = 0
        while controller.is_agent_busy(agent_id) and waited < max_wait:
            time.sleep(0.5)
            waited += 0.5
        
        # Step 5: Store in chest if inventory is full or mining complete
        # Find nearest chest
        reachable = controller.get_reachable_entities(agent_id)
        if reachable:
            entities = reachable.get('entities', [])
            chests = [e for e in entities if 'chest' in e.get('name', '').lower()]
            
            if chests:
                # Use first chest found
                chest = chests[0]
                pos = chest.get('position', {})
                if isinstance(pos, dict):
                    chest_pos = (pos.get('x', 0), pos.get('y', 0))
                    
                    # Walk to chest
                    controller.execute_action(agent_id, 'walk_to', {'x': chest_pos[0], 'y': chest_pos[1]})
                    
                    # Wait to arrive
                    waited = 0
                    while controller.is_agent_busy(agent_id) and waited < 10:
                        time.sleep(0.5)
                        waited += 0.5
                    
                    # Deposit all of the mined resource
                    agent_state = controller.get_agent_state(agent_id)
                    if agent_state:
                        inventory = agent_state.get('inventory', {})
                        if resource_name in inventory:
                            count_to_deposit = inventory.get(resource_name, 0)
                            if count_to_deposit > 0:
                                controller.execute_action(agent_id, 'set_inventory_item', {
                                    'entity': chest.get('name', 'wooden-chest'),
                                    'x': chest_pos[0],
                                    'y': chest_pos[1],
                                    'inventory': 'chest',
                                    'item': resource_name,
                                    'count': count_to_deposit
                                })
        
        return {'success': True, 'message': f'Gathered {resource_name}'}


class BuildBlueprintWorkflow(Workflow):
    """
    Build a blueprint/ghost entity: walk to it, place the entity.
    ONLY executes if blueprints exist. If missing resources, gathers them first.
    
    Params:
        - ghost_entity: The ghost entity dict from reachable entities
        - OR ghost_position: {x, y} position of ghost
        - entity_name: Name of entity to build (extracted from ghost name)
    """
    
    def __init__(self):
        super().__init__(
            name="build_blueprint",
            description="Walk to a ghost entity and build it (only if blueprints exist, gathers resources if needed)"
        )
    
    def execute(self, controller, agent_id: str, params: Dict) -> Dict:
        # Check if blueprints actually exist
        reachable = controller.get_reachable_entities(agent_id)
        if not reachable:
            return {'success': False, 'message': 'Could not get reachable entities to check for blueprints'}
        
        ghosts = reachable.get('ghosts', [])
        if not ghosts:
            # No blueprints detected - don't build
            return {'success': False, 'message': 'No blueprints detected - nothing to build'}
        
        ghost_entity = params.get('ghost_entity')
        ghost_position = params.get('ghost_position')
        entity_name = params.get('entity_name')
        
        # If no specific ghost provided, use first one found
        if not ghost_entity and not ghost_position:
            ghost_entity = ghosts[0]
        
        # Extract entity name from ghost if not provided
        if ghost_entity and not entity_name:
            ghost_name = ghost_entity.get('name', '')
            # Remove "entity-ghost-" or "item-entity-ghost-" prefix
            entity_name = ghost_name.replace('entity-ghost-', '').replace('item-entity-ghost-', '')
        
        if not entity_name:
            return {'success': False, 'message': 'Could not determine entity name from ghost'}
        
        # Get position
        if ghost_entity:
            pos = ghost_entity.get('position', {})
            if isinstance(pos, dict):
                target_pos = (pos.get('x', 0), pos.get('y', 0))
            else:
                return {'success': False, 'message': 'Invalid ghost entity position'}
        elif ghost_position:
            target_pos = (ghost_position.get('x', 0), ghost_position.get('y', 0))
        else:
            return {'success': False, 'message': 'No ghost position specified'}
        
        # Check if we have required resources (simplified check - just check inventory)
        # For now, we'll try to build and if it fails due to missing resources, gather them
        # Step 1: Walk to ghost position
        result = controller.execute_action(agent_id, 'walk_to', {'x': target_pos[0], 'y': target_pos[1]})
        if isinstance(result, str) and 'error' in result.lower():
            return {'success': False, 'message': f'Failed to walk to blueprint: {result}'}
        
        # Wait for agent to arrive
        max_wait = 30
        waited = 0
        while controller.is_agent_busy(agent_id) and waited < max_wait:
            time.sleep(0.5)
            waited += 0.5
        
        if waited >= max_wait:
            return {'success': False, 'message': 'Timeout waiting for agent to reach blueprint'}
        
        # Step 2: Try to place entity
        result = controller.execute_action(agent_id, 'place_entity', {
            'entity': entity_name,
            'x': target_pos[0],
            'y': target_pos[1]
        })
        
        # If failed due to missing resources, try to gather them
        if isinstance(result, str) and ('insufficient' in result.lower() or 'missing' in result.lower() or 'need' in result.lower()):
            # Try to find required resources in storage or gather them
            # For now, return error message so LLM can decide to gather resources
            return {'success': False, 'message': f'Missing resources to build {entity_name}. Need to gather resources first: {result}'}
        
        if isinstance(result, str) and 'error' in result.lower():
            return {'success': False, 'message': f'Failed to place entity: {result}'}
        
        return {'success': True, 'message': f'Built {entity_name} at ({target_pos[0]}, {target_pos[1]})'}


class DefendBaseWorkflow(Workflow):
    """
    Defend against enemies: walk to enemy, engage (attack).
    ONLY executes if enemies are actually present and threatening.
    
    Params:
        - enemy: Enemy entity dict from reachable entities
        - OR enemy_position: {x, y} position of enemy
    """
    
    def __init__(self):
        super().__init__(
            name="defend_base",
            description="Move to enemy and engage in combat (only if enemies are present)"
        )
    
    def execute(self, controller, agent_id: str, params: Dict) -> Dict:
        # Check if enemies actually exist
        reachable = controller.get_reachable_entities(agent_id)
        if not reachable:
            return {'success': False, 'message': 'Could not get reachable entities to check for enemies'}
        
        enemies = reachable.get('enemies', [])
        if not enemies:
            # No enemies detected - don't defend
            return {'success': False, 'message': 'No enemies detected - nothing to defend against'}
        
        enemy = params.get('enemy')
        enemy_position = params.get('enemy_position')
        
        # If no specific enemy provided, use first one found
        if not enemy and not enemy_position:
            enemy = enemies[0]
        
        # Get position
        if enemy:
            pos = enemy.get('position', {})
            if isinstance(pos, dict):
                target_pos = (pos.get('x', 0), pos.get('y', 0))
            else:
                return {'success': False, 'message': 'Invalid enemy position'}
        elif enemy_position:
            target_pos = (enemy_position.get('x', 0), enemy_position.get('y', 0))
        else:
            return {'success': False, 'message': 'No enemy position specified'}
        
        # Walk to enemy (agent will auto-attack when in range)
        result = controller.execute_action(agent_id, 'walk_to', {'x': target_pos[0], 'y': target_pos[1]})
        
        if isinstance(result, str) and 'error' in result.lower():
            return {'success': False, 'message': f'Failed to move to enemy: {result}'}
        
        return {'success': True, 'message': f'Moving to engage enemy at ({target_pos[0]}, {target_pos[1]})'}


class PatrolWorkflow(Workflow):
    """
    Patrol in a circle around a center point.
    
    Params:
        - center: {x, y} center point (default: {0, 0})
        - radius: Circle radius in tiles (default: 50)
    """
    
    def __init__(self):
        super().__init__(
            name="patrol",
            description="Patrol in a circle around a center point"
        )
        self.patrol_angles = {}  # Track angle per agent
    
    def execute(self, controller, agent_id: str, params: Dict) -> Dict:
        import math
        
        center = params.get('center', {'x': 0, 'y': 0})
        radius = params.get('radius', 50)
        
        # Get or initialize patrol angle for this agent
        if agent_id not in self.patrol_angles:
            self.patrol_angles[agent_id] = 0.0
        
        angle = self.patrol_angles[agent_id]
        
        # Calculate next point on circle
        next_x = int(center['x'] + radius * math.cos(angle))
        next_y = int(center['y'] + radius * math.sin(angle))
        
        # Increment angle for next time
        self.patrol_angles[agent_id] = angle + (math.pi / 8)  # 22.5 degrees
        if self.patrol_angles[agent_id] >= 2 * math.pi:
            self.patrol_angles[agent_id] = 0.0
        
        # Walk to next point
        result = controller.execute_action(agent_id, 'walk_to', {'x': next_x, 'y': next_y})
        
        if isinstance(result, str) and 'error' in result.lower():
            return {'success': False, 'message': f'Failed to patrol: {result}'}
        
        return {'success': True, 'message': f'Patrolling to ({next_x}, {next_y})'}


class BuildChestAndFillWorkflow(Workflow):
    """
    Gather wood, build a chest, and fill it with any available resources.
    This is the idle task when there's nothing to defend or build.
    
    Params:
        - position: Optional {x, y} where to build chest (default: near agent)
    """
    
    def __init__(self):
        super().__init__(
            name="build_chest_and_fill",
            description="Gather wood, build a chest, and fill it with resources"
        )
    
    def execute(self, controller, agent_id: str, params: Dict) -> Dict:
        # Step 1: Gather wood (if not already in inventory)
        agent_state = controller.get_agent_state(agent_id)
        inventory = agent_state.get('inventory', {}) if agent_state else {}
        wood_count = inventory.get('wood', 0)
        
        if wood_count < 2:  # Need at least 2 wood for a chest
            # Gather wood first
            reachable = controller.get_reachable_entities(agent_id)
            if reachable:
                resources = reachable.get('resources', [])
                wood_resource = None
                for r in resources:
                    if r.get('name', '').lower() == 'wood':
                        wood_resource = r
                        break
                
                if wood_resource:
                    # Use gather_resource workflow to get wood
                    gather_workflow = GatherResourceWorkflow()
                    result = gather_workflow.execute(controller, agent_id, {'resource_name': 'wood', 'count': 10})
                    if not result.get('success'):
                        return {'success': False, 'message': f'Failed to gather wood: {result.get("message")}'}
                else:
                    return {'success': False, 'message': 'No wood found to gather'}
        
        # Step 2: Find a good position for the chest (near agent, within range of constructions)
        agent_state = controller.get_agent_state(agent_id)
        if not agent_state:
            return {'success': False, 'message': 'Could not get agent state'}
        
        pos = agent_state.get('position', {})
        if isinstance(pos, dict):
            agent_pos = (pos.get('x', 0), pos.get('y', 0))
        else:
            agent_pos = (0, 0)
        
        # Build chest near agent (offset by a few tiles)
        chest_pos = {'x': agent_pos[0] + 5, 'y': agent_pos[1] + 5}
        
        # Step 3: Build the chest
        result = controller.execute_action(agent_id, 'place_entity', {
            'entity': 'wooden-chest',
            'x': chest_pos['x'],
            'y': chest_pos['y']
        })
        
        if isinstance(result, str) and 'error' in result.lower():
            return {'success': False, 'message': f'Failed to build chest: {result}'}
        
        # Step 4: Fill chest with any resources in inventory
        agent_state = controller.get_agent_state(agent_id)
        inventory = agent_state.get('inventory', {}) if agent_state else {}
        
        # Walk to chest
        controller.execute_action(agent_id, 'walk_to', {'x': chest_pos['x'], 'y': chest_pos['y']})
        waited = 0
        while controller.is_agent_busy(agent_id) and waited < 10:
            time.sleep(0.5)
            waited += 0.5
        
        # Deposit all resources (except wood, keep some for building)
        deposited = []
        for item_name, count in inventory.items():
            if item_name.lower() != 'wood' and count > 0:
                controller.execute_action(agent_id, 'set_inventory_item', {
                    'entity': 'wooden-chest',
                    'x': chest_pos['x'],
                    'y': chest_pos['y'],
                    'inventory': 'chest',
                    'item': item_name,
                    'count': count
                })
                deposited.append(f"{count} {item_name}")
        
        # Step 5: Gather more resources to fill the chest
        reachable = controller.get_reachable_entities(agent_id)
        if reachable:
            resources = reachable.get('resources', [])
            if resources:
                # Gather first available resource
                resource = resources[0]
                resource_name = resource.get('name', '')
                if resource_name:
                    gather_workflow = GatherResourceWorkflow()
                    gather_workflow.execute(controller, agent_id, {'resource_name': resource_name})
        
        return {'success': True, 'message': f'Built chest at ({chest_pos["x"]}, {chest_pos["y"]}) and filled with {", ".join(deposited) if deposited else "nothing"}'}


class ChatWorkflow(Workflow):
    """
    Send a chat message to players in-game.
    
    Params:
        - message: Text message to send
        - agent_name: Optional name to prefix message with
    """
    
    def __init__(self):
        super().__init__(
            name="chat",
            description="Send a chat message to players"
        )
    
    def execute(self, controller, agent_id: str, params: Dict) -> Dict:
        message = params.get('message', '')
        agent_name = params.get('agent_name', '')
        
        if not message:
            return {'success': False, 'message': 'No message specified'}
        
        # Format message with agent name if provided
        if agent_name:
            formatted_message = f"[{agent_name}] {message}"
        else:
            formatted_message = message
        
        # Send via game.print() in Factorio
        # Escape quotes in message for Lua
        escaped_message = formatted_message.replace('"', '\\"').replace("'", "\\'")
        command = f'/sc game.print("{escaped_message}")'
        
        try:
            response = controller.factorio.send_command(command)
            return {'success': True, 'message': f'Sent chat: {formatted_message}'}
        except Exception as e:
            return {'success': False, 'message': f'Failed to send chat: {e}'}


# Registry of available workflows
WORKFLOWS = {
    'gather_resource': GatherResourceWorkflow(),
    'build_blueprint': BuildBlueprintWorkflow(),
    'defend_base': DefendBaseWorkflow(),
    'build_chest_and_fill': BuildChestAndFillWorkflow(),
    'patrol': PatrolWorkflow(),
    'chat': ChatWorkflow(),
}


def get_workflow(name: str) -> Optional[Workflow]:
    """Get a workflow by name."""
    return WORKFLOWS.get(name)


def list_workflows() -> List[Dict]:
    """List all available workflows with descriptions."""
    return [
        {'name': wf.name, 'description': wf.description}
        for wf in WORKFLOWS.values()
    ]
