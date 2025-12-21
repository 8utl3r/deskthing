# Qdrant on NAS - Docker Setup Guide

## Overview

Since you have a NAS with Docker, **Qdrant is the optimal choice** for Atlas RAG. It offloads all vector database operations to your NAS, keeping your Mac's resources free.

## Benefits

- ✅ **Zero Mac resource usage** - All processing on NAS
- ✅ **One-command setup** - Docker makes it trivial
- ✅ **24/7 availability** - NAS typically always on
- ✅ **Production-grade** - Best performance and reliability
- ✅ **Scalable** - Handles millions of vectors
- ✅ **Easy backup** - Docker volumes are simple to backup

## Setup Steps

### 1. On NAS: Start Qdrant Container

```bash
docker run -d \
  --name atlas-qdrant \
  --restart unless-stopped \
  -p 6333:6333 \
  -p 6334:6334 \
  -v atlas_qdrant_data:/qdrant/storage \
  qdrant/qdrant
```

**Ports**:
- `6333`: HTTP API (for proxy)
- `6334`: gRPC API (optional, for advanced use)

**Volume**: `atlas_qdrant_data` persists all vector data

### 2. Verify Qdrant is Running

```bash
# From NAS
docker ps | grep qdrant

# Test API
curl http://localhost:6333/health
```

### 3. Configure Proxy to Use NAS Qdrant

The Atlas proxy (running on your Mac) will connect to Qdrant on your NAS.

**Configuration** (`ollama/proxy/config.json`):
```json
{
  "qdrant": {
    "host": "your-nas-ip",
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

### 4. Network Considerations

**Option A: Direct IP** (Simplest)
- Use NAS's local IP (e.g., `192.168.1.100:6333`)
- Works if Mac and NAS on same network

**Option B: Docker Network** (If both on Docker)
- Create shared Docker network
- Use container names for service discovery

**Option C: VPN/Tailscale** (If NAS remote)
- Use Tailscale or VPN for secure access
- Access NAS via VPN IP

## Proxy Integration

The Atlas proxy will:

1. **Generate embeddings** via Ollama (on Mac)
2. **Store/search vectors** via Qdrant (on NAS)
3. **Retrieve context** before each query
4. **Inject context** into Atlas prompts

**Flow**:
```
User Query → Proxy (Mac)
              ↓
         Generate embedding (Ollama on Mac)
              ↓
         Search Qdrant (NAS)
              ↓
         Retrieve relevant context
              ↓
         Inject into prompt
              ↓
         Query Atlas (Ollama on Mac)
              ↓
         Return response
              ↓
         Index conversation (Qdrant on NAS)
```

## Maintenance

### Backup Qdrant Data

```bash
# On NAS
docker exec atlas-qdrant qdrant export snapshot /qdrant/snapshots/backup.snapshot

# Or backup volume
docker run --rm -v atlas_qdrant_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/qdrant-backup.tar.gz /data
```

### Update Qdrant

```bash
# On NAS
docker pull qdrant/qdrant:latest
docker stop atlas-qdrant
docker rm atlas-qdrant
# Re-run setup command with new image
```

### Monitor Qdrant

```bash
# Check status
curl http://nas-ip:6333/metrics

# View collections
curl http://nas-ip:6333/collections
```

## Alternative: ChromaDB on NAS

If you prefer ChromaDB (easier Python integration):

```bash
docker run -d \
  --name atlas-chromadb \
  -p 8000:8000 \
  -v atlas_chromadb_data:/chroma/chroma \
  chromadb/chroma
```

**Pros**: Easier Python integration, simpler API  
**Cons**: Less powerful than Qdrant, smaller scale

## Performance Expectations

**With Qdrant on NAS**:
- Query latency: ~20-50ms (network + search)
- Indexing: ~100-200ms per conversation
- Storage: ~1-2KB per vector (with metadata)
- Memory: Qdrant uses NAS RAM (not Mac RAM)

**Network Impact**:
- Minimal - only vector search requests
- Embeddings generated on Mac (Ollama)
- Only small vector data transferred

## Troubleshooting

### Can't Connect to NAS

```bash
# Test connectivity
ping nas-ip
curl http://nas-ip:6333/health

# Check firewall
# Ensure port 6333 is open on NAS
```

### Qdrant Container Stops

```bash
# Check logs
docker logs atlas-qdrant

# Restart
docker restart atlas-qdrant
```

### Performance Issues

- Check NAS CPU/RAM usage
- Consider increasing Qdrant container resources
- Monitor network latency between Mac and NAS

## Next Steps

1. Set up Qdrant on NAS (this guide)
2. Implement Atlas proxy with Qdrant integration
3. Test vector search and retrieval
4. Enable automatic conversation indexing

