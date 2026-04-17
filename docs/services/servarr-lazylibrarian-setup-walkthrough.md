# LazyLibrarian Setup Walkthrough

Step-by-step config in the LazyLibrarian UI (http://pi5.xcvr.link:5299).

**API automation:** Run `./scripts/servarr-pi5-lazylibrarian-config-automate.sh` to configure most settings via API (requires `LAZYLIBRARIAN_API_KEY`, `SABNZBD_API_KEY` in `scripts/servarr/.env`).

---

## 1. First run / wizard

If you see a setup wizard, complete it (language, etc.). Skip any path prompts—we'll set those in Config.

---

## 2. Config → Ebook

| Setting | Value |
|---------|-------|
| **Ebook folder** | `/books` |
| **Ebook formats** | `epub,mobi,pdf` |

Save.

---

## 3. Config → Audio

| Setting | Value |
|---------|-------|
| **Audio folder** | `/audiobooks` |
| **Audio formats** | `mp3,m4b` |

Save.

---

## 4. Config → Magazines

Disable unless you want magazines. Save.

---

## 5. Config → Providers → Newznab

Add each Prowlarr **Usenet** indexer that supports books (e.g. NZBgeek, NzbPlanet).

**Prowlarr API key:** Settings → General → API Key in Prowlarr (http://pi5.xcvr.link:9696)

| Provider | URL | API |
|----------|-----|-----|
| NZBgeek (via Prowlarr) | `http://192.168.0.136:9696/5/api` | Prowlarr API key |
| NzbPlanet (via Prowlarr) | `http://192.168.0.136:9696/6/api` | Prowlarr API key |

Tick the box so the provider is used. Set **Types** to include `E` (ebook) and `A` (audio) if supported. Save.

> Indexer IDs may differ. In Prowlarr: Indexers → click indexer → note the ID in the URL or details. URL format: `http://192.168.0.136:9696/{id}/api`.

---

## 6. Config → Providers → Torznab

Add each Prowlarr **torrent** indexer that supports books (e.g. LimeTorrents).

| Provider | URL | API |
|----------|-----|-----|
| LimeTorrents (via Prowlarr) | `http://192.168.0.136:9696/2/api` | Prowlarr API key |

Tick the box. Set **Types** to `E` and `A` if supported. Save.

---

## 7. Config → Torrent (download clients)

Add **qBittorrent**:

| Setting | Value |
|---------|-------|
| **Host** | `192.168.0.136` (or `host.docker.internal` if localhost fails) |
| **Port** | `8080` |
| **Username** | `admin` |
| **Password** | `adminadmin` (or your qBittorrent Web UI password) |
| **Category** | `lazylibrarian` |

Add **rdt-client** (second torrent client):

| Setting | Value |
|---------|-------|
| **Host** | `192.168.0.136` |
| **Port** | `6500` |
| **Username** | (leave empty) |
| **Password** | (leave empty) |
| **Category** | `lazylibrarian` |

> rdt-client uses qBittorrent-compatible API; no auth by default.

Save.

---

## 8. Config → Sabnzbd

If you use Sabnzbd:

| Setting | Value |
|---------|-------|
| **Host** | `192.168.0.136` |
| **Port** | `8085` |
| **API key** | From Sabnzbd Config → General |
| **Category** | `lazylibrarian` |

**In Sabnzbd:** Config → Categories → add `lazylibrarian` → path `/downloads/complete/lazylibrarian`

Save.

---

## 9. Config → Notifications

Enable **Custom** notification:

| Setting | Value |
|---------|-------|
| **Notify on Download** | ✓ |
| **Script path** | `/config/jellyfin-autoscan-notify.sh` |

This triggers a Jellyfin library scan when a book/audiobook is added. Save.

---

## 10. Add authors / books

1. **Authors** → Add Author (search by name or add from Goodreads/ISBN).
2. Or use **RSS/Wishlist** in Config → Providers to add e.g. NYT bestsellers, Goodreads lists.
3. **Search** → use the search icon to find and grab missing books.

---

## 11. Jellyfin libraries

Ensure Jellyfin has:

- **Books** → `/media/books`
- **Audiobooks** → `/media/audiobooks`

Dashboard → Libraries → Add if missing. Paths are inside the Jellyfin container; adjust if your mount differs.

---

## Quick reference

| Item | Value |
|------|-------|
| LazyLibrarian UI | http://pi5.xcvr.link:5299 |
| Prowlarr API key | http://pi5.xcvr.link:9696 → Settings → General |
| qBittorrent | http://pi5.xcvr.link:8080 (admin / adminadmin) |
| rdt-client | http://pi5.xcvr.link:6500 |
| Sabnzbd | http://pi5.xcvr.link:8085 |

---

## Troubleshooting

- **No results from Newznab:** Check indexer IDs in Prowlarr. For Books, Usenet indexers (NZBgeek, NzbPlanet) are usually best.
- **Download client errors:** Ensure qBittorrent/rdt-client are reachable from the LazyLibrarian container. Use `192.168.0.136` (Pi IP) instead of `localhost`.
- **Jellyfin not scanning:** Run `curl -X POST http://192.168.0.136:8282/refresh` to test jellyfin-autoscan. Check custom script path `/config/jellyfin-autoscan-notify.sh` and that it’s executable.
