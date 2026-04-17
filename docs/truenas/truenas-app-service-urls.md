# TrueNAS App Service URLs (Verified)

**Purpose:** Correct URLs for Cloudflare Tunnel published routes and NPM proxy hosts.

**Verified via:** NPM config, ss port scan, tunnel docs. Container names tested from host: `authelia` does NOT resolve (host DNS). NPM uses `authelia` successfully, so it resolves from within the container network.

---

## Host Ports (Verified)

| App | Host Port | Notes |
|-----|-----------|-------|
| NPM (proxy) | 80, 443 | Receives all proxied traffic |
| NPM (admin) | 30020 | API at /api |
| TrueNAS UI | 81 | Web interface |
| Authelia | 30133 | SSO |
| rules-static | 30081 | Rules docs |
| Immich | 30041 | Photos |
| n8n | 30109 | Workflows |
| Syncthing | 8334 | Web UI |

---

## Cloudflare Tunnel: Use Host IP

**All published routes should use `http://192.168.0.158:<port>`** — cloudflared can reach the host; container names may not resolve from its network.

### Route Everything Through NPM (Recommended)

Point all hostnames to NPM; NPM routes by hostname:

| Hostname | Service URL |
|----------|-------------|
| sso.xcvr.link | `http://192.168.0.158:80` |
| nas.xcvr.link | `http://192.168.0.158:80` |
| rules.xcvr.link | `http://192.168.0.158:80` |
| immich.xcvr.link | `http://192.168.0.158:80` |
| n8n.xcvr.link | `http://192.168.0.158:80` |
| syncthing.xcvr.link | `http://192.168.0.158:80` |

### Direct Routes (If Not Using NPM)

| Hostname | Service URL |
|----------|-------------|
| sso.xcvr.link | `http://192.168.0.158:30133` |
| nas.xcvr.link | `http://192.168.0.158:81` |
| rules.xcvr.link | `http://192.168.0.158:30081` |
| immich.xcvr.link | `http://192.168.0.158:30041` |
| n8n.xcvr.link | `http://192.168.0.158:30109` |
| syncthing.xcvr.link | `http://192.168.0.158:8334` |

---

## Container Names (Unverified for cloudflared)

NPM uses `authelia:30133` — works from NPM's container. cloudflared may or may not resolve `authelia`; host IP is safer.

**Do not use** `http://authelia:30133` in Cloudflare routes unless you've verified it from cloudflared's network. Use `http://192.168.0.158:30133` instead.

**DNS alignment:** For UniFi Local DNS, Cloudflare Tunnel routes, and NPM proxy hosts in one place, see `docs/networking/dns-alignment-unifi-cloudflare-npm.md`.
