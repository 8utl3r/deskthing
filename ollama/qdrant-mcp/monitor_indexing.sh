#!/bin/bash
# Monitor Wikipedia indexing progress

LOG_FILE="${1:-/tmp/wikipedia_indexing.log}"
COLLECTION="${2:-wikipedia}"

echo "📊 Wikipedia Indexing Monitor"
echo "============================"
echo ""

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ Log file not found: $LOG_FILE"
    exit 1
fi

# Get current progress from log
echo "📝 Latest progress from log:"
tail -5 "$LOG_FILE" | grep -E "(Progress|Complete|articles|chunks)" || echo "  (No progress lines yet)"
echo ""

# Check Qdrant collection status
echo "🔍 Current Qdrant collection status:"
curl -s http://192.168.0.158:6333/collections/$COLLECTION | python3 -m json.tool | grep -E "(points_count|status)" | head -2
echo ""

# Estimate time remaining (rough)
LAST_PROGRESS=$(tail -100 "$LOG_FILE" | grep "Progress:" | tail -1)
if [ -n "$LAST_PROGRESS" ]; then
    echo "📈 Last progress update:"
    echo "  $LAST_PROGRESS"
fi

echo ""
echo "💡 To watch live: tail -f $LOG_FILE"
