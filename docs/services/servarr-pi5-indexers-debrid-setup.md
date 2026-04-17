# Servarr Pi 5: Backup Indexers + Debrid Setup

**Date:** 2026-02-02  
**Prerequisites:** Prowlarr, *arr apps, qBittorrent running. NewsgroupDirect (Usenet) and debrid account.

---

## Part 1: Backup Indexers

### Torrent indexers (Prowlarr)

Add in **Prowlarr** → Indexers → Add Indexer. For Cloudflare-protected sites, assign **FlareSolverr** as proxy.

| Indexer | Type | FlareSolverr | Notes |
|---------|------|--------------|-------|
| 1337x | Torrent | Yes | Add manually; often blocked during auto-add |
| EZTV | Torrent | Check | TV-focused |
| TorrentGalaxy | Torrent | Yes | General |
| LimeTorrents | Torrent | Yes | General |
| YTS | Torrent | No | Movies (often lower quality) |

**Steps:**
1. Open http://pi5.xcvr.link:9696
2. Indexers → Add Indexer
3. Search for each, add, assign FlareSolverr if prompted
4. Settings → Apps → **Sync App Indexers** (pushes to Sonarr/Radarr/Lidarr). LazyLibrarian adds Prowlarr as Newznab in its own config.

### Usenet indexers (Prowlarr)

Add in Prowlarr → Indexers → Add Indexer. Requires API key from each site.

| Indexer | Cost | Signup | API key |
|---------|------|--------|---------|
| **NZBGeek** | ~$6/year | nzbgeek.info | Profile → API Key |
| **NZBPlanet** | Free tier | nzbplanet.net | Profile → API |
| **DrunkenSlug** | Free tier | Invite or open reg | Profile → API |
| **NinjaCentral** | Free | ninjacentral.co.za | Profile → API |

**Steps:**
1. Sign up at each indexer, get API key from profile
2. Prowlarr → Indexers → Add Indexer → search for name
3. Paste API key, save
4. Settings → Apps → Sync App Indexers

---

## Part 2: Debrid Connection (rdt-client)

**rdt-client** sends torrents to Real-Debrid, AllDebrid, or Premiumize, downloads the files, and exposes a fake qBittorrent API so Sonarr/Radarr/Lidarr can use it as a download client. LazyLibrarian also adds rdt-client in its config.

### Get API key

- **Real-Debrid:** https://real-debrid.com/apitoken
- **AllDebrid:** https://alldebrid.com/apikey
- **Premiumize:** https://www.premiumize.me/account

### Deploy rdt-client on Pi

**Option A: Run via SSH**

```bash
ssh pi@192.168.0.136

# Create dirs
sudo mkdir -p /mnt/data/downloads/rdt-client
sudo chown -R pi:pi /mnt/data/downloads/rdt-client

# Run (replace YOUR_RD_API_KEY with your Real-Debrid API key)
sudo docker run -d \
  --name rdt-client \
  -p 6500:6500 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/Chicago \
  -v /mnt/data/downloads/rdt-client/db:/data/db \
  -v /mnt/data/downloads/rdt-client:/data/downloads \
  --restart unless-stopped \
  rogerfar/rdtclient
```

**Option B: Use setup script** (if created)

```bash
./scripts/servarr-pi5-rdt-client-setup.sh
```

### Configure rdt-client (first run)

1. Open http://pi5.xcvr.link:6500
2. **Settings → Provider:** Choose RealDebrid (or AllDebrid/Premiumize), paste API key
3. **Settings → Download Client:** Choose "Download all files to host"
4. **Settings → General → Categories:** Add `radarr`, `sonarr`, `lidarr`, `lazylibrarian` (one per line)
5. **Settings → qBittorrent / *darr:** Enable "Allow external access", note the API key shown
6. Save

### Add rdt-client to *arr apps

In **Radarr** (repeat for Sonarr, Lidarr):

1. Settings → Download Clients → Add → **qBittorrent**
2. Name: `rdt-client`
3. Host: `127.0.0.1` (or `localhost`)
4. Port: `6500`
5. Username: leave blank (or as configured)
6. Password: leave blank (or as configured)
7. Category: `radarr` (use `sonarr` for Sonarr, `lidarr` for Lidarr). LazyLibrarian uses `lazylibrarian` in its config.
8. Test → Save

**Priority:** Set rdt-client higher than qBittorrent if you want debrid preferred; or lower if you prefer torrents first.

---

## Part 3: Download path alignment

| Client | Download path | Category subfolders |
|--------|---------------|---------------------|
| qBittorrent | /mnt/data/torrents | (as configured) |
| rdt-client | /mnt/data/downloads/rdt-client | radarr/, sonarr/, lidarr/, lazylibrarian/ |

The *arr apps import from these paths into `/mnt/data/media/{movies,tv,music,books}`. jellyfin-autoscan will trigger a Jellyfin scan when imports complete.

---

## Checklist

- [ ] Add torrent indexers in Prowlarr (1337x, EZTV, TorrentGalaxy, etc.)
- [ ] Add Usenet indexers in Prowlarr (NZBGeek, NZBPlanet, etc.)
- [ ] Prowlarr → Sync App Indexers
- [ ] Deploy rdt-client on Pi
- [ ] Configure rdt-client (API key, categories)
- [ ] Add rdt-client as download client in Radarr, Sonarr, Lidarr (LazyLibrarian adds it in its UI)
- [ ] Test: add a movie in Radarr, confirm it can grab via debrid
