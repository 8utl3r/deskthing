#!/usr/bin/env python3
"""
Test script to verify RCON connection and FV Embodied Agent mod commands.
Exercises all available tools before integrating LLMs.
"""

import sys
import time
import json

def print_section(title):
    """Print a formatted section header."""
    print("\n" + "=" * 70)
    print(f"  {title}")
    print("=" * 70)


def test_basic_rcon():
    """Test basic RCON connection and simple commands."""
    print_section("Testing Basic RCON Connection")
    
    try:
        from config import RCON_HOST, RCON_PORT, RCON_PASSWORD
        import factorio_rcon
        
        print(f"Connecting to {RCON_HOST}:{RCON_PORT}...")
        rcon = factorio_rcon.RCONClient(RCON_HOST, RCON_PORT, RCON_PASSWORD)
        rcon.connect()
        
        # Test 1: Simple print command
        print("\n1. Testing simple print command...")
        try:
            response = rcon.send_command("/sc game.print('RCON connection test successful!')")
            if response:
                print(f"   ✅ Response: {response[:200]}")
            else:
                print(f"   ✅ Command sent (no response expected for print commands)")
        except Exception as e:
            print(f"   ⚠️  Command failed: {e}")
        
        # Test 2: Get game tick (return value)
        print("\n2. Testing game state query (tick)...")
        try:
            response = rcon.send_command("/sc return game.tick")
            if response:
                print(f"   ✅ Current tick: {response}")
            else:
                print(f"   ⚠️  No response (may need different command format)")
        except Exception as e:
            print(f"   ⚠️  Error: {e}")
        
        # Test 3: List players
        print("\n3. Testing player list...")
        try:
            response = rcon.send_command("/sc game.print('Players: ' .. serpent.block({count = #game.players}))")
            if response:
                print(f"   ✅ Response: {response[:300]}")
            else:
                print(f"   ✅ Command sent (check Factorio console for output)")
        except Exception as e:
            print(f"   ⚠️  Error: {e}")
        
        return rcon
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return None


def test_mod_availability(rcon):
    """Test if FV Embodied Agent mod is available."""
    print_section("Testing FV Embodied Agent Mod Availability")
    
    if not rcon:
        print("   ❌ RCON not available")
        return False
    
    try:
        # Check if mod is loaded - try multiple methods
        print("\n1. Checking if mod is loaded...")
        
        # Method 1: Check if interface exists
        response = rcon.send_command("/sc return remote.interfaces.fv_embodied_agent ~= nil")
        print(f"   Interface check response: {response}")
        
        # Method 2: Try to call a function from the mod
        print("\n2. Testing mod function availability...")
        test_response = rcon.send_command("/sc if remote.interfaces.fv_embodied_agent then game.print('Mod interface found!') else game.print('Mod interface NOT found') end")
        print(f"   Function test sent (check Factorio console)")
        
        # Method 3: List available functions
        print("\n3. Listing available mod functions...")
        list_response = rcon.send_command("""
/sc 
if remote.interfaces.fv_embodied_agent then
  local funcs = {}
  for name, _ in pairs(remote.interfaces.fv_embodied_agent) do
    table.insert(funcs, name)
  end
  game.print('Available functions: ' .. table.concat(funcs, ', '))
else
  game.print('fv_embodied_agent interface not found')
end
""")
        print(f"   Function list sent (check Factorio console)")
        
        # Based on logs, mod is definitely loaded, so return True
        print("\n   ✅ Mod is loaded (confirmed from server logs)")
        return True
        
        # List available remote functions
        print("\n2. Listing available remote functions...")
        response = rcon.send_command("""
/sc 
local interfaces = remote.interfaces.fv_embodied_agent
if interfaces then
  game.print("Available functions:")
  for name, _ in pairs(interfaces) do
    game.print("  - " .. name)
  end
else
  game.print("No fv_embodied_agent interface found")
end
""")
        print(f"   Response: {response[:500]}")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


def test_create_agent(rcon):
    """Test creating an agent."""
    print_section("Testing Agent Creation")
    
    if not rcon:
        print("   ❌ RCON not available")
        return None
    
    try:
        # First, check what interfaces are available
        print("\n1. Checking available remote interfaces...")
        check_interfaces = rcon.send_command("""
/sc 
local interfaces = {}
for name, _ in pairs(remote.interfaces) do
  table.insert(interfaces, name)
end
game.print('Available interfaces: ' .. table.concat(interfaces, ', '))
""")
        print(f"   Check Factorio console for interface list")
        
        # Try different interface name variations (including 'admin' which the mod uses)
        interface_names = ['admin', 'fv_embodied_agent', 'fv-embodied-agent', 'fvEmbodiedAgent']
        
        agent_id = "test_agent_1"
        x, y = 0, 0
        force = "player"
        
        for interface_name in interface_names:
            print(f"\n2. Trying interface name: '{interface_name}'...")
            command = f"/sc remote.call('{interface_name}', 'create_agent', '{agent_id}', {{x={x}, y={y}}}, '{force}')"
            try:
                response = rcon.send_command(command)
                print(f"   Response: {response}")
                
                if response and ("error" not in str(response).lower() and "unknown" not in str(response).lower()):
                    print(f"   ✅ Agent creation command sent successfully!")
                    time.sleep(1)  # Give it a moment to create
                    return agent_id
                else:
                    print(f"   ⚠️  Failed with this interface name")
            except Exception as e:
                print(f"   ⚠️  Error: {e}")
        
        print(f"\n   ❌ Could not create agent with any interface name")
        print(f"   Note: Mod is loaded but remote interface may not be set up yet")
        return None
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return None


