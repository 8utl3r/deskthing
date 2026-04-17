# Factorio Server Connection Troubleshooting

## Error: "Can't establish network communication with server"

This usually means the Factorio client can't reach the server on port 34197 (UDP).

## Step 1: Verify Server is Running

**In TrueNAS Web UI:**
1. Go to **Apps → Installed Apps**
2. Find **factorio**
3. Check status - should be "Running" (green)
4. If not running, click **Start**

**Check Logs:**
1. Click on **factorio** app
2. Click **Logs** tab
3. Look for:
   - `Hosting game at IP ADDR:({0.0.0.0:34197})`
   - `RCON interface at IP ADDR:({0.0.0.0:27015})`
   - Any error messages

## Step 2: Verify Ports are Exposed

**In TrueNAS Web UI:**
1. Go to **Apps → Installed Apps → factorio**
2. Click **Edit**
3. Check **Ports** section:
   - Should show: `27015:27015/tcp`
   - Should show: `34197:34197/udp`
4. If missing, add them manually in the UI

## Step 3: Check Container Networking

**SSH to NAS and verify:**
```bash
ssh truenas_admin@192.168.0.158

# Check if container is running
sudo docker ps | grep factorio

# Check if ports are listening
sudo netstat -tulpn | grep 34197
sudo netstat -tulpn | grep 27015

# Check container logs
sudo docker logs factorio | tail -50
```

## Step 4: Test RCON Connection (Easier to Debug)

RCON uses TCP, which is easier to test than UDP:

```bash
# From your Mac
cd /Users/pete/dotfiles/factorio

# Test RCON connection
python3 -c "
from factorio_rcon import FactorioRcon
try:
    rcon = FactorioRcon('192.168.0.158', 27015, 'YOUR_PASSWORD')
    response = rcon.send_command('/sc game.print(\"RCON test\")')
    print('✅ RCON works! Response:', response)
except Exception as e:
    print('❌ RCON failed:', e)
"
```

If RCON works but game connection doesn't, it's a UDP issue.

## Step 5: Check TrueNAS Firewall

**In TrueNAS Web UI:**
1. Go to **Network → Firewall**
2. Check if firewall is enabled
3. If enabled, verify rules allow:
   - TCP port 27015 (RCON)
   - UDP port 34197 (Game)

**Or temporarily disable firewall to test:**
- Go to **Network → Firewall → Settings**
- Disable firewall temporarily
- Try connecting again
- If it works, add firewall rules

## Step 6: Test UDP Port from Mac

```bash
# Test if UDP port is reachable (may not work, UDP is connectionless)
nc -u -v 192.168.0.158 34197

# Or use nmap
nmap -sU -p 34197 192.168.0.158
```

## Step 7: Check Factorio Server Binding

The server should bind to `0.0.0.0` (all interfaces), not `127.0.0.1` (localhost only).

**Check logs for:**
```
Hosting game at IP ADDR:({0.0.0.0:34197})  ✅ Good
Hosting game at IP ADDR:({127.0.0.1:34197}) ❌ Bad - only localhost
```

## Step 8: Try Direct IP Connection

**In Factorio client:**
1. Multiplayer → Connect to Server
2. Enter: `192.168.0.158:34197`
3. Don't use hostname or "localhost"

## Step 9: Check for Port Conflicts

```bash
# SSH to NAS
ssh truenas_admin@192.168.0.158

# Check what's using the ports
sudo lsof -i :34197
sudo lsof -i :27015

# If something else is using them, change ports in YAML
```

## Step 10: Verify Container Network Mode

TrueNAS Custom Apps might use host networking or bridge networking. Check:

```bash
# SSH to NAS
ssh truenas_admin@192.168.0.158

# Check container network
sudo docker inspect factorio | grep -A 10 NetworkMode
```

## Common Fixes

### Fix 1: Add Network Configuration

If TrueNAS isn't exposing ports properly, try adding explicit network config:

```yaml
services:
  factorio:
    # ... existing config ...
    network_mode: bridge
    # Or try: network_mode: host (if TrueNAS supports it)
```

### Fix 2: Use Host Network Mode (If Supported)

Some TrueNAS setups work better with host networking:

```yaml
services:
  factorio:
    network_mode: host
    # Remove ports section when using host mode
```

**Note:** Host mode may not work in TrueNAS Custom Apps - test carefully.

### Fix 3: Check TrueNAS App Network Settings

In TrueNAS Web UI:
1. Apps → Installed Apps → factorio → Edit
2. Look for **Network** or **Networking** section
3. Verify **Host Network** is disabled (unless you want host mode)
4. Check **Port Forwarding** or **Port Mapping** settings

## Still Not Working?

1. **Check if server actually started:**
   - Look for save file creation in logs
   - Check if `/mnt/boot-pool/apps/factorio/factorio/saves/` has files

2. **Try connecting from NAS itself:**
   ```bash
   ssh truenas_admin@192.168.0.158
   # Install Factorio client or use telnet to test port
   telnet localhost 27015  # RCON TCP
   ```

3. **Check TrueNAS version compatibility:**
   - Some TrueNAS versions have networking quirks
   - Try updating TrueNAS if very old

4. **Try different port:**
   - Change UDP port to something else (e.g., `34198:34197/udp`)
   - Test if new port works

## Quick Test Script

Save this as `test_factorio_connection.sh`:

```bash
#!/bin/bash
echo "Testing Factorio server connection..."
echo ""

echo "1. Testing RCON (TCP 27015)..."
timeout 3 bash -c 'cat < /dev/null > /dev/tcp/192.168.0.158/27015' 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ RCON port is open"
else
    echo "   ❌ RCON port is closed or unreachable"
fi

echo ""
echo "2. Testing Game port (UDP 34197)..."
# UDP is harder to test, but we can try
nc -u -z -v -w 3 192.168.0.158 34197 2>&1 | grep -q "succeeded" && echo "   ✅ UDP port might be open" || echo "   ⚠️  UDP test inconclusive (UDP is connectionless)"

echo ""
echo "3. Checking if server is running on NAS..."
ssh truenas_admin@192.168.0.158 "sudo docker ps | grep factorio" && echo "   ✅ Container is running" || echo "   ❌ Container is not running"

echo ""
echo "Done!"
```

Run: `chmod +x test_factorio_connection.sh && ./test_factorio_connection.sh`
