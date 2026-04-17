# UDP Port 34197 Not Showing in Scans - This is Normal!

## Why UDP Ports Don't Show in Scans

**UDP is connectionless** - unlike TCP, there's no "handshake" to detect. Most port scanners can't reliably detect UDP ports because:

1. UDP doesn't send responses to probes (unlike TCP SYN-ACK)
2. Firewalls often drop UDP packets silently
3. Port scanners need special UDP scanning techniques

**Your ports are configured correctly:**
- ✅ `tcp://0.0.0.0:27015:27015` (RCON - shows as open ✅)
- ✅ `udp://0.0.0.0:34197:34197` (Game - "closed" in scan is normal for UDP)

## The Real Test: Can You Connect?

UDP port scans are unreliable. The **real test** is whether Factorio client can connect.

## Troubleshooting Steps

### Step 1: Test UDP Port Properly

**From your Mac, try these UDP tests:**

```bash
# Method 1: Use nmap with UDP scan (if installed)
nmap -sU -p 34197 192.168.0.158

# Method 2: Use nc (netcat) with UDP
nc -u -v -w 3 192.168.0.158 34197

# Method 3: Use Factorio client directly (best test!)
```

**Note:** Even if these show "closed" or "filtered", the port might still work for Factorio!

### Step 2: Check TrueNAS Firewall for UDP

1. Go to **Network → Firewall → Firewall Rules**
2. Look for a rule allowing **UDP port 34197**
3. If missing, **add it**:
   - Action: `ALLOW`
   - Protocol: `UDP`
   - Port: `34197`
   - Source: `Any` (or your network: `192.168.0.0/24`)
   - Destination: `This host`

### Step 3: Try Connecting in Factorio Client

**This is the real test!**

1. Open Factorio client
2. **Multiplayer → Connect to Server**
3. Enter: `192.168.0.158:34197`
4. Click **Connect**

**If it connects:** ✅ Port is working, scanner just can't detect UDP!

**If it fails:** Continue to Step 4

### Step 4: Check if Server Appears in LAN Browser

1. In Factorio client: **Multiplayer → Browse Games**
2. Look for your server in the **LAN** tab
3. If it appears: ✅ Server is broadcasting correctly, connection issue is client-side
4. If it doesn't appear: Server might not be discoverable (but direct connect might still work)

### Step 5: Verify UDP Forwarding in TrueNAS

TrueNAS Custom Apps sometimes have issues with UDP. Check:

1. **Apps → Installed Apps → factorio → Edit**
2. Look for **Networking** or **Network** section
3. Check if there's a **Host Network** option
4. If UDP still doesn't work, try:
   - **Enable Host Network** (if available)
   - This bypasses port forwarding and uses host ports directly
   - **Note:** You may need to remove port mappings when using host network

### Step 6: Test from NAS Itself

SSH to NAS and verify UDP socket is listening:

```bash
ssh truenas_admin@192.168.0.158

# Check if UDP port is listening
sudo netstat -ulnp | grep 34197

# Should show something like:
# udp  0  0  0.0.0.0:34197  0.0.0.0:*  <pid>/factorio
```

If it shows `0.0.0.0:34197`, the server is listening correctly.

### Step 7: Check Router/Firewall (If Connecting from Outside LAN)

If you're trying to connect from outside your network:

1. Check router port forwarding for UDP 34197
2. Check if your ISP blocks UDP (some do)
3. Try connecting from within your LAN first to isolate the issue

## Common Solutions

### Solution 1: Add Explicit Firewall Rule

Even if firewall shows "allow all", add explicit UDP rule:

1. **Network → Firewall → Firewall Rules → Add Rule**
2. Configure:
   - **Action:** `ALLOW`
   - **Protocol:** `UDP`
   - **Port:** `34197`
   - **Source:** `192.168.0.0/24` (your LAN)
   - **Destination:** `This host`
3. **Save** and restart Factorio app

### Solution 2: Try Host Network Mode

If bridge networking has UDP issues:

1. **Stop** factorio app
2. **Edit** app
3. Enable **Host Network** (if available in TrueNAS UI)
4. **Note:** This uses host ports directly - make sure nothing else uses 34197
5. **Start** app

### Solution 3: Use Different Port

Sometimes specific ports have issues. Try:

1. Change game port to `34198` in YAML:
   ```yaml
   ports:
     - "27015:27015/tcp"
     - "34198:34197/udp"  # Host port 34198 → Container port 34197
   ```
2. Connect to: `192.168.0.158:34198`

## Why RCON Works But Game Doesn't

- **RCON (TCP 27015):** ✅ Works - TCP is reliable, easy to scan
- **Game (UDP 34197):** ❓ Unknown - UDP is unreliable to scan, but might still work!

**The fact that RCON works proves:**
- ✅ Container networking is working
- ✅ Port forwarding is working
- ✅ Firewall allows connections
- ✅ Server is running

**UDP might still work** - you just can't scan it reliably!

## Best Test: Try Connecting!

**Stop worrying about the scan** - try connecting in Factorio client:

1. Open Factorio
2. **Multiplayer → Connect to Server**
3. Enter: `192.168.0.158:34197`
4. Click **Connect**

**If it works:** ✅ Problem solved! UDP scans are unreliable.

**If it doesn't work:** Check firewall rules (Step 2) and try host network mode (Solution 2).

## Quick Diagnostic

```bash
# From your Mac - test if you can reach the port (even if scan fails)
# This won't tell you if it's open, but will test connectivity
ping -c 1 192.168.0.158  # Basic connectivity

# Then just try connecting in Factorio client!
```

**Remember:** UDP port scans are notoriously unreliable. The real test is whether Factorio can connect!