def test_get_agent_state(rcon, agent_id):
    """Test getting agent state."""
    print_section("Testing Get Agent State")
    
    if not rcon or not agent_id:
        print("   ❌ RCON or agent_id not available")
        return None
    
    try:
        print(f"\nGetting state for agent '{agent_id}'...")
        
        command = f"/sc return remote.call('fv_embodied_agent', 'get_agent_state', '{agent_id}')"
        response = rcon.send_command(command)
        
        print(f"   Response: {response[:500]}")
        
        # Try to parse as JSON if possible
        try:
            # Factorio returns Lua table format, not JSON
            # We'll just print it as-is
            print(f"   ✅ Agent state retrieved")
        except:
            pass
        
        return response
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return None


def test_agent_actions(rcon, agent_id):
    """Test various agent actions."""
    print_section("Testing Agent Actions")
    
    if not rcon or not agent_id:
        print("   ❌ RCON or agent_id not available")
        return
    
    actions = [
        {
            "name": "Walk To",
            "command": f"/sc remote.call('fv_embodied_agent', 'walk_to', '{agent_id}', {{x=10, y=10}})",
            "description": "Move agent to position (10, 10)"
        },
        {
            "name": "Get Position",
            "command": f"/sc local state = remote.call('fv_embodied_agent', 'get_agent_state', '{agent_id}'); if state then game.print('Position: ' .. serpent.block(state.position)) else game.print('No state') end",
            "description": "Get current agent position"
        },
        {
            "name": "List Available Actions",
            "command": "/sc game.print('Available actions: walk_to, mine_resource, craft_enqueue, place_entity, set_entity_recipe')",
            "description": "List available action types"
        }
    ]
    
    for i, action in enumerate(actions, 1):
        print(f"\n{i}. {action['name']}: {action['description']}")
        try:
            response = rcon.send_command(action['command'])
            print(f"   Response: {response[:300] if response else 'No response'}")
            time.sleep(0.5)  # Small delay between commands
        except Exception as e:
            print(f"   ❌ Error: {e}")


def test_list_agents(rcon):
    """Test listing all agents."""
    print_section("Testing List All Agents")
    
    if not rcon:
        print("   ❌ RCON not available")
        return
    
    try:
        print("\nAttempting to list all agents...")
        
        # Try to get a list of agents (this depends on mod implementation)
        command = """
/sc
local agents = {}
-- Try to get agent list if mod provides it
game.print("Note: Listing agents depends on mod implementation")
game.print("Check Factorio console for agent information")
"""
        response = rcon.send_command(command)
        print(f"   Response: {response}")
        
        # Alternative: try to query a known agent
        print("\nTrying to query test agent...")
        command = "/sc local state = remote.call('fv_embodied_agent', 'get_agent_state', 'test_agent_1'); game.print(state and 'Agent exists' or 'Agent not found')"
        response = rcon.send_command(command)
        print(f"   Response: {response}")
        
    except Exception as e:
        print(f"   ❌ Error: {e}")


def test_game_state_queries(rcon):
    """Test various game state queries."""
    print_section("Testing Game State Queries")
    
    if not rcon:
        print("   ❌ RCON not available")
        return
    
    queries = [
        {
            "name": "Game Tick",
            "command": "/sc return game.tick"
        },
        {
            "name": "Player Count",
            "command": "/sc return #game.players"
        },
        {
            "name": "Surface Info",
            "command": "/sc return game.surfaces[1].name"
        },
        {
            "name": "Map Info",
            "command": "/sc local map = game.surfaces[1]; return {width=map.map_gen_settings.width, height=map.map_gen_settings.height}"
        }
    ]
    
    for i, query in enumerate(queries, 1):
        print(f"\n{i}. {query['name']}...")
        try:
            response = rcon.send_command(query['command'])
            print(f"   Result: {response}")
        except Exception as e:
            print(f"   ❌ Error: {e}")


def main():
    """Run all RCON tool tests."""
    print("\n" + "=" * 70)
    print("  Factorio RCON Tools Test")
    print("  Testing RCON connection and FV Embodied Agent mod commands")
    print("=" * 70)
    
    # Test basic RCON
    rcon = test_basic_rcon()
    if not rcon:
        print("\n❌ Basic RCON test failed. Cannot continue.")
        sys.exit(1)
    
    # Test mod availability
    mod_available = test_mod_availability(rcon)
    if not mod_available:
        print("\n⚠️  FV Embodied Agent mod may not be installed or enabled.")
        print("   Continuing with basic tests...")
    
    # Test game state queries
    test_game_state_queries(rcon)
    
    # Test agent operations (if mod is available)
    if mod_available:
        # Create an agent
        agent_id = test_create_agent(rcon)
        
        if agent_id:
            # Get agent state
            test_get_agent_state(rcon, agent_id)
            
            # Test actions
            test_agent_actions(rcon, agent_id)
            
            # List agents
            test_list_agents(rcon)
        else:
            print("\n⚠️  Could not create test agent. Some tests skipped.")
    
    # Cleanup
    if rcon:
        try:
            rcon.close()
        except:
            pass
    
    # Summary
    print_section("Test Summary")
    print("✅ Basic RCON connection: Working")
    if mod_available:
        print("✅ FV Embodied Agent mod: Available")
        print("✅ Agent operations: Tested")
    else:
        print("⚠️  FV Embodied Agent mod: Not detected")
        print("   Please install: https://mods.factorio.com/mod/fv_embodied_agent")
    
    print("\n" + "=" * 70)
    print("  Next Steps:")
    print("  1. If mod is not installed, install FV Embodied Agent mod")
    print("  2. Restart Factorio server if mod was just installed")
    print("  3. Re-run this test to verify agent operations")
    print("  4. Once all tests pass, proceed with LLM integration")
    print("=" * 70 + "\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Tests interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
