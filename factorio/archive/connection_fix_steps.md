# Factorio Connection Fix - Server is Running Correctly

## ✅ Good News

Your server logs show:
- ✅ Server binding to `0.0.0.0:34197` (correct - accepts external connections)
- ✅ RCON running on `0.0.0.0:27015` (correct)
- ✅ Server is in-game and running
- ✅ Version 2.0.73 (latest!)

## 🔍 The Problem

The "can't establish network communication" error is likely a **TrueNAS networking issue** with UDP port forwarding, not a server configuration problem.

## Fix Steps

### Step 1: Verify Ports in TrueNAS UI

1. Go to **Apps → Installed Apps → factorio**
2. Click **Edit**
3. Scroll to **Ports** section
4. Verify you see:
   - `27015:27015/tcp` (RCON)
   - `34197:34197/udp` (Game)
5. If ports are missing or different, **manually add them**:
   - Click **Add Port**
   - Protocol: `TCP`, Container Port: `27015`, Node Port: `27015`
   - Click **Add Port** again
   - Protocol: `UDP`, Container Port: `34197`, Node Port: `34197`
6. **Save** and restart the app

### Step 2: Check TrueNAS Firewall

1. Go to **Network → Firewall**
2. Check if firewall is **enabled**
3. If enabled:
   - Go to **Firewall Rules**
   - Verify rules exist for:
     - TCP port `27015` (RCON)
     - UDP port `34197` (Game)
   - If missing, **add them**:
     - Action: `ALLOW`
     - Protocol: `TCP`, Port: `27015`
     - Action: `ALLOW`
     - Protocol: `UDP`, Port: `34197`
4. **Or temporarily disable firewall** to test:
   - Go to **Firewall → Settings**
   - Disable firewall
   - Try connecting
   - If it works, re-enable and add proper rules

### Step 3: Test RCON First (Easier to Debug)

RCON uses TCP which is easier to test:

```bash
cd /Users/pete/dotfiles/factorio

# Update config.py with the RCON password from logs: Ahth7Ahl1ereeC7
# Then test:
python3 -c "
from factorio_rcon import FactorioRcon
try:
    rcon = FactorioRcon('192.168.0.158', 27015, 'Ahth7Ahl1ereeC7')
    response = rcon.send_command('/sc game.print(\"Test\")')
    print('✅ RCON works!')
except Exception as e:
    print('❌ RCON failed:', e)
"
```

If RCON works but game doesn't, it's definitely a UDP/firewall issue.

### Step 4: Try Different Connection Methods

**In Factorio client:**

1. **Direct IP:**
   - Multiplayer → Connect to Server
   - Enter: `192.168.0.158:34197`
   - Don't use hostname

2. **LAN Browser:**
   - Multiplayer → Browse Games
   - Look for server in LAN list
   - If it appears, the server is working but client connection has issues

3. **Public IP (if port forwarded):**
   - Your server detected external IP: `24.155.117.71`
   - If you have port forwarding, try: `24.155.117.71:34197`

### Step 5: Check TrueNAS Network Mode

TrueNAS Custom Apps might need explicit network configuration:

1. Go to **Apps → Installed Apps → factorio → Edit**
2. Look for **Networking** or **Network** section
3. Check **Host Network** setting:
   - If enabled: Disable it (use bridge mode)
   - If disabled: Try enabling it temporarily to test

### Step 6: Verify from NAS Itself

SSH to NAS and test:

```bash
ssh truenas_admin@192.168.0.158

# Check if ports are listening
sudo netstat -tulpn | grep 34197
sudo netstat -tulpn | grep 27015

# Should show something like:
# udp  0  0  0.0.0.0:34197  0.0.0.0:*  LISTEN  <pid>/factorio
# tcp  0  0  0.0.0.0:27015  0.0.0.0:*  LISTEN  <pid>/factorio
```

If ports aren't listening, TrueNAS isn't forwarding them properly.

### Step 7: Try Host Network Mode (If Supported)

If bridge mode isn't working, try host network mode:

1. **Stop** the factorio app
2. **Edit** the app
3. Find **Networking** section
4. Enable **Host Network**
5. **Remove the ports section** from YAML (host mode uses host ports directly)
6. **Save** and start

**Note:** Host mode may not work in all TrueNAS versions - test carefully.

## Quick Test Commands

```bash
# From your Mac - test TCP (RCON)
nc -zv 192.168.0.158 27015

# Test UDP (may not work, UDP is connectionless)
nc -u -zv 192.168.0.158 34197

# Check if server is reachable
ping 192.168.0.158
```

## Most Likely Fix

Based on the logs, your server is configured correctly. The issue is most likely:

1. **Ports not properly exposed in TrueNAS UI** - Check Step 1
2. **Firewall blocking UDP** - Check Step 2
3. **TrueNAS networking quirk** - Try Step 6 (host network mode)

Try Steps 1-2 first - those are the most common issues.
