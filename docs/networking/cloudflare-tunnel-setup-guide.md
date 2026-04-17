# Cloudflare Tunnel Setup Guide

## Overview
This guide sets up Cloudflare Tunnel to route external traffic directly to your internal services. **Caddy is not used** – Cloudflare Tunnel routes to each service’s port.

## Prerequisites
- ✅ Cloudflare account
- ✅ Domain `xcvr.link` added to Cloudflare

## Step 1: Create Tunnel in Cloudflare Dashboard

1. **Go to:** [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. **Select your domain:** `xcvr.link`
3. **Go to:** Zero Trust → Networks → Tunnels
4. **Click:** "Create a tunnel"
5. **Choose:** "Cloudflared" (not WARP)
6. **Name it:** `truenas-tunnel` (or any name)
7. **Click:** "Save tunnel"

## Step 2: Get Tunnel Token

After creating the tunnel:
1. **Copy the token** (looks like: `eyJhIjoi...` - long string)
2. **Save to** `cloudflared/.env`: `cp cloudflared/.env.example cloudflared/.env` then add `TUNNEL_TOKEN=your_token`

## Step 3: Install cloudflared on TrueNAS

1. **Create .env on TrueNAS** (run from Mac with `cloudflared/.env` populated):
   ```bash
   scp cloudflared/.env truenas_admin@192.168.0.158:/tmp/
   ssh truenas_admin@192.168.0.158 "sudo mkdir -p /mnt/tank/apps/cloudflared && sudo mv /tmp/.env /mnt/tank/apps/cloudflared/.env && sudo chmod 600 /mnt/tank/apps/cloudflared/.env"
   ```

2. **Go to:** TrueNAS Web UI → Apps → Install via YAML

3. **Paste** the contents of `docs/networking/cloudflared-truenas.yml` (uses env_file, no token in YAML)

4. **Deploy** the app

## Step 4: Configure Routes in Cloudflare Dashboard

Back in Cloudflare Dashboard → Zero Trust → Networks → Tunnels → Your tunnel → **Published application routes**:

Add a public hostname for each service, **routing directly to each service** (not Caddy):

### Immich
- **Subdomain:** `immich`
- **Domain:** `xcvr.link`
- **Service:** `http://192.168.0.158:30041`
- **Path:** (leave empty)
- **Save**

### Syncthing
- **Subdomain:** `syncthing`
- **Domain:** `xcvr.link`
- **Service:** `http://192.168.0.158:8334`
- **Path:** (leave empty)
- **Save**

### n8n
- **Subdomain:** `n8n`
- **Domain:** `xcvr.link`
- **Service:** `http://192.168.0.158:30109`
- **Path:** (leave empty)
- **Save**

### TrueNAS – **do not add** (local only)
- Do **not** create a public hostname for `nas.xcvr.link`.
- Access TrueNAS only on your network: `http://192.168.0.158:81`

## Step 5: Update DNS Records

Cloudflare will automatically create DNS records (CNAME) pointing to your tunnel. Verify in:
- **Cloudflare Dashboard → DNS → Records**

You should see:
- `immich.xcvr.link` → CNAME → `truenas-tunnel.cfargotunnel.com`
- `syncthing.xcvr.link` → CNAME → `truenas-tunnel.cfargotunnel.com`
- `n8n.xcvr.link` → CNAME → `truenas-tunnel.cfargotunnel.com`
- `nas.xcvr.link` → CNAME → `truenas-tunnel.cfargotunnel.com`

## Step 6: Verify

1. **Check cloudflared logs** in TrueNAS: Apps → Installed Apps → cloudflared → Logs
2. **Test external access:** Visit `https://immich.xcvr.link` from outside your network
3. **Test internal access:** Visit `https://immich.xcvr.link` from your network (should also work!)

## How It Works

```
External User → https://immich.xcvr.link
  ↓
Cloudflare (handles HTTPS, DDoS protection)
  ↓
Cloudflare Tunnel (encrypted connection)
  ↓
cloudflared on TrueNAS
  ↓
Immich on port 30041 (direct)
```

## Troubleshooting

**Tunnel not connecting:**
- Check tunnel token is correct
- Check cloudflared logs
- Verify tunnel is "Active" in Cloudflare dashboard

**Services not accessible:**
- Verify Caddy is running on port 8080
- Check Caddyfile has correct routes
- Test Caddy directly: `curl -H "Host: immich.xcvr.link" http://192.168.0.158:8080`

**DNS not resolving:**
- Wait a few minutes for DNS propagation
- Check DNS records in Cloudflare dashboard
- Verify CNAME records point to tunnel
