# NPM+ scripts (retired)

**NPM+ (Nginx Proxy Manager Plus)** on TrueNAS has been **replaced by Caddy on Pi 5** as the reverse proxy for `*.xcvr.link`.

- **Caddyfile:** `scripts/servarr-pi5/caddy/Caddyfile` (deploy with `./scripts/servarr-pi5-caddy-update.sh`)
- **Verification:** `./scripts/caddy/verify-caddy-hosts.sh`
- **Migration doc:** `docs/networking/caddy-pi5-replace-npm.md`

The scripts in this directory (`npm-api.sh`, `verify-proxy-hosts.sh`, etc.) are kept for reference or one-off use against an NPM+ instance if you still have one running. They are no longer part of the active reverse-proxy workflow.
