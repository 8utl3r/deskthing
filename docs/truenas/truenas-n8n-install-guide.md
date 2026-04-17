# Installing n8n on TrueNAS Scale 25.04

## Issue: n8n Not Visible in Catalog

**n8n is in the "community" train, not "stable"**

The web UI may be filtering to show only "stable" apps by default. n8n is available but in the community train.

---

## Solution 1: Switch to Community Train in Web UI

1. **Go to Apps page**
   - Navigate to `http://192.168.0.158/ui/apps`

2. **Look for Train Filter**
   - Find a dropdown or filter for "Train" or "Catalog"
   - Change from "stable" to "community"
   - Or look for tabs: "Stable", "Community", etc.

3. **Search for n8n**
   - Once on community train, search for "n8n"
   - Should appear now

4. **Install**
   - Click Install/Deploy
   - Configure storage mount: `/mnt/tank/apps/n8n` → `/home/node/.n8n`
   - Port: 5678

---

## Solution 2: Install as Custom App (Docker Compose)

If you can't find the train filter, install n8n as a custom Docker app:

1. **Go to Apps → Discover Apps**
2. **Click the three-dot menu** (⋮) or "More Options"
3. **Select "Install via YAML"** or "Custom App"
4. **Paste this Docker Compose YAML:**

```yaml
version: "3.8"

services:
  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - TZ=America/Los_Angeles
      - GENERIC_TIMEZONE=America/Los_Angeles
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
    volumes:
      - /mnt/tank/apps/n8n:/home/node/.n8n
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

5. **Configure:**
   - Application Name: `n8n`
   - Storage: Ensure `/mnt/tank/apps/n8n` is mounted to `/home/node/.n8n`
   - Port: 5678

6. **Deploy**

---

## Solution 3: Via CLI (If API Works)

I can try installing via CLI once we figure out the correct API format, but the web UI is usually easier.

---

## What to Look For in Web UI

**On Apps page, look for:**
- Train/Catalog dropdown (top of page)
- Tabs: "Stable", "Community", "Enterprise"
- Filter options
- "Show all trains" or similar option

**If you see tabs:**
- Click "Community" tab
- Search for n8n
- Should appear

---

**Can you check if there's a train/catalog filter or tabs on the Apps page? That will help us find n8n!**
