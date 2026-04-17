#!/bin/bash
# Quick status check for Wikipedia indexing

echo "📊 Indexing Status Check"
echo "========================"
echo ""

# Check if process is running
if pgrep -f "index_wikipedia.py" > /dev/null; then
    echo "✅ Indexing process is running"
    ps aux | grep "index_wikipedia.py" | grep -v grep | awk '{print "   PID: "$2" | CPU: "$3"% | Memory: "$4"%"}'
else
    echo "❌ Indexing process not running"
fi
echo ""

# Check current point count
CURRENT=$(curl -s http://192.168.0.158:6333/collections/wikipedia | python3 -c "import sys, json; print(json.load(sys.stdin)['result']['points_count'])" 2>/dev/null)
INITIAL=382
ADDED=$((CURRENT - INITIAL))

echo "📈 Collection Status:"
echo "   Initial points: $INITIAL"
echo "   Current points: $CURRENT"
echo "   New points added: $ADDED"
echo ""

# Estimate progress (if we know the limit)
if [ -f /tmp/wikipedia_indexing.log ]; then
    LIMIT=$(grep -o "limit.*1000" /tmp/wikipedia_indexing.log | head -1 | grep -o "[0-9]*" | head -1 || echo "1000")
    if [ -n "$LIMIT" ] && [ "$LIMIT" != "0" ]; then
        # Rough estimate: ~19 chunks per article (from test: 10 articles = 191 chunks)
        ESTIMATED_CHUNKS=$((LIMIT * 19))
        if [ "$ADDED" -gt 0 ]; then
            PROGRESS=$(echo "scale=1; $ADDED * 100 / $ESTIMATED_CHUNKS" | bc)
            echo "   Estimated progress: ~${PROGRESS}% (rough estimate)"
        fi
    fi
fi

echo ""
echo "💡 Monitor live: tail -f /tmp/wikipedia_indexing.log"
