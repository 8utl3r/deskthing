# Caddy Multi-Service Configuration

## Services Configured

All services are now accessible via Caddy reverse proxy:

- **Immich**: `http://immich.xcvr.link:8080` → `192.168.0.158:30041`
- **n8n**: `http://n8n.xcvr.link:8080` → `192.168.0.158:30109`
- **Seafile**: `http://seafile.xcvr.link:8080` → `192.168.0.158:8082`
- **Qdrant**: `http://qdrant.xcvr.link:8080` → `192.168.0.158:6333`

## DNS Entries Needed in UniFi

Add these DNS entries (all point to `192.168.0.158`):

1. **immich.xcvr.link**
   - Hostname: `immich`
   - Domain: `xcvr.link`
   - IP: `192.168.0.158`
   - Type: A

2. **n8n.xcvr.link**
   - Hostname: `n8n`
   - Domain: `xcvr.link`
   - IP: `192.168.0.158`
   - Type: A

3. **seafile.xcvr.link**
   - Hostname: `seafile`
   - Domain: `xcvr.link`
   - IP: `192.168.0.158`
   - Type: A

4. **qdrant.xcvr.link** (optional)
   - Hostname: `qdrant`
   - Domain: `xcvr.link`
   - IP: `192.168.0.158`
   - Type: A

## Testing

After adding DNS entries:

```bash
# Test DNS resolution
dig @192.168.0.1 immich.xcvr.link +short
dig @192.168.0.1 n8n.xcvr.link +short

# Test via Caddy (once DNS is working)
curl -I http://immich.xcvr.link:8080
curl -I http://n8n.xcvr.link:8080
```

## Adding More Services

To add a new service:

1. Add DNS entry in UniFi
2. Add block to Caddyfile:
```caddy
newservice.xcvr.link {
    reverse_proxy 192.168.0.158:PORT
}
```
3. Caddy auto-reloads (or restart the app)

## Caddyfile Location

`/mnt/tank/apps/caddy/Caddyfile`
