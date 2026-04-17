#!/bin/bash
# Show summary of completed indexing

LOG_FILE="${1:-/tmp/wikipedia_indexing.log}"
COLLECTION="${2:-wikipedia}"

echo "📊 Wikipedia Indexing Summary"
echo "============================="
echo ""

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ Log file not found: $LOG_FILE"
    exit 1
fi

# Check if completed
if grep -q "✅ Complete!" "$LOG_FILE"; then
    echo "✅ Status: COMPLETED"
    echo ""
    
    # Extract completion info
    COMPLETE_LINE=$(grep "✅ Complete!" "$LOG_FILE" | tail -1)
    COMPLETE_TIME=$(echo "$COMPLETE_LINE" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}" | head -1)
    
    ARTICLES=$(grep "Articles processed:" "$LOG_FILE" | tail -1 | sed 's/.*Articles processed: \([0-9]*\).*/\1/')
    CHUNKS=$(grep "Chunks indexed:" "$LOG_FILE" | tail -1 | sed 's/.*Chunks indexed: \([0-9]*\).*/\1/')
    
    # Get current point count
    CURRENT=$(curl -s http://192.168.0.158:6333/collections/$COLLECTION 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin)['result']['points_count'])" 2>/dev/null || echo "?")
    
    echo "📅 Completed: $COMPLETE_TIME"
    echo "📚 Articles processed: $ARTICLES"
    echo "📝 Chunks indexed: $CHUNKS"
    echo "🔢 Total points in collection: $CURRENT"
    echo ""
    
    # Show last few progress updates
    echo "📈 Progress updates:"
    grep "Progress:" "$LOG_FILE" | tail -3 | sed 's/.*Progress: /   /'
    echo ""
    
    echo "📋 Full completion log:"
    grep -A 5 "✅ Complete!" "$LOG_FILE" | tail -5 | sed 's/.*INFO - /   /'
    
else
    echo "⏳ Status: IN PROGRESS or NOT STARTED"
    echo ""
    
    # Check if process is running
    if pgrep -f "index_wikipedia.py" > /dev/null; then
        echo "✅ Indexing process is currently running"
        CURRENT=$(curl -s http://192.168.0.158:6333/collections/$COLLECTION 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin)['result']['points_count'])" 2>/dev/null || echo "?")
        echo "   Current points: $CURRENT"
    else
        echo "❌ No indexing process found"
    fi
    
    echo ""
    echo "Last log entries:"
    tail -5 "$LOG_FILE" | sed 's/.*INFO - /   /'
fi
