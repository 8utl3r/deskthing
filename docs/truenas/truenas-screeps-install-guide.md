# Screeps Private Server on TrueNAS Scale

## Overview

Screeps is an MMO strategy game where you control units by writing JavaScript. This guide installs a **local private server** on TrueNAS Scale 25.04 using the Screepers Launcher (Docker).

**Components:**
- **Screeps server** (Node.js) – game logic, port 21025
- **MongoDB** – game data storage
- **Redis** – tick sync and task queues

Screeps is not in the TrueNAS catalog, so we use **Install via YAML** (Custom App).

---

## Prerequisites

1. **Steam API key** (free): https://steamcommunity.com/dev/apikey  
   - Required for the Screeps launcher.

2. **Storage directories** – create before install (see Step 1).

3. **Apps enabled** on TrueNAS with pool `tank` selected.

---

## Step 1: Create Storage and Config

### 1.1 Create directories (TrueNAS Shell)

```bash
# Create app directory structure
sudo mkdir -p /mnt/tank/apps/screeps/{data,mongo,redis}

# Set permissions (apps user = 568:568)
sudo chown -R 568:568 /mnt/tank/apps/screeps
```

### 1.2 Create config.yml

Create `/mnt/tank/apps/screeps/config.yml` with this content (replace `YOUR_STEAM_API_KEY`):

```yaml
steamKey: YOUR_STEAM_API_KEY

# Required for MongoDB/Redis
mods:
  - screepsmod-mongo
  - screepsmod-auth
  - screepsmod-admin-utils

# Optional: add bots for single-player
bots:
  simplebot: screepsbot-zeswarm

serverConfig:
  welcomeText: |
    Local Screeps Private Server
    Running on TrueNAS
  tickRate: 1000   # ms between ticks (1 sec default)
```

**Via Shell:**
```bash
cat > /mnt/tank/apps/screeps/config.yml << 'EOF'
steamKey: YOUR_STEAM_API_KEY
mods:
  - screepsmod-mongo
  - screepsmod-auth
  - screepsmod-admin-utils
bots:
  simplebot: screepsbot-zeswarm
serverConfig:
  welcomeText: |
    Local Screeps Private Server
    Running on TrueNAS
  tickRate: 1000
EOF

# Fix ownership
sudo chown 568:568 /mnt/tank/apps/screeps/config.yml
```

---

## Step 2: Install via Custom App

1. **Open TrueNAS Web UI**  
   - Go to `http://192.168.0.158` (or your NAS IP)

2. **Apps → Discover Apps**

3. **Install via YAML**  
   - Click the three-dot menu (⋮)  
   - Select **"Install via YAML"**

4. **Application name:** `screeps`

5. **Paste this Docker Compose YAML:**

```yaml
version: '3.8'

services:
  screeps:
    image: screepers/screeps-launcher
    container_name: screeps
    user: "0:0"   # Run as root - launcher needs to download Node.js to data dir
    restart: unless-stopped
    ports:
      - "127.0.0.1:21025:21025/tcp"   # Local only - change to "21025:21025" for LAN access
    volumes:
      - /mnt/tank/apps/screeps/config.yml:/screeps/config.yml
      - /mnt/tank/apps/screeps/data:/screeps
    environment:
      MONGO_HOST: mongo
      REDIS_HOST: redis
    depends_on:
      mongo:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://127.0.0.1:21025/ || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 30s

  mongo:
    image: mongo:8
    container_name: screeps-mongo
    restart: unless-stopped
    volumes:
      - /mnt/tank/apps/screeps/mongo:/data/db
    healthcheck:
      test: ["CMD-SHELL", "mongosh --eval \"db.adminCommand('ping')\" --quiet || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  redis:
    image: redis:7
    container_name: screeps-redis
    restart: unless-stopped
    volumes:
      - /mnt/tank/apps/screeps/redis:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 5s
      retries: 3
```

6. **Storage mounts**  
   The YAML uses host paths. Ensure these exist (Step 1 creates the parent; subdirs are created by containers):
   - `/mnt/tank/apps/screeps/config.yml` → config
   - `/mnt/tank/apps/screeps/data` → Screeps server data
   - `/mnt/tank/apps/screeps/mongo` → MongoDB data
   - `/mnt/tank/apps/screeps/redis` → Redis data

7. **Deploy**  
   - Review and deploy  
   - Wait 2–5 minutes for services to start

---

## Step 3: Initialize Database

The server must run `system.resetAllData()` once before first use.

### Option A: TrueNAS Apps UI

1. **Apps → Installed Applications → screeps**
2. Open the **screeps** workload (main container)
3. Use **Shell** or **Console** to open a shell in the container
4. Run:
   ```bash
   screeps-launcher cli
   ```
5. In the CLI:
   ```javascript
   system.resetAllData()
   ```
6. Exit with `Ctrl+D`
7. Restart the screeps app from the Apps UI

### Option B: SSH + Docker (if Docker CLI is available)

```bash
# Find container ID
docker ps | grep screeps

# Exec into screeps container (not mongo/redis)
docker exec -it <screeps-container-id> screeps-launcher cli

# In CLI:
system.resetAllData()
# Ctrl+D to exit

# Restart screeps container
```

---

## Step 4: Connect from Screeps Client

1. Open **Screeps** (Steam or web client)
2. Go to **Private Server**
3. Enter:
   - **Host:** `192.168.0.158` (your NAS IP) or `localhost` if on the NAS
   - **Port:** `21025`
   - **Password:** leave blank (or set via screepsmod-auth)

4. **Sign up** – create your first user (no Steam required for private server with screepsmod-auth)

---

## Port Binding

- **`127.0.0.1:21025`** – only from the NAS itself (most secure for local-only)
- **`21025:21025`** – from any device on your LAN

To allow LAN access, change the port mapping in the YAML to:
```yaml
ports:
  - "21025:21025/tcp"
```

---

## Directory Layout

```
/mnt/tank/apps/screeps/
├── config.yml      # Server config (edit steamKey, mods, etc.)
├── data/           # Screeps server data (launcher, node_modules)
├── mongo/          # MongoDB data
└── redis/          # Redis data
```

---

## Useful Mods

Add to `mods:` in `config.yml`:

| Mod | Purpose |
|-----|---------|
| `screepsmod-auth` | Password management, web UI at `/authmod/password` |
| `screepsmod-admin-utils` | Admin commands, welcome text |
| `screepsmod-map-tool` | Map utilities |
| `screepsmod-history` | Room history |
| `screepsmod-market` | Market features |

Restart the screeps app after editing `config.yml`.

---

## Troubleshooting

### Server won't start
- Check logs: **Apps → screeps → Logs**
- Ensure `config.yml` exists and has valid YAML
- Ensure `steamKey` is set in `config.yml`

### "Connection refused" from client
- Confirm port is `21025`
- If using `127.0.0.1`, switch to `0.0.0.0` or `21025:21025` for LAN access
- Check firewall on TrueNAS

### Database errors
- Run `system.resetAllData()` in the CLI (Step 3)
- Restart the screeps app after reset

### Permission errors
```bash
sudo chown -R 568:568 /mnt/tank/apps/screeps
```

---

## References

- [Screepers Launcher](https://github.com/screepers/screeps-launcher)
- [Private Server Wiki](https://wiki.screepspl.us/Private_Server_Installation/)
- [Screeps Docs](https://docs.screeps.com/)
