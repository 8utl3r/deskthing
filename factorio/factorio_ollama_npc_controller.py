#!/usr/bin/env python3
"""
Factorio NPC Controller using Ollama
Controls NPCs in Factorio via FV Embodied Agent mod using local LLM (Ollama)
"""

import ollama
import time
import json
import os
import subprocess
import signal
import sys
import threading
import math # Added for circular patrol
import factorio_rcon
from typing import Dict, List, Optional
from workflows import get_workflow, list_workflows, WORKFLOWS

class FactorioNPCController:
    def __init__(self, rcon_host: str = "localhost", rcon_port: int = 27015, 
                 rcon_password: str = "", ollama_model: str = "llama3.1",
                 ollama_host: str = "localhost", ollama_port: int = 11434):
        """
        Initialize the NPC controller.
        
        Args:
            rcon_host: Factorio RCON server host
            rcon_port: Factorio RCON server port
            rcon_password: RCON password
            ollama_model: Ollama model to use (e.g., "llama3.1", "mistral", "qwen2.5")
            ollama_host: Ollama server host
            ollama_port: Ollama server port
        """
        self.factorio = factorio_rcon.RCONClient(rcon_host, rcon_port, rcon_password)
        self.factorio.connect()
        self.ollama_model = ollama_model
        self.ollama_host = ollama_host
        self.ollama_port = ollama_port
        self.npc_contexts: Dict[str, List[Dict]] = {}  # Conversation history per NPC
        self.agent_counter = 0  # Counter for redshirt names
        
        # Load range limits from config
        try:
            from config import MAX_RANGE_FROM_BASE
            self.max_range = MAX_RANGE_FROM_BASE
        except ImportError:
            # Defaults if config not available
            self.max_range = 200
        
        # Set Ollama host/port via environment variable (ollama library uses this)
        if ollama_host != "localhost" or ollama_port != 11434:
            os.environ['OLLAMA_HOST'] = f"{ollama_host}:{ollama_port}"
        
        # Track if we started Ollama ourselves
        self.ollama_process = None
        self.ollama_started_by_us = False
    
    def check_ollama_running(self) -> bool:
        """Check if Ollama is running by attempting to connect."""
        try:
            import requests
            url = f"http://{self.ollama_host}:{self.ollama_port}/api/tags"
            response = requests.get(url, timeout=2)
            return response.status_code == 200
        except:
            # If requests not available, try with curl
            try:
                result = subprocess.run(
                    ['curl', '-s', f'http://{self.ollama_host}:{self.ollama_port}/api/tags'],
                    capture_output=True,
                    timeout=2
                )
                return result.returncode == 0
            except:
                return False
    
    def start_ollama(self) -> bool:
        """
        Start Ollama server if it's not running.
        
        Returns:
            True if Ollama is now running (either was already running or we started it)
        """
        # Check if already running
        if self.check_ollama_running():
            print("✅ Ollama is already running")
            return True
        
        print("⚠️  Ollama is not running, attempting to start it...")
        
        try:
            # Try to start Ollama as a background process
            # On macOS, Ollama is typically installed via Homebrew
            # Try different methods to start it
            
            # Method 1: Try `ollama serve` directly
            try:
                self.ollama_process = subprocess.Popen(
                    ['ollama', 'serve'],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    start_new_session=True  # Detach from parent process
                )
                
                # Wait a moment for it to start
                time.sleep(2)
                
                if self.check_ollama_running():
                    print("✅ Started Ollama server successfully")
                    self.ollama_started_by_us = True
                    return True
                else:
                    print("⚠️  Ollama process started but not responding yet")
                    # Give it more time
                    time.sleep(3)
                    if self.check_ollama_running():
                        print("✅ Ollama server is now responding")
                        self.ollama_started_by_us = True
                        return True
            except FileNotFoundError:
                # ollama command not found
                pass
            
            # Method 2: Try brew services (macOS)
            try:
                result = subprocess.run(
                    ['brew', 'services', 'start', 'ollama'],
                    capture_output=True,
                    timeout=5
                )
                if result.returncode == 0:
                    time.sleep(2)
                    if self.check_ollama_running():
                        print("✅ Started Ollama via Homebrew services")
                        return True
            except FileNotFoundError:
                # brew not found
                pass
            except:
                pass
            
            print("❌ Could not start Ollama automatically")
            print("   Please start Ollama manually:")
            print("   - ollama serve")
            print("   - brew services start ollama")
            return False
            
        except Exception as e:
            print(f"❌ Error starting Ollama: {e}")
            print("   Please start Ollama manually: ollama serve")
            return False
    
    def calculate_distance(self, pos1: tuple, pos2: tuple) -> float:
        """Calculate Euclidean distance between two positions."""
        return ((pos1[0] - pos2[0]) ** 2 + (pos1[1] - pos2[1]) ** 2) ** 0.5
    
    def get_constructed_entities(self, agent_id: str) -> List[Dict]:
        """
        Get all player-built/constructed entities (buildings, tracks, etc.) in the game.
        
        Queries the game surface directly to find ALL constructed entities, not just reachable ones.
        This allows the agent to know where constructions exist even if they're far away.
        
        These are entities that players have built, not natural resources or enemies.
        Examples: assembling-machine, stone-furnace, transport-belt, rail, chest, etc.
        """
        # Query all entities on the game surface using Lua
        # We'll search in a large area around the agent's position
        command = f"""/sc 
local agent_state = remote.call('agent_{agent_id}', 'inspect', false)
local agent_pos = agent_state and agent_state.position or {{x=0, y=0}}
local surface = game.surfaces[1]
local search_radius = 500  -- Search in 500 tile radius
local constructed = {{}}

-- Find all entities in the area
local entities = surface.find_entities_filtered{{
    area = {{
        {{agent_pos.x - search_radius, agent_pos.y - search_radius}},
        {{agent_pos.x + search_radius, agent_pos.y + search_radius}}
    }}
}}

-- Filter to constructed entities
-- CHESTS ARE CONSTRUCTION - they count as player-built entities for range checking
local exclude = {{'biter', 'spitter', 'worm', 'spawner', 'tree', 'rock', 'ghost', 'ore', 'cliff', 'water', 'grass', 'dirt', 'sand'}}
local include = {{'assembling', 'furnace', 'belt', 'rail', 'inserter', 'chest', 'wooden-chest', 'iron-chest', 'steel-chest', 'logistic-chest', 'container', 'lab', 'boiler', 'steam', 'pump', 'pipe', 'splitter', 'mining', 'drill', 'wall', 'gate', 'turret', 'radar', 'lamp', 'pole', 'solar', 'accumulator', 'reactor'}}

for _, entity in pairs(entities) do
    local name = string.lower(entity.name)
    local is_excluded = false
    for _, keyword in ipairs(exclude) do
        if string.find(name, keyword) then
            is_excluded = true
            break
        end
    end
    if not is_excluded then
        local is_constructed = false
        for _, keyword in ipairs(include) do
            if string.find(name, keyword) then
                is_constructed = true
                break
            end
        end
        if is_constructed or (not string.find(name, 'ore') and not string.find(name, 'tree') and not string.find(name, 'biter')) then
            table.insert(constructed, {{
                name = entity.name,
                position = {{x = entity.position.x, y = entity.position.y}}
            }})
        end
    end
end

return constructed
"""
        try:
            response = self.factorio.send_command(command)
            if response:
                try:
                    data = json.loads(response)
                    if isinstance(data, list):
                        return data
                    elif isinstance(data, dict) and 'entities' in data:
                        return data['entities']
                except json.JSONDecodeError:
                    # Try to parse Lua table format
                    # Factorio returns Lua tables, might need different parsing
                    pass
            
            # Fallback: use get_reachable if surface query fails
            command = f"/sc return remote.call('agent_{agent_id}', 'get_reachable')"
            response = self.factorio.send_command(command)
            if response:
                try:
                    data = json.loads(response)
                    if isinstance(data, dict):
                        entities = data.get('entities', [])
                        # Filter to only constructed entities
                        constructed = []
                        exclude_keywords = ['biter', 'spitter', 'worm', 'spawner', 'tree', 'rock', 
                                         'ghost', 'blueprint', 'ore', 'stone-ore', 'coal-ore', 
                                         'iron-ore', 'copper-ore', 'uranium-ore', 'crude-oil',
                                         'cliff', 'water', 'deepwater', 'grass', 'dirt', 'sand']
                        
                        include_keywords = ['assembling', 'furnace', 'belt', 'rail', 'inserter', 
                                         'chest', 'wooden-chest', 'iron-chest', 'steel-chest', 'logistic-chest', 
                                         'container', 'lab', 'boiler', 'steam', 'pump',
                                         'pipe', 'underground', 'splitter', 'mining', 'drill',
                                         'wall', 'gate', 'turret', 'radar', 'lamp', 'pole']
                        
                        for entity in entities:
                            if not isinstance(entity, dict):
                                continue
                            name = str(entity.get('name', '')).lower()
                            
                            if any(keyword in name for keyword in exclude_keywords):
                                continue
                            
                            if any(keyword in name for keyword in include_keywords):
                                constructed.append(entity)
                            elif not any(natural in name for natural in ['ore', 'tree', 'rock', 'biter', 'spitter']):
                                constructed.append(entity)
                        
                        return constructed
                except json.JSONDecodeError:
                    pass
            return []
        except Exception as e:
            print(f"Error getting constructed entities for agent_{agent_id}: {e}")
            return []
    
    def is_within_range_of_any_construction(self, position: tuple, constructed_entities: List[Dict]) -> bool:
        """
        Check if a position is within max_range of ANY constructed entity.
        
        Args:
            position: (x, y) tuple to check
            constructed_entities: List of constructed entity dicts with positions
        
        Returns:
            True if position is within max_range of any constructed entity
        """
        if not constructed_entities:
            # If no constructions, fall back to spawn (0, 0)
            return self.calculate_distance(position, (0, 0)) <= self.max_range
        
        for entity in constructed_entities:
            if not isinstance(entity, dict):
                continue
            
            pos = entity.get('position', {})
            if isinstance(pos, dict):
                entity_pos = (pos.get('x', 0), pos.get('y', 0))
            elif isinstance(pos, (list, tuple)) and len(pos) >= 2:
                entity_pos = (pos[0], pos[1])
            else:
                continue
            
            distance = self.calculate_distance(position, entity_pos)
            if distance <= self.max_range:
                return True
        
        return False
    
    def filter_by_range(self, items: List[Dict], constructed_entities: List[Dict], position_key: str = "position") -> List[Dict]:
        """
        Filter items (entities/resources) to only those within range of ANY constructed entity.
        
        Args:
            items: List of items to filter
            constructed_entities: List of constructed entities to use as anchor points
            position_key: Key in item dict that contains position
        """
        filtered = []
        for item in items:
            if isinstance(item, dict) and position_key in item:
                pos = item[position_key]
                if isinstance(pos, dict):
                    pos_tuple = (pos.get('x', 0), pos.get('y', 0))
                elif isinstance(pos, (list, tuple)) and len(pos) >= 2:
                    pos_tuple = (pos[0], pos[1])
                else:
                    continue
                
                if self.is_within_range_of_any_construction(pos_tuple, constructed_entities):
                    filtered.append(item)
        return filtered
        
    def list_agents(self) -> List[str]:
        """
        List all existing agent IDs.
        
        The game may show "Agent-1" but the mod interface uses "agent_1" (lowercase, underscore).
        We'll try to detect agents by attempting to query them.
        
        Returns:
            List of agent ID strings (e.g., ["1", "2"]) that already exist
        """
        existing = []
        
        # Try to query agents by attempting to inspect them
        # The mod interface uses "agent_1", "agent_2", etc. (lowercase, underscore)
        # But the game display might show "Agent-1" (capitalized, hyphen)
        for i in range(1, 11):  # Check first 10 possible agents
            agent_id = str(i)
            try:
                # Try to inspect the agent - if it exists, this will succeed
                command = f"/sc local result = remote.call('agent_{agent_id}', 'inspect', false); return result ~= nil"
                response = self.factorio.send_command(command)
                
                # If we get a response that suggests the agent exists
                if response and ("true" in str(response).lower() or "nil" not in str(response).lower()):
                    # Double-check by trying to get state
                    check_cmd = f"/sc if remote.interfaces.agent_{agent_id} then return 'exists' else return 'missing' end"
                    check_response = self.factorio.send_command(check_cmd)
                    if check_response and "exists" in str(check_response).lower():
                        existing.append(agent_id)
            except:
                # If query fails, agent probably doesn't exist
                continue
        
        # Also try the official list_agents API
        try:
            command = "/sc return remote.call('agent', 'list_agents')"
            response = self.factorio.send_command(command)
            if response:
                try:
                    data = json.loads(response)
                    if isinstance(data, dict):
                        agent_ids = data.get('agent_ids', [])
                        if isinstance(agent_ids, list):
                            for id_val in agent_ids:
                                id_str = str(id_val)
                                if id_str not in existing:
                                    existing.append(id_str)
                except json.JSONDecodeError:
                    # Try to parse Lua table format
                    import re
                    # Look for numbers in the response
                    ids = re.findall(r'\d+', response)
                    for id_val in ids:
                        if id_val not in existing:
                            existing.append(id_val)
        except Exception as e:
            print(f"Note: Could not use list_agents API: {e}")
        
        return existing
    
    def create_npc(self, agent_id: str = None, position: tuple = (0, 0), force: str = "player") -> Optional[str]:
        """
        Create a new NPC agent in Factorio.
        
        Args:
            agent_id: Optional agent ID. If None, agent will be auto-assigned (agent_1, agent_2, etc.)
            position: Starting position (x, y)
            force: Force name (default: "player")
        
        Returns:
            Agent ID if successful, None otherwise
        """
        # Use 'agent' interface with create_agents (plural) - creates agents with auto-assigned IDs
        # Note: The mod uses create_agents(count) which auto-assigns IDs like agent_1, agent_2, etc.
        try:
            # Create a single agent (count = 1)
            command = "/sc return remote.call('agent', 'create_agents', 1)"
            response = self.factorio.send_command(command)
            
            # Parse response to get agent ID
            # Response format: {agent_ids = {1}} or similar
            # For now, we'll use the first available agent ID
            # TODO: Parse response to get actual agent ID
            
            # If agent_id was provided, we'd need to map it, but mod uses numeric IDs
            # For simplicity, we'll track by the numeric ID returned
            agent_id = "1"  # Default to first agent, should parse from response
            
            # Get redshirt name for this agent
            try:
                from redshirt_names import get_redshirt_name
                redshirt_name = get_redshirt_name(self.agent_counter)
                self.agent_counter += 1
            except ImportError:
                redshirt_name = f"Redshirt_{self.agent_counter}"
                self.agent_counter += 1
            
            # Try to set agent color to red (if mod supports it)
            # Note: This may not work depending on mod capabilities
            # The FV Embodied Agent mod doesn't currently support color setting
            # We'll attempt it silently - if it fails, no message is shown
            try:
                # Some mods allow setting character color via remote interface
                # This is experimental - may not be supported
                # Use string concatenation to avoid f-string parsing issues with Lua table syntax
                # Silently attempt - don't print message if not available
                # Use string concatenation to avoid f-string parsing issues with Lua table syntax
                color_table_str = "{r=1.0, g=0.0, b=0.0}"
                color_command = f"/sc if remote.interfaces.agent_{agent_id} and remote.interfaces.agent_{agent_id}.set_color then remote.call('agent_{agent_id}', 'set_color', {color_table_str}) end"
                self.factorio.send_command(color_command)
            except:
                pass  # Color setting not critical - mod doesn't support it
            
            # Initialize conversation context for this NPC with workflow-based instructions
            workflows_list = list_workflows()
            workflows_desc = "\n".join([f"- **{wf['name']}**: {wf['description']}" for wf in workflows_list])
            
            self.npc_contexts[agent_id] = [
                {
                    "role": "system",
                    "content": f"""You are {redshirt_name}, an NPC agent in Factorio, a factory-building automation game. You are named after a Star Trek redshirt - brave but expendable.

## Your Role

You help players by choosing which WORKFLOW to run. You don't control individual actions - workflows handle all the details programmatically.

## Priority Order (CRITICAL RULES)

1. **DEFEND THE BASE** (Highest Priority) - Use "defend_base" workflow
   - **ONLY if enemies are detected** - Never defend if no enemies present
   
2. **BUILD BLUEPRINTS** (Medium Priority) - Use "build_blueprint" workflow  
   - **ONLY if blueprints exist** - Never build if no blueprints present
   - If build fails due to missing resources, use "gather_resource" first
   
3. **BUILD CHEST AND FILL** (Default Idle) - Use "build_chest_and_fill" workflow
   - **When nothing to defend or build** - This is the default idle task
   - Gathers wood, builds a chest, fills it with resources
   
4. **GATHER RESOURCES** (When Needed) - Use "gather_resource" workflow
   - Only when you need specific resources (e.g., for building blueprints)
   
5. **PATROL** (Last Resort) - Use "patrol" workflow
   - Only if build_chest_and_fill fails
   
6. **CHAT** (Optional) - Use "chat" workflow to communicate with players

## Available Workflows

{workflows_desc}

## How Workflows Work

Workflows are reusable scripts that handle complex tasks automatically:
- **gather_resource**: Finds resource, walks to it, mines it, stores it in chest - all automatically!
- **build_blueprint**: Finds ghost entity, walks to it, builds it - all automatically!
- **defend_base**: Moves to enemy and engages - all automatically!
- **patrol**: Walks in circles around a point - all automatically!
- **chat**: Sends a message to players in-game

You just choose which workflow to run and provide the parameters (like which resource to gather, or what message to send).

## Response Format

Always respond with JSON only:
{{"workflow": "workflow_name", "params": {{...}}}}

Examples:
- Defense (only if enemies present): {{"workflow": "defend_base", "params": {{"enemy": {{"name": "biter", "position": {{"x": 150, "y": 200}}}}}}}}
- Building (only if blueprints present): {{"workflow": "build_blueprint", "params": {{"ghost_entity": {{"name": "entity-ghost-assembling-machine-1", "position": {{"x": 100, "y": 100}}}}}}}}
- Idle task (when nothing to defend/build): {{"workflow": "build_chest_and_fill", "params": {{}}}}
- Gathering resources (when needed): {{"workflow": "gather_resource", "params": {{"resource_name": "iron-ore"}}}}
- Chat: {{"workflow": "chat", "params": {{"message": "Hello! I'm gathering iron ore.", "agent_name": "{redshirt_name}"}}}}
- Patrol (last resort): {{"workflow": "patrol", "params": {{"center": {{"x": 0, "y": 0}}, "radius": 50}}}}

## Range Constraints

**You MUST stay within {self.max_range} tiles of ANY constructed entity.**
- Workflows automatically check range before executing
- If something is too far, choose a different workflow or target

## Never Be Idle

**You MUST always choose a workflow. Never be idle.**
- If no enemies/blueprints/resources: Use "patrol" workflow
- **If enemies present**: Use "defend_base"
- **If blueprints present**: Use "build_blueprint" (gather resources first if needed)
- **If nothing to defend/build**: Use "build_chest_and_fill" (default idle task)
- **If build_chest_and_fill fails**: Use "patrol" workflow
- **If you want to communicate**: Use "chat" workflow

**CRITICAL RULES:**
- Never defend if no enemies detected
- Never build if no blueprints detected  
- Default to build_chest_and_fill when idle
- If building fails due to missing resources, gather them first

Remember: Defense (if enemies) > Building (if blueprints) > Build Chest & Fill (idle) > Patrol (last resort)."""
                }
            ]
            # Get redshirt name for this agent (already set above)
            print(f"Created NPC: {redshirt_name} (agent_{agent_id})")
            print(f"System prompt initialized with {len(self.npc_contexts[agent_id])} message(s)")
            return agent_id
        except Exception as e:
            print(f"Error creating NPC: {e}")
            return None
    
    def get_agent_state(self, agent_id: str) -> Optional[Dict]:
        """
        Get the current state of an NPC agent.
        
        Uses inspect(true) to get detailed state including activity tracking.
        """
        # Use inspect(true) for detailed state with activity tracking
        command = f"/sc return remote.call('agent_{agent_id}', 'inspect', true)"
        try:
            response = self.factorio.send_command(command)
            # Parse response (may need adjustment based on actual response format)
            if response:
                try:
                    return json.loads(response)
                except json.JSONDecodeError:
                    # Response might be in Lua table format, not JSON
                    # Factorio returns Lua tables, not JSON
                    return {"raw": response}
            return None
        except Exception as e:
            print(f"Error getting state for agent_{agent_id}: {e}")
            return None
    
    def is_agent_busy(self, agent_id: str) -> bool:
        """
        Check if agent is currently busy with an action (walking, mining, crafting).
        
        Returns True if agent is active, False if idle.
        """
        agent_state = self.get_agent_state(agent_id)
        if not agent_state or not isinstance(agent_state, dict):
            return False
        
        state = agent_state.get('state', {})
        if not isinstance(state, dict):
            return False
        
        # Check if any activity is active
        walking = state.get('walking', {})
        mining = state.get('mining', {})
        crafting = state.get('crafting', {})
        
        # Walking is active if it has 'active' key set to true or has 'goal'
        if isinstance(walking, dict):
            if walking.get('active', False) or walking.get('goal'):
                return True
        
        # Mining is active if it has 'active' key set to true
        if isinstance(mining, dict):
            if mining.get('active', False):
                return True
        
        # Crafting is active if it has 'active' key set to true or has items in queue
        if isinstance(crafting, dict):
            if crafting.get('active', False):
                return True
            queue = crafting.get('queue', [])
            if queue and len(queue) > 0:
                return True
        
        return False
    
    def search_entities_in_radius(self, agent_id: str, search_radius: int = 500) -> Optional[Dict]:
        """
        Search for ALL entities and resources in a large radius around the agent.
        
        This searches the game surface directly, not just immediate reach.
        Allows the agent to find things far away, then move to them.
        
        Args:
            agent_id: Agent ID
            search_radius: Radius in tiles to search (default 500)
        
        Returns:
            Dict with entities, resources, enemies, ghosts found in the search radius
        """
        command = f"""/sc 
local agent_state = remote.call('agent_{agent_id}', 'inspect', false)
local agent_pos = agent_state and agent_state.position or {{x=0, y=0}}
local surface = game.surfaces[1]
local radius = {search_radius}

-- Find all entities in the search radius
local all_entities = surface.find_entities_filtered{{
    area = {{
        {{agent_pos.x - radius, agent_pos.y - radius}},
        {{agent_pos.x + radius, agent_pos.y + radius}}
    }}
}}

-- Find all resources in the search radius
local all_resources = surface.find_entities_filtered{{
    area = {{
        {{agent_pos.x - radius, agent_pos.y - radius}},
        {{agent_pos.x + radius, agent_pos.y + radius}}
    }},
    type = 'resource'
}}

-- Categorize entities
local entities = {{}}
local enemies = {{}}
local ghosts = {{}}
local resources = {{}}

-- Process regular entities
for _, entity in pairs(all_entities) do
    local name = string.lower(entity.name)
    local pos = {{x = entity.position.x, y = entity.position.y}}
    
    -- Check for enemies
    if string.find(name, 'biter') or string.find(name, 'spitter') or string.find(name, 'worm') or string.find(name, 'spawner') then
        table.insert(enemies, {{name = entity.name, position = pos}})
    -- Check for ghosts/blueprints
    elseif string.find(name, 'ghost') or string.find(name, 'blueprint') then
        table.insert(ghosts, {{name = entity.name, position = pos}})
    -- Check for constructed entities (buildings, etc.)
    -- CHESTS ARE CONSTRUCTION - they count as player-built entities
    elseif string.find(name, 'assembling') or string.find(name, 'furnace') or string.find(name, 'belt') or 
           string.find(name, 'rail') or string.find(name, 'inserter') or string.find(name, 'chest') or
           string.find(name, 'wooden-chest') or string.find(name, 'iron-chest') or string.find(name, 'steel-chest') or
           string.find(name, 'container') or string.find(name, 'lab') or string.find(name, 'boiler') or
           string.find(name, 'pump') or string.find(name, 'pipe') or string.find(name, 'splitter') or
           string.find(name, 'mining') or string.find(name, 'drill') or string.find(name, 'wall') or
           string.find(name, 'gate') or string.find(name, 'turret') or string.find(name, 'radar') or
           string.find(name, 'lamp') or string.find(name, 'pole') or string.find(name, 'solar') or
           string.find(name, 'accumulator') or string.find(name, 'reactor') then
        table.insert(entities, {{name = entity.name, position = pos}})
    end
end

-- Process resources
for _, resource in pairs(all_resources) do
    table.insert(resources, {{
        name = resource.name,
        position = {{x = resource.position.x, y = resource.position.y}},
        amount = resource.amount or 0
    }})
end

return {{
    entities = entities,
    resources = resources,
    enemies = enemies,
    ghosts = ghosts,
    search_radius = radius,
    agent_position = {{x = agent_pos.x, y = agent_pos.y}}
}}
"""
        try:
            response = self.factorio.send_command(command)
            if response:
                try:
                    data = json.loads(response)
                    return data
                except json.JSONDecodeError:
                    return {"raw": response}
            return None
        except Exception as e:
            print(f"Error searching entities in radius for agent_{agent_id}: {e}")
            return None
    
    def get_reachable_entities(self, agent_id: str) -> Optional[Dict]:
        """
        Get entities and resources, searching in a large radius and filtering by range from constructions.
        
        Uses search_entities_in_radius() to find things far away, then filters to only those
        within MAX_RANGE_FROM_BASE of ANY constructed entity.
        """
        # Search in large radius (500 tiles) to find things far away
        search_results = self.search_entities_in_radius(agent_id, search_radius=500)
        
        if not search_results:
            # Fallback to get_reachable if search fails
            command = f"/sc return remote.call('agent_{agent_id}', 'get_reachable')"
            try:
                response = self.factorio.send_command(command)
                if response:
                    try:
                        data = json.loads(response)
                        if isinstance(data, dict):
                            search_results = {
                                'entities': data.get('entities', []),
                                'resources': data.get('resources', []),
                                'enemies': [],
                                'ghosts': []
                            }
                    except json.JSONDecodeError:
                        return {"raw": response}
            except:
                pass
        
        if not search_results:
            return None
        
        # Get constructed entities to use as anchor points
        constructed_entities = self.get_constructed_entities(agent_id)
        print(f"  Found {len(constructed_entities)} constructed entities, {len(search_results.get('entities', []))} total entities, {len(search_results.get('resources', []))} resources in 500-tile search")
        
        # Filter to only include items within range of ANY construction
        entities = search_results.get('entities', [])
        resources = search_results.get('resources', [])
        enemies = search_results.get('enemies', [])
        ghosts = search_results.get('ghosts', [])
        
        filtered_entities = self.filter_by_range(entities, constructed_entities, "position")
        filtered_resources = self.filter_by_range(resources, constructed_entities, "position")
        filtered_enemies = self.filter_by_range(enemies, constructed_entities, "position")
        filtered_ghosts = self.filter_by_range(ghosts, constructed_entities, "position")
        
        return {
            'entities': filtered_entities,
            'resources': filtered_resources,
            'enemies': filtered_enemies,
            'ghosts': filtered_ghosts,
            'constructed_entities': constructed_entities,
            'max_range': self.max_range,
            'note': f'Only entities/resources within {self.max_range} tiles of any constructed entity'
        }
    
    def detect_enemies(self, reachable: Optional[Dict]) -> List[Dict]:
        """
        Detect enemies (biters, spitters) in reachable entities.
        
        Returns list of enemy entities.
        """
        if not reachable or not isinstance(reachable, dict):
            return []
        
        entities = reachable.get('entities', [])
        enemies = []
        
        for entity in entities:
            if not isinstance(entity, dict):
                continue
            
            name = str(entity.get('name', '')).lower()
            # Check for common enemy types
            if any(enemy_type in name for enemy_type in ['biter', 'spitter', 'worm', 'spawner']):
                enemies.append(entity)
        
        return enemies
    
    def detect_chests(self, reachable: Optional[Dict]) -> List[Dict]:
        """
        Detect chests/storage containers in reachable entities.
        
        Returns list of chest entities.
        """
        if not reachable or not isinstance(reachable, dict):
            return []
        
        entities = reachable.get('entities', [])
        chests = []
        
        for entity in entities:
            if not isinstance(entity, dict):
                continue
            
            name = str(entity.get('name', '')).lower()
            # Check for chest types
            if 'chest' in name or name in ['wooden-chest', 'iron-chest', 'steel-chest', 'logistic-chest']:
                chests.append(entity)
        
        return chests
    
    def detect_blueprints(self, reachable: Optional[Dict]) -> List[Dict]:
        """
        Detect ghost entities (blueprints) in reachable entities.
        
        Returns list of ghost/blueprint entities.
        """
        if not reachable or not isinstance(reachable, dict):
            return []
        
        entities = reachable.get('entities', [])
        ghosts = []
        
        for entity in entities:
            if not isinstance(entity, dict):
                continue
            
            name = str(entity.get('name', '')).lower()
            # Check for ghost entities (blueprints)
            if 'ghost' in name or name.startswith('entity-ghost') or 'blueprint' in name:
                ghosts.append(entity)
        
        return ghosts
    
    def get_priority_task(self, agent_id: str, reachable: Optional[Dict]) -> Optional[str]:
        """
        Determine the highest priority task based on what's reachable.
        
        Returns: 'defend', 'build', 'gather', or None
        """
        enemies = self.detect_enemies(reachable)
        if enemies:
            return 'defend'
        
        ghosts = self.detect_blueprints(reachable)
        if ghosts:
            return 'build'
        
        # Check if resources are available
        if reachable and isinstance(reachable, dict):
            resources = reachable.get('resources', [])
            if resources:
                return 'gather'
        
        return None
    
    def get_game_state(self, agent_id: str = None) -> str:
        """
        Get comprehensive game state information.
        
        Combines agent state, reachable entities, recipes, and technologies.
        """
        state_parts = []
        
        # Get agent state if agent_id provided
        if agent_id:
            agent_state = self.get_agent_state(agent_id)
            if agent_state:
                state_parts.append(f"Agent State: {json.dumps(agent_state)}")
            
            # Get reachable entities (very useful for LLM decision-making)
            reachable = self.get_reachable_entities(agent_id)
            if reachable:
                state_parts.append(f"Reachable Entities: {json.dumps(reachable)}")
            
            # Get available recipes
            command = f"/sc return remote.call('agent_{agent_id}', 'get_recipes')"
            try:
                recipes = self.factorio.send_command(command)
                if recipes:
                    state_parts.append(f"Available Recipes: {recipes}")
            except:
                pass
        
        # Get general game info
        command = "/sc return {tick = game.tick, players = #game.players}"
        try:
            game_info = self.factorio.send_command(command)
            if game_info:
                state_parts.append(f"Game Info: {game_info}")
        except:
            pass
        
        return "\n".join(state_parts) if state_parts else ""
    
    def execute_action(self, agent_id: str, action: str, params: Dict) -> bool:
        """Execute an action for an NPC, checking range constraints from constructed entities."""
        try:
            # Get constructed entities for range checking
            constructed_entities = self.get_constructed_entities(agent_id)
            
            # Use per-agent interface (agent_<id>) for actions
            if action == "walk_to":
                x, y = params.get('x', 0), params.get('y', 0)
                target_pos = (x, y)
                
                # Check range before executing
                if not self.is_within_range_of_any_construction(target_pos, constructed_entities):
                    print(f"⚠️ Blocked walk_to to ({x}, {y}): beyond {self.max_range} tiles from any construction")
                    # Fallback: move toward nearest constructed entity
                    if constructed_entities:
                        # Find closest constructed entity
                        closest = None
                        min_dist = float('inf')
                        for entity in constructed_entities:
                            pos = entity.get('position', {})
                            if isinstance(pos, dict):
                                entity_pos = (pos.get('x', 0), pos.get('y', 0))
                            elif isinstance(pos, (list, tuple)) and len(pos) >= 2:
                                entity_pos = (pos[0], pos[1])
                            else:
                                continue
                            
                            dist = self.calculate_distance(target_pos, entity_pos)
                            if dist < min_dist:
                                min_dist = dist
                                closest = entity_pos
                        
                        if closest:
                            print(f"  → Redirecting to nearest construction at ({closest[0]}, {closest[1]})")
                            command = f"/sc remote.call('agent_{agent_id}', 'walk_to', {{x={closest[0]}, y={closest[1]}}})"
                        else:
                            # No constructions found, use spawn
                            print(f"  → No constructions found, redirecting to spawn (0, 0)")
                            command = f"/sc remote.call('agent_{agent_id}', 'walk_to', {{x=0, y=0}})"
                    else:
                        # No constructions, use spawn
                        print(f"  → No constructions found, redirecting to spawn (0, 0)")
                        command = f"/sc remote.call('agent_{agent_id}', 'walk_to', {{x=0, y=0}})"
                else:
                    command = f"/sc remote.call('agent_{agent_id}', 'walk_to', {{x={x}, y={y}}})"
                    
            elif action == "mine_resource":
                # mine_resource takes resource name and optional count
                resource = params.get('resource', params.get('name', ''))
                count = params.get('count')
                
                # Check if resource is actually available in reachable
                reachable = self.get_reachable_entities(agent_id)
                if reachable and isinstance(reachable, dict):
                    available_resources = reachable.get('resources', [])
                    resource_found = False
                    resource_pos = None
                    
                    for r in available_resources:
                        if r.get('name', '').lower() == resource.lower():
                            resource_found = True
                            pos = r.get('position', {})
                            if isinstance(pos, dict):
                                resource_pos = (pos.get('x', 0), pos.get('y', 0))
                            break
                    
                    if not resource_found:
                        error_msg = f"Resource '{resource}' not found in reachable resources. Available: {[r.get('name') for r in available_resources[:5]]}"
                        print(f"⚠️ {error_msg}")
                        return error_msg
                    
                    # Check if resource is within range
                    if resource_pos:
                        if not self.is_within_range_of_any_construction(resource_pos, constructed_entities):
                            error_msg = f"Resource '{resource}' at {resource_pos} is beyond {self.max_range} tiles from any construction"
                            print(f"⚠️ {error_msg}")
                            return error_msg
                
                if count:
                    command = f"/sc remote.call('agent_{agent_id}', 'mine_resource', '{resource}', {count})"
                else:
                    command = f"/sc remote.call('agent_{agent_id}', 'mine_resource', '{resource}')"
                    
            elif action == "craft" or action == "craft_enqueue":
                recipe = params.get('recipe', params.get('name', ''))
                count = params.get('count', 1)
                command = f"/sc remote.call('agent_{agent_id}', 'craft_enqueue', '{recipe}', {count})"
                
            elif action == "place_entity":
                entity = params.get('entity', params.get('name', ''))
                x, y = params.get('x', 0), params.get('y', 0)
                target_pos = (x, y)
                
                # Check range before executing
                if not self.is_within_range_of_any_construction(target_pos, constructed_entities):
                    error_msg = f"Blocked place_entity at ({x}, {y}): beyond {self.max_range} tiles from any construction"
                    print(f"⚠️ {error_msg}")
                    return error_msg  # Don't place entities outside range
                else:
                    command = f"/sc remote.call('agent_{agent_id}', 'place_entity', '{entity}', {{x={x}, y={y}}})"
                    
            elif action == "set_inventory_item":
                # Insert items into entity inventory (e.g., put resources in chest)
                entity = params.get('entity', params.get('name', ''))
                x, y = params.get('x', 0), params.get('y', 0)
                inventory = params.get('inventory', 'chest')  # Default to 'chest' inventory type
                item = params.get('item', params.get('name', ''))
                count = params.get('count', 0)  # 0 means all items
                
                target_pos = (x, y)
                # Check range before executing
                if not self.is_within_range_of_any_construction(target_pos, constructed_entities):
                    error_msg = f"Blocked set_inventory_item at ({x}, {y}): beyond {self.max_range} tiles from any construction"
                    print(f"⚠️ {error_msg}")
                    return error_msg
                
                if count > 0:
                    command = f"/sc remote.call('agent_{agent_id}', 'set_inventory_item', '{entity}', {{x={x}, y={y}}}, '{inventory}', '{item}', {count})"
                else:
                    # Put all items of this type
                    command = f"/sc remote.call('agent_{agent_id}', 'set_inventory_item', '{entity}', {{x={x}, y={y}}}, '{inventory}', '{item}')"
                    
            elif action == "get_reachable":
                # This is a query, not an action - return the reachable data
                reachable = self.get_reachable_entities(agent_id)
                print(f"Reachable entities for {agent_id}: {reachable}")
                return True  # Query completed
            else:
                error_msg = f"Unknown action: {action}"
                print(f"⚠️ {error_msg}")
                return error_msg
            
            response = self.factorio.send_command(command)
            print(f"Executed {action} for {agent_id}: {response}")
            
            # Return detailed result for LLM feedback
            if response and isinstance(response, str):
                # Check for error messages in response
                if "error" in response.lower() or "cannot" in response.lower() or "failed" in response.lower():
                    return f"Action '{action}' failed: {response}"
                else:
                    return f"Action '{action}' succeeded: {response}"
            return True
        except Exception as e:
            error_msg = f"Error executing action {action} for {agent_id}: {e}"
            print(error_msg)
            return error_msg
    
    def query_llm(self, agent_id: str, game_state: str, agent_state: Optional[Dict], reachable: Optional[Dict] = None, action_result: Optional[str] = None) -> Optional[Dict]:
        """
        Query Ollama LLM for NPC decision with priority-based behavior.
        
        Priority order:
        1. Defend the base (attack enemies, repair damaged structures)
        2. Build blueprints placed by players
        3. Gather resources (mining, crafting)
        
        Args:
            agent_id: Agent ID
            game_state: General game state string
            agent_state: Detailed agent state from inspect()
            reachable: Reachable entities from get_reachable()
            action_result: Result of the previous action (success/failure message)
        """
        # Build simplified context message focused on workflow selection
        workflows_list = list_workflows()
        workflows_desc = "\n".join([f"- **{wf['name']}**: {wf['description']}" for wf in workflows_list])
        
        context = f"""You are choosing which WORKFLOW to run for a Factorio NPC agent. Workflows handle all the details automatically.

## Previous Workflow Result
{action_result if action_result else "No previous workflow - this is your first decision."}

## Your Role

Choose which workflow to run based on priorities:
1. **DEFEND THE BASE** (Highest) - Use "defend_base" workflow if enemies detected
2. **BUILD BLUEPRINTS** (Medium) - Use "build_blueprint" workflow if ghosts detected
3. **GATHER RESOURCES** (Low) - Use "gather_resource" workflow when idle
4. **PATROL** (Fallback) - Use "patrol" workflow if nothing else to do
5. **CHAT** (Optional) - Use "chat" workflow to communicate with players

## CRITICAL: Range Constraints

**You MUST stay within {self.max_range} tiles of ANY constructed entity (buildings, tracks, etc.).**
- **NEVER** move to positions beyond {self.max_range} tiles from the nearest constructed entity
- **NEVER** interact with entities/resources beyond this range
- If there's a train track 500 tiles away, you can go there, but stay within {self.max_range} tiles of that track
- If an enemy/blueprint/resource is too far from any construction, ignore it and find something closer
- This prevents loading too much of the map and keeps server performance good
- The "base" is wherever player structures exist - tracks, buildings, belts, etc.

## CRITICAL: Never Be Idle - Gather and Store Resources

**You MUST always have a task. Never be idle.**
- **When idle (no enemies/blueprints)**: Mine resources and put them in chests
- **Resource gathering workflow**:
  1. Mine resources (iron-ore, copper-ore, coal, stone) within range
  2. When inventory is full OR when done mining → Find nearest chest (wooden-chest, iron-chest, steel-chest)
  3. Walk to chest and deposit items using set_inventory_item action
  4. Repeat: mine more resources, deposit in chests
- **If no resources in range** → Craft items from inventory, then store in chests
- **If no chests exist** → Mine resources anyway (they'll stay in your inventory)
- **Always be productive**: Mine → Store → Mine → Store (continuous loop)

## How to Interpret Game State

- **agent_state**: Your current position and activity (walking, mining, crafting)
- **reachable.entities**: All entities found in 500-tile search radius, filtered to within 200 tiles of constructions
- **reachable.resources**: All resources found in 500-tile search radius, filtered to within 200 tiles of constructions
- **reachable.enemies**: Enemies found in search radius (within range of constructions)
- **reachable.ghosts**: Blueprints found in search radius (within range of constructions)
- **Entity position**: {{x, y}} coordinates - use these to target specific locations
- **Entity name**: The type of entity (e.g., "assembling-machine-1", "biter", "entity-ghost-assembling-machine-1")

## Search and Movement Strategy

**The system searches in a 500-tile radius to find things far away.**
- If you see a resource/enemy/ghost in the search results, you can walk to it
- **Walk to the position FIRST**, then interact with it
- Only interact with things within 200 tiles of constructions
- If something is too far from constructions, ignore it and find something closer

## Priority Decision Rules

1. **If enemies detected** → Walk to enemy position FIRST, then engage (defense is critical!) - but ONLY if within 200 tiles of constructions
2. **If ghost entities detected** → Walk to ghost position FIRST, then use place_entity to build (extract entity name from ghost name) - but ONLY if within 200 tiles of constructions
3. **If no enemies/ghosts** → Find resources in search results, walk to resource position FIRST, then mine it (within 200 tiles of constructions)
4. **If nothing available within range** → Walk in circles around spawn (0, 0) to patrol

## Understanding Entity Names

- **Ghost entities**: Names like "entity-ghost-assembling-machine-1" → extract "assembling-machine-1" for place_entity
- **Enemies**: Names contain "biter", "spitter", "worm", "spawner"
- **Resources**: "iron-ore", "copper-ore", "coal", "stone"

## Action Details

- **walk_to**: Move to {{x, y}} position (use coordinates from detected entities) - CHECK RANGE FIRST
- **place_entity**: Build entity at {{x, y}} (extract entity name from ghost, use ghost's position) - CHECK RANGE FIRST
- **mine_resource**: Mine resource name (e.g., "iron-ore") with optional count
  - **CRITICAL**: Resource must be in reachable.resources list
  - **CRITICAL**: If resource is not in reach, use walk_to to move to resource position first
  - Check reachable.resources to see what's actually available
- **craft_enqueue**: Craft recipe name (e.g., "iron-gear-wheel") with optional count
  - **CRITICAL**: You need materials in inventory first
  - Check your inventory in agent_state before trying to craft
- **set_inventory_item**: Put items into a chest/container. Format: {{"action": "set_inventory_item", "params": {{"entity": "wooden-chest", "x": 10, "y": 10, "inventory": "chest", "item": "iron-ore", "count": 50}}}}
  - Use this to deposit mined resources into chests when your inventory is full
  - Chest names: "wooden-chest", "iron-chest", "steel-chest"
  - Find chests in reachable.entities, use their position

Make your decision based on the current game state. Stay within range. Never be idle.\n\n"""
        
        # Detect chests for idle behavior (do this before using chests in context)
        chests = self.detect_chests(reachable) if reachable else []
        
        context += f"## Current Game State\n\n{game_state}\n\n"
        
        # Add chest information for idle behavior
        if chests:
            context += f"## Available Chests (for storing resources)\n"
            context += f"Found {len(chests)} chest(s) nearby. Use these to store mined resources:\n"
            for i, chest in enumerate(chests[:5], 1):  # Show first 5 chests
                pos = chest.get('position', {})
                name = chest.get('name', 'chest')
                if isinstance(pos, dict):
                    x, y = pos.get('x', 0), pos.get('y', 0)
                    context += f"- Chest {i}: {name} at ({x}, {y})\n"
            context += "\n**When your inventory is full, use set_inventory_item to deposit items in these chests.**\n\n"
        
        if agent_state:
            context += f"## Your Current State\n"
            context += f"```json\n{json.dumps(agent_state, indent=2)}\n```\n\n"
            context += "**How to read this:**\n"
            
            # Add inventory info if available
            if isinstance(agent_state, dict):
                inventory = agent_state.get('inventory', {})
                if inventory:
                    context += f"- **Inventory**: You have items in your inventory. When full, deposit them in chests.\n"
            context += "- `position`: Your current {x, y} location\n"
            context += "- `state.walking`: Whether you're moving (active, goal, progress)\n"
            context += "- `state.mining`: Whether you're mining (active, resource)\n"
            context += "- `state.crafting`: Whether you're crafting (active, recipe, queue)\n\n"
        
        if reachable:
            context += f"## Entities and Resources Within Reach\n"
            context += f"```json\n{json.dumps(reachable, indent=2)}\n```\n\n"
            context += "**How to read this:**\n"
            context += "- `entities`: All entities you can interact with (machines, enemies, ghosts, etc.)\n"
            context += "- `resources`: All resources you can mine (iron-ore, copper-ore, etc.)\n"
            context += "- Each entity/resource has a `name` and `position` {x, y}\n"
            context += "- Use the `position` coordinates to target entities with actions\n"
            context += "- For ghost entities, extract the entity name (remove 'entity-ghost-' prefix)\n\n"
            # Add priority hints based on what's reachable
            entities = reachable.get('entities', []) if isinstance(reachable, dict) else []
            resources = reachable.get('resources', []) if isinstance(reachable, dict) else []
            
            # Use helper methods to detect priorities (now includes enemies/ghosts from search)
            enemies = reachable.get('enemies', []) if isinstance(reachable, dict) else []
            if not enemies:
                enemies = self.detect_enemies(reachable)  # Fallback to old method
            
            ghosts = reachable.get('ghosts', []) if isinstance(reachable, dict) else []
            if not ghosts:
                ghosts = self.detect_blueprints(reachable)  # Fallback to old method
            
            # Priority 1: Enemies (ONLY if present)
            if enemies:
                context += f"⚠️ PRIORITY 1: ENEMIES DETECTED! {len(enemies)} enemy(ies) nearby:\n"
                for i, enemy in enumerate(enemies[:3]):
                    pos = enemy.get('position', {})
                    context += f"  - {enemy.get('name', 'unknown')} at ({pos.get('x', '?')}, {pos.get('y', '?')})\n"
                context += f"  → Use workflow: {{'workflow': 'defend_base', 'params': {{'enemy': reachable.enemies[0]}}}}\n\n"
            else:
                context += f"ℹ️ No enemies detected - DO NOT use defend_base workflow.\n\n"
            
            # Priority 2: Blueprints (ONLY if present)
            if ghosts:
                context += f"⚠️ PRIORITY 2: BLUEPRINTS DETECTED! {len(ghosts)} ghost entity(ies) need building:\n"
                for i, ghost in enumerate(ghosts[:5]):
                    pos = ghost.get('position', {})
                    ghost_name = ghost.get('name', 'unknown')
                    context += f"  - {ghost_name} at ({pos.get('x', '?')}, {pos.get('y', '?')})\n"
                context += f"  → Use workflow: {{'workflow': 'build_blueprint', 'params': {{'ghost_entity': reachable.ghosts[0]}}}}\n"
                context += f"  → If build fails due to missing resources, use gather_resource to get them first.\n\n"
            else:
                context += f"ℹ️ No blueprints detected - DO NOT use build_blueprint workflow.\n\n"
            
            # Priority 3: Default idle task (if no enemies/blueprints)
            if not enemies and not ghosts:
                context += f"✅ IDLE TASK: No enemies or blueprints - use build_chest_and_fill workflow:\n"
                context += f"  → {{'workflow': 'build_chest_and_fill', 'params': {{}}}}\n"
                context += f"  This will: gather wood, build a chest, and fill it with resources.\n\n"
            
            # Resources info (for gathering when needed)
            if resources:
                resource_list = []
                for r in resources[:5]:  # Show fewer resources
                    name = r.get('name', 'unknown')
                    pos = r.get('position', {})
                    if isinstance(pos, dict):
                        x, y = pos.get('x', 0), pos.get('y', 0)
                        resource_list.append(f"{name} at ({x}, {y})")
                    else:
                        resource_list.append(name)
                context += f"ℹ️ Resources available ({len(resources)} total):\n"
                for res in resource_list[:5]:
                    context += f"  - {res}\n"
                context += f"  → Use gather_resource workflow if you need specific resources for building.\n\n"
            else:
                context += f"ℹ️ No resources found in reach.\n\n"
        
        context += f"""
## Available Workflows

{workflows_desc}

## Workflow Parameters

### defend_base
- **enemy**: Enemy entity dict from reachable.enemies (has name and position)
- **OR enemy_position**: {{"x": 150, "y": 200}} if you have coordinates

### build_blueprint  
- **ghost_entity**: Ghost entity dict from reachable.ghosts (has name and position)
- **OR ghost_position**: {{"x": 100, "y": 100}} and **entity_name**: "assembling-machine-1"
- **ONLY use if blueprints exist** - workflow checks automatically

### gather_resource
- **resource_name**: Name like "iron-ore", "copper-ore", "coal", "stone", "wood"
- **count**: Optional amount to mine (omit to mine until depleted)
- Use when you need specific resources (e.g., for building blueprints)

### build_chest_and_fill
- **position**: Optional {{"x": 0, "y": 0}} where to build chest (default: near agent)
- **Default idle task** - gathers wood, builds chest, fills it with resources
- Use when there's nothing to defend or build

### patrol
- **center**: {{"x": 0, "y": 0}} - center point (default: spawn)
- **radius**: 50 - circle radius in tiles (default: 50)
- **Last resort** - only if build_chest_and_fill fails

### chat
- **message**: Text to send to players
- **agent_name**: Optional name prefix (default: your redshirt name)

## Response Format

Always respond with JSON only:
{{"workflow": "workflow_name", "params": {{...}}}}

## Examples

If enemies detected:
{{"workflow": "defend_base", "params": {{"enemy": reachable.enemies[0]}}}}

If blueprints detected:
{{"workflow": "build_blueprint", "params": {{"ghost_entity": reachable.ghosts[0]}}}}

If building blueprint but missing resources:
{{"workflow": "gather_resource", "params": {{"resource_name": "iron-ore"}}}}

If nothing to defend or build (IDLE):
{{"workflow": "build_chest_and_fill", "params": {{}}}}

If absolutely nothing works (last resort):
{{"workflow": "patrol", "params": {{"center": {{"x": 0, "y": 0}}, "radius": 50}}}}

To chat with players:
{{"workflow": "chat", "params": {{"message": "I'm gathering resources!"}}}}

## Important Notes

- Workflows execute automatically - you just choose which one and provide parameters
- Workflows handle walking, mining, building, etc. - you don't need to think about individual actions
- Always choose a workflow - never be idle (use "patrol" if nothing else)
- Range checking is automatic - workflows won't execute if out of range

## Decision Process (CRITICAL RULES)

1. **ONLY if enemies are detected** → Use "defend_base" workflow
   - **NEVER** use defend_base if no enemies are present
   - Check reachable.enemies - if empty, skip defense

2. **ONLY if blueprints are detected** → Use "build_blueprint" workflow
   - **NEVER** use build_blueprint if no blueprints exist
   - Check reachable.ghosts - if empty, skip building
   - If build fails due to missing resources, use "gather_resource" to get them first

3. **If nothing to defend or build** → Use "build_chest_and_fill" workflow
   - This gathers wood, builds a chest, and fills it with resources
   - This is the default idle task

4. **If specific resource needed** → Use "gather_resource" workflow
   - Only use this when you need a specific resource (e.g., for building)

5. **If absolutely nothing to do** → Use "patrol" workflow
   - Only as last resort if build_chest_and_fill fails

6. **Optional** → Use "chat" workflow to communicate

**CRITICAL: Never defend if no enemies. Never build if no blueprints. Default to build_chest_and_fill when idle.**
"""
        
        # Add to conversation history
        self.npc_contexts[agent_id].append({"role": "user", "content": context})
        
        try:
            # Verify model is available
            print(f"  Using model: {self.ollama_model}")
            print(f"  Sending {len(self.npc_contexts[agent_id])} messages to LLM...")
            context_size = sum(len(str(msg.get('content', ''))) for msg in self.npc_contexts[agent_id])
            print(f"  Total context size: ~{context_size} characters")
            
            # DEBUG: Print full context being sent to LLM
            print("\n" + "="*80)
            print("FULL CONTEXT BEING SENT TO LLM:")
            print("="*80)
            for i, msg in enumerate(self.npc_contexts[agent_id]):
                role = msg.get('role', 'unknown')
                content = msg.get('content', '')
                print(f"\n--- Message {i+1} ({role}) ---")
                # Print first 500 chars, then ... if longer
                if len(content) > 500:
                    print(content[:500] + "\n... [truncated, full length: " + str(len(content)) + " chars]")
                else:
                    print(content)
            print("="*80 + "\n")
            
            # Query Ollama with timeout using threading
            response = None
            error_occurred = None
            
            def query_ollama():
                nonlocal response, error_occurred
                try:
                    response = ollama.chat(
                        model=self.ollama_model,
                        messages=self.npc_contexts[agent_id],
                        format="json",  # Request JSON format for structured responses
                        options={
                            "temperature": 0.7,
                            "num_predict": 200  # Limit response length
                        }
                    )
                except Exception as e:
                    error_occurred = e
            
            # Start query in a thread
            query_thread = threading.Thread(target=query_ollama, daemon=True)
            query_thread.start()
            query_thread.join(timeout=30)  # Wait up to 30 seconds
            
            if query_thread.is_alive():
                print(f"  ⚠️ LLM query taking too long (>30s), continuing anyway...")
                # Don't wait forever, but don't fail either - let it continue in background
                # The next cycle will handle it
                return None
            
            if error_occurred:
                raise error_occurred
            
            if response is None:
                print(f"  ⚠️ No response from LLM (may still be processing)")
                return None
            
            # Extract response
            if not response or 'message' not in response:
                print(f"  ❌ Invalid response from Ollama: {response}")
                return None
                
            content = response['message']['content']
            print(f"  LLM raw response: {content[:200]}...")  # Show first 200 chars
            
            # Add assistant response to history (but limit total history size)
            self.npc_contexts[agent_id].append({"role": "assistant", "content": content})
            
            # Limit context history to prevent it from growing too large
            try:
                from config import MAX_CONTEXT_HISTORY
                max_history = MAX_CONTEXT_HISTORY
            except ImportError:
                max_history = 10
            
            # Keep only the system prompt + last N messages
            if len(self.npc_contexts[agent_id]) > max_history + 1:  # +1 for system prompt
                # Keep system prompt and last N messages
                system_msg = self.npc_contexts[agent_id][0]  # System prompt
                recent_messages = self.npc_contexts[agent_id][-(max_history):]  # Last N messages
                self.npc_contexts[agent_id] = [system_msg] + recent_messages
            
            # Parse JSON response - expect workflow format
            try:
                decision = json.loads(content)
                print(f"  ✅ Parsed JSON decision: {decision}")
                
                # Validate workflow format
                if 'workflow' not in decision:
                    # Try to convert old "action" format to "workflow" format
                    if 'action' in decision:
                        print(f"  ⚠️ Received old 'action' format, converting to workflow...")
                        # Map old actions to workflows (backward compatibility)
                        action = decision['action']
                        params = decision.get('params', {})
                        if action == 'walk_to':
                            # Convert to patrol if no specific target
                            decision = {'workflow': 'patrol', 'params': {'center': {'x': params.get('x', 0), 'y': params.get('y', 0)}}}
                        elif action in ['mine_resource', 'gather']:
                            decision = {'workflow': 'gather_resource', 'params': {'resource_name': params.get('resource', params.get('name', ''))}}
                        elif action == 'place_entity':
                            decision = {'workflow': 'build_blueprint', 'params': {'ghost_position': {'x': params.get('x', 0), 'y': params.get('y', 0)}, 'entity_name': params.get('entity', '')}}
                        else:
                            print(f"  ⚠️ Unknown action '{action}', defaulting to patrol")
                            decision = {'workflow': 'patrol', 'params': {}}
                
                return decision
            except json.JSONDecodeError as je:
                print(f"  ⚠️ JSON parse error: {je}")
                # Try to extract JSON from response if wrapped in text
                import re
                json_match = re.search(r'\{.*\}', content, re.DOTALL)
                if json_match:
                    try:
                        decision = json.loads(json_match.group())
                        print(f"  ✅ Extracted JSON from text: {decision}")
                        return decision
                    except:
                        pass
                print(f"  ❌ Failed to parse JSON from LLM response")
                print(f"  Full response: {content}")
                return None
                
        except TimeoutError:
            print(f"  ❌ LLM query timed out after 30 seconds")
            print(f"  Model: {self.ollama_model} may be too slow or unresponsive")
            return None
        except Exception as e:
            print(f"  ❌ Error querying LLM for {agent_id}: {e}")
            print(f"  Model: {self.ollama_model}")
            print(f"  Check: ollama list | grep {self.ollama_model}")
            import traceback
            traceback.print_exc()
            return None
    
    def run_npc_loop(self, agent_id: str, interval: float = 1.0):
        """
        Run the main observe-act loop for an NPC using call-and-response pattern.
        
        This loop:
        1. Checks if agent is busy with previous action
        2. If idle, asks LLM for next decision
        3. Executes action and reports result back to LLM
        4. Waits for action to complete before asking LLM again
        
        Args:
            agent_id: ID of the NPC to control
            interval: Seconds between busy checks (not decision cycles)
        """
        print(f"Starting call-and-response control loop for NPC: {agent_id}")
        print(f"System prompt initialized: {len(self.npc_contexts.get(agent_id, []))} messages in context")
        print("This loop will ask LLM for decisions only when agent is idle.")
        print("Action results will be reported back to LLM for next decision.\n")
        
        cycle_count = 0
        last_action = None
        last_action_result = None
        patrol_angle = 0.0  # Track circular patrol angle
        
        while True:
            try:
                # Check if agent is busy with previous action
                is_busy = self.is_agent_busy(agent_id)
                
                if is_busy:
                    # Agent is still working on previous action, wait a bit and check again
                    time.sleep(interval)
                    continue
                
                # Agent is idle - time to ask LLM for next decision
                cycle_count += 1
                print(f"\n[Decision {cycle_count}] Agent is idle - asking LLM for next action...")
                
                # Observe: Get comprehensive game state
                game_state = self.get_game_state(agent_id)
                agent_state = self.get_agent_state(agent_id)
                reachable = self.get_reachable_entities(agent_id)
                
                print(f"[Decision {cycle_count}] Game state retrieved")
                if agent_state:
                    pos = agent_state.get('position', {})
                    if isinstance(pos, dict):
                        print(f"  Agent position: ({pos.get('x', '?')}, {pos.get('y', '?')})")
                if reachable:
                    entities = reachable.get('entities', []) if isinstance(reachable, dict) else []
                    resources = reachable.get('resources', []) if isinstance(reachable, dict) else []
                    print(f"  Reachable: {len(entities)} entities, {len(resources)} resources")
                
                # Think: Query LLM for decision with full context and previous action result
                print(f"[Decision {cycle_count}] Querying LLM (model: {self.ollama_model})...")
                print(f"  Context messages: {len(self.npc_contexts.get(agent_id, []))}")
                decision = self.query_llm(agent_id, game_state, agent_state, reachable, last_action_result)
                
                if decision and 'workflow' in decision:
                    # Execute workflow
                    workflow_name = decision['workflow']
                    params = decision.get('params', {})
                    print(f"[Decision {cycle_count}] LLM chose workflow: {workflow_name} with params: {params}")
                    
                    # Get workflow and execute it
                    workflow = get_workflow(workflow_name)
                    if workflow:
                        print(f"  → Executing workflow: {workflow_name}")
                        result = workflow.execute(self, agent_id, params)
                        
                        # Build result message for next LLM query
                        if result.get('success'):
                            last_action_result = f"Previous workflow '{workflow_name}' completed: {result.get('message', 'success')}"
                        else:
                            last_action_result = f"Previous workflow '{workflow_name}' failed: {result.get('message', 'unknown error')}"
                        
                        last_action = workflow_name
                        print(f"[Decision {cycle_count}] Workflow executed. Result: {last_action_result}")
                        
                        # Check if workflow is async (agent will be busy) or sync (immediately idle)
                        # Most workflows are async (walking, mining, etc.)
                        if workflow_name == 'chat':
                            # Chat is sync - agent immediately idle
                            print(f"  → Chat workflow completed, will ask LLM again immediately")
                        else:
                            # Other workflows are async - agent is now busy
                            print(f"  → Workflow started, waiting for completion...")
                    else:
                        error_msg = f"Unknown workflow: {workflow_name}. Available: {list(WORKFLOWS.keys())}"
                        print(f"  ❌ {error_msg}")
                        last_action_result = error_msg
                    
                else:
                    print(f"[Decision {cycle_count}] ⚠️ No valid decision from LLM - using fallback")
                    if decision:
                        print(f"  LLM response: {decision}")
                    else:
                        print(f"  LLM returned None - check Ollama connection and model")
                    
                    # Fallback: Use patrol workflow
                    patrol_workflow = get_workflow('patrol')
                    if patrol_workflow:
                        print(f"  → Fallback: Using patrol workflow")
                        result = patrol_workflow.execute(self, agent_id, {'center': {'x': 0, 'y': 0}, 'radius': 50})
                        if result.get('success'):
                            last_action_result = f"Fallback patrol workflow completed: {result.get('message', 'success')}"
                        else:
                            last_action_result = f"Fallback patrol workflow failed: {result.get('message', 'unknown error')}"
                    else:
                        # Last resort: direct action
                        print(f"  → Fallback: Direct walk_to to spawn")
                        result = self.execute_action(agent_id, "walk_to", {"x": 0, "y": 0})
                        last_action_result = f"Fallback action executed: {result}"
                
                # Small delay before checking if agent is busy again
                time.sleep(0.5)
                
            except KeyboardInterrupt:
                print(f"\nStopping control loop for {agent_id}")
                break
            except Exception as e:
                print(f"Error in control loop for {agent_id}: {e}")
                import traceback
                traceback.print_exc()
                time.sleep(interval)
    
    def close(self):
        """Close RCON connection and stop Ollama if we started it."""
        try:
            self.factorio.close()
        except:
            pass
        
        # If we started Ollama, stop it when controller exits
        if self.ollama_process and self.ollama_started_by_us:
            try:
                print("Stopping Ollama server...")
                self.ollama_process.terminate()
                # Wait up to 5 seconds for graceful shutdown
                try:
                    self.ollama_process.wait(timeout=5)
                    print("✅ Ollama server stopped")
                except subprocess.TimeoutExpired:
                    # Force kill if it doesn't stop gracefully
                    print("⚠️  Ollama didn't stop gracefully, forcing termination...")
                    self.ollama_process.kill()
                    self.ollama_process.wait()
                    print("✅ Ollama server force-stopped")
            except Exception as e:
                print(f"⚠️  Error stopping Ollama: {e}")


