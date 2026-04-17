#!/bin/bash
# Verify Qdrant data after reinstall

echo "🔍 Verifying Qdrant after reinstall..."
echo ""

# Wait a moment for Qdrant to start
sleep 5

# Check health
echo "1. Health check:"
curl -s http://192.168.0.158:6333/ | python3 -m json.tool | head -5
echo ""

# List collections
echo "2. Collections:"
curl -s http://192.168.0.158:6333/collections | python3 -m json.tool
echo ""

# Check Wikipedia collection
echo "3. Wikipedia collection status:"
curl -s http://192.168.0.158:6333/collections/wikipedia | python3 -m json.tool | grep -E "(points_count|status)"
echo ""

echo "✅ If you see your collections and point counts, your data is safe!"
