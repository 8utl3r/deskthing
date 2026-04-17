#!/bin/bash
# Qdrant MCP Server Setup Script

set -e

echo "🚀 Setting up Qdrant MCP Server..."

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found"
    exit 1
fi

echo "✓ Python 3 found"

# Install dependencies
echo "📦 Installing dependencies..."
pip3 install -r requirements.txt

echo "✓ Dependencies installed"

# Check Ollama embedding model
echo "🔍 Checking embedding model..."
if ollama list | grep -q "nomic-embed-text"; then
    echo "✓ Embedding model installed"
else
    echo "⚠️  Embedding model not found. Installing..."
    ollama pull nomic-embed-text
    echo "✓ Embedding model installed"
fi

# Test Qdrant connection
echo "🔍 Testing Qdrant connection..."
if curl -s http://192.168.0.158:6333/health | grep -q "ok"; then
    echo "✓ Qdrant connection successful"
else
    echo "⚠️  Qdrant connection failed. Check if Qdrant is running on TrueNAS."
fi

# Make server executable
chmod +x qdrant_mcp_server.py
echo "✓ Server script is executable"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Restart Cursor IDE to load MCP server"
echo "2. Test tools in Cursor chat"
echo ""
echo "Configuration:"
echo "  Qdrant URL: http://192.168.0.158:6333"
echo "  Ollama URL: http://localhost:11434"
echo "  Embedding Model: nomic-embed-text"
echo "  Collection: atlas_conversations"
