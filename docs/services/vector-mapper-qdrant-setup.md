# vector_mapper Qdrant Setup Guide

## Overview

This guide helps you configure vector_mapper (formerly Atlas Proxy) to use Qdrant for RAG (Retrieval-Augmented Generation).

## Prerequisites

✅ **Qdrant running on TrueNAS**
- URL: `http://192.168.0.158:6333`
- Status: Running (verified)

✅ **Ollama running on Mac**
- URL: `http://localhost:11434`
- Embedding model: `nomic-embed-text` (install if needed)

## Step 1: Install Embedding Model

**On your Mac:**

```bash
# Install nomic-embed-text embedding model
ollama pull nomic-embed-text

# Verify it's installed
ollama list | grep nomic-embed-text
```

## Step 2: Configure vector_mapper

**Create or edit config file:**

```bash
cd ~/dotfiles/ollama/proxy
nano config.json
```

**Add Qdrant configuration:**

```json
{
  "qdrant_url": "http://192.168.0.158:6333",
  "qdrant_collection": "atlas_conversations",
  "embedding_model": "nomic-embed-text"
}
```

**Or set via environment variables:**

```bash
export ATLAS_QDRANT_URL="http://192.168.0.158:6333"
export ATLAS_QDRANT_COLLECTION="atlas_conversations"
export ATLAS_EMBEDDING_MODEL="nomic-embed-text"
```

## Step 3: Update Proxy Code

The RAG manager component has been created. Now we need to integrate it into the proxy.

**The integration will:**
1. Search Qdrant before each query (for relevant context)
2. Inject RAG context into prompts
3. Index conversations after each exchange

## Step 4: Test Connection

**Test Qdrant connection:**

```bash
# From Mac
curl http://192.168.0.158:6333/health
# Should return: {"status":"ok"}
```

**Test embedding generation:**

```bash
curl http://localhost:11434/api/embeddings \
  -d '{"model": "nomic-embed-text", "prompt": "test"}'
# Should return embedding vector
```

## Step 5: Restart vector_mapper

**If running as service:**

```bash
atlas-proxy-restart
```

**Or manually:**

```bash
cd ~/dotfiles/ollama/proxy
python3 atlas_proxy.py
```

## Step 6: Verify Integration

**Check logs for:**
- "Collection 'atlas_conversations' already exists" or "Created collection"
- "Found X relevant results for query"
- "Indexed text with metadata"

**Test with a query:**
- Ask Atlas a question
- Check if RAG context is being retrieved
- Verify conversations are being indexed

## Configuration Options

**Full config.json example:**

```json
{
  "ollama_url": "http://localhost:11434",
  "proxy_port": 11435,
  "data_dir": "~/dotfiles/ollama/data",
  "qdrant_url": "http://192.168.0.158:6333",
  "qdrant_collection": "atlas_conversations",
  "embedding_model": "nomic-embed-text",
  "max_context_tokens": 32768,
  "dynamic_context": true
}
```

## Troubleshooting

### Qdrant Connection Failed

**Check:**
- Qdrant is running: `curl http://192.168.0.158:6333/health`
- Network connectivity: `ping 192.168.0.158`
- Firewall allows port 6333

### Embedding Model Not Found

**Install model:**
```bash
ollama pull nomic-embed-text
```

**Verify:**
```bash
ollama list | grep nomic-embed-text
```

### Collection Creation Failed

**Check Qdrant logs:**
- Apps → Installed Apps → qdrant → Logs
- Look for errors about collection creation

**Manual collection creation (if needed):**
```bash
curl -X PUT http://192.168.0.158:6333/collections/atlas_conversations \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 768,
      "distance": "Cosine"
    }
  }'
```

## Next Steps

1. ✅ Configure Qdrant URL
2. ✅ Install embedding model
3. 🔲 Integrate RAG into proxy (code update needed)
4. 🔲 Test RAG search and retrieval
5. 🔲 Enable automatic conversation indexing

---

**Ready to configure? Follow the steps above!**
