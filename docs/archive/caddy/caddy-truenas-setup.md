# Caddy + Cloudflared Setup for TrueNAS

## Status: Ready to Install

All configuration files have been prepared. Caddy needs to be installed via TrueNAS Web UI.

## Step 1: Install Caddy (Do This First)

1. **Open TrueNAS Web UI**: `http://192.168.0.158`
2. **Go to**: Apps → Discover Apps
3. **Click**: Three dots (⋮) in top right → **"Install via YAML"**
4. **Application Name**: `caddy`
5. **Paste this YAML**:

```yaml
version: '3.8'

services:
  caddy:
    image: caddy:latest
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /mnt/tank/apps/caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - /mnt/tank/apps/caddy/data:/data
      - /mnt/tank/apps/caddy/config:/config
    healthcheck:
      test: ["CMD", "caddy", "version"]
      interval: 30s
      timeout: 10s
      retries: 3
```

6. **Deploy** the app

## Step 2: Create Caddyfile

After Caddy is installed, create the Caddyfile:

1. **Go to**: System Settings → Shell
2. **Run**:
```bash
cat > /mnt/tank/apps/caddy/Caddyfile << 'EOF'
# Caddy reverse proxy configuration for immich.xcvr.link
immich.xcvr.link {
    reverse_proxy 192.168.0.158:30041
}
EOF
chmod 644 /mnt/tank/apps/caddy/Caddyfile
```

3. **Restart Caddy app** in TrueNAS Apps → Installed Apps → caddy → Restart

## Step 3: Verify Caddy is Running

```bash
# From your Mac:
curl -I http://192.168.0.158
# Should return Caddy headers
```

## Next: Cloudflare Tunnel Setup

After Caddy is working, proceed to Cloudflare Tunnel setup (step 2 in main guide).
