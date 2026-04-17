# How Reverse Proxy Works with Multiple Services

## The Concept

**DNS only resolves domain names to IP addresses. The reverse proxy (Caddy) handles routing based on the domain name.**

## How It Works

### Step 1: DNS Resolution
All your service domains point to the **same IP** (your NAS):
- `immich.xcvr.link` → `192.168.0.158`
- `n8n.xcvr.link` → `192.168.0.158`
- `seafile.xcvr.link` → `192.168.0.158`
- `jet.xcvr.link` → `192.168.0.197` (different server, but same concept)

**DNS doesn't care about ports** - it just resolves names to IPs.

### Step 2: Caddy Receives the Request
When you visit `http://immich.xcvr.link:8080`:
1. DNS resolves `immich.xcvr.link` → `192.168.0.158`
2. Your browser connects to `192.168.0.158:8080` (where Caddy is listening)
3. Browser sends HTTP request with **Host header**: `Host: immich.xcvr.link`

### Step 3: Caddy Routes Based on Domain
Caddy reads the **Host header** and routes to the correct backend:
- Request for `immich.xcvr.link` → Routes to `192.168.0.158:30041` (Immich)
- Request for `n8n.xcvr.link` → Routes to `192.168.0.158:30109` (n8n)
- Request for `seafile.xcvr.link` → Routes to `192.168.0.158:8082` (Seafile)

## Your Current Setup

**Caddy is listening on:**
- Port 8080 (HTTP)
- Port 8444 (HTTPS)

**All services share these ports** - Caddy handles the routing.

## Example: Adding n8n

### 1. Add DNS Entry in UniFi
- Hostname: `n8n`
- Domain: `xcvr.link`
- IP: `192.168.0.158` (same as immich!)
- Type: A

### 2. Update Caddyfile
Add to `/mnt/tank/apps/caddy/Caddyfile`:
```caddy
n8n.xcvr.link {
    reverse_proxy 192.168.0.158:30109
}
```

### 3. Restart Caddy
Caddy will reload and now handle both domains.

## Complete Example Caddyfile

```caddy
# Immich photo management
immich.xcvr.link {
    reverse_proxy 192.168.0.158:30041
}

# n8n workflow automation
n8n.xcvr.link {
    reverse_proxy 192.168.0.158:30109
}

# Seafile file sync
seafile.xcvr.link {
    reverse_proxy 192.168.0.158:8082
}

# Qdrant vector database (if you want web UI)
qdrant.xcvr.link {
    reverse_proxy 192.168.0.158:6333
}
```

## Key Points

1. **All DNS entries point to the same IP** (`192.168.0.158`)
2. **Caddy listens on one set of ports** (8080/8444)
3. **Caddy routes based on domain name** (Host header)
4. **Each service keeps its original port** (30041, 30109, etc.) - Caddy connects to those internally
5. **You access everything through Caddy's ports** (8080/8444)

## Benefits

- ✅ One port to remember (8080 or 8444)
- ✅ Automatic HTTPS (once Cloudflare Tunnel is set up)
- ✅ Clean URLs (`immich.xcvr.link` instead of `192.168.0.158:30041`)
- ✅ Easy to add more services
