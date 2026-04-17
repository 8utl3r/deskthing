# Caddy Installation Troubleshooting

## Issue: Port 8443 Already in Use

Port 8443 is already in use by another service. Updated YAML uses port **8444** instead.

## Updated YAML

Use `caddy-docker-compose-final.yml` which uses:
- Port **8080** for HTTP (instead of 80)
- Port **8444** for HTTPS (instead of 443, avoiding conflict with 8443)

## Installation Steps

1. **Delete any failed Caddy app** in TrueNAS (if it exists)
2. **Use the final YAML** from `caddy-docker-compose-final.yml`
3. **Install via**: Apps → Discover Apps → Three dots → Install via YAML

## Cloudflare Tunnel Configuration

When setting up Cloudflare Tunnel, point it to:
- **HTTP**: `http://192.168.0.158:8080`
- **HTTPS**: `https://192.168.0.158:8444`

The tunnel will handle external 80/443 and route to these internal ports.
