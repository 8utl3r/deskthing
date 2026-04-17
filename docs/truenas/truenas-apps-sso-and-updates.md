# TrueNAS Apps: SSO (Authelia / PocketID) and Making Updates Easy

**Purpose:** Can you run Authelia and PocketID from the TrueNAS web UI? How do catalogs, YAML, and “update available” work?  
**Relevant:** [sso-feature-matrix.md](../services/sso-feature-matrix.md), [sso-features-explained.md](../services/sso-features-explained.md).

**Current architecture:** The reverse proxy for `*.xcvr.link` is **Caddy on Pi 5** (192.168.0.136), not NPM+ on TrueNAS. **Authelia** remains on TrueNAS (192.168.0.158:30133). Caddy can use `forward_auth` to Authelia for protected hosts. See [caddy-pi5-replace-npm.md](../networking/caddy-pi5-replace-npm.md).

---

## SSO setup: order of operations (NPM + Authelia)

Use this order so each step has what it needs. You’re using **Cloudflare Tunnel direct** today (Immich, Syncthing, n8n); SSO adds **NPM** and **Authelia** so traffic for SSO-protected hostnames goes Tunnel → NPM → Authelia (login) or NPM → app (after auth).

| Step | What | Why first |
|------|------|-----------|
| **1** | **Prerequisites** — Apps pool set, Community train enabled, decide SSO subdomain (e.g. `sso.xcvr.link`) | So Apps can install and you know the Authelia URL. |
| **2** | **Install Authelia** — Apps → Discover → Authelia (Community) → Install; set port (e.g. 9091), storage | Authelia is the IdP; NPM will point to it. |
| **3** | **Configure Authelia** — Create `configuration.yml` and `users_database.yml` on Authelia’s storage; set session domain (`xcvr.link`), `authelia_url` (e.g. `https://sso.xcvr.link`), redirect URLs, access control | NPM can’t use Authelia until it’s configured and running. |
| **4** | **Install Nginx Proxy Manager** — Apps → Discover → Nginx Proxy Manager → Install; note the **HTTP/HTTPS proxy ports** (e.g. 3080, 3443) NPM publishes | NPM is the reverse proxy that will do auth_request to Authelia and proxy to apps. |
| **5** | **NPM: Proxy Host for Authelia** — In NPM, add Proxy Host `sso.xcvr.link` → forward to Authelia (hostname/port from step 2, e.g. `authelia:9091`); SSL via NPM; Advanced tab = proxy snippet only (no auth_request on the portal) | So users can open the login page at sso.xcvr.link. |
| **6** | **Cloudflare Tunnel: route for SSO** — In Cloudflare Tunnel, add public hostname `sso.xcvr.link` → `http://192.168.0.158:<NPM_HTTP_port>` (e.g. 3080) | So https://sso.xcvr.link hits NPM, which proxies to Authelia. |
| **7** | **NPM: Proxy Hosts for protected apps** — For each app you want behind SSO (e.g. Immich, n8n), add a Proxy Host in NPM with the **auth_request** snippet in Advanced; forward to the app’s port. Then add Tunnel routes for those hostnames to NPM’s port (or switch existing direct routes to NPM) | So those apps require Authelia login before NPM proxies to them. |

**First thing to do now:** **Step 1 (Prerequisites)** then **Step 2 (Install Authelia)**. After that we’ll do Step 3 (Authelia config), then NPM install and NPM config.

**Step-by-step walkthrough (including Install via YAML if Authelia isn’t in the catalog):** [sso-setup-walkthrough.md](sso-setup-walkthrough.md).

---

## 1. Running Authelia and PocketID via the TrueNAS Web UI

**Yes.** Both are in the **TrueNAS Apps Market** (catalog) and can be installed from the web UI.