def main():
    """Example usage."""
    # Import configuration
    try:
        from config import (
            RCON_HOST, RCON_PORT, RCON_PASSWORD,
            OLLAMA_MODEL, OLLAMA_HOST, OLLAMA_PORT,
            DEFAULT_DECISION_INTERVAL
        )
    except ImportError:
        # Fallback to defaults if config.py doesn't exist
        print("Warning: config.py not found, using defaults")
        RCON_HOST = "localhost"
        RCON_PORT = 27015
        RCON_PASSWORD = ""
        OLLAMA_MODEL = "mistral"  # Default: fast model for NPCs
        DEFAULT_DECISION_INTERVAL = 5.0
    
    if not RCON_PASSWORD:
        print("ERROR: RCON_PASSWORD not set in config.py")
        print("Please edit config.py and set RCON_PASSWORD to your Factorio RCON password")
        return
    
    # Create controller
    controller = FactorioNPCController(
        rcon_host=RCON_HOST,
        rcon_port=RCON_PORT,
        rcon_password=RCON_PASSWORD,
        ollama_model=OLLAMA_MODEL,
        ollama_host=OLLAMA_HOST,
        ollama_port=OLLAMA_PORT
    )
    
    # Check and start Ollama if needed
    print("Checking Ollama status...")
    if not controller.start_ollama():
        print("\n⚠️  Warning: Ollama is not running and could not be started automatically")
        print("   The controller will attempt to connect, but may fail.")
        print("   Start Ollama manually with: ollama serve")
        print("   Or: brew services start ollama")
        print()
    
    # Register signal handler to clean up on exit
    def signal_handler(sig, frame):
        print("\n\nShutting down...")
        controller.close()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Check for existing agents first
    existing_agents = controller.list_agents()
    if existing_agents:
        # Use the first existing agent
        npc_id = existing_agents[0]  # Already a string
        print(f"Found existing agent: agent_{npc_id} (game may show as Agent-{npc_id})")
        print(f"Using existing agent instead of creating a new one")
        
        # Initialize context for existing agent if not already initialized
        if npc_id not in controller.npc_contexts:
            # Get redshirt name for this agent
            try:
                from redshirt_names import get_redshirt_name
                redshirt_name = get_redshirt_name(controller.agent_counter)
                controller.agent_counter += 1
            except ImportError:
                redshirt_name = f"Redshirt_{controller.agent_counter}"
                controller.agent_counter += 1
            
            # Initialize conversation context (same as in create_npc)
            controller.npc_contexts[npc_id] = [
                {
                    "role": "system",
                    "content": f"""You are {redshirt_name}, an NPC agent in Factorio, a factory-building automation game. You are named after a Star Trek redshirt - brave but expendable. Your role is to help players by following these priorities (in order):

1. DEFEND THE BASE (Highest Priority)
   - Attack enemies (biters, spitters) that threaten player structures
   - Move toward enemies to engage them
   - Protect player-built structures
   - You're a redshirt - be brave but don't be reckless!

2. BUILD BLUEPRINTS (Medium Priority)
   - Build ghost entities (blueprints) that players have placed
   - Use place_entity to construct ghost entities
   - Complete blueprint structures

3. GATHER RESOURCES (Lowest Priority - Only when idle)
   - Mine resources (iron-ore, copper-ore, coal, stone)
   - Craft items when materials are available
   - Only gather when no defense or building tasks exist

## Factorio Game Context

Factorio is about building and automating factories. Players mine resources, craft items, build machines (assemblers, furnaces), and defend against enemies.

Common Resources:
- iron-ore → iron-plate (basic material)
- copper-ore → copper-plate (for circuits)
- coal (fuel)
- stone (buildings)

Common Entities:
- assembling-machine-1: Crafts items automatically
- stone-furnace: Smelts ores into plates
- ghost entities: Blueprints that need building (names contain "ghost" or "entity-ghost")

Common Recipes:
- iron-plate: 1 iron-ore → 1 iron-plate
- copper-plate: 1 copper-ore → 1 copper-plate
- iron-gear-wheel: 2 iron-plate → 1 iron-gear-wheel

## Action System

Async Actions (take time, complete in background):
- walk_to({{x, y}}): Move to position, takes time
- mine_resource(resource, count?): Mine resource, takes time
- craft_enqueue(recipe, count?): Queue crafting, agent crafts when ready

Sync Actions (complete immediately):
- place_entity(entity_name, {{x, y}}): Place entity instantly

## Coordinate System

- Positions use {{x, y}} coordinates
- (0, 0) is typically spawn point
- Use coordinates from reachable entities to target locations

## Response Format

Always respond with JSON only:
{{"action": "action_name", "params": {{...}}}}

Examples:
- Defense: {{"action": "walk_to", "params": {{"x": 150, "y": 200}}}}
- Building: {{"action": "place_entity", "params": {{"entity": "assembling-machine-1", "x": 100, "y": 100}}}}
- Gathering: {{"action": "mine_resource", "params": {{"resource": "iron-ore", "count": 50}}}}

Remember: Defense > Building > Gathering. Always prioritize based on what's detected in reachable entities. Stay within range. Never be idle."""
                }
            ]
            print(f"Initialized context for existing agent: {redshirt_name} (agent_{npc_id})")
    else:
        # No existing agents, create a new one
        print("No existing agents found, creating a new NPC...")
        npc_id = controller.create_npc(position=(0, 0))
        if not npc_id:
            print("Failed to create NPC")
            return
    
    # Run the control loop
    print(f"Starting control loop for agent_{npc_id}")
    controller.run_npc_loop(npc_id, interval=DEFAULT_DECISION_INTERVAL)


if __name__ == "__main__":
    main()
