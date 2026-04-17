#!/bin/bash
# Complete Wikipedia download and indexing workflow

set -e

NAS_IP="${NAS_IP:-192.168.0.158}"
NAS_PATH="${NAS_PATH:-/mnt/tank/apps/qdrant/wikipedia}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIMIT="${LIMIT:-1000}"  # Start with 1000 articles for testing

echo "🚀 Wikipedia Download and Indexing Workflow"
echo "=========================================="
echo ""

# Step 1: Create directory on NAS
echo "📁 Step 1: Creating directory on NAS..."
echo "   Path: $NAS_PATH"
echo "   Note: You may need to create this manually in TrueNAS if permissions require it"
echo ""

# Step 2: Download options
echo "📥 Step 2: Choose download method:"
echo ""
echo "Option A: Google Drive (requires manual download)"
echo "   URL: https://drive.google.com/file/d/1tuHFrfRQJvYVh3QlEaAJleF05DIukuWP/view"
echo "   Size: 3GB compressed, 16GB uncompressed"
echo "   Format: Individual .txt files (~4.7M articles)"
echo ""
echo "Option B: Use MCP tool to download (if available)"
echo ""
echo "Option C: Download smaller subset for testing"
echo ""

# For now, let's create a script that uses the MCP tool
echo "💡 Recommended: Use the Qdrant MCP tools to index Wikipedia"
echo ""
echo "After downloading Wikipedia, you can index it using:"
echo ""
echo "  python3 $SCRIPT_DIR/index_wikipedia.py \\"
echo "    --dir <path-to-wikipedia-files> \\"
echo "    --limit $LIMIT \\"
echo "    --collection wikipedia"
echo ""
echo "Or use MCP tools in Cursor:"
echo "  'Index Wikipedia articles from /path/to/files'"
echo ""

# Check if directory exists
if ssh truenas_admin@$NAS_IP "test -d $NAS_PATH" 2>/dev/null; then
    echo "✅ Directory exists on NAS"
else
    echo "⚠️  Directory doesn't exist. Create it manually:"
    echo "   ssh truenas_admin@$NAS_IP"
    echo "   sudo mkdir -p $NAS_PATH"
    echo "   sudo chown -R 568:568 $NAS_PATH"
fi

echo ""
echo "Next: Download Wikipedia and run indexing script"
