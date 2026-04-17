# Wikipedia Download Options

## Quick Start (Recommended)

For testing, use Simple English Wikipedia (~1GB):

```bash
cd /Users/pete/dotfiles/ollama/qdrant-mcp
./download_wikipedia_simple.sh
```

This will:
1. Download Simple English Wikipedia XML dump
2. Extract to text files
3. Copy to NAS
4. Index first 1000 articles into Qdrant

## Full English Wikipedia Options

### Option 1: Kaggle (Recommended - Pre-processed JSON)

**Prerequisites:**
1. Install Kaggle CLI: `pip3 install kaggle`
2. Get API credentials from https://www.kaggle.com/settings
3. Place `kaggle.json` in `~/.kaggle/`

**Download:**
```bash
cd /Users/pete/dotfiles/ollama/qdrant-mcp
./download_wikipedia_kaggle.sh
```

**Dataset:** `wikimedia-foundation/wikipedia-structured-contents`
- Format: JSONL (one article per line)
- Size: ~25-30GB
- Pre-processed, clean text

### Option 2: Official Wikimedia XML Dump

**Download:**
```bash
# Download latest English Wikipedia dump
wget -c https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles-multistream.xml.bz2

# Extract using wikiextractor
pip3 install wikiextractor
wikiextractor -o extracted --no-templates --no-style --no-doc --no-lists \
  enwiki-latest-pages-articles-multistream.xml.bz2

# Index
python3 /Users/pete/dotfiles/ollama/qdrant-mcp/index_wikipedia.py \
  --dir extracted \
  --collection wikipedia
```

**Size:** ~23GB compressed, ~100GB+ uncompressed

### Option 3: Pre-processed Text Files (Google Drive)

**Manual Download:**
1. Go to: https://drive.google.com/file/d/1tuHFrfRQJvYVh3QlEaAJleF05DIukuWP/view
2. Download zip file (~3GB compressed, 16GB uncompressed)
3. Extract to NAS: `/mnt/tank/apps/qdrant/wikipedia`
4. Index:
```bash
python3 /Users/pete/dotfiles/ollama/qdrant-mcp/index_wikipedia.py \
  --dir /mnt/tank/apps/qdrant/wikipedia \
  --collection wikipedia
```

## Indexing Script Usage

```bash
# Index from directory of .txt files
python3 index_wikipedia.py --dir /path/to/wikipedia --collection wikipedia

# Index from single JSONL file
python3 index_wikipedia.py --file /path/to/wikipedia.jsonl --collection wikipedia

# Limit for testing
python3 index_wikipedia.py --dir /path/to/wikipedia --limit 1000 --collection wikipedia

# Custom chunk size
python3 index_wikipedia.py --dir /path/to/wikipedia --chunk-size 1000 --collection wikipedia
```

## Environment Variables

```bash
export QDRANT_URL="http://192.168.0.158:6333"
export OLLAMA_URL="http://localhost:11434"
export EMBEDDING_MODEL="nomic-embed-text"
export QDRANT_COLLECTION="wikipedia"
```

## Performance Estimates

- **Simple English Wikipedia:** ~100K articles, ~1 hour to index
- **Full English Wikipedia:** ~6M articles, ~50-100 hours to index
- **Chunking:** ~500 chars per chunk (configurable)
- **Batch size:** 50 vectors per batch
- **Embedding model:** nomic-embed-text (768 dimensions)

## Next Steps

After indexing:
1. Test search via MCP tools in Cursor
2. Query Qdrant directly: `curl http://192.168.0.158:6333/collections/wikipedia`
3. Use in RAG queries through Atlas
