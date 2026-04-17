# Wikipedia Indexing Guide

## Overview

This guide explains how to download and index Wikipedia into Qdrant for RAG.

## Scale Considerations

**Full Wikipedia:**
- **Size:** ~25GB compressed, ~105GB uncompressed
- **Articles:** ~6.8 million articles
- **Estimated vectors:** ~50-100 million (depending on chunking)
- **Indexing time:** Days/weeks (depending on hardware)
- **Storage:** ~50-200GB for vectors

**Your setup:**
- Mac storage: 232GB free ✅ (enough for full dump)
- NAS storage: Multiple TB ✅ (plenty for vectors)
- Qdrant: Can handle millions of vectors ✅

## Options

### Option 1: Full Wikipedia (Complete)

**Download:**
- Latest dump: `https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles.xml.bz2`
- Requires parsing XML (complex)

**Better: Pre-processed Simple format**
- Hugging Face: `omarkamali/wikipedia-monthly` (monthly updates)
- Kaggle: Plaintext Wikipedia datasets
- Already cleaned and in JSON format

### Option 2: Subset (Recommended for Testing)

**Start with:**
- First 1,000 articles (test indexing)
- First 10,000 articles (small knowledge base)
- First 100,000 articles (medium knowledge base)

**Then scale up** to full Wikipedia if needed.

## Quick Start

### 1. Install Dependencies

```bash
pip3 install httpx tqdm
```

### 2. Download Wikipedia (Simple Format)

**Option A: Hugging Face (Recommended)**
```bash
# Install huggingface_hub
pip3 install huggingface_hub

# Download latest English Wikipedia
python3 -c "
from huggingface_hub import hf_hub_download
file = hf_hub_download(repo_id='omarkamali/wikipedia-monthly', filename='latest.en.jsonl', repo_type='dataset')
print(f'Downloaded to: {file}')
"
```

**Option B: Direct Download**
```bash
# Find latest Simple format dump URL
# Then download with curl or wget
```

### 3. Index into Qdrant

**Test with small subset:**
```bash
cd ~/dotfiles/ollama/qdrant-mcp
python3 index_wikipedia.py \
  --file /path/to/wikipedia.jsonl \
  --limit 1000 \
  --collection wikipedia
```

**Full indexing:**
```bash
python3 index_wikipedia.py \
  --file /path/to/wikipedia.jsonl \
  --collection wikipedia
```

## Process

1. **Download** Wikipedia dump (Simple format JSONL)
2. **Parse** articles (one per line)
3. **Chunk** articles into ~500 character pieces
4. **Generate embeddings** via Ollama
5. **Index** vectors in Qdrant with metadata

## Metadata Stored

Each vector includes:
- `text`: Chunk content
- `title`: Article title
- `article_id`: Article identifier
- `chunk_index`: Position in article
- `total_chunks`: Total chunks in article
- `source_type`: "wikipedia"

## Search Example

After indexing:
```
"Search Wikipedia for information about quantum computing"
→ Finds relevant Wikipedia articles
→ Returns chunks with article titles
→ Can verify against source
```

## Performance Estimates

**Per 1,000 articles:**
- Time: ~10-30 minutes
- Vectors: ~5,000-10,000
- Storage: ~10-20MB

**Full Wikipedia (6.8M articles):**
- Time: ~5-15 days (continuous)
- Vectors: ~50-100 million
- Storage: ~50-200GB

## Recommendations

**Start small:**
1. Index 1,000 articles (test)
2. Verify search works
3. Index 10,000 articles (small KB)
4. Scale up as needed

**Full indexing:**
- Run on NAS if possible (24/7)
- Use background process
- Monitor Qdrant storage
- Can pause/resume

---

**Ready to start? Let's download a subset first!**
