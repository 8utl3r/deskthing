# Secure Factorio External Access Setup

## What is RCON?

**RCON (Remote Console)** is an admin/control interface for the Factorio server:
- Allows sending commands to the server remotely
- Used by your Python NPC controller (`factorio_ollama_npc_controller.py`) to control NPCs
- Runs on TCP port 27015

**Do you need it externally?**
- ❌ **No** - Your NPC controller runs on your local Mac
- ❌ **No** - It connects to `192.168.0.158:27015` (local network)
- ✅ **Keep it local only** - More secure, no external exposure needed

## Recommended Setup: Minimal Exposure

Since you want DNS obfuscation but minimal exposure:

### Option 1: DNS-Only Record + Port Forwarding (Recommended)

**What this does:**
- ✅ Friendly DNS name: `factorio.xcvr.link`
- ✅ Only exposes game port (UDP 34197)
- ✅ RCON stays local only (more secure)
- ✅ No Cloudflare tunnel needed for game server

**Setup Steps:**

1. **Router Port Forwarding:**
   - Forward **UDP port 34197** → `192.168.0.158:34197`
   - That's it - only one port exposed

2. **Cloudflare DNS Record (DNS-only, not proxied):**
   - Go to **Cloudflare Dashboard → DNS → Records**
   - **Add Record:**
     - **Type:** A
     - **Name:** `factorio`
     - **IPv4 address:** `24.155.117.71` (your public IP)
     - **Proxy status:** DNS only (gray cloud ☁️ - **NOT proxied**)
     - **TTL:** Auto
     - **Save**

3. **Connect using:**
   - `factorio.xcvr.link:34197` from anywhere
   - Or `24.155.117.71:34197` (same thing, just less friendly)

**Why DNS-only (not proxied):**
- Cloudflare proxy (orange cloud) only works for HTTP/HTTPS
- Game servers need raw UDP, so proxy won't work anyway
- DNS-only gives you the friendly name without trying to proxy

**Security:**
- Only UDP 34197 exposed (game traffic)
- RCON (27015) stays local only
- No unnecessary ports open

### Option 2: Cloudflare Tunnel for RCON (If You Ever Need It)

If you ever need RCON access from outside (unlikely for your use case):

1. **Cloudflare Dashboard → Zero Trust → Networks → Tunnels → Your tunnel**
2. **Published application routes → Add a public hostname**
3. Configure:
   - **Subdomain:** `factorio-rcon`
   - **Domain:** `xcvr.link`
   - **Service Type:** TCP
   - **Service:** `192.168.0.158:27015`
   - **Save**

**But you probably don't need this** since your NPC controller is local.

## Why Keep RCON Local?

**Security Benefits:**
- RCON has password authentication, but it's still an admin interface
- No reason to expose admin access if you don't need it
- Reduces attack surface

**Your Use Case:**
- NPC controller runs on your Mac (`localhost`)
- Connects to NAS at `192.168.0.158:27015` (local network)
- No external access needed

## Complete Setup Summary

### What to Expose:
- ✅ **UDP 34197** - Game server (via router port forwarding)
- ❌ **TCP 27015** - RCON (keep local only)

### DNS Setup:
- ✅ **factorio.xcvr.link** - DNS-only A record → your public IP
- ❌ **No Cloudflare proxy** - Can't proxy UDP anyway

### Security:
- ✅ Minimal exposure (one port)
- ✅ RCON stays local
- ✅ Friendly DNS name for convenience

## Step-by-Step Setup

### 1. Router Port Forwarding

Log into your router and add:

```
Rule Name: Factorio Game Server
Protocol: UDP
External Port: 34197
Internal IP: 192.168.0.158
Internal Port: 34197
```

### 2. Cloudflare DNS Record

1. **Cloudflare Dashboard → DNS → Records**
2. **Add Record**
3. Fill in:
   ```
   Type: A
   Name: factorio
   IPv4 address: 24.155.117.71
   Proxy status: DNS only (gray cloud)
   TTL: Auto
   ```
4. **Save**

### 3. Test Connection

From outside your network (or use mobile data):
- Open Factorio client
- Connect to: `factorio.xcvr.link:34197`
- Should connect!

### 4. Verify RCON is Local Only

From your Mac (local network):
```bash
# This should work (local)
python3 -c "
from factorio_rcon import FactorioRcon
rcon = FactorioRcon('192.168.0.158', 27015, 'Ahth7Ahl1ereeC7')
print(rcon.send_command('/sc game.print(\"Test\")'))
"
```

From outside your network:
- RCON should **NOT** be accessible
- This is good - it's local only!

## Security Considerations

### What's Exposed:
- ✅ Game server (UDP 34197) - necessary for multiplayer
- ❌ RCON (TCP 27015) - local only (secure)

### Additional Security (Optional):

1. **Firewall Rules:**
   - Only allow UDP 34197 from specific IPs (if you want)
   - Or allow from anywhere (standard for game servers)

2. **Factorio Server Settings:**
   - Use server password (in `server-settings.json`)
   - Whitelist players (if you want)
   - Ban list for unwanted players

3. **Regular Updates:**
   - Keep Factorio server updated
   - Keep TrueNAS updated

## Summary

**Best Setup for Your Needs:**
1. ✅ DNS-only A record: `factorio.xcvr.link` → your public IP
2. ✅ Router port forward: UDP 34197 → 192.168.0.158:34197
3. ✅ RCON stays local: No external exposure needed
4. ✅ Minimal exposure: Only game port open

**Why This Works:**
- DNS gives you friendly name
- Port forwarding handles UDP (which tunnels can't)
- RCON local only (more secure)
- Simple and reliable

This is the standard approach for game servers - DNS for convenience, direct port forwarding for performance and reliability.
