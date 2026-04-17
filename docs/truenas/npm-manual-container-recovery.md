# NPM Manual Container — Recovery & Notes

## Status

NPM runs as a **manually started** container (not ix-apps managed) because:
- TrueNAS occupies ports 80/443 by default; we changed it to 81/444
- ix-apps NPM was on 30021/30022; we updated `user_config.yaml` to 80/443
- Removing the container does not trigger ix-apps auto-recreate (requires UI redeploy)
- Browser/API redeploy requires login; no headless redeploy path found

## Recovery (if NPM goes down)

```bash
./scripts/truenas/npm-restore.sh
```

## Avoiding Breakage

- **Do not** Update/Redeploy NPM from TrueNAS Apps UI unless you first verify port mappings (80, 443)
- `user_config.yaml` at `/mnt/.ix-apps/app_configs/nginx-proxy-manager/versions/1.2.27/user_config.yaml` has http_port: 80, https_port: 443
- If you redeploy via UI, ix-apps *may* use those ports; if not, run the recovery script above

## Ports

| Port | Service        |
|------|----------------|
| 80   | NPM proxy HTTP |
| 443  | NPM proxy HTTPS|
| 30020| NPM admin UI   |
| 81   | TrueNAS HTTP   |
| 444  | TrueNAS HTTPS  |

## Troubleshooting: Connection Refused on 80/30020

**Symptom:** `curl http://192.168.0.158:80` or `:30020` returns "Connection refused" even though the container is running.

**Cause:** NPM's startup script runs `chown -R` on certbot's Python site-packages (~200MB+). On a NAS this can take **5–15 minutes**. Until it finishes, nginx never starts and docker-proxy refuses connections.

**Verify container is still starting:**
```bash
ssh truenas_admin@192.168.0.158 "sudo docker logs ix-nginx-proxy-manager-npm-1 2>&1 | tail -5"
```
If you see `Changing ownership of certbot directories` or `site-packages` — it's still starting. Wait and retry.

**When ready:** Logs will show nginx starting. Then:
```bash
curl -sI -w "Exit: %{exitcode}\n" -H "Host: jellyfin.xcvr.link" http://192.168.0.158:80/ 2>&1 | head -8
# Expect: HTTP/1.1 302 and Exit: 0
```

**Workaround:** Use Jellyfin directly until NPM is ready: `http://pi5.xcvr.link:8096` or `http://192.168.0.136:8096`

**Wait script (Rich UI):**
```bash
python scripts/npm/wait-for-npm-ready.py
# Polls every 5s, shows spinner, beeps when ready
```
