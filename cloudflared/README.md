# Cloudflare Tunnel (cloudflared)

Token stored in `.env` (gitignored). Never commit the token.

## Migration (token was in YAML)

If you had the token in `cloudflared-truenas.yml`:

1. **Rotate the token** — Cloudflare → Zero Trust → Tunnels → Configure → Create new token (old one was exposed)
2. Create `cloudflared/.env` with the new token
3. Run `./scripts/cloudflared/deploy-env-to-truenas.sh`
4. Edit the cloudflared app in TrueNAS → Update the YAML to the new version (from `docs/networking/cloudflared-truenas.yml`) or redeploy
5. Restart the app

## Setup

```bash
cp .env.example .env
# Edit .env: add TUNNEL_TOKEN from Cloudflare → Zero Trust → Tunnels → Configure
```

## TrueNAS Deployment

1. **Create .env locally** (see Setup above).

2. **Deploy .env to TrueNAS:**
   ```bash
   ./scripts/cloudflared/deploy-env-to-truenas.sh
   ```
   Requires `factorio/.env.nas` with `NAS_SUDO_PASSWORD`.

3. **Deploy** using `docs/networking/cloudflared-truenas.yml` via Apps → Install via YAML.

4. If the app fails to find the .env (path differs), add `TUNNEL_TOKEN` in the app's **Environment Variables** when editing the app.

## Rotate Token

1. Cloudflare → Zero Trust → Tunnels → Configure → Create new token
2. Update `.env` (local) and `/mnt/tank/apps/cloudflared/.env` (TrueNAS)
3. Restart the cloudflared app
