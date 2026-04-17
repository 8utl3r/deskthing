#!/usr/bin/env python3
"""
Test Workflow Actions

Comprehensive test suite for all workflow actions to identify where agents get stuck.
Tests each action individually and verifies completion.
"""

import sys
import time
import json
from config import RCON_HOST, RCON_PORT, RCON_PASSWORD
import factorio_rcon
from workflows import get_workflow, list_workflows
from factorio_ollama_npc_controller import FactorioNPCController


def test_action_execution(controller, agent_id: str, action: str, params: dict, timeout: int = 30):
    """
    Test a single action execution and verify it completes.
    
    Returns:
        (success: bool, message: str, duration: float)
    """
    print(f"\n  Testing: {action} with params: {params}")
    start_time = time.time()
    
    try:
        # Execute action
        result = controller.execute_action(agent_id, action, params)
        
        # Check if action was queued/started
        if result is True or (isinstance(result, str) and 'error' not in result.lower()):
            print(f"    ✅ Action queued/started: {result}")
        else:
            print(f"    ❌ Action failed immediately: {result}")
            return False, str(result), time.time() - start_time
        
        # Wait for action to complete (check if agent is busy)
        waited = 0
        check_interval = 0.5
        max_wait = timeout
        
        while waited < max_wait:
            is_busy = controller.is_agent_busy(agent_id)
            if not is_busy:
                duration = time.time() - start_time
                print(f"    ✅ Action completed in {duration:.1f}s")
                return True, "Completed", duration
            
            time.sleep(check_interval)
            waited += check_interval
            
            # Print progress every 5 seconds
            if int(waited) % 5 == 0 and waited > 0:
                print(f"    ⏳ Still busy... ({int(waited)}s/{max_wait}s)")
        
        duration = time.time() - start_time
        print(f"    ⚠️  Action timed out after {duration:.1f}s (agent still busy)")
        return False, f"Timeout after {duration:.1f}s", duration
        
    except Exception as e:
        duration = time.time() - start_time
        print(f"    ❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return False, str(e), duration


def test_workflow_execution(controller, agent_id: str, workflow_name: str, params: dict, timeout: int = 60):
    """
    Test a workflow execution and verify it completes.
    
    Returns:
        (success: bool, message: str, duration: float)
    """
    print(f"\n  Testing workflow: {workflow_name} with params: {params}")
    start_time = time.time()
    
    try:
        workflow = get_workflow(workflow_name)
        if not workflow:
            return False, f"Workflow {workflow_name} not found", 0
        
        # Execute workflow
        result = workflow.execute(controller, agent_id, params)
        
        duration = time.time() - start_time
        
        if result.get('success'):
            print(f"    ✅ Workflow completed in {duration:.1f}s: {result.get('message')}")
            return True, result.get('message', 'Success'), duration
        else:
            print(f"    ❌ Workflow failed: {result.get('message')}")
            return False, result.get('message', 'Unknown error'), duration
        
    except Exception as e:
        duration = time.time() - start_time
        print(f"    ❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return False, str(e), duration


def test_basic_actions(controller, agent_id: str):
    """Test basic individual actions."""
    print("\n" + "="*70)
    print("Testing Basic Actions")
    print("="*70)
    
    # Get agent state first
    agent_state = controller.get_agent_state(agent_id)
    if agent_state:
        pos = agent_state.get('position', {})
        if isinstance(pos, dict):
            current_pos = (pos.get('x', 0), pos.get('y', 0))
            print(f"\nCurrent agent position: {current_pos}")
    
    tests = [
        {
            'action': 'walk_to',
            'params': {'x': 10, 'y': 10},
            'timeout': 30,
            'description': 'Walk to position (10, 10)'
        },
        {
            'action': 'walk_to',
            'params': {'x': 0, 'y': 0},
            'timeout': 30,
            'description': 'Walk back to spawn (0, 0)'
        },
    ]
    
    results = []
    for test in tests:
        print(f"\n{test['description']}")
        success, message, duration = test_action_execution(
            controller, agent_id, test['action'], test['params'], test['timeout']
        )
        results.append({
            'test': test['description'],
            'success': success,
            'message': message,
            'duration': duration
        })
        time.sleep(1)  # Brief pause between tests
    
    return results


def test_workflows(controller, agent_id: str):
    """Test all workflows."""
    print("\n" + "="*70)
    print("Testing Workflows")
    print("="*70)
    
    # Get game state
    reachable = controller.get_reachable_entities(agent_id)
    enemies = reachable.get('enemies', []) if reachable else []
    ghosts = reachable.get('ghosts', []) if reachable else []
    resources = reachable.get('resources', []) if reachable else []
    
    print(f"\nGame state:")
    print(f"  Enemies: {len(enemies)}")
    print(f"  Blueprints: {len(ghosts)}")
    print(f"  Resources: {len(resources)}")
    
    tests = []
    
    # Test defend_base (only if enemies exist)
    if enemies:
        tests.append({
            'workflow': 'defend_base',
            'params': {'enemy': enemies[0]},
            'timeout': 30,
            'description': 'Defend against enemy'
        })
    else:
        print("\n⚠️  Skipping defend_base test (no enemies)")
    
    # Test build_blueprint (only if blueprints exist)
    if ghosts:
        tests.append({
            'workflow': 'build_blueprint',
            'params': {'ghost_entity': ghosts[0]},
            'timeout': 60,
            'description': 'Build blueprint'
        })
    else:
        print("\n⚠️  Skipping build_blueprint test (no blueprints)")
    
    # Test gather_resource (if resources exist)
    if resources:
        resource_name = resources[0].get('name', 'iron-ore')
        tests.append({
            'workflow': 'gather_resource',
            'params': {'resource_name': resource_name, 'count': 10},
            'timeout': 60,
            'description': f'Gather {resource_name}'
        })
    else:
        print("\n⚠️  Skipping gather_resource test (no resources)")
    
    # Test build_chest_and_fill (always available)
    tests.append({
        'workflow': 'build_chest_and_fill',
        'params': {},
        'timeout': 120,
        'description': 'Build chest and fill with resources'
    })
    
    # Test patrol (always available)
    tests.append({
        'workflow': 'patrol',
        'params': {'center': {'x': 0, 'y': 0}, 'radius': 20},
        'timeout': 30,
        'description': 'Patrol in circle'
    })
    
    results = []
    for test in tests:
        print(f"\n{test['description']}")
        success, message, duration = test_workflow_execution(
            controller, agent_id, test['workflow'], test['params'], test['timeout']
        )
        results.append({
            'test': test['description'],
            'workflow': test['workflow'],
            'success': success,
            'message': message,
            'duration': duration
        })
        time.sleep(2)  # Brief pause between tests
    
    return results


def test_agent_state_tracking(controller, agent_id: str):
    """Test agent state tracking and busy detection."""
    print("\n" + "="*70)
    print("Testing Agent State Tracking")
    print("="*70)
    
    print("\n1. Getting initial agent state...")
    agent_state = controller.get_agent_state(agent_id)
    if agent_state:
        print(f"   ✅ Agent state retrieved")
        print(f"   Position: {agent_state.get('position', 'unknown')}")
        state = agent_state.get('state', {})
        print(f"   Walking: {state.get('walking', {})}")
        print(f"   Mining: {state.get('mining', {})}")
        print(f"   Crafting: {state.get('crafting', {})}")
    else:
        print(f"   ❌ Failed to get agent state")
        return False
    
    print("\n2. Checking if agent is busy...")
    is_busy = controller.is_agent_busy(agent_id)
    print(f"   Agent busy: {is_busy}")
    
    print("\n3. Starting a walk action and monitoring state...")
    result = controller.execute_action(agent_id, 'walk_to', {'x': 5, 'y': 5})
    print(f"   Action result: {result}")
    
    # Monitor state changes
    for i in range(10):
        time.sleep(1)
        is_busy = controller.is_agent_busy(agent_id)
        agent_state = controller.get_agent_state(agent_id)
        state = agent_state.get('state', {}) if agent_state else {}
        walking = state.get('walking', {})
        
        print(f"   [{i+1}s] Busy: {is_busy}, Walking: {walking}")
        
        if not is_busy:
            print(f"   ✅ Agent completed action")
            break
    
    return True


def main():
    """Run all workflow action tests."""
    print("\n" + "="*70)
    print("  Workflow Action Test Suite")
    print("  Testing all actions and workflows to identify stuck agents")
    print("="*70)
    
    try:
        # Initialize controller
        print("\n1. Initializing controller...")
        controller = FactorioNPCController(
            rcon_host=RCON_HOST,
            rcon_port=RCON_PORT,
            rcon_password=RCON_PASSWORD
        )
        print("   ✅ Controller initialized")
        
        # List existing agents or create one
        print("\n2. Finding or creating agent...")
        existing_agents = controller.list_agents()
        if existing_agents:
            agent_id = existing_agents[0]
            print(f"   ✅ Using existing agent: {agent_id}")
        else:
            agent_id = controller.create_npc()
            if agent_id:
                print(f"   ✅ Created new agent: {agent_id}")
            else:
                print("   ❌ Failed to create agent")
                return
        
        # Wait a moment for agent to initialize
        time.sleep(2)
        
        # Run tests
        print("\n" + "="*70)
        print("Running Tests")
        print("="*70)
        
        # Test 1: Agent state tracking
        test_agent_state_tracking(controller, agent_id)
        
        # Test 2: Basic actions
        action_results = test_basic_actions(controller, agent_id)
        
        # Test 3: Workflows
        workflow_results = test_workflows(controller, agent_id)
        
        # Summary
        print("\n" + "="*70)
        print("Test Summary")
        print("="*70)
        
        print("\nBasic Actions:")
        for result in action_results:
            status = "✅" if result['success'] else "❌"
            print(f"  {status} {result['test']}: {result['message']} ({result['duration']:.1f}s)")
        
        print("\nWorkflows:")
        for result in workflow_results:
            status = "✅" if result['success'] else "❌"
            print(f"  {status} {result['test']}: {result['message']} ({result['duration']:.1f}s)")
        
        # Identify problematic actions
        failed_actions = [r for r in action_results if not r['success']]
        failed_workflows = [r for r in workflow_results if not r['success']]
        
        if failed_actions or failed_workflows:
            print("\n⚠️  Failed Tests (may indicate where agents get stuck):")
            for result in failed_actions + failed_workflows:
                print(f"  - {result['test']}: {result['message']}")
        
        # Cleanup
        controller.close()
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Tests interrupted by user")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
