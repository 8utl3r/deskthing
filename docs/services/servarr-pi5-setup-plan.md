# Raspberry Pi 5 Servarr + Jellyfin Setup Plan

**Date:** 2026-01-31  
**Hardware:** Pi 5 8GB, Samsung 990 EVO Plus 1TB NVMe (M.2 2280, no heatsink)  
**Goal:** Full Servarr stack, Jellyfin (library + on-demand via Gelato/AIOStreams), multiple accounts, remote access via your DNS.

**Before the drive arrives:** See **`servarr-pi5-prep-before-drive.md`** for downloads, accounts, and optional Pi prep. Use **`scripts/servarr-pi5-day-one-commands.md`** and **`scripts/servarr-pi5-create-data-dirs.sh`** on first boot.

---

## 1. Overview

| Layer | Components |
|-------|------------|
| **Boot** | Raspberry Pi OS 64-bit (Lite) on NVMe |
| **Automation** | Prowlarr, Sonarr, Radarr, Lidarr, LazyLibrarian, Bazarr, qBittorrent, FlareSolverr |
| **Media server** | Jellyfin (local library + Gelato on-demand) |
| **On-demand** | Gelato plugin + AIOStreams (Torrentio/Comet + Real-Debrid) |
| **VPN** | Gluetun (torrent traffic only) |
| **Remote** | Reverse proxy (Caddy) + your DNS + Let's Encrypt |

**Domain:** **xcvr.link** — subdomains **listen.xcvr.link**, **watch.xcvr.link**, **read.xcvr.link** (see Phase 6 and table below).

**Completion status:** See **`servarr-pi5-architecture.md`** §0 for current status. As of 2026-02-02: Phase 3 done (*arr, qBittorrent, FlareSolverr); Phase 4 (Jellyfin) and Phase 6 (Caddy) pending.

**Multiple accounts (where they matter):**
- **Jellyfin:** Create one user per person; restrict library access and remote access per user in Dashboard → Users.
- **Servarr (*arr):** Single instance per app; no built-in multi-tenant. One Radarr/Sonarr/etc. serves all Jellyfin libraries.
- **Real-Debrid:** One account shared by AIOStreams (and optionally *arr); you already have this.
- **Mullvad + Gluetun:** One Mullvad account; Gluetun routes **only qBittorrent** (and optionally AIOStreams) through Mullvad so your home IP is not exposed to torrent peers. **Gluetun** = Docker container that runs Mullvad (or other VPN); qBittorrent runs through it. **Tailscale** = separate mesh VPN for *accessing* your Pi; it does not route torrent traffic. You can use **both** Tailscale (access) and Gluetun + Mullvad (torrent privacy).
- **Tailscale:** Optional; for secure remote access to Jellyfin and *arr UIs without exposing them on the public internet.
- **DNS:** xcvr.link; subdomains listen / watch / read (see table below).

**Subdomains (listen / watch / read)** — all proxy to the same Jellyfin instance:

| Subdomain | Purpose | Jellyfin libraries / content |
|-----------|---------|------------------------------|
| **listen.xcvr.link** | Audio | Music, Podcasts, Audiobooks (Lidarr, LazyLibrarian audiobooks). |
| **watch.xcvr.link** | Video | Movies, TV Shows, Gelato on-demand, scraped videos, news. |
| **read.xcvr.link** | Reading | Books (LazyLibrarian ebooks), PDFs. For articles/news/journal excerpts, add a reader (Wallabag, FreshRSS, Calibre-Web) later or use Jellyfin Books for ebooks only. |

Caddyfile example: **`scripts/servarr-pi5-caddyfile.example`**.  
**Visual breakdown:** **`servarr-pi5-architecture.md`** — diagrams of components and how they interact.

---

## 2. Phase 1: Pi 5 + NVMe Boot

