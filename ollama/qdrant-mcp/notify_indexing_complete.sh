#!/bin/bash
# Monitor Wikipedia indexing and notify when complete

LOG_FILE="${1:-/tmp/wikipedia_indexing.log}"
COLLECTION="${2:-wikipedia}"
CHECK_INTERVAL=10  # Check every 10 seconds

echo "🔔 Starting indexing monitor..."
echo "   Log file: $LOG_FILE"
echo "   Collection: $COLLECTION"
echo "   Check interval: ${CHECK_INTERVAL}s"
echo ""
echo "Press Ctrl+C to stop monitoring"
echo ""

# Get initial point count
INITIAL=$(curl -s http://192.168.0.158:6333/collections/$COLLECTION 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin)['result']['points_count'])" 2>/dev/null || echo "0")
echo "📊 Initial points: $INITIAL"
echo ""

# Monitor loop
LAST_CHECK=0
while true; do
    # Check if process is still running
    if ! pgrep -f "index_wikipedia.py" > /dev/null; then
        # Process stopped - wait a moment for log to flush
        sleep 2
        
        # Check if it completed successfully
        if grep -q "✅ Complete!" "$LOG_FILE" 2>/dev/null; then
            # Get final stats
            FINAL=$(curl -s http://192.168.0.158:6333/collections/$COLLECTION 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin)['result']['points_count'])" 2>/dev/null || echo "0")
            ADDED=$((FINAL - INITIAL))
            
            # Extract completion info from log
            ARTICLES=$(grep "Articles processed:" "$LOG_FILE" | tail -1 | grep -o "[0-9]*" | head -1 || echo "?")
            CHUNKS=$(grep "Chunks indexed:" "$LOG_FILE" | tail -1 | grep -o "[0-9]*" | head -1 || echo "?")
            
            # Send notification
            osascript -e "display notification \"Indexed $ARTICLES articles ($CHUNKS chunks, $ADDED new points)\" with title \"✅ Wikipedia Indexing Complete\" sound name \"Glass\""
            
            echo ""
            echo "✅ Indexing Complete!"
            echo "   Articles processed: $ARTICLES"
            echo "   Chunks indexed: $CHUNKS"
            echo "   Points added: $ADDED"
            echo "   Total points: $FINAL"
            echo ""
            echo "📋 Full summary:"
            grep -A 5 "✅ Complete!" "$LOG_FILE" | tail -5
            
            exit 0
        else
            # Process stopped but didn't complete - might have errored
            osascript -e "display notification \"Indexing process stopped unexpectedly. Check logs.\" with title \"⚠️ Wikipedia Indexing Stopped\" sound name \"Basso\""
            echo ""
            echo "⚠️ Process stopped but didn't complete successfully"
            echo "   Check log: $LOG_FILE"
            tail -20 "$LOG_FILE"
            exit 1
        fi
    fi
    
    # Check if completion message appeared (process might still be running but done)
    if grep -q "✅ Complete!" "$LOG_FILE" 2>/dev/null && [ $LAST_CHECK -eq 0 ]; then
        LAST_CHECK=1
        # Wait a moment for process to fully exit
        sleep 3
        if ! pgrep -f "index_wikipedia.py" > /dev/null; then
            # Process finished - trigger completion
            continue
        fi
    fi
    
    # Still running - show progress
    CURRENT=$(curl -s http://192.168.0.158:6333/collections/$COLLECTION 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin)['result']['points_count'])" 2>/dev/null || echo "0")
    ADDED=$((CURRENT - INITIAL))
    
    # Show progress every minute (6 checks)
    if [ $((SECONDS % 60)) -lt $CHECK_INTERVAL ]; then
        echo "[$(date +%H:%M:%S)] Still indexing... Points: $CURRENT (+$ADDED)"
    fi
    
    sleep $CHECK_INTERVAL
done
