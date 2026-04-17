# Cloudflare Tunnel + NPM (All Through NPM)

## Architecture

All traffic goes through **Nginx Proxy Manager** (port 80). NPM routes by hostname to each app.

## Cloudflare Tunnel: Published Application Routes

**All hostnames point to NPM.** In your tunnel's "Published application routes", set each to:

| Subdomain | Domain | Service |
|-----------|--------|---------|
| sso | xcvr.link | `http://192.168.0.158:80` |
| nas | xcvr.link | `http://192.168.0.158:80` |
| rules | xcvr.link | `http://192.168.0.158:80` |
| immich | xcvr.link | `http://192.168.0.158:80` |
| n8n | xcvr.link | `http://192.168.0.158:80` |
| syncthing | xcvr.link | `http://192.168.0.158:80` |
| jellyfin | xcvr.link | `http://192.168.0.158:80` |

## NPM Proxy Hosts (Configured)

| Domain | Forwards To |
|--------|-------------|
| sso.xcvr.link | authelia:30133 |
| nas.xcvr.link | 192.168.0.158:81 |
| rules.xcvr.link | 192.168.0.158:30081 |
| immich.xcvr.link | 192.168.0.158:30041 |
| n8n.xcvr.link | 192.168.0.158:30109 |
| syncthing.xcvr.link | 192.168.0.158:8334 |

## How It Works

```
External User → https://immich.xcvr.link
  ↓
Cloudflare (HTTPS, DDoS protection)
  ↓
Cloudflare Tunnel
  ↓
cloudflared → NPM (port 80)
  ↓
NPM routes by hostname → app port
```

## Benefits

- Single entry point (NPM)
- SSL/SSO config in one place
- Add new apps by adding NPM proxy host + tunnel route

## Internal Access

- Direct: `http://192.168.0.158:<port>` for each app
- TrueNAS: `http://192.168.0.158:81`
- Cloudflare URLs work from LAN too

## DNS Alignment

For a single source of truth aligning UniFi Local DNS, Cloudflare Tunnel routes, and NPM proxy hosts, see **`dns-alignment-unifi-cloudflare-npm.md`**.
