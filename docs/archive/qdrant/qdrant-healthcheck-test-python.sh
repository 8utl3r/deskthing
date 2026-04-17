#!/bin/bash
# Test Python healthcheck command for Qdrant

echo "🧪 Testing Python healthcheck for Qdrant..."
echo ""

# Test if Qdrant responds
echo "1. Testing Qdrant endpoint:"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.0.158:6333/)
if [ "$RESPONSE" = "200" ]; then
    echo "   ✅ Qdrant is responding (HTTP $RESPONSE)"
else
    echo "   ❌ Qdrant not responding (HTTP $RESPONSE)"
fi
echo ""

# Show the Python command that will be used
echo "2. Python healthcheck command:"
echo "   python3 -c 'import http.client; conn = http.client.HTTPConnection(\"localhost\", 6333); conn.request(\"GET\", \"/\"); res = conn.getresponse(); exit(0) if res.status == 200 else exit(1)'"
echo ""

echo "💡 This command will be run INSIDE the Qdrant container"
echo "   If Python isn't available, use the no-healthcheck YAML instead"
echo ""
