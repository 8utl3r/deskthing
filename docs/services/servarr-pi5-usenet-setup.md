# Servarr Pi 5: Usenet (Sabnzbd + NewsgroupDirect)

**Date:** 2026-02-02  
**Provider:** NewsgroupDirect (yearly $75)

---

## NewsgroupDirect Server Details

| Setting | Value |
|---------|-------|
| **Server (US)** | news.newsgroupdirect.com |
| **Server (EU)** | eu-tst.newsgroupdirect.com |
| **SSL ports** | 563, 80, 81 |
| **Standard ports** | 119, 23, 3128, 7000, 8000, 9000 |

**Use:** Host `news.newsgroupdirect.com`, port **563**, SSL enabled. Get username/password from your NewsgroupDirect account (login-form → account).

---

## Deploy Sabnzbd

Run from Mac:

```bash
./scripts/servarr-pi5-sabnzbd-setup.sh
```

Or manually on Pi:

```bash
sudo docker run -d \
  --name sabnzbd \
  -p 8085:8080 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/Chicago \
  -v /mnt/data/downloads/sabnzbd/config:/config \
  -v /mnt/data/downloads/sabnzbd:/downloads \
  --restart unless-stopped \
  lscr.io/linuxserver/sabnzbd:latest
```

**Note:** Host port 8085 (qBittorrent uses 8080). Sabnzbd UI: http://pi5.xcvr.link:8085

---

## Configure Sabnzbd (first run)

1. Open http://pi5.xcvr.link:8085
2. Complete setup wizard (language, folder paths)
3. **Config → Servers → Add server:**
   - **Server:** news.newsgroupdirect.com
   - **Port:** 563
   - **SSL:** Yes
   - **Username:** (from NewsgroupDirect)
   - **Password:** (from NewsgroupDirect)
   - **Connections:** 50–100 (NewsgroupDirect allows 100)
4. **Config → Folders:**
   - **Download folder:** /downloads/incomplete
   - **Complete folder:** /downloads/complete
5. **Config → Categories:** Add `radarr`, `sonarr`, `lidarr`, `lazylibrarian` with paths:
   - radarr → /downloads/complete/radarr
   - sonarr → /downloads/complete/sonarr
   - lidarr → /downloads/complete/lidarr
   - lazylibrarian → /downloads/complete/lazylibrarian
6. **Config → General → API:** API key and NZB key stored in `scripts/servarr/.env`

**NZB key:** Used when indexers (e.g. NZBGeek) send NZB URLs to Sabnzbd. Some indexers let you set a "Sabnzbd URL" with the NZB key for authenticated fetch.

---

## Add Sabnzbd to *arr Apps (automated)

In Radarr (repeat for Sonarr, Lidarr):

1. Settings → Download Clients → Add → **Sabnzbd**
2. Name: `Sabnzbd`
3. Host: `127.0.0.1`
4. Port: `8085`
5. API key: (from Sabnzbd Config → General)
6. Category: `radarr` (use sonarr/lidarr per app). LazyLibrarian uses `lazylibrarian` in its own config.
7. Test → Save

---

## Usenet Indexers (Prowlarr)

### Quick start: NZBGeek + NZBPlanet (recommended)

1. **Sign up** at [nzbgeek.info](https://nzbgeek.info) and [nzbplanet.net](https://nzbplanet.net)
2. **Get API keys** from each: Profile → API (or Security)
3. **Add to** `scripts/servarr/.env`:
   ```
   NZBGEEK_API_KEY=your_nzbgeek_key
   NZBPLANET_API_KEY=your_nzbplanet_key
   ```
4. **Run:**
   ```bash
   ./scripts/servarr-pi5-sync-and-usenet-indexers.sh
   ```

The script adds both indexers to Prowlarr and syncs them to Sonarr, Radarr, Lidarr.

---

**Other indexers:** Set `DRUNKENSLUG_API_KEY`, `NINJACENTRAL_API_KEY` in `.env` if desired.

**Manual:** Prowlarr → Indexers → Add Indexer:

| Indexer | API key from |
|---------|--------------|
| NZBGeek | nzbgeek.info → Profile |
| NZBPlanet | nzbplanet.net → Profile |
| DrunkenSlug | Profile (invite or open reg) |
| NinjaCentral | ninjacentral.co.za → Profile |

---

## Paths

| Path (in container) | Host path |
|--------------------|-----------|
| /downloads/incomplete | /mnt/data/downloads/sabnzbd/incomplete |
| /downloads/complete | /mnt/data/downloads/sabnzbd/complete |

*arr apps import from category subfolders into /mnt/data/media/{movies,tv,music}. LazyLibrarian imports to books/ and audiobooks/.

## Remote path mapping (required for Sabnzbd in Docker)

Sabnzbd reports paths as `/downloads/...` (container path). Sonarr/Radarr run natively and see `/mnt/data/downloads/sabnzbd/...`. Add in each app:

**Settings → Download Clients → Remote Path Mappings:**
- Host: `127.0.0.1` (matches Sabnzbd download client)
- Remote Path: `/downloads/`
- Local Path: `/mnt/data/downloads/sabnzbd/`

Or via API (Sonarr): `curl -X POST .../api/v3/remotepathmapping -d '{"host":"127.0.0.1","remotePath":"/downloads/","localPath":"/mnt/data/downloads/sabnzbd/"}'`

## Permissions

Sonarr/Radarr need read access to completed downloads. Add them to group `pi`: `sudo usermod -aG pi sonarr radarr` then restart services.
