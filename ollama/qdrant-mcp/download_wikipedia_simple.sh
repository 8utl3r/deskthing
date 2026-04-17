#!/bin/bash
# Download Simple English Wikipedia (smaller test set) and index into Qdrant

set -e

NAS_IP="${NAS_IP:-192.168.0.158}"
NAS_PATH="${NAS_PATH:-/mnt/tank/apps/qdrant/wikipedia}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIMIT="${LIMIT:-1000}"  # Start with 1000 articles for testing

echo "🚀 Wikipedia Download and Indexing (Simple English - Test Set)"
echo "=============================================================="
echo ""
echo "This downloads Simple English Wikipedia (~1GB) as a test set."
echo "After testing, you can download full English Wikipedia."
echo ""

# Create directory on NAS
echo "📁 Creating directory on NAS..."
echo "   Path: $NAS_PATH"
echo ""

# Note: We'll download to local temp first, then copy to NAS
TEMP_DIR="/tmp/wikipedia_download_$$"
mkdir -p "$TEMP_DIR"
echo "📁 Using temp directory: $TEMP_DIR"
echo ""

# Download Simple English Wikipedia XML dump
echo "📥 Downloading Simple English Wikipedia..."
echo "   This is a smaller test set (~1GB compressed)"
echo ""

SIMPLE_WIKI_URL="https://dumps.wikimedia.org/simplewiki/latest/simplewiki-latest-pages-articles.xml.bz2"
cd "$TEMP_DIR"

echo "Downloading: $SIMPLE_WIKI_URL"
curl -L -C - -o simplewiki.xml.bz2 "$SIMPLE_WIKI_URL" || {
    echo "❌ Download failed"
    exit 1
}

echo ""
echo "📦 Extracting XML dump..."
echo "   This requires wikiextractor (will install if needed)"
echo ""

# Check for wikiextractor
if ! command -v wikiextractor &> /dev/null; then
    echo "Installing wikiextractor..."
    pip3 install wikiextractor --user || {
        echo "⚠️  Could not install wikiextractor"
        echo "   Install manually: pip3 install wikiextractor"
        exit 1
    }
fi

# Extract to text files
mkdir -p extracted
wikiextractor -o extracted --no-templates --no-style --no-doc --no-lists simplewiki.xml.bz2 || {
    echo "⚠️  Extraction failed, trying alternative method..."
    # Alternative: use Python script
    python3 -c "
import bz2
import xml.etree.ElementTree as ET
import os

os.makedirs('extracted', exist_ok=True)
with bz2.open('simplewiki.xml.bz2', 'rt', encoding='utf-8') as f:
    for event, elem in ET.iterparse(f, events=('end',)):
        if elem.tag.endswith('text'):
            title = elem.getparent().find('{http://www.mediawiki.org/xml/export-0.10/}title')
            if title is not None:
                title_text = title.text or 'Untitled'
                safe_title = title_text.replace('/', '_').replace('\\', '_')
                with open(f'extracted/{safe_title}.txt', 'w', encoding='utf-8') as out:
                    out.write(elem.text or '')
            elem.clear()
" || {
        echo "❌ Extraction failed"
        exit 1
    }
}

echo ""
echo "✅ Extraction complete"
echo ""

# Find extracted files
TXT_COUNT=$(find extracted -name "*.txt" | wc -l)
if [ "$TXT_COUNT" -eq 0 ]; then
    echo "❌ No text files extracted"
    exit 1
fi

echo "Found $TXT_COUNT text files"
echo ""

# Copy to NAS
echo "📤 Copying to NAS..."
echo "   Target: $NAS_PATH"
echo ""

# Try to create directory on NAS
ssh truenas_admin@$NAS_IP "sudo mkdir -p $NAS_PATH && sudo chown -R 568:568 $NAS_PATH" 2>/dev/null || {
    echo "⚠️  Could not create directory on NAS automatically"
    echo "   Create manually:"
    echo "   ssh truenas_admin@$NAS_IP"
    echo "   sudo mkdir -p $NAS_PATH"
    echo "   sudo chown -R 568:568 $NAS_PATH"
    echo ""
    read -p "Continue with local indexing? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    INDEX_PATH="$TEMP_DIR/extracted"
} || {
    # Copy files
    echo "Copying files to NAS..."
    rsync -avz --progress extracted/ truenas_admin@$NAS_IP:$NAS_PATH/ || {
        echo "⚠️  Could not copy to NAS, will index from local"
        INDEX_PATH="$TEMP_DIR/extracted"
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
    --dir "${INDEX_PATH:-$NAS_PATH}" \
    --limit "$LIMIT" \
    --collection wikipedia

echo ""
echo "✅ Complete!"
echo ""
echo "To index more articles, run:"
echo "  python3 $SCRIPT_DIR/index_wikipedia.py \\"
echo "    --dir $NAS_PATH \\"
echo "    --collection wikipedia"
echo ""
echo "Temp files: $TEMP_DIR"
echo "Clean up with: rm -rf $TEMP_DIR"
