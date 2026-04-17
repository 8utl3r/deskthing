#!/bin/bash
# Script to run the Factorio NPC controller with all prerequisites checked

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Factorio NPC Controller - Startup Check"
echo "========================================"
echo ""

# Check Python dependencies
echo "1. Checking Python dependencies..."
if ! python3 -c "import ollama" 2>/dev/null; then
    echo "   ❌ Missing: ollama"
    echo "   Install with: pip install -r requirements.txt"
    exit 1
fi

if ! python3 -c "import factorio_rcon" 2>/dev/null; then
    echo "   ❌ Missing: factorio_rcon"
    echo "   Install with: pip install -r requirements.txt"
    exit 1
fi
echo "   ✅ Python dependencies OK"

# Check Ollama is running
echo ""
echo "2. Checking Ollama connection..."
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo "   ❌ Ollama is not running"
    echo "   Start with: ollama serve"
    echo "   Or: brew services start ollama"
    exit 1
fi
echo "   ✅ Ollama is running"

# Check model is available
echo ""
echo "3. Checking Ollama model..."
MODEL=$(python3 -c "from config import OLLAMA_MODEL; print(OLLAMA_MODEL)" 2>/dev/null || echo "mistral")
if ! ollama list 2>/dev/null | grep -q "$MODEL"; then
    echo "   ⚠️  Model '$MODEL' not found"
    echo "   Available models:"
    ollama list 2>/dev/null | grep -v "^NAME" | awk '{print "     - " $1}'
    echo ""
    read -p "   Pull model '$MODEL' now? (y/n): " pull_model
    if [ "$pull_model" == "y" ]; then
        echo "   Pulling model..."
        ollama pull "$MODEL"
    else
        echo "   Please pull the model first: ollama pull $MODEL"
        exit 1
    fi
fi
echo "   ✅ Model '$MODEL' is available"

# Check RCON connection
echo ""
echo "4. Testing RCON connection..."
if ! python3 verify_rcon_password.py >/dev/null 2>&1; then
    echo "   ❌ RCON connection failed"
    echo "   Check config.py and verify Factorio server is running"
    exit 1
fi
echo "   ✅ RCON connection OK"

# Check config
echo ""
echo "5. Checking configuration..."
if ! python3 -c "from config import RCON_HOST, RCON_PASSWORD, OLLAMA_MODEL; assert RCON_PASSWORD, 'RCON_PASSWORD not set'" 2>/dev/null; then
    echo "   ❌ Configuration error"
    echo "   Check config.py has RCON_PASSWORD set"
    exit 1
fi
echo "   ✅ Configuration OK"

# All checks passed
echo ""
echo "========================================"
echo "✅ All checks passed!"
echo ""
echo "Starting NPC controller..."
echo "Press Ctrl+C to stop"
echo "========================================"
echo ""

# Run the controller
python3 factorio_ollama_npc_controller.py