| App       | In catalog | Where |
|----------|------------|--------|
| **Authelia**  | Yes | [apps.truenas.com/catalog/authelia](https://apps.truenas.com/catalog/authelia). Enable **Community** train in Apps → Settings if needed, then Discover → Authelia → Install. |
| **PocketID**  | Yes | [apps.truenas.com/catalog/pocket-id](https://apps.truenas.com/catalog/pocket-id). Same: Community train, Discover → Pocket ID → Install. |

**Steps (high level):**

1. Apps → **Settings** → choose a **pool** for apps (if not already set).
2. In **Settings**, enable the **Community** train (checkbox) so Community catalog apps appear.
3. **Discover** → search for Authelia or Pocket ID → open the app → **Install**, then complete the wizard (ports, storage, env vars, etc.).
4. After install, the app appears under **Installed**. You get a **Web UI** link and, when the catalog has a newer version, an **Update** button.

So you can run **both** via the web UI: install one, then the other, and manage them from Apps → Installed.

**Caveat:** Authelia and PocketID only handle *auth*. To protect other apps (e.g. Jellyfin) with SSO you still need a reverse proxy and config (forward_auth / auth_request or OIDC). On TrueNAS, **Caddy is not in the Apps catalog** and **Caddy had repeated port/networking issues on this NAS** (see [§6.1 Past Caddy issues](#61-past-caddy-issues-on-truenas)); the usual choice is **Nginx Proxy Manager (NPM)**. See [§5. Authelia + Nginx Proxy Manager](#5-authelia--nginx-proxy-manager-truenas). Caddy via Install via YAML is possible but not recommended here; see [§6](#6-adding-caddy-via-install-via-yaml--and-why-we-moved-away-from-it).

---

## 2. “We’re already running Docker”—what’s actually running?

**Yes.** On TrueNAS Scale 24.10 / 25.04, **Apps are Docker containers**. When you install something from **Apps → Discover** (or **Install via YAML**), it runs as a container on the NAS. You don’t get a `docker` or `docker compose` CLI on the host; the **Apps UI** is how you add and manage those containers.

From your docs, things you’re already running (or have guides for) on the NAS as **Apps** include:

- **n8n** (workflow automation)
- **Qdrant** (vector DB)
- **Immich** (photos)
- **Syncthing** (file sync)
- Plus anything else you’ve installed from **Apps → Discover** (e.g. Nginx Proxy Manager, Jellyfin, etc.)

So “we’re already running stuff in Docker” = those Apps. **Authelia** and **Caddy** (or NPM) would simply be more Apps (containers) on the same NAS, on the same Docker network, so they can talk to each other (e.g. Caddy → Authelia, Caddy → Jellyfin).

---

## 3. YAML vs Catalog: What Points to a Repo, and When Do You See “Update Available”?, and When Do You See “Update Available”?

Two different things are easy to mix up.

### Catalog apps (Authelia, PocketID, Jellyfin, …)

- **Catalog** = a “repo” of **app definitions** (metadata, questions, image reference, version). TrueNAS ships with trains: **stable**, **enterprise**, **community**, **test**. Each train is a catalog; the catalog is maintained by iX/community (not by you).
- When you install **Authelia** or **PocketID** from **Discover**, you’re installing an app that’s **defined in that catalog**. The app definition points to a container image (e.g. `ghcr.io/authelia/authelia`) and a version.
- **“Update available”** appears when the **catalog** is updated: the maintainers publish a new version of the app (new image tag / chart version). TrueNAS periodically refreshes the catalog; when it sees a newer version than what you have, it shows the update badge and **Update** button.
- So: for catalog apps you **don’t** add your own YAML to “point to a repo.” The catalog already points to the images/repos; you just enable a train and install. Updates are driven by the catalog.

### Custom app (“Install via YAML”)

- **Apps → Discover → ⋮ (menu) → “Install via YAML”** lets you deploy an app from a **Docker Compose–style YAML** you paste/edit. That YAML describes **containers** (image, ports, volumes, etc.). It does **not** “point to a repo” of app definitions; it points to **container image(s)** (e.g. `image: ghcr.io/some/app:latest`).
- TrueNAS has a global setting **“Check for docker image updates”** (Apps → Settings). For apps (including custom YAML apps), TrueNAS can check the image registry and show when a **newer image** is available (e.g. newer tag or digest). So you *can* get “update available” for a custom app, but the “source of truth” is the **container image** (Docker Hub, ghcr.io, etc.), not a custom “app definition repo.”
- So: **adding your own app via YAML** = you add a custom app whose “update” signal comes from the **image** you specified, not from a catalog repo. You’re not adding a custom catalog; you’re adding one-off YAML that references an image.

### Can you add a *custom* catalog (your own repo) so your app shows in Discover and gets update info from your repo?

- **Built-in UI:** Apps → Settings only lets you enable/disable the **predefined trains** (stable, enterprise, community, test). There is no “Add catalog URL” field in the main 25.04 Apps docs for the Docker-based Apps. So **out of the box**, you don’t “add your own app via YAML that points to a repo” in the sense of “my repo of app definitions drives Discover and updates.”
- **Custom app via YAML** still gives you: (1) an app that shows in **Installed**, (2) optional “update available” if **Check for docker image updates** is on and the image has a newer tag/digest. So you can make **updating** easier by using a well-known image (e.g. `ghcr.io/authelia/authelia:latest`) and relying on that; you don’t get a custom “catalog” in Discover.

**Summary**

- **Easiest way to get “update available”:** Use **catalog apps** (Authelia, PocketID, etc.) from the Community (or other) train. The catalog points to the repo/images; TrueNAS shows updates when the catalog is updated.
- **Your own app:** Use **Install via YAML** with the image you want; enable **Check for docker image updates** so TrueNAS can notify when that image has an update. You’re not adding a custom catalog; you’re adding one app whose updates are tied to the image.

---

## 4. Making Updating Easy (Summary)

| Goal | How |
|------|-----|
| Run Authelia and PocketID, see “Update available” in the UI | Install them from **Discover** (Community train). Updates appear when the catalog publishes a new version. |
| Run something not in the catalog but still get update prompts | Use **Install via YAML** with the container image; turn on **Check for docker image updates** in Apps → Settings. |
| Have your own “catalog” (repo of app definitions) drive Discover and updates | Not exposed in the standard 25.04 Apps UI; catalogs are the predefined trains. Custom catalog support would require checking TrueNAS docs/forums for any advanced or future option. |

---

## 5. Authelia + Nginx Proxy Manager (TrueNAS)

**Context:** Caddy isn’t available as a TrueNAS App; **Nginx Proxy Manager (NPM)** is the usual reverse proxy on TrueNAS. Authelia **officially supports** Nginx Proxy Manager using nginx’s `auth_request` (same idea as Caddy’s `forward_auth`).

### How it works

1. **Two Proxy Hosts in NPM**
   - **Authelia portal:** One Proxy Host for your SSO URL (e.g. `sso.xcvr.link` or `auth.example.com`). Forwards to the Authelia container; SSL and optional “Force SSL” in NPM. In the host’s **Advanced** tab you add a small custom location block that proxies to Authelia (see Authelia’s NPM doc).
   - **Protected app:** For each app you want behind SSO (e.g. Jellyfin at `watch.xcvr.link`), create a Proxy Host that forwards to that app, and in the **Advanced** tab add the **auth_request** logic so nginx asks Authelia “is this user allowed?” before proxying. If not logged in, the user is redirected to the Authelia portal.

2. **Snippets vs inline**
   - Authelia’s [Nginx Proxy Manager guide](https://www.authelia.com/integration/proxies/nginx-proxy-manager/) uses **include** directives to files under `/snippets/` (e.g. `include /snippets/authelia-authrequest.conf;`). Those snippets are from the [Authelia NGINX integration](https://www.authelia.com/integration/proxies/nginx/#supporting-configuration-snippets) (proxy.conf, authelia-location.conf, authelia-authrequest.conf).
   - On TrueNAS, NPM runs as an App; you may not have a way to mount a custom `/snippets/` volume. In that case, paste the **contents** of those snippet files directly into the **Advanced** tab for each host (replace `include /snippets/...;` with the actual directive blocks). Copy from the [Authelia NGINX snippets](https://www.authelia.com/integration/proxies/nginx/#supporting-configuration-snippets) and adapt `authelia` / `9091` to the hostname and port NPM uses to reach Authelia (see below).

3. **Network: NPM reaching Authelia**
   - Both **Nginx Proxy Manager** and **Authelia** run as TrueNAS Apps (containers). They must be able to reach each other. TrueNAS typically puts Apps on a shared Docker network; the Authelia app is usually reachable by its **app name** or **container name** (e.g. `authelia`) and the port you gave it (e.g. `9091`). In the snippets, set `set $upstream_authelia http://authelia:9091/...` (or whatever hostname/port your TrueNAS Apps use). If in doubt, check the Authelia app’s “Workloads” / port in the Apps UI and use that internal hostname.

4. **Trusted proxies**
   - So Authelia sees the real client IP and correct redirect URL, configure [trusted proxies](https://www.authelia.com/integration/proxies/nginx/#trusted-proxies) in the `proxy.conf` snippet (e.g. `set_realip_from` for your NPM / Docker network). If you inline snippets, include that in the block you paste.

5. **Summary**
   - Install **Authelia** and **Nginx Proxy Manager** from the TrueNAS Apps catalog. Create one NPM Proxy Host for the Authelia portal and one per protected app. In each host’s **Advanced** tab, add the Authelia-related nginx config (snippet content inlined if you can’t mount `/snippets/`). Use Authelia’s session cookie domain so one login covers all subdomains (e.g. `xcvr.link`).

### References

- [Authelia – NGINX Proxy Manager](https://www.authelia.com/integration/proxies/nginx-proxy-manager/)
- [Authelia – NGINX (snippets: proxy.conf, authelia-location.conf, authelia-authrequest.conf)](https://www.authelia.com/integration/proxies/nginx/#supporting-configuration-snippets)
- [Authelia – Forwarded Headers / Trusted Proxies](https://www.authelia.com/integration/proxies/forwarded-headers/)

---

## 6. Adding Caddy via Install via YAML — and Why We Moved Away From It

**Context:** You’re already “running Docker” on the NAS—TrueNAS Apps are Docker containers. You *can* add **Authelia** from the catalog and **Caddy** as a **Custom App** (Install via YAML), but **Caddy on this NAS had repeated networking/port issues**; you eventually removed it in favor of **Cloudflare Tunnel direct routes**. See [§6.1 Past Caddy issues on TrueNAS](#61-past-caddy-issues-on-truenas) below.

### 6.1 Past Caddy issues on TrueNAS

When Caddy was run on the NAS (Install via YAML), you hit **TrueNAS-specific constraints**:

1. **Port 80/443 belong to TrueNAS Web UI**  
   By default the TrueNAS UI uses HTTP 80 and HTTPS 443. So Caddy could not bind to 80/443 unless you either:
   - Moved the TrueNAS UI to other ports (e.g. 81/444), or  
   - Ran Caddy on different ports (e.g. 8080/8444) and had Cloudflare Tunnel (or another proxy) forward to those.

2. **Port 8443 already in use**  
   Another service was using 8443, so the “final” Caddy setup used **8080** (HTTP) and **8444** (HTTPS). That meant external access had to go through something (e.g. Cloudflare Tunnel) pointing at 8080/8444, not 80/443.

3. **Outcome**  
   You **removed Caddy** and switched to **Cloudflare Tunnel direct routes** (tunnel → each app’s port directly; no reverse proxy on the NAS). TrueNAS was reverted to port 80. See `docs/archive/caddy/caddy-removal.md` and `docs/networking/cloudflare-tunnel-direct-routes.md`.

**Takeaway:** On this NAS, **Caddy is not the path of least resistance**. Prefer **Nginx Proxy Manager + Authelia** (NPM is a catalog app, no port wrestling with the TrueNAS UI if NPM uses different published ports), or keep **Cloudflare Tunnel direct** and add SSO only where you really need it (e.g. via NPM for a subset of hosts).

### 6.2 If you still want Caddy on the NAS

- **Authelia:** Install from **Apps → Discover** (Community train).
- **Caddy:** Add via **Apps → Discover → ⋮ → Install via YAML**. Use **non-standard ports** (e.g. 8080/8444) so the TrueNAS UI can keep 80/443. Point Cloudflare Tunnel (or your external proxy) at 8080/8444. In the Caddyfile, use `forward_auth` to `http://authelia:9091/...` and reverse proxy to your other Apps by hostname. All Apps share the same Docker network, so Caddy can reach `authelia:9091` and other app hostnames.

### 6.3 One proxy, not two

- If you use **Caddy** (custom app) as the only reverse proxy, you don’t need **Nginx Proxy Manager** for the same hosts.
- If you already use **NPM** or **Cloudflare Tunnel direct**, stick with **NPM + Authelia** (or Tunnel direct + NPM only for SSO-protected hosts); see [§5. Authelia + Nginx Proxy Manager](#5-authelia--nginx-proxy-manager-truenas).
- Given the past Caddy issues, **recommended on this NAS:** **NPM + Authelia**, or **Cloudflare Tunnel direct** with no reverse proxy on the NAS; add Caddy only if you’re willing to manage port conflicts and UI port changes again.

---

## References

- [TrueNAS 25.04 Apps (UI reference)](https://www.truenas.com/docs/scale/25.04/scaleuireference/apps/)
- [TrueNAS Apps Market](https://apps.truenas.com/) (browse catalog)
- [Install Custom App / Install via YAML](https://www.truenas.com/docs/scale/25.04/scaleuireference/apps/installcustomappscreens/)
- **Caddy on this NAS (archive):** [caddy-removal.md](../archive/caddy/caddy-removal.md), [caddy-troubleshooting.md](../archive/caddy/caddy-troubleshooting.md), [truenas-webui-port-change.md](truenas-webui-port-change.md). Current access: [Cloudflare Tunnel direct routes](../networking/cloudflare-tunnel-direct-routes.md) (no Caddy).
