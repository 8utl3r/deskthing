# Factorio + Ollama NPC System - Implementation Summary

## Overview

System to run LLM-controlled NPCs in Factorio using:
- **FV Embodied Agent** mod (Factorio mod for NPC control)
- **Ollama** (local LLM runner)
- **Python controller** (connects LLM to Factorio via RCON)

## Architecture

```
Ollama (Local LLM) ←→ Python Controller ←→ Factorio RCON ←→ FV Embodied Agent Mod ←→ NPCs
```

## Components

### 1. Factorio Server
- **Type**: Headless server (Docker recommended)
- **Mod Required**: FV Embodied Agent (https://mods.factorio.com/mod/fv_embodied_agent)
- **RCON**: Must be enabled for external control
- **Ports**: 
  - 34197/udp (game)
  - 27015/tcp (RCON)

### 2. Ollama
- **Purpose**: Local LLM inference (no API costs)
- **Models**: llama3.1, mistral, qwen2.5:7b, phi3:medium
- **API**: http://localhost:11434/api/chat
- **Python Library**: `ollama` package

### 3. Python Controller
- **Purpose**: Bridge between Ollama and Factorio
- **Dependencies**: `ollama`, `factorio-rcon-py`
- **Features**:
  - Create/manage multiple NPCs
  - Observe-act loop per NPC
  - Conversation history per NPC
  - JSON-structured LLM responses

## Installation Steps

### Factorio Server Setup

1. **Install Factorio headless server**
   - Download from factorio.com
   - Or use Docker: `goofball222/factorio`

2. **Install FV Embodied Agent mod**
   - Download from mod portal
   - Place in `~/.factorio/mods/` or Docker volume
   - Enable in mod settings

3. **Configure RCON**
   - Edit server config or Docker env vars:
     ```
     enable-rcon=true
     rcon-port=27015
     rcon-password=<secure_password>
     ```

### Ollama Setup

```bash
# Install Ollama
brew install ollama  # macOS
# or download from ollama.com

# Start service
ollama serve

# Pull a model
ollama pull llama3.1
```

### Python Controller Setup

```bash
# Install dependencies
pip install ollama factorio-rcon-py

# Files needed:
# - factorio_ollama_npc_controller.py (main controller)
# - requirements.txt (dependencies)
```

## Configuration

### Controller Configuration
```python
RCON_HOST = "localhost"  # or NAS IP
RCON_PORT = 27015
RCON_PASSWORD = "your_password"
OLLAMA_MODEL = "llama3.1"
```

### NPC System Prompts
Customize per NPC type:
- **Miner**: Focus on resource gathering
- **Builder**: Focus on construction
- **Explorer**: Focus on discovery

## File Structure

```
factorio-npc-system/
├── factorio_ollama_npc_controller.py  # Main controller
├── requirements.txt                    # Python deps
├── config.py                          # Configuration
└── README.md                          # Setup instructions
```

## Key Remote Interface Commands (FV Embodied Agent)

**Agent Management:**
- `create_agent(agent_id, position, force)` - Create NPC
- `remove_agent(agent_id)` - Remove NPC
- `get_agent_state(agent_id)` - Get NPC state

**Actions:**
- `walk_to(agent_id, position)` - Move (async)
- `mine_resource(agent_id, position)` - Mine (async)
- `craft_enqueue(agent_id, recipe, count)` - Craft (async)
- `place_entity(agent_id, entity_name, position)` - Build (sync)
- `set_entity_recipe(agent_id, entity, recipe)` - Configure (sync)

## Usage Example

```python
from factorio_ollama_npc_controller import FactorioNPCController

controller = FactorioNPCController(
    rcon_host="nas.local",
    rcon_port=27015,
    rcon_password="password",
    ollama_model="llama3.1"
)

# Create NPC
controller.create_npc("miner_bob", position=(10, 10))

# Run control loop
controller.run_npc_loop("miner_bob", interval=5.0)
```

## Docker Compose Example (Factorio Server)

```yaml
version: '3'
services:
  factorio:
    image: goofball222/factorio
    container_name: factorio
    restart: unless-stopped
    ports:
      - "27015:27015"      # RCON
      - "34197:34197/udp"   # Game
    volumes:
      - ./factorio:/factorio
    environment:
      - FACTORIO_RCON_PASSWORD=your_password
```

## Key Features

- ✅ Multi-NPC support (unique IDs, independent control)
- ✅ Persistent state (NPCs survive game sessions)
- ✅ Async actions (non-blocking operations)
- ✅ Local LLM (no API costs, privacy)
- ✅ JSON-structured responses
- ✅ Conversation history per NPC
- ✅ Customizable NPC personalities

## Resources

- **FV Embodied Agent**: https://mods.factorio.com/mod/fv_embodied_agent
- **Factorio Lua API**: https://lua-api.factorio.com/
- **Ollama**: https://ollama.com/
- **Ollama API Docs**: https://docs.ollama.com/api
- **Factorio Docker**: https://hub.docker.com/r/goofball222/factorio
- **Python RCON**: `factorio-rcon-py` package

## Implementation Checklist

- [ ] Set up Factorio headless server (Docker or native)
- [ ] Install FV Embodied Agent mod
- [ ] Configure RCON (port, password)
- [ ] Install Ollama and pull model
- [ ] Install Python dependencies
- [ ] Create controller script
- [ ] Test RCON connection
- [ ] Test Ollama connection
- [ ] Create first NPC
- [ ] Run observe-act loop
- [ ] Customize NPC personalities
- [ ] Scale to multiple NPCs

## Notes

- **Architecture Requirement**: Factorio needs x86_64 CPU (not ARM)
- **NAS Consideration**: Check if NAS has x86_64 CPU or use Docker with platform emulation
- **Performance**: Larger models (7B+) give better decisions but slower responses
- **Decision Interval**: 5-10 seconds recommended for most NPCs
- **Context Management**: Keep conversation history limited (last 5-10 messages)
