#!/bin/bash
# Download Wikipedia from Kaggle and index into Qdrant

set -e

NAS_IP="${NAS_IP:-192.168.0.158}"
NAS_PATH="${NAS_PATH:-/mnt/tank/apps/qdrant/wikipedia}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIMIT="${LIMIT:-1000}"  # Start with 1000 articles for testing

echo "🚀 Wikipedia Download and Indexing (Kaggle)"
echo "=========================================="
echo ""

# Check for Kaggle CLI
if ! command -v kaggle &> /dev/null; then
    echo "❌ Kaggle CLI not found"
    echo ""
    echo "Install with:"
    echo "  pip install kaggle"
    echo ""
    echo "Then set up credentials:"
    echo "  1. Go to https://www.kaggle.com/settings"
    echo "  2. Create API token"
    echo "  3. Place kaggle.json in ~/.kaggle/"
    echo ""
    exit 1
fi

# Check credentials
if [ ! -f ~/.kaggle/kaggle.json ]; then
    echo "❌ Kaggle credentials not found"
    echo "   Place kaggle.json in ~/.kaggle/"
    exit 1
fi

echo "✅ Kaggle CLI found"
echo ""

# Create local temp directory
TEMP_DIR="/tmp/wikipedia_download_$$"
mkdir -p "$TEMP_DIR"
echo "📁 Using temp directory: $TEMP_DIR"
echo ""

# Download dataset
echo "📥 Downloading Wikipedia dataset from Kaggle..."
echo "   Dataset: wikimedia-foundation/wikipedia-structured-contents"
echo "   This may take a while (25-30GB)..."
echo ""

cd "$TEMP_DIR"
kaggle datasets download -d wikimedia-foundation/wikipedia-structured-contents

# Extract
echo ""
echo "📦 Extracting files..."
unzip -q "*.zip" || true  # May have multiple zip files

# Find JSONL files
JSONL_FILES=$(find . -name "*.jsonl" -o -name "*.json" | head -1)
if [ -z "$JSONL_FILES" ]; then
    echo "❌ No JSONL files found in download"
    echo "   Files downloaded:"
    ls -lh
    exit 1
fi

echo "✅ Found data files"
echo ""

# Copy to NAS (or use directly from temp)
echo "📤 Copying to NAS..."
echo "   Target: $NAS_PATH"
echo ""

# Create directory on NAS if needed
ssh truenas_admin@$NAS_IP "sudo mkdir -p $NAS_PATH && sudo chown -R 568:568 $NAS_PATH" || {
    echo "⚠️  Could not create directory on NAS"
    echo "   Create manually:"
    echo "   ssh truenas_admin@$NAS_IP"
    echo "   sudo mkdir -p $NAS_PATH"
    echo "   sudo chown -R 568:568 $NAS_PATH"
    echo ""
    echo "   Or index from local temp directory: $TEMP_DIR"
    read -p "Continue with local indexing? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    INDEX_PATH="$TEMP_DIR"
} || {
    # Copy files
    scp "$JSONL_FILES" truenas_admin@$NAS_IP:$NAS_PATH/ || {
        echo "⚠️  Could not copy to NAS, will index from local"
        INDEX_PATH="$TEMP_DIR"
    } || {
        INDEX_PATH="$NAS_PATH"
    }
}

echo ""
echo "🔍 Starting indexing..."
echo "   Collection: wikipedia"
echo "   Limit: $LIMIT articles (for testing)"
echo ""

# Index using Python script
python3 "$SCRIPT_DIR/index_wikipedia.py" \
    --file "${INDEX_PATH:-$NAS_PATH}/$(basename $JSONL_FILES)" \
    --limit "$LIMIT" \
    --collection wikipedia

echo ""
echo "✅ Complete!"
echo ""
echo "To index more articles, run:"
echo "  python3 $SCRIPT_DIR/index_wikipedia.py \\"
echo "    --file $NAS_PATH/$(basename $JSONL_FILES) \\"
echo "    --collection wikipedia"
echo ""
echo "Temp files: $TEMP_DIR"
echo "Clean up with: rm -rf $TEMP_DIR"
