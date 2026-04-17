#!/usr/bin/env python3
"""
Quick script to test RCON password without running full tests.
Helps verify the correct password is in config.py
"""

import sys
from config import RCON_HOST, RCON_PORT, RCON_PASSWORD
import factorio_rcon

print(f"Testing RCON connection to {RCON_HOST}:{RCON_PORT}")
print(f"Using password: {'*' * len(RCON_PASSWORD)}")
print()

try:
    rcon = factorio_rcon.RCONClient(RCON_HOST, RCON_PORT, RCON_PASSWORD)
    rcon.connect()
    print("✅ Connection successful!")
    
    # Try a simple command
    response = rcon.send_command("/sc return game.tick")
    print(f"✅ Command test successful!")
    print(f"   Response: {response}")
    
    rcon.close()
    sys.exit(0)
    
except factorio_rcon.InvalidPassword:
    print("❌ Password is incorrect!")
    print()
    print("To find the correct password:")
    print("1. SSH to TrueNAS: ssh truenas_admin@192.168.0.158")
    print("2. Check container: docker exec factorio cat /opt/factorio/config/rconpw")
    print("3. Or check docker-compose: cd /mnt/boot-pool/apps/factorio && grep FACTORIO_RCON_PASSWORD docker-compose.yml")
    print()
    print("Then update config.py with the correct password.")
    sys.exit(1)
    
except factorio_rcon.RCONConnectError as e:
    print(f"❌ Connection failed: {e}")
    print()
    print("Check:")
    print(f"  - Factorio server is running")
    print(f"  - RCON is enabled")
    print(f"  - Network connectivity to {RCON_HOST}:{RCON_PORT}")
    sys.exit(1)
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
