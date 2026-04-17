#!/bin/bash
# Test if Qdrant container has curl or wget

echo "🔍 Testing Qdrant container healthcheck tools..."
echo ""

# Test if Qdrant responds
echo "1. Testing Qdrant HTTP endpoint:"
curl -f -s http://192.168.0.158:6333/ > /dev/null && echo "   ✅ Qdrant is responding" || echo "   ❌ Qdrant not responding"
echo ""

# The issue is likely that the container doesn't have curl
# Qdrant is a minimal container - it might only have wget or neither

echo "💡 Solution: Update healthcheck to use wget instead of curl"
echo ""
echo "Change this:"
echo "  test:"
echo "    - CMD"
echo "    - curl"
echo "    - '-f'"
echo "    - http://localhost:6333/"
echo ""
echo "To this:"
echo "  test:"
echo "    - CMD-SHELL"
echo "    - wget --no-verbose --tries=1 --spider http://localhost:6333/ || exit 1"
echo ""
echo "Or increase start_period to 30s and disable healthcheck if it still fails"
