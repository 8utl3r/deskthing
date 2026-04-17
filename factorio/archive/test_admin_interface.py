#!/usr/bin/env python3
"""
Test the admin interface to see what functions are available
"""

from config import RCON_HOST, RCON_PORT, RCON_PASSWORD
import factorio_rcon

print("Testing admin interface functions...")
print()

try:
    rcon = factorio_rcon.RCONClient(RCON_HOST, RCON_PORT, RCON_PASSWORD)
    rcon.connect()
    
    # List available functions in admin interface
    print("1. Listing admin interface functions...")
    cmd = "/sc if remote.interfaces.admin then local funcs = {}; for k, v in pairs(remote.interfaces.admin) do table.insert(funcs, k) end; game.print('Admin functions: ' .. table.concat(funcs, ', ')) else game.print('Admin interface not found') end"
    response = rcon.send_command(cmd)
    print(f"   Check Factorio console for function list")
    
    # Try the "agent" interface
    print("\n2. Trying 'agent' interface...")
    cmd2 = "/sc if remote.interfaces.agent then local funcs = {}; for k, v in pairs(remote.interfaces.agent) do table.insert(funcs, k) end; game.print('Agent interface functions: ' .. table.concat(funcs, ', ')) else game.print('Agent interface not found') end"
    response2 = rcon.send_command(cmd2)
    print(f"   Check Factorio console for agent interface functions")
    
    # Try creating agent via agent interface
    print("\n3. Trying to create agent via 'agent' interface...")
    cmd3 = "/sc local result = remote.call('agent', 'create_agent', 'test1', {x=0, y=0}, 'player'); game.print('Create result: ' .. tostring(result))"
    response3 = rcon.send_command(cmd3)
    print(f"   Response: {response3}")
    print(f"   ⚠️  Check Factorio console/logs for result")
    
    # Try getting agent state
    print("\n4. Trying to get agent state...")
    cmd4 = "/sc local state = remote.call('agent', 'get_agent_state', 'test1'); if state then game.print('Agent exists!') else game.print('Agent not found') end"
    response4 = rcon.send_command(cmd4)
    print(f"   Response: {response4}")
    print(f"   ⚠️  Check Factorio console/logs for result")
    
    # Try common function names in admin interface
    functions_to_try = [
        'create_agent',
        'spawn_agent', 
        'add_agent',
        'new_agent',
        'get_agents',
        'list_agents'
    ]
    
    print("\n4. Trying common function names in admin interface...")
    for func_name in functions_to_try:
        cmd = f"/sc remote.call('admin', '{func_name}', 'test1', {{x=0, y=0}}, 'player')"
        try:
            response = rcon.send_command(cmd)
            if response and "error" not in response.lower() and "no such" not in response.lower():
                print(f"   ✅ {func_name}: {response}")
            else:
                print(f"   ❌ {func_name}: {response}")
        except Exception as e:
            print(f"   ❌ {func_name}: {e}")
    
    rcon.close()
    
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
