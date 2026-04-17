#!/bin/bash
# Start Wikipedia indexing with automatic notifications

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIMIT="${1:-1000}"
LOG_FILE="/tmp/wikipedia_indexing.log"

echo "🚀 Starting Wikipedia Indexing"
echo "================================"
echo "   Limit: $LIMIT articles"
echo "   Log: $LOG_FILE"
echo ""

# Start indexing in background
echo "📝 Starting indexing process..."
cd "$SCRIPT_DIR"
python3 index_wikipedia.py \
    --dir /tmp/wikipedia_download_73499/extracted \
    --limit "$LIMIT" \
    --collection wikipedia \
    2>&1 | tee "$LOG_FILE" &

INDEXING_PID=$!
echo "   Process ID: $INDEXING_PID"
echo ""

# Start notification monitor in background
echo "🔔 Starting notification monitor..."
"$SCRIPT_DIR/notify_indexing_complete.sh" "$LOG_FILE" wikipedia &
MONITOR_PID=$!
echo "   Monitor PID: $MONITOR_PID"
echo ""

echo "✅ Indexing started!"
echo ""
echo "📊 Monitor progress:"
echo "   tail -f $LOG_FILE"
echo ""
echo "📈 Quick status:"
echo "   $SCRIPT_DIR/check_indexing_status.sh"
echo ""
echo "⏹️  Stop indexing:"
echo "   kill $INDEXING_PID"
echo ""
echo "💡 You'll get a notification when indexing completes!"

# Wait for indexing to complete
wait $INDEXING_PID
INDEXING_EXIT=$?

# Stop monitor (it will exit on its own, but just in case)
kill $MONITOR_PID 2>/dev/null

exit $INDEXING_EXIT
