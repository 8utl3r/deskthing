#!/bin/bash
# Download pre-processed English Wikipedia text dump to NAS

set -e

NAS_IP="${NAS_IP:-192.168.0.158}"
NAS_PATH="${NAS_PATH:-/mnt/tank/apps/qdrant/wikipedia}"

echo "📥 Downloading pre-processed English Wikipedia to NAS..."

# Option 1: GitHub - Wikipedia Text Data Dump (3GB compressed, 16GB uncompressed)
# Individual .txt files, ~4.7M articles
WIKI_URL="https://github.com/Jatin1o1/Wikipedia_Text_Data_Dump_english/releases/download/v1.0/Wikipedia_Text_Data_Dump_english.zip"

# Option 2: Kaggle dataset (requires Kaggle API)
# Dataset: ffatty/plaintext-wikipedia-full-english
# ~22GB uncompressed, concatenated .txt files

echo "NAS: $NAS_IP"
echo "Path: $NAS_PATH"
echo "URL: $WIKI_URL"
echo ""

# Create directory on NAS
echo "Creating directory on NAS..."
ssh truenas_admin@$NAS_IP "sudo mkdir -p $NAS_PATH && sudo chown -R 568:568 $NAS_PATH"

# Download directly to NAS
echo "Downloading to NAS (this may take a while)..."
ssh truenas_admin@$NAS_IP "cd $NAS_PATH && curl -L -o wikipedia_english.zip '$WIKI_URL'"

echo ""
echo "✅ Download complete on NAS!"
echo ""
echo "Next steps:"
echo "1. Unzip on NAS: ssh truenas_admin@$NAS_IP 'cd $NAS_PATH && unzip wikipedia_english.zip'"
echo "2. Index: python3 ~/dotfiles/ollama/qdrant-mcp/index_wikipedia.py --dir $NAS_PATH/Wikipedia_Text_Data_Dump_english --limit 1000"
