# SSO Setup Walkthrough (NPM + Authelia on TrueNAS)

**Where you are:** `sso.xcvr.link` works (NPM + Cloudflare Tunnel likely). Authelia wasn’t visible in the TrueNAS Apps catalog. This walkthrough gets Authelia running (via **Install via YAML** if needed), then wires `sso.xcvr.link` to it.

**See also:** [truenas-apps-sso-and-updates.md](truenas-apps-sso-and-updates.md) (overview), [Authelia NPM guide](https://www.authelia.com/integration/proxies/nginx-proxy-manager/).

---

## Step 1: Try Authelia from the catalog (optional)

1. Open **TrueNAS** → **Apps** → **Installed** (or **Discover**).
2. Open **Settings** (gear icon or **Configure**).
3. Under **Trains** (or **Catalogs**), ensure **Community** is **checked**. Save if you changed it.
4. Go to **Discover**. In the search box, type **Authelia**.
5. If **Authelia** appears → open it → **Install**, set port (e.g. **9091**) and storage → Deploy. Then skip to **Step 3**.
6. If **Authelia does not appear** → use **Step 2** (Install via YAML).

---

## Step 2: Install Authelia via YAML (if not in catalog)

1. **Apps** → **Discover** → open the **⋮** (three dots) menu → **Install via YAML**.
2. **Application Name:** `authelia`.
3. Paste the YAML below. Adjust the **host path** for the config volume if your pool/dataset is different (e.g. `/mnt/tank/apps/authelia` or the path TrueNAS gives you for an ix volume).

```yaml
services:
  authelia:
    image: docker.io/authelia/authelia:latest
    container_name: authelia
    restart: unless-stopped
    ports:
      - "9091:9091"
    volumes:
      - authelia-config:/config
    environment:
      - TZ=America/Chicago
```

4. In the wizard, map **authelia-config** to a **Host Path** or **ixVolume** (e.g. `/mnt/tank/apps/authelia` or create an ix volume). Authelia needs persistent storage for `configuration.yml` and `users_database.yml`.
5. **Deploy**. Wait until the app is **Running**. Note the app name (e.g. `authelia`) and port **9091** for NPM.

---

## Step 3: Create Authelia config files

Authelia needs two files on its config storage: `configuration.yml` and `users_database.yml`.

1. **Find Authelia’s config path**
   - **Apps** → **Installed** → **authelia** → **Workloads** or **Volume Mounts** → note the path that maps to `/config` inside the container (e.g. `/mnt/tank/apps/authelia` or an ix volume path).

2. **Create the directory** (if using host path)
   - TrueNAS **Shell**: `mkdir -p /mnt/tank/apps/authelia` (use the path you noted).

3. **Create `configuration.yml`** in that directory. Minimal example for `sso.xcvr.link`:

```yaml
server:
  host: 0.0.0.0
  port: 9091

log:
  level: info

authentication_backend:
  file:
    path: /config/users_database.yml

access_control:
  default_policy: deny
  rules:
    - domain: sso.xcvr.link
      policy: one_factor
    - domain: "*.xcvr.link"
      policy: one_factor

session:
  name: authelia_session
  domain: xcvr.link
  expiration: 1h
  inactivity: 15m
  cookies:
    - name: authelia_session
      domain: xcvr.link
      authelia_url: https://sso.xcvr.link
      default_redirection_url: https://sso.xcvr.link

storage:
  local:
    path: /config/database.sqlite3

notifier:
  filesystem:
    filename: /config/notification.txt

identity_providers:
  oidc:
    hmac_secret: REPLACE_WITH_RANDOM_STRING
    issuer_private_key: REPLACE_WITH_BASE64_KEY
```

Replace:
- `REPLACE_WITH_RANDOM_STRING`: e.g. `openssl rand -base64 32`
- `REPLACE_WITH_BASE64_KEY`: optional for “just login”; required if you use Jellyfin SSO (OIDC). Generate with Authelia’s docs or `authelia crypto certificate rsa generate` and base64 the key.

**If Authelia won’t start:** Check [Authelia configuration docs](https://www.authelia.com/configuration/) — the schema can change by version; the example above is a starting point.

4. **Create `users_database.yml`** in the same directory:

```yaml
users:
  your_username:
    displayname: "Your Name"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
```

Generate a hash (TrueNAS Shell or your Mac):

```bash
docker run --rm -it authelia/authelia:latest authelia crypto hash generate argon2 --password 'YOUR_PLAIN_PASSWORD'
```

Paste the output into `users_database.yml` in place of `$argon2id$...`. Use one user for testing.

5. **Restart Authelia**: Apps → Installed → authelia → **Stop** → **Start**.

---

## Step 4: Point sso.xcvr.link in NPM to Authelia

1. Open **Nginx Proxy Manager** (from Apps or the port you use for NPM admin).
2. **Proxy Hosts** → find the host for **sso.xcvr.link** (you said it already works; that host may be pointing somewhere else or to a placeholder).
3. **Edit** that Proxy Host:
   - **Details:** Domain Names = `sso.xcvr.link`. **Forward Hostname / IP** = `authelia` (the TrueNAS app name). **Forward Port** = `9091`. Scheme = **http**.
   - **SSL:** Use NPM’s SSL (e.g. Let’s Encrypt) so `https://sso.xcvr.link` works.
   - **Advanced:** Paste only the proxy snippet (no auth_request for the portal). From [Authelia NPM](https://www.authelia.com/integration/proxies/nginx-proxy-manager/), for the **Authelia portal** the Advanced tab is:

   ```nginx
   location / {
       proxy_pass $forward_scheme://$server:$port;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
   }
   ```

   (Or the minimal proxy headers from Authelia’s [proxy.conf](https://www.authelia.com/integration/proxies/nginx/#proxyconf).)

4. Save. NPM will now send `sso.xcvr.link` traffic to the Authelia container.

---

## Step 5: Cloudflare Tunnel (if not already set)

Ensure **sso.xcvr.link** is a public hostname in your Cloudflare Tunnel, pointing to NPM’s HTTP port (e.g. `http://192.168.0.158:3080`). If `sso.xcvr.link` already works, this is likely done.

---

## Step 6: Test

1. Open **https://sso.xcvr.link** in a browser.
2. You should see the **Authelia login** page. Log in with the user you added in `users_database.yml`.
3. After login you may see a redirect or “Authenticated” — that’s expected. The portal is working.

---

## Step 7: Add protected apps (later)

For each app you want behind SSO (e.g. Immich, n8n):

1. In NPM, add a **Proxy Host** for that app’s domain (e.g. `immich.xcvr.link` → forward to the app’s hostname:port).
2. In the **Advanced** tab, add the **auth_request** snippets (authelia-location + authelia-authrequest) so unauthenticated users are redirected to `sso.xcvr.link`. See [truenas-apps-sso-and-updates.md §5](truenas-apps-sso-and-updates.md#5-authelia--nginx-proxy-manager-truenas) and [Authelia NGINX snippets](https://www.authelia.com/integration/proxies/nginx/#supporting-configuration-snippets).
3. In Cloudflare Tunnel, point that hostname to NPM’s port (or switch the existing direct route to NPM).

---

## Summary

| Step | Action |
|------|--------|
| 1 | Try Authelia from Discover (enable Community train); if not found → |
| 2 | Install Authelia via **Install via YAML** (name `authelia`, port 9091, config volume). |
| 3 | Create `configuration.yml` and `users_database.yml` on Authelia’s config path; restart Authelia. |
| 4 | In NPM, set **sso.xcvr.link** Proxy Host to forward to **authelia:9091**; Advanced = proxy snippet only. |
| 5 | Confirm Tunnel route for sso.xcvr.link → NPM. |
| 6 | Test https://sso.xcvr.link → login. |
| 7 | Later: add Proxy Hosts for protected apps with auth_request. |
