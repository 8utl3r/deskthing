# Factorio + Cloudflare Tunnel Setup

## Important Limitation: UDP Support

**Cloudflare tunnels primarily support HTTP/HTTPS (TCP traffic).** Factorio uses:
- **UDP port 34197** - Game traffic (main connection)
- **TCP port 27015** - RCON (admin/control)

**The Challenge:**
- ✅ TCP (RCON) can work through Cloudflare tunnel
- ❌ UDP (game traffic) **does not work** through standard Cloudflare tunnels

## Option 1: Expose RCON Only (TCP)

If you only need RCON access externally, you can route TCP through the tunnel:

### In Cloudflare Dashboard

1. Go to **Zero Trust → Networks → Tunnels → Your tunnel → Published application routes**
2. Click **Add a public hostname**
3. Configure:
   - **Subdomain:** `factorio-rcon` (or any name)
   - **Domain:** `xcvr.link`
   - **Service Type:** `tcp://192.168.0.158:27015`
   - **Save**

**Note:** This only exposes RCON, not the game server itself.

## Option 2: Use Cloudflare Spectrum (Paid Feature)

Cloudflare Spectrum supports UDP for game servers, but it's a **paid feature**:
- Requires Cloudflare Business plan or higher
- Supports UDP game servers
- More complex setup

**Not recommended** unless you already have a Business plan.

## Option 3: Direct Port Forwarding (Recommended for Game Traffic)

For the actual game server (UDP), **direct port forwarding on your router** is the best option:

1. **Router Port Forwarding:**
   - Forward UDP port `34197` → `192.168.0.158:34197`
   - Forward TCP port `27015` → `192.168.0.158:27015` (if you want RCON external)

2. **Connect using:**
   - Your public IP: `24.155.117.71:34197`
   - Or set up a DNS record pointing to your public IP

**Why this is better:**
- ✅ UDP works perfectly
- ✅ Lower latency (no tunnel overhead)
- ✅ Standard for game servers
- ✅ Free

## Option 4: Hybrid Approach (Best of Both)

**For RCON (admin access):**
- Use Cloudflare tunnel: `factorio-rcon.xcvr.link` → TCP `192.168.0.158:27015`
- Secure, encrypted, no port forwarding needed

**For Game Server:**
- Use direct port forwarding: UDP `34197` → `192.168.0.158:34197`
- Better performance, works reliably

## Option 5: Alternative Tunneling Solutions

If you need UDP tunneling, consider:

### Tailscale (Recommended)
- Free for personal use
- Excellent UDP support
- Easy setup
- Works great for game servers

### WireGuard
- Open source VPN
- Excellent performance
- UDP support

### Pomerium
- Mentioned in Cloudflare community discussions
- Supports UDP for Factorio
- More complex setup

## Recommended Setup

**For your use case, I recommend:**

1. **RCON (admin):** Cloudflare tunnel
   - Secure, encrypted access
   - No port forwarding needed
   - Access via: `factorio-rcon.xcvr.link:27015`

2. **Game Server:** Direct port forwarding
   - Best performance
   - Reliable UDP
   - Connect via: `24.155.117.71:34197` or `factorio.xcvr.link:34197` (if you set up DNS)

## Setting Up RCON via Cloudflare Tunnel

If you want to expose RCON through the tunnel:

### Step 1: Add Route in Cloudflare Dashboard

1. Go to **Cloudflare Dashboard → Zero Trust → Networks → Tunnels**
2. Click on your tunnel (e.g., `truenas-tunnel`)
3. Go to **Published application routes**
4. Click **Add a public hostname**
5. Configure:
   - **Subdomain:** `factorio-rcon`
   - **Domain:** `xcvr.link`
   - **Service Type:** Select **TCP**
   - **Service:** `192.168.0.158:27015`
   - **Save**

### Step 2: Update Your RCON Client

In your `config.py` or RCON client, you can now use:
```python
RCON_HOST = "factorio-rcon.xcvr.link"  # Instead of 192.168.0.158
RCON_PORT = 27015
```

**Note:** The port might be different if Cloudflare assigns a different port. Check the tunnel configuration.

## Setting Up Direct Port Forwarding (For Game Server)

### Step 1: Router Configuration

1. Log into your router admin panel
2. Find **Port Forwarding** or **Virtual Server** settings
3. Add rule:
   - **Protocol:** UDP
   - **External Port:** 34197
   - **Internal IP:** 192.168.0.158
   - **Internal Port:** 34197
   - **Save**

4. (Optional) Add TCP rule for RCON:
   - **Protocol:** TCP
   - **External Port:** 27015
   - **Internal IP:** 192.168.0.158
   - **Internal Port:** 27015
   - **Save**

### Step 2: DNS Record (Optional)

If you want a friendly name instead of IP:

1. **Cloudflare Dashboard → DNS → Records**
2. **Add Record:**
   - **Type:** A
   - **Name:** `factorio`
   - **IPv4 address:** `24.155.117.71` (your public IP)
   - **Proxy status:** DNS only (gray cloud - not proxied, since it's not HTTP)
   - **Save**

3. **Connect using:** `factorio.xcvr.link:34197`

## Summary

**What Works:**
- ✅ RCON (TCP) through Cloudflare tunnel
- ✅ Game server (UDP) via direct port forwarding

**What Doesn't Work:**
- ❌ Game server (UDP) through standard Cloudflare tunnel

**Best Approach:**
- Hybrid: RCON via tunnel, game server via port forwarding

Would you like me to help you set up the RCON tunnel route, or do you prefer to use direct port forwarding for everything?
