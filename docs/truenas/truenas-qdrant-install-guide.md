# Qdrant Installation on TrueNAS Scale

## Overview

Qdrant is a vector database for storing and searching embeddings. It will be used by vector_mapper (your Atlas proxy) for RAG (Retrieval Augmented Generation).

## Prerequisites

✅ Storage directory created:
- `/mnt/tank/apps/qdrant` - Qdrant data storage

✅ Permissions set to `apps:apps` (568:568)

## Installation Steps

### Option 1: Via Web UI (Recommended)

1. **Open TrueNAS Web UI**
   - Go to `http://192.168.0.158`
   - Navigate to **Apps** → **Discover Apps**

2. **Install Custom App**
   - Click the three-dot menu (⋮) in top right
   - Select **"Install via YAML"**

3. **Application Name**
   - Enter: `qdrant`

4. **Paste Docker Compose YAML**
   - Use the YAML configuration below

5. **Complete Installation**
   - Review configuration
   - Deploy the app

---

## Docker Compose Configuration

**Copy this YAML for installation:**

```yaml
version: '3.8'

services:
  qdrant:
    image: qdrant/qdrant:latest
    container_name: qdrant
    restart: unless-stopped
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - /mnt/tank/apps/qdrant:/qdrant/storage
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6333/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
```

**Key Configuration:**
- **Port 6333**: HTTP API (used by vector_mapper)
- **Port 6334**: gRPC API (optional, for advanced use)
- **Storage**: `/mnt/tank/apps/qdrant` → `/qdrant/storage`
- **Health Check**: Verifies Qdrant is running

---

## Post-Installation

### 1. Verify Qdrant is Running

**From TrueNAS Web UI:**
- Apps → Installed Apps → qdrant
- Check status shows "Running"
- Check logs for any errors

**From Mac (test connection):**
```bash
# Test health endpoint
curl http://192.168.0.158:6333/health

# Should return: {"status":"ok"}
```

### 2. Create Storage Directory (if needed)

**In TrueNAS Shell:**
```bash
# Create directory if it doesn't exist
sudo mkdir -p /mnt/tank/apps/qdrant

# Set permissions
sudo chown -R 568:568 /mnt/tank/apps/qdrant
```

### 3. Test Qdrant API

**From Mac:**
```bash
# Check Qdrant version
curl http://192.168.0.158:6333/

# List collections (should be empty initially)
curl http://192.168.0.158:6333/collections
```

---

## Configuration for vector_mapper

Once Qdrant is running, configure vector_mapper to connect to it.

**In `ollama/proxy/config.json` (or wherever vector_mapper config is):**

```json
{
  "qdrant": {
    "host": "192.168.0.158",
    "port": 6333,
    "collection": "atlas_conversations"
  },
  "ollama": {
    "host": "localhost",
    "port": 11434
  },
  "embedding_model": "nomic-embed-text"
}
```

---

## Storage Requirements

**Qdrant Storage:**
- Base: ~100-200MB (Docker image + base files)
- Per 1M vectors: ~1-2GB
- Very lightweight compared to Immich/Seafile

**Your setup:**
- Storage: `/mnt/tank/apps/qdrant`
- Will grow slowly as you index conversations/documents
- Estimated: ~1-2GB for 1 million vectors

---

## Troubleshooting

### Container Won't Start

**Check logs:**
- Apps → Installed Apps → qdrant → Logs
- Look for permission errors or port conflicts

**Common issues:**
- Port 6333 already in use → Change port in YAML
- Permission denied → Check directory permissions
- Storage path doesn't exist → Create directory first

### Can't Connect from Mac

**Test connectivity:**
```bash
# Ping NAS
ping 192.168.0.158

# Test Qdrant port
curl http://192.168.0.158:6333/health
```

**Check firewall:**
- Ensure port 6333 is accessible on NAS
- TrueNAS Apps should handle port mapping automatically

### Performance Issues

**Monitor resources:**
- Check CPU/RAM usage in TrueNAS
- Qdrant is lightweight (~200MB RAM base)
- Should run fine alongside other apps

---

## Maintenance

### Backup Qdrant Data

**Option 1: Backup Storage Directory**
```bash
# On TrueNAS Shell
sudo tar czf /mnt/tank/backups/qdrant-backup-$(date +%Y%m%d).tar.gz \
  -C /mnt/tank/apps qdrant
```

**Option 2: Qdrant Snapshot (if needed)**
```bash
# Via TrueNAS Shell (if container allows)
# This requires exec access to container
```

### Update Qdrant

1. **Apps → Installed Apps → qdrant → Edit**
2. **Change image tag** to latest version (or specific version)
3. **Save and restart**

Or update YAML:
```yaml
image: qdrant/qdrant:v1.7.0  # Specific version
# or
image: qdrant/qdrant:latest  # Latest
```

---

## Next Steps

1. ✅ Install Qdrant (this guide)
2. 🔲 Configure vector_mapper to connect to Qdrant
3. 🔲 Test vector search and retrieval
4. 🔲 Enable automatic conversation indexing
5. 🔲 Index documents from Seafile/Immich

---

## Integration Flow

```
vector_mapper (Mac) → Generates embedding (Ollama)
                    ↓
                 Searches Qdrant (NAS: 192.168.0.158:6333)
                    ↓
                 Retrieves relevant vectors + metadata
                    ↓
                 Injects context into prompt
                    ↓
                 Queries Atlas (Ollama on Mac)
                    ↓
                 Indexes conversation in Qdrant (NAS)
```

---

**Ready to install? Use the YAML above in TrueNAS Apps → Install via YAML!**
