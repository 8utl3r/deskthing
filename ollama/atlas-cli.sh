#!/bin/bash
# Lightweight CLI interface for Atlas
# Uses Atlas Proxy API (no Docker required)
# Usage: atlas-cli "your prompt" or atlas-cli (interactive)

ATLAS_PROXY="http://localhost:11435"
PROMPT="${1:-}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if proxy is running
if ! curl -s "${ATLAS_PROXY}/api/tags" >/dev/null 2>&1; then
    echo "❌ Atlas Proxy not running on ${ATLAS_PROXY}"
    echo "   Start it with: atlas-proxy-start"
    exit 1
fi

# Interactive mode
if [ -z "$PROMPT" ]; then
    echo -e "${BLUE}Atlas CLI${NC} - Type 'exit' or 'quit' to end, 'help' for commands"
    echo ""
    
    while true; do
        echo -ne "${GREEN}You:${NC} "
        read -r PROMPT
        
        if [ -z "$PROMPT" ]; then
            continue
        fi
        
        case "$PROMPT" in
            exit|quit|q)
                echo "Goodbye!"
                exit 0
                ;;
            help|h)
                echo ""
                echo "Commands:"
                echo "  exit/quit/q  - Exit Atlas CLI"
                echo "  help/h       - Show this help"
                echo "  vars         - Show stored variables"
                echo "  files        - List files in data/files/"
                echo ""
                echo "File operations (Atlas will execute automatically):"
                echo "  Create: 'Create file notes/test.md with content...'"
                echo "  Read: 'Read notes/test.md'"
                echo "  Update: 'Update notes/test.md with...'"
                echo ""
                continue
                ;;
            vars)
                echo -e "${YELLOW}Fetching variables...${NC}"
                curl -s "${ATLAS_PROXY}/api/variables" 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "No variables stored"
                echo ""
                continue
                ;;
            files)
                echo -e "${YELLOW}Listing files...${NC}"
                find ~/dotfiles/ollama/proxy/data/files -type f 2>/dev/null | sed "s|${HOME}/dotfiles/ollama/proxy/data/files/||" | head -20
                echo ""
                continue
                ;;
        esac
        
        # Send to Atlas via proxy (using /api/chat for context injection)
        echo -ne "${BLUE}Atlas:${NC} "
        
        # Build messages array for conversation history
        # For now, just send current prompt (conversation history could be added later)
        curl -s -X POST "${ATLAS_PROXY}/api/chat" \
            -H "Content-Type: application/json" \
            -d "{
                \"model\": \"atlas\",
                \"messages\": [{\"role\": \"user\", \"content\": \"${PROMPT}\"}],
                \"stream\": true
            }" | python3 -c "
import sys
import json

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        # Parse JSON line (format: {"model":"atlas","message":{"role":"assistant","content":"text"},"done":false})
        data = json.loads(line)
        if 'message' in data and 'content' in data['message']:
            print(data['message']['content'], end='', flush=True)
    except json.JSONDecodeError:
        # Try SSE format as fallback
        if line.startswith('data: '):
            try:
                data = json.loads(line[6:])
                if 'message' in data and 'content' in data['message']:
                    print(data['message']['content'], end='', flush=True)
            except:
                pass
    except:
        pass
" 2>/dev/null
        echo ""
        echo ""
    done
else
    # Single prompt mode (using /api/chat for context injection)
    curl -s -X POST "${ATLAS_PROXY}/api/chat" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"atlas\",
            \"messages\": [{\"role\": \"user\", \"content\": \"${PROMPT}\"}],
            \"stream\": false
        }" | python3 -c "
import sys
import json

data = json.load(sys.stdin)
# Extract response from chat format
if 'message' in data and 'content' in data['message']:
    print(data['message']['content'])
elif 'response' in data:
    print(data['response'])
" 2>/dev/null
fi