**References:** [TRaSH](https://trash-guides.info/), [Pi NVMe boot](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#nvme-ssd-boot), [Jeff Geerling](https://jeffgeerling.com/blog/2023/nvme-ssd-boot-raspberry-pi-5).

1. **Imaging**
   - Use Raspberry Pi Imager; create **SD card** with Raspberry Pi OS **Lite (64-bit)**.
   - Enable SSH, set hostname (e.g. `servarr`), set user/password or SSH key.
   - Optionally set Wi-Fi so Pi is reachable without Ethernet first.

2. **First boot (from SD)**
   - Boot from SD, SSH in.
   - Update: `sudo apt update && sudo apt full-upgrade -y`
   - Update EEPROM: `sudo rpi-update` (if needed for your board).
   - Install rpi-imager: `sudo apt install -y rpi-imager`

3. **Write OS to NVMe**
   - Download same OS image (e.g. Raspberry Pi OS Lite 64-bit) or use rpi-imager to write to NVMe.
   - Example (writing to NVMe): use rpi-imager CLI or GUI; target device = `/dev/nvme0n1` (verify with `lsblk`).
   - **Do not** remove SD until boot order is set.

4. **Boot order**
   - `sudo raspi-config` → Advanced Options → Boot → Boot Order → **NVMe/USB Boot** (or equivalent).
   - Alternatively EEPROM: `sudo rpi-eeprom-config --edit` → `BOOT_ORDER=0xf416`, `PCIE_PROBE=1`.
   - Shut down, remove SD, power on; Pi should boot from Samsung 990 EVO Plus.

5. **Post-NVMe boot**
   - Expand filesystem if needed: `sudo raspi-config` → Advanced → Expand Filesystem.
   - Set static IP (recommended) or reserve DHCP on router.
   - Optional: enable PCIe in `/boot/firmware/config.txt` if not auto (e.g. `dtparam=pciex1`).

---

## 3. Phase 2: Storage and Folder Structure (TRaSH)

**Rule:** All *arr apps + qBittorrent + Jellyfin must see the **same** filesystem for hardlinks (no copy, instant move).

**On 1TB NVMe:** OS + app data + media. Suggested layout:

```
/mnt/data/                    # or /data – single mount for media + downloads
├── torrents/
│   ├── movies/
│   ├── tv/
│   ├── music/
│   ├── books/
│   └── audiobooks/
└── media/
    ├── movies/
    ├── tv/
    ├── music/
    ├── books/
    └── audiobooks/
```

Create once, then use **same path inside containers** (e.g. `/data`) for every *arr and qBittorrent. Jellyfin libraries point at `/data/media/*`. Gelato uses its own dirs (e.g. `/tmp/gelato/movies`, `/tmp/gelato/series`) – no hardlink requirement there.

If you add a **USB HDD** later for media, put `media/` and `torrents/` on that drive and mount it (e.g. `/mnt/data`) so everything still shares one filesystem.

---

## 4. Phase 3: Servarr Stack (PiJARR vs Docker)

**Recommendation:** **PiJARR** for stability and lower RAM use on Pi 5; **Docker** if you prefer portability and Gluetun integration.

**Option A – PiJARR (native)**  
- One script: Jackett, Sonarr, Radarr, Lidarr, LazyLibrarian, Prowlarr, Bazarr, FlareSolverr, qBittorrent-nox.  
- Install: `sudo sh -c "$(wget -qO- https://raw.githubusercontent.com/pijarr/pijarr/main/setup.sh)"` → Install ALL.  
- Configure download root and media root to match `/mnt/data` (or your chosen path).  
- **VPN:** Run qBittorrent behind a VPN at router level, or use a separate Gluetun+qBittorrent Docker stack just for torrents.

**Option B – Docker (full stack)**  
- Use a single `docker-compose.yml` with shared `/mnt/data` → `/data`.  
- Run **Gluetun** + qBittorrent: qBittorrent `network_mode: service:gluetun` so only torrents go through VPN.  
- Sonarr/Radarr/Lidarr/Prowlarr/Bazarr/Jellyfin use normal network; LazyLibrarian in Docker.  
- Follow TRaSH Docker guide for exact volume mounts and user/group (e.g. `PUID`/`PGID`).

**Order of config:** Prowlarr first (indexers) → add Prowlarr to Sonarr, Radarr, Lidarr → add qBittorrent as download client in each → set root folders and quality profiles per TRaSH. LazyLibrarian: deploy separately, add Prowlarr as Newznab, add qBittorrent/Sabnzbd.

---

## 5. Phase 4: Jellyfin + Hardware Acceleration

- **Install:** Docker (linuxserver/jellyfin) or native package; ensure Jellyfin can read `/data/media` (and later Gelato dirs).
- **Pi 5 acceleration:** Pi 5 lacks hardware encoders; Jellyfin deprecated V4L2 for Raspberry Pi. Transcoding uses CPU. Prefer **Direct Play** where possible. Use bundled **jellyfin-ffmpeg** (do not replace with system FFmpeg).
- **Libraries (for listen / watch / read):** Add libraries pointing at `/data/media/*`: **Watch** — Movies, TV Shows, optional “Videos” or “News”; **Listen** — Music, Podcasts, Audiobooks; **Read** — Books (epubs, PDFs from LazyLibrarian). For articles/news/journal excerpts, Jellyfin is not ideal; add a reader app (Wallabag, FreshRSS, Calibre-Web) later or use Jellyfin Books for ebooks only.
- **Multiple accounts:** Dashboard → Users → add users; per-user library access and permissions (disable “access to all libraries” to restrict). Set remote access policy per user if needed.

---

## 6. Phase 5: On-Demand (Gelato + AIOStreams)

- **Gelato (Jellyfin plugin):** Add repo `https://raw.githubusercontent.com/lostb1t/Gelato/refs/heads/gh-pages/repository.json`, install Gelato, restart Jellyfin.
- **AIOStreams:** Run in Docker; configure Torrentio and/or Comet + Real-Debrid (or similar) in `.env`; get manifest URL from AIOStreams UI.
- **Gelato config:** In Gelato settings, set “Stremio URL (manifest or base)” to that AIOStreams manifest URL.
- **Gelato libraries:** Add Jellyfin libraries for Movies and Shows pointing at Gelato’s paths (e.g. `/tmp/gelato/movies`, `/tmp/gelato/series` – exact paths depend on Gelato/AIOStreams deployment). Scan libraries.
- **Accounts:** One Real-Debrid (or similar) account; optionally one VPN for AIOStreams if you self-host Torrentio/Comet and hit IP blocks.

---

## 7. Phase 6: Remote Access (xcvr.link)

**Domain:** **xcvr.link**. Subdomains: **listen.xcvr.link**, **watch.xcvr.link**, **read.xcvr.link** (all to Jellyfin; optional deep-links per subdomain).

1. **Router:** Port forward **443** (HTTPS) to Pi’s LAN IP. Optionally 80 → Pi for HTTP→HTTPS redirect.
2. **DNS:** Point **listen.xcvr.link**, **watch.xcvr.link**, **read.xcvr.link** (and any other subdomains) to your home IP. If IP is dynamic, use DDNS (ddclient or router DDNS) to update the A record for xcvr.link or `*.xcvr.link`.
3. **Reverse proxy:** Install **Caddy** on the Pi. Use **`scripts/servarr-pi5-caddyfile.example`** as a template: each subdomain reverse-proxies to Jellyfin (`localhost:8096`). Caddy obtains and renews Let’s Encrypt certs automatically.
4. **Expose only what you need:** Jellyfin via listen/watch/read; do **not** expose *arr UIs or qBittorrent publicly unless you add auth. Prefer **Tailscale** for *arr admin from your devices.
5. **Jellyfin:** Dashboard → Networking: allow remote connections; Base URL left empty (subdomains handle routing). Test from outside LAN.

---

## 8. Phase 7: Security and Accounts Checklist

- **Firewall (ufw):** Allow SSH (22), HTTP (80), HTTPS (443), and any local ports (e.g. 8096 Jellyfin) from LAN only; default deny.
- **VPN (Gluetun):** Only qBittorrent (and optionally AIOStreams) through VPN; rest of stack direct.
- **Passwords:** Strong passwords for Jellyfin admin, *arr UIs, qBittorrent; SSH key-based where possible.
- **Accounts list:** Jellyfin users (multiple); Real-Debrid (done); Mullvad for Gluetun; xcvr.link DNS/DDNS; optional: Tailscale, Trakt, Notifiarr.

---

## 9. Suggested Order of Execution

1. Pi 5 + NVMe boot (Phase 1).  
2. Create `/mnt/data` layout and mount (Phase 2).  
3. Install Servarr stack (PiJARR or Docker) and Gluetun+qBittorrent; configure Prowlarr → *arrs → qBittorrent (Phase 3).  
4. Install Jellyfin; add libraries for `/data/media`; enable V4L2; add users (Phases 4 & 7).  
5. Deploy AIOStreams; install and configure Gelato; add Gelato libraries (Phase 5).  
6. Point DNS to home IP; install Caddy; forward 443; expose Jellyfin (Phase 6).  
7. Harden firewall and review access (Phase 7).

---

## 10. Architecture diagram

See **`servarr-pi5-architecture.md`** for Mermaid diagrams: high-level components, remote access paths, download→library flow, and on-demand (Gelato) flow.

---

## 11. References

- TRaSH Guides: https://trash-guides.info/  
- PiJARR: https://pijarr.github.io/pijarr/  
- Gelato: https://github.com/lostb1t/Gelato  
- AIOStreams: https://github.com/Viren070/AIOStreams (wiki: Deployment, CONFIGURING.md)  
- Jellyfin hardware acceleration: https://jellyfin.org/docs/general/administration/hardware-acceleration  
- Caddy reverse proxy: https://caddyserver.com/docs/quick-starts/reverse-proxy  
- Gluetun + qBittorrent: e.g. qmcgaw/gluetun, blog posts by Alex The IT Guy / Tate Walker
