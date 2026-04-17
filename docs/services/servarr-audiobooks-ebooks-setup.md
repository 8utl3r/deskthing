# Audible & Kindle Equivalents: LazyLibrarian

**Date:** 2026-02-08  
**Context:** Your Pi 5 stack has Sonarr, Radarr, Lidarr, Jellyfin. LazyLibrarian provides:
- **Audible equivalent** → Audiobooks (listen.xcvr.link)
- **Kindle equivalent** → Ebooks (read.xcvr.link)

---

## Quick setup

From Mac:

```bash
./scripts/servarr-pi5-lazylibrarian-setup.sh
```

Then run the migration to remove Readarr (if you had it):

```bash
./scripts/servarr-pi5-readarr-to-lazylibrarian-migration.sh
```

---

## What LazyLibrarian does

- Handles **ebooks** (epub, mobi, pdf) → `/mnt/data/media/books` → Jellyfin Books on read.xcvr.link
- Handles **audiobooks** (mp3, m4b) → `/mnt/data/media/audiobooks` → Jellyfin Audiobooks on listen.xcvr.link
- Integrates with Prowlarr (Newznab), qBittorrent, Sabnzbd, rdt-client
- Triggers jellyfin-autoscan on download via custom notification script

---

## After deploy: LazyLibrarian UI config

Open http://pi5.xcvr.link:5299 and configure:

1. **Config → Ebook:** Ebook folder = `/books`, formats = epub,mobi,pdf
2. **Config → Audio:** Audio folder = `/audiobooks`, formats = mp3,m4b
3. **Config → Magazines:** Disable unless needed
4. **Config → Newznab:** Add Prowlarr — URL `http://192.168.0.136:9696/1/api` (or each indexer from Prowlarr Indexers → copy URL), API key from Prowlarr Settings → General
5. **Config → Torrent:** Add qBittorrent (host, port 8080, admin/pass, category `lazylibrarian`)
6. **Config → Torrent:** Add rdt-client (host 127.0.0.1, port 6500, category `lazylibrarian`)
7. **Config → Sabnzbd:** Add Sabnzbd (host, port 8085, category `lazylibrarian`)
8. **Config → Notifications:** Enable Custom, Notify on Download, script = `/config/jellyfin-autoscan-notify.sh`

---

## Sabnzbd / rdt-client categories

- **Sabnzbd:** Add category `lazylibrarian` → `/downloads/complete/lazylibrarian`
- **rdt-client:** Category `lazylibrarian` is added by the setup script

---

## Jellyfin libraries

Ensure Jellyfin has:

- **Books** → `/media/books` (epub, PDF, mobi)
- **Audiobooks** → `/media/audiobooks` (mp3, m4b)

Add in Dashboard → Libraries if missing. Both appear on read.xcvr.link and listen.xcvr.link per your subdomain config.

**Detailed walkthrough:** [`servarr-lazylibrarian-setup-walkthrough.md`](servarr-lazylibrarian-setup-walkthrough.md)
