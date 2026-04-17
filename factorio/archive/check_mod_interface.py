#!/usr/bin/env python3
"""
Script to check what remote interfaces are actually available in Factorio
"""

from config import RCON_HOST, RCON_PORT, RCON_PASSWORD
import factorio_rcon

print("Checking available remote interfaces in Factorio...")
print()

try:
    rcon = factorio_rcon.RCONClient(RCON_HOST, RCON_PORT, RCON_PASSWORD)
    rcon.connect()
    
    # List all remote interfaces (single line command)
    print("Querying all remote interfaces...")
    command = "/sc local interfaces = {}; for name, _ in pairs(remote.interfaces) do table.insert(interfaces, name) end; if #interfaces > 0 then game.print('=== Available Remote Interfaces ==='); for _, name in ipairs(interfaces) do game.print('  - ' .. name) end else game.print('No remote interfaces found') end"
    
    response = rcon.send_command(command)
    print(f"Response: {response}")
    print()
    print("⚠️  Check the Factorio server console for the interface list!")
    print("   (RCON doesn't return print output, but it will appear in server logs)")
    
    rcon.close()
    
except Exception as e:
    print(f"Error: {e}")
