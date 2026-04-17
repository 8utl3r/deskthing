# Degoogling Services on TrueNAS Scale NAS

## Overview

The TrueNAS NAS is core to your degoogling efforts - replacing Google services with self-hosted, privacy-focused alternatives.

## Planned Services

### ✅ Completed
- **n8n** - Workflow automation (replaces Google Apps Script, IFTTT, Zapier)
  - Status: ✅ Running at `http://192.168.0.158:30109`
  - Storage: `/mnt/tank/apps/n8n`

### 🔲 To Install

#### 1. **Nextcloud** - File Sync & Sharing
**Replaces:** Google Drive, Google Photos
- **Purpose:** Self-hosted file storage, sync, and sharing
- **Features:**
  - File sync across devices
  - Photo gallery
  - Calendar & Contacts sync
  - Document collaboration
  - App ecosystem
- **Storage:** `/mnt/tank/apps/nextcloud`
- **Port:** TBD (default 8080 or custom)
- **Notes:** Can integrate with n8n for automation

#### 2. **Qdrant** - Vector Database
**Replaces:** Google's AI/ML services (for local RAG)
- **Purpose:** Vector database for Atlas RAG system
- **Features:**
  - Store embeddings for local AI
  - Semantic search
  - RAG (Retrieval Augmented Generation) support
- **Storage:** `/mnt/tank/apps/qdrant`
- **Port:** TBD (default 6333)
- **Notes:** Integrates with Ollama/Atlas for private AI

#### 3. **Jellyfin** - Media Server
**Replaces:** YouTube Premium, Google Play Movies/TV
- **Purpose:** Self-hosted media streaming
- **Features:**
  - Movies & TV shows
  - Music library
  - Live TV (if configured)
  - Mobile apps available
- **Storage:** `/mnt/tank/media` (for media files)
- **Port:** TBD (default 8096)
- **Notes:** Can use existing `media/` dataset

#### 4. **Home Assistant** - Home Automation
**Replaces:** Google Home, Nest integration
- **Purpose:** Local home automation hub
- **Features:**
  - Device control
  - Automation rules
  - Local-first (no cloud required)
- **Storage:** `/mnt/tank/apps/homeassistant`
- **Port:** TBD (default 8123)
- **Notes:** You already have Home Assistant config in dotfiles

#### 5. **Portainer** (Optional) - Container Management
**Purpose:** Web UI for managing Docker containers
- **Features:**
  - Container management
  - Image management
  - Volume management
- **Port:** TBD (default 9000)
- **Notes:** Helpful for managing apps, but TrueNAS Apps UI may be sufficient

---

## Installation Priority

### Phase 1: Core Services (High Priority)
1. ✅ **n8n** - Workflow automation (DONE)
2. **Nextcloud** - File sync (replaces Google Drive)
3. **Qdrant** - Vector DB (for Atlas RAG)

### Phase 2: Media & Automation
4. **Jellyfin** - Media server (replaces YouTube/Play Movies)
5. **Home Assistant** - Home automation (replaces Google Home)

### Phase 3: Management Tools
6. **Portainer** - Container management (optional)

---

## Storage Organization

**Current Datasets:**
- `/mnt/tank/apps/` - App data (n8n, nextcloud, etc.)
- `/mnt/tank/media/` - Media files (movies, TV, music)
- `/mnt/tank/backups/` - System backups
- `/mnt/tank/documents/` - Personal files

**Recommended Structure:**
```
/mnt/tank/
├── apps/
│   ├── n8n/              ✅ (done)
│   ├── nextcloud/        🔲
│   ├── qdrant/           🔲
│   ├── homeassistant/    🔲
│   └── portainer/        🔲 (optional)
├── media/
│   ├── movies/
│   ├── tv/
│   └── music/
├── backups/
└── documents/
```

---

## Next Steps

1. **Install Nextcloud** (highest priority for degoogling)
   - Replaces Google Drive immediately
   - Can sync files across devices
   - Mobile apps available

2. **Install Qdrant** (for Atlas RAG)
   - Enables local AI with RAG
   - Private knowledge base
   - No Google AI services needed

3. **Install Jellyfin** (media consumption)
   - Self-hosted streaming
   - No YouTube/Play Movies dependency

4. **Install Home Assistant** (home automation)
   - Local-first automation
   - No Google Home/Nest cloud dependency

---

## Degoogling Impact

**Services Replaced:**
- ✅ Google Apps Script → n8n
- 🔲 Google Drive → Nextcloud
- 🔲 Google Photos → Nextcloud
- 🔲 Google AI/ML → Qdrant + Ollama
- 🔲 YouTube/Play Movies → Jellyfin
- 🔲 Google Home/Nest → Home Assistant

**Privacy Benefits:**
- All data stays local
- No cloud dependencies
- Full control over data
- No telemetry/phone-home
- Self-hosted = privacy-first

---

**Ready to install Nextcloud next? It's the biggest degoogling win after n8n!**
