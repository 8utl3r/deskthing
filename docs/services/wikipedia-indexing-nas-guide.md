# Wikipedia Indexing to NAS Qdrant - Complete Guide

## Overview

Download Wikipedia to NAS storage and index it into Qdrant running on NAS.

## Architecture

```
Download → NAS Storage (/mnt/tank/apps/qdrant/wikipedia)
    ↓
Process → Mac (Ollama generates embeddings)
    ↓
Index → NAS Qdrant (stores vectors)
```

**Storage:**
- Wikipedia files: NAS (`/mnt/tank/apps/qdrant/wikipedia`)
- Vectors: NAS Qdrant (`http://192.168.0.158:6333`)
- Processing: Mac (uses Ollama for embeddings)

## Step 1: Download Wikipedia to NAS

**Run download script:**

```bash
cd ~/dotfiles/ollama/qdrant-mcp
./download_wikipedia.sh
```

**Or manually:**

```bash
# Create directory on NAS
ssh truenas_admin@192.168.0.158 "sudo mkdir -p /mnt/tank/apps/qdrant/wikipedia && sudo chown -R 568:568 /mnt/tank/apps/qdrant/wikipedia"

# Download to NAS
ssh truenas_admin@192.168.0.158 "cd /mnt/tank/apps/qdrant/wikipedia && curl -L -o wikipedia.zip 'https://github.com/Jatin1o1/Wikipedia_Text_Data_Dump_english/releases/download/v1.0/Wikipedia_Text_Data_Dump_english.zip'"
```

**Unzip on NAS:**

```bash
ssh truenas_admin@192.168.0.158 "cd /mnt/tank/apps/qdrant/wikipedia && unzip wikipedia.zip"
```

## Step 2: Index into Qdrant

**Test with small subset:**

```bash
cd ~/dotfiles/ollama/qdrant-mcp
python3 index_wikipedia.py \
  --dir /mnt/tank/apps/qdrant/wikipedia/Wikipedia_Text_Data_Dump_english \
  --limit 1000 \
  --collection wikipedia
```

**Note:** The `--dir` path needs to be accessible from your Mac. Options:
- Mount NAS share: `--dir /Volumes/nas-share/wikipedia/...`
- Or use SSH path if script supports it
- Or copy subset to Mac for testing

## Step 3: Monitor Progress

**Check Qdrant collection:**

```bash
curl http://192.168.0.158:6333/collections/wikipedia | python3 -m json.tool
```

**Or use MCP tool:**
```
"Get info about the wikipedia collection in Qdrant"
```

## Storage Estimates

**Wikipedia files on NAS:**
- Compressed: ~3GB
- Uncompressed: ~16GB
- Location: `/mnt/tank/apps/qdrant/wikipedia/`

**Vectors in Qdrant:**
- Per 1,000 articles: ~5,000-10,000 vectors (~10-20MB)
- Full Wikipedia (4.7M articles): ~25-50 million vectors (~50-100GB)
- Location: Qdrant storage on NAS

## Performance

**Indexing speed:**
- ~10-30 articles/minute (depending on article length)
- ~1,000 articles: 30-60 minutes
- Full Wikipedia: ~5-15 days (continuous)

**Recommendation:**
- Start with 1,000 articles (test)
- Then 10,000 articles (small KB)
- Scale up gradually

## Alternative: Mount NAS Share

**Mount NAS share on Mac for easier access:**

```bash
# Mount SMB share
mkdir -p ~/nas
mount_smbfs //truenas_admin@192.168.0.158/tank ~/nas

# Then use local path
python3 index_wikipedia.py --dir ~/nas/apps/qdrant/wikipedia/... --limit 1000
```

---

**Ready to download? Run the download script!**
