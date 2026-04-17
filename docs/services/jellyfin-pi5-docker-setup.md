# Jellyfin on Pi 5 via Docker (10.10.7)

Jellyfin runs on the **Pi**, not the NAS. Media is on the NAS and mounted to the Pi (e.g. `/mnt/data/media`).

Native apt Jellyfin 10.11 has migration bugs. Use Docker with 10.10.7 instead.

## Prerequisites

- Pi has Docker installed (`sudo apt install docker.io docker-compose` or `curl -fsSL https://get.docker.com | sh`)
- Add user to docker group: `sudo usermod -aG docker pi` (log out and back in)
- Media mounted at `/mnt/data/media` (or your path)
- Subdirs: `movies`, `tv`, `music`, `books`, `audiobooks`

## Install

```bash
# On Pi (ssh pi@192.168.0.136)

# Stop native jellyfin if installed
sudo systemctl stop jellyfin 2>/dev/null || true
sudo systemctl disable jellyfin 2>/dev/null || true

# Create config dir
sudo mkdir -p /var/lib/jellyfin-docker/{config,cache,transcodes}
sudo chown -R 1000:1000 /var/lib/jellyfin-docker

# Run Jellyfin 10.10.7
docker run -d \
  --name jellyfin \
  --restart unless-stopped \
  -p 8096:8096 \
  -e TZ=America/Los_Angeles \
  -e PUID=1000 \
  -e PGID=1000 \
  -v /var/lib/jellyfin-docker/config:/config \
  -v /var/lib/jellyfin-docker/cache:/cache \
  -v /var/lib/jellyfin-docker/transcodes:/config/transcodes \
  -v /mnt/data/media/movies:/media/movies:ro \
  -v /mnt/data/media/tv:/media/tv:ro \
  -v /mnt/data/media/music:/media/music:ro \
  -v /mnt/data/media/books:/media/books:ro \
  -v /mnt/data/media/audiobooks:/media/audiobooks:ro \
  jellyfin/jellyfin:10.10.7
```

## Post-install

1. Open http://192.168.0.136:8096 (or pi5.xcvr.link:8096)
2. Create admin user (e.g. pete / 12345678)
3. Add libraries: Movies → `/media/movies`, TV Shows → `/media/tv`, Music → `/media/music`, Books → `/media/books`, Audiobooks → `/media/audiobooks`
4. Complete wizard

Or run from Mac: `JF_USER=pete JF_PASS=12345678 ./scripts/servarr-pi5-phase4-jellyfin-config.sh` (adds libraries via API)

## Upgrade to 10.11 later

Once 10.10.7 is running with data, you can upgrade:

```bash
docker stop jellyfin
docker rm jellyfin
# Re-run docker run with jellyfin/jellyfin:10.11.6 (or latest)
```

Migration from 10.10 → 10.11 is supported; fresh 10.11 installs have the bugs.
