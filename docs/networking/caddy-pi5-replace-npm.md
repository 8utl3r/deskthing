# Caddy on Pi 5 Replaces NPM+

**Purpose:** Migration steps and reference after replacing Nginx Proxy Manager Plus (NPM+) on TrueNAS with a single Caddy instance on the Pi 5.

**See also:** Migration plan (Cursor plan or `docs/...`), [NETWORK_REFERENCE.md](NETWORK_REFERENCE.md), [npmplus-dns-tunnel-diagram-and-verification.md](npmplus-dns-tunnel-diagram-and-verification.md).

---

## 1. Architecture (post-migration)

- **Entry point:** Caddy on **Pi 5** (192.168.0.136) binds ports 80 and 443.
- **Cloudflare Tunnel** and **UniFi Local DNS** point proxied `*.xcvr.link` to **192.168.0.136:80** (Caddy).
- Caddy reverse-proxies to:
  - **TrueNAS** (192.168.0.158): sso, nas, headscale, rules, immich, n8n, syncthing
  - **Pi 5 host** (192.168.0.136:8096, 4533): jellyfin, music, listen, watch, read

---

## 2. Caddyfile location

- **In dotfiles:** `scripts/servarr-pi5/caddy/Caddyfile`
- **On Pi 5:** `/var/lib/caddy/config/Caddyfile` (read by Caddy Docker container)

**Deploy/update:** From the repo root, run:

```bash
./scripts/servarr-pi5-caddy-update.sh
```

Or manually: `scp scripts/servarr-pi5/caddy/Caddyfile pi@pi5.xcvr.link:/tmp/` then on the Pi: `sudo mv /tmp/Caddyfile /var/lib/caddy/config/Caddyfile && sudo docker restart caddy`.

---

## 3. Tunnel and Local DNS changes

- **Cloudflare Tunnel:** Zero Trust → Tunnels → your tunnel → Public Hostname. Set **Service URL** for each hostname (sso, nas, headscale, rules, immich, n8n, syncthing, jellyfin, music) to **`http://192.168.0.136:80`**. If you expose listen, watch, or read, add them with the same Service URL.
- **UniFi Local DNS:** Run `./unifi/add-local-dns-via-ssh.sh` after ensuring the script’s `RECORDS` array points the proxied hostnames to **192.168.0.136** (script in dotfiles is already updated for Caddy-on-Pi-5).

---

## 4. Verification

From the Mac (or any host that can reach 192.168.0.136):

```bash
./scripts/caddy/verify-caddy-hosts.sh
```

Or manually for one host:

```bash
curl -sI -H "Host: rules.xcvr.link" http://192.168.0.136
```

Expect 2xx or 3xx (e.g. 302 to HTTPS). 502 = backend unreachable (e.g. TrueNAS or Pi 5 service down).

---

## 5. Jellyfin WebSockets

Caddy’s `reverse_proxy` supports WebSockets by default. If playback via jellyfin.xcvr.link (or listen/watch/read) fails with “fatal player error” or similar, ensure the Caddyfile does not add options that break WebSockets (e.g. buffering). No extra config is normally required.

---

## 6. Rollback

If you need to revert to NPM+:

1. Start NPM+ on TrueNAS (Apps → NPM+ → Start).
2. In Cloudflare Tunnel, set each hostname’s Service URL back to `http://192.168.0.158:80`.
3. In `unifi/add-local-dns-via-ssh.sh`, set the nine proxied hostnames back to 192.168.0.158 in `RECORDS`, then re-run the script.
