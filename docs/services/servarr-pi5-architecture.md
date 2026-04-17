# Servarr Pi 5: System Architecture (Visual)

**Domain:** xcvr.link (listen / watch / read)  
**Hardware:** Pi 5 8GB, Samsung 990 EVO Plus 1TB NVMe

---

## 0. Completion Status (as of 2026-02-02)

| Component | Status | Notes |
|-----------|--------|-------|
| **Prowlarr** | ✅ Running | Port 9696 |
| **Sonarr** | ✅ Running | Port 8989 |
| **Radarr** | ✅ Running | Port 7878 |
| **Lidarr** | ✅ Running | Port 8686 |
| **LazyLibrarian** | ✅ Running | Port 5299 |
| **Bazarr** | ✅ Running | Port 6767 |
| **Jackett** | ✅ Running | Port 9117 |
| **FlareSolverr** | ✅ Running | Port 8191 |
| **qBittorrent** | ✅ Running | Port 8080 |
| **Jellyfin** | ✅ Running | Docker 10.10.7 on port 8096 |
| **Caddy** | ❌ Not installed | Reverse proxy for listen/watch/read.xcvr.link |
| **Gelato** | ⏳ Pending | Jellyfin plugin for on-demand |
| **Gluetun** | ⏳ Pending | VPN for qBittorrent (optional) |
| **AIOStreams** | ⏳ Pending | Torrentio/Comet for Gelato |

```mermaid
flowchart TB
    subgraph Done["✅ Completed"]
        Prowlarr["Prowlarr"]
        Sonarr["Sonarr"]
        Radarr["Radarr"]
        Lidarr["Lidarr"]
        LazyLibrarian["LazyLibrarian"]
        Bazarr["Bazarr"]
        Jackett["Jackett"]
        FlareSolverr["FlareSolverr"]
        QB["qBittorrent"]
        Jellyfin["Jellyfin (Docker 10.10.7)"]
    end

    subgraph Todo["❌ Not done"]
        Caddy["Caddy"]
    end

    subgraph Later["⏳ Later"]
        Gelato["Gelato"]
        Gluetun["Gluetun"]
        AIO["AIOStreams"]
    end
```

---

## 1. High-level: What runs where

```mermaid
flowchart TB
    subgraph Internet["Internet"]
        User["You / devices"]
        RD["Real-Debrid"]
        Mullvad["Mullvad VPN"]
        Indexers["Torrent indexers"]
    end

    subgraph DNS["DNS: xcvr.link"]
        Listen["listen.xcvr.link"]
        Watch["watch.xcvr.link"]
        Read["read.xcvr.link"]
    end

    subgraph Pi["Raspberry Pi 5"]
        Caddy["Caddy\n(reverse proxy + TLS)"]
        Jellyfin["Jellyfin\n(media server)"]
        Gelato["Gelato plugin\n(on-demand)"]
        Prowlarr["Prowlarr\n(indexer manager)"]
        Sonarr["Sonarr"]
        Radarr["Radarr"]
        Lidarr["Lidarr"]
        LazyLibrarian["LazyLibrarian"]
        Bazarr["Bazarr"]
        FlareSolverr["FlareSolverr"]
        Gluetun["Gluetun\n(VPN container)"]
        QB["qBittorrent"]
        AIO["AIOStreams\n(Torrentio/Comet)"]
        Storage["/mnt/data\n(torrents + media)"]
    end

    User -->|HTTPS| Listen
    User -->|HTTPS| Watch
    User -->|HTTPS| Read
    Listen --> Caddy
    Watch --> Caddy
    Read --> Caddy
    Caddy --> Jellyfin
    Jellyfin --> Gelato
    Gelato --> AIO
    AIO -->|debrid API| RD

    Prowlarr --> Sonarr
    Prowlarr --> Radarr
    Prowlarr --> Lidarr
    LazyLibrarian -->|Newznab| Prowlarr
    Prowlarr -->|indexers| Indexers
    Sonarr --> QB
    Radarr --> QB
    Lidarr --> QB
    LazyLibrarian --> QB
    QB --> Gluetun
    Gluetun -->|all torrent traffic| Mullvad

    Sonarr --> Storage
    Radarr --> Storage
    Lidarr --> Storage
    LazyLibrarian --> Storage
    QB --> Storage
    Jellyfin --> Storage
```

---

## 2. Remote access paths

```mermaid
flowchart LR
    subgraph Public["Public (xcvr.link)"]
        L["listen.xcvr.link"]
        W["watch.xcvr.link"]
        R["read.xcvr.link"]
    end

    subgraph Pi["Pi 5"]
        Caddy["Caddy :443"]
        Jellyfin["Jellyfin :8096"]
    end

    subgraph Private["Private (Tailscale optional)"]
        TS["Tailscale"]
        Arr["*arr UIs\nSonarr, Radarr, etc."]
    end

    L --> Caddy
    W --> Caddy
    R --> Caddy
    Caddy --> Jellyfin
    TS --> Arr
    TS --> Jellyfin
```

- **Public:** listen / watch / read → Caddy → Jellyfin (Let’s Encrypt).
- **Private:** Tailscale (optional) for *arr admin and Jellyfin without exposing ports.

---

## 3. Download → library flow (permanent media)

