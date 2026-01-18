#!/bin/bash
# Setup script for Open WebUI to work with Atlas Proxy

set -e

echo "🚀 Setting up Open WebUI for Atlas Proxy..."

# Check if Docker is running
if ! docker ps >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    echo "   Run: open -a Docker"
    exit 1
fi

echo "✅ Docker is running"

# Check if container already exists
if docker ps -a | grep -q open-webui; then
    echo "📦 Open WebUI container exists"
    if docker ps | grep -q open-webui; then
        echo "✅ Open WebUI is already running"
    else
        echo "🔄 Starting existing Open WebUI container..."
        docker start open-webui
    fi
else
    echo "📥 Pulling Open WebUI image and creating container..."
    docker run -d \
        -p 3000:8080 \
        --add-host=host.docker.internal:host-gateway \
        -v open-webui:/app/backend/data \
        --name open-webui \
        --restart always \
        --memory="2g" \
        --memory-swap="2g" \
        --cpus="1.0" \
        -e RAG_EMBEDDING_ENGINE=ollama \
        -e AUDIO_STT_ENGINE=openai \
        ghcr.io/open-webui/open-webui:main
fi

echo ""
echo "⏳ Waiting for Open WebUI to start (this may take 30-60 seconds)..."
sleep 10

# Wait for it to be ready
for i in {1..30}; do
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        echo "✅ Open WebUI is ready!"
        break
    fi
    sleep 2
done

echo ""
echo "✅ Container status:"
docker ps | grep open-webui
echo ""
echo "📝 Configuration Steps:"
echo "   1. Open http://localhost:3000 in your browser"
echo "   2. Create an account (first user becomes admin)"
echo "   3. Go to Settings → Connection"
echo "   4. Set 'Ollama Base URL' to: http://host.docker.internal:11435"
echo "   5. Save and start chatting with Atlas!"
echo ""
echo "✅ Setup complete!"
