#!/usr/bin/env python3
"""
Direct test of FV Embodied Agent mod - try to call functions directly
"""

from config import RCON_HOST, RCON_PORT, RCON_PASSWORD
import factorio_rcon

print("Testing FV Embodied Agent mod directly...")
print()

try:
    rcon = factorio_rcon.RCONClient(RCON_HOST, RCON_PORT, RCON_PASSWORD)
    rcon.connect()
    
    # Try to check if interface exists using a return statement
    print("1. Checking if interface exists...")
    cmd1 = "/sc return remote.interfaces.fv_embodied_agent ~= nil"
    response1 = rcon.send_command(cmd1)
    print(f"   Response: {response1}")
    
    # Try to list all interfaces
    print("\n2. Listing all interfaces...")
    cmd2 = "/sc local s = ''; for k, v in pairs(remote.interfaces) do s = s .. k .. ' ' end; return s"
    response2 = rcon.send_command(cmd2)
    print(f"   Response: {response2}")
    
    # Try to call a function directly (maybe it works even if interface check fails)
    print("\n3. Trying to call create_agent directly...")
    cmd3 = "/sc remote.call('fv_embodied_agent', 'create_agent', 'test1', {x=0, y=0}, 'player')"
    response3 = rcon.send_command(cmd3)
    print(f"   Response: {response3}")
    
    # Check mod version
    print("\n4. Checking mod version...")
    cmd4 = "/sc return mods['fv_embodied_agent'] and mods['fv_embodied_agent'].version or 'not found'"
    response4 = rcon.send_command(cmd4)
    print(f"   Response: {response4}")
    
    rcon.close()
    
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