```mermaid
flowchart LR
    subgraph Add["You add content"]
        Sonarr["Sonarr\n(TV)"]
        Radarr["Radarr\n(Movies)"]
        Lidarr["Lidarr\n(Music)"]
        LazyLibrarian["LazyLibrarian\n(Books/Audiobooks)"]
    end

    Prowlarr["Prowlarr\n(indexers)"]
    QB["qBittorrent"]
    Gluetun["Gluetun → Mullvad"]
    Torrents["/mnt/data/torrents/"]
    Media["/mnt/data/media/"]
    Jellyfin["Jellyfin\n(libraries)"]

    Sonarr --> Prowlarr
    Radarr --> Prowlarr
    Lidarr --> Prowlarr
    LazyLibrarian --> Prowlarr
    Prowlarr -->|send to| QB
    QB --> Gluetun
    QB -->|writes| Torrents
    Sonarr -->|hardlink/move| Media
    Radarr -->|hardlink/move| Media
    Lidarr -->|hardlink/move| Media
    LazyLibrarian -->|hardlink/move| Media
    Media --> Jellyfin
```

Same filesystem (`/mnt/data`) so *arr can hardlink from `torrents/` to `media/` (no copy). Jellyfin scans `media/`.

---

## 4. On-demand flow (Gelato + AIOStreams)

```mermaid
flowchart LR
    User["You pick a title\nin Jellyfin"]
    Jellyfin["Jellyfin"]
    Gelato["Gelato plugin"]
    AIO["AIOStreams"]
    Torrentio["Torrentio / Comet"]
    RD["Real-Debrid"]
    Stream["Stream to device"]

    User --> Jellyfin
    Jellyfin --> Gelato
    Gelato -->|manifest URL| AIO
    AIO --> Torrentio
    Torrentio -->|check cache / fetch| RD
    RD --> Stream
    Stream --> User
```

No download to disk; stream via Real-Debrid. Gelato libraries (e.g. `/tmp/gelato/movies`, `series`) are populated by the plugin from AIOStreams.

---

## 5. Component summary

| Component | Role | Talks to |
|-----------|------|----------|
| **Caddy** | Reverse proxy, TLS (listen/watch/read.xcvr.link) | Jellyfin :8096 |
| **Jellyfin** | Media server, users, libraries | Storage, Gelato |
| **Gelato** | Jellyfin plugin: on-demand sources | AIOStreams (manifest URL) |
| **AIOStreams** | Aggregates Torrentio/Comet addons | Real-Debrid |
| **Prowlarr** | Indexer manager | Sonarr, Radarr, Lidarr, indexers; LazyLibrarian adds Prowlarr as Newznab |
| **Sonarr / Radarr / Lidarr / LazyLibrarian** | Automate TV / movies / music / books & audiobooks | Prowlarr, qBittorrent, storage |
| **Bazarr** | Subtitles | Sonarr, Radarr |
| **FlareSolverr** | Bypass Cloudflare on indexers | Prowlarr / indexers |
| **qBittorrent** | Torrent client | Gluetun (network), storage |
| **Gluetun** | VPN (Mullvad); only qBittorrent uses it | Mullvad, qBittorrent |
| **Storage** | `/mnt/data` (torrents + media) | All *arr, qBittorrent, Jellyfin |

---

## 6. SSO options for exposed subdomains (xcvr.link)

Right now **listen**, **watch**, and **read** all hit the **same** Jellyfin instance, so one Jellyfin login covers all three. If you add more apps (e.g. Calibre-Web, FreshRSS) or expose *arr UIs and want **one login for everything**, see the **feature matrix:** **`sso-feature-matrix.md`** (same folder) — what self-hosters use, full comparison table, and Pi 5 recommendation. Short summary:

| Option | What it does | Pros | Cons |
|--------|----------------|------|------|
| **No SSO (current)** | Each app has its own login. Jellyfin = one login for listen/watch/read. | Simple, nothing extra to run. | Separate logins per app if you expose more. |
| **Authelia + Caddy forward_auth** | One login at e.g. **sso.xcvr.link**. Caddy sends unauthenticated requests to Authelia; after login, session cookie grants access to all protected subdomains. | Lightweight (~30 MB RAM), 2FA, file or LDAP users, works well on Pi. Official Caddy integration. | You run and configure Authelia (Docker). Jellyfin has its own users—use Authelia in front and optionally **Jellyfin SSO plugin** with Authelia as OIDC so one Authelia account = Jellyfin login. |
| **Authentik** | Full IdP (OIDC/OAuth2, SAML). Jellyfin SSO plugin can use Authentik. | Rich features, nice UI, one place for all app logins. | Heavier than Authelia; may be tight on Pi 5 with full stack. |
| **oauth2-proxy + Caddy** | Caddy forward_auth to oauth2-proxy; login with Google/GitHub or any OIDC provider. | Simple “login with Google” in front of everything. | No built-in user DB; depends on external IdP. Less control than self-hosted Authelia/Authentik. |
| **Tailscale (no public login)** | Don’t expose Jellyfin/*arr on the internet; use Tailscale to reach them. | No public login page; Tailscale identity is your “SSO.” | Services only reachable when on Tailscale; not true SSO for random subdomains. |

**Recommended for Pi 5:** **Authelia** behind Caddy (forward_auth). Put Authelia at e.g. **sso.xcvr.link**; protect listen/watch/read (and any other apps) with Caddy’s `forward_auth` to Authelia. For Jellyfin specifically, either (a) rely on Authelia in front (login to Authelia, then Caddy passes you to Jellyfin—Jellyfin can be set to trust the proxy and use Authelia’s `Remote-User` header if supported), or (b) use the **Jellyfin SSO plugin** with Authelia as OIDC so Jellyfin login is “Sign in with Authelia.”
