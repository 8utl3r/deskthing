# Factorio AI Automation - Feature Comparison Matrix

## Terminology Note
- **Table**: A structured grid of rows and columns showing data
- **Chart**: A visual representation (bar chart, line graph, etc.) - often used interchangeably with "table" in casual conversation
- **Matrix**: A specific type of table where each cell represents a relationship/value between row and column categories - perfect for feature comparisons

## Feature Comparison Matrix

| Feature | FV Embodied Agent | Factorio Ember Autopilot | factorio-automation | factorio-ai-bot | factorio-bot | Custom Mod |
|---------|-------------------|-------------------------|---------------------|-----------------|--------------|------------|
| **Type** | Mod (Lua) | Framework (Lua) | Mod (Lua) | External Bot (C++) | External Bot (Rust/Tauri) | Mod (Lua) |
| **Multi-Agent Support** | ✅ Yes (unique IDs) | ❓ Unknown | ❓ Unknown | ❌ No (single bot) | ❓ Unknown | ⚙️ Customizable |
| **Movement Control** | ✅ `walk_to()` with pathfinding | ❓ Unknown | ✅ `walk_to_entity()` | ✅ WASD simulation | ❓ Unknown | ⚙️ Customizable |
| **Mining** | ✅ `mine_resource()` async | ❓ Unknown | ✅ `mine_entity()` | ✅ Auto-mining (5 tile range) | ❓ Unknown | ⚙️ Customizable |
| **Crafting** | ✅ `craft_enqueue()` | ❓ Unknown | ✅ `craft_item()` | ❌ No | ❓ Unknown | ⚙️ Customizable |
| **Building/Placement** | ✅ `place_entity()` sync | ❓ Unknown | ✅ `place_entity()` | ❌ No | ❓ Unknown | ⚙️ Customizable |
| **Machine Configuration** | ✅ `set_entity_recipe()`, `set_entity_filter()` | ❓ Unknown | ❌ No | ❌ No | ❓ Unknown | ⚙️ Customizable |
| **Research** | ❌ No | ❓ Unknown | ✅ `research_technology()` | ❌ No | ❓ Unknown | ⚙️ Customizable |
| **Combat** | ❌ No | ❓ Unknown | ✅ `attack_nearest_enemy()` | ❌ No | ❓ Unknown | ⚙️ Customizable |
| **Inventory Management** | ✅ `set_inventory_limit()` | ❓ Unknown | ✅ `place_item_in_chest()`, `pick_up_item()` | ❌ No | ❓ Unknown | ⚙️ Customizable |
| **External API** | ✅ Remote Interface (RCON) | ❓ Unknown | ✅ Remote Interface | ❌ No (reads logs) | ❓ Unknown | ⚙️ Customizable |
| **Headless Server** | ✅ Yes | ❓ Unknown | ✅ Yes | ❌ No (requires GUI) | ❓ Unknown | ⚙️ Customizable |
| **Computer Vision** | ❌ No | ❓ Unknown | ❌ No | ✅ OpenCV template matching | ❓ Unknown | ❌ No |
| **Log File Reading** | ❌ No | ❓ Unknown | ❌ No | ✅ Yes (position/resources) | ❓ Unknown | ❌ No |
| **Hot Reload Support** | ✅ Yes (agent survival) | ❓ Unknown | ❓ Unknown | ❌ No | ❓ Unknown | ⚙️ Customizable |
| **Persistent State** | ✅ Yes (metatable) | ❓ Unknown | ❓ Unknown | ❌ No | ❓ Unknown | ⚙️ Customizable |
| **Async Actions** | ✅ Yes (UDP completion) | ❓ Unknown | ❓ Unknown | ❌ No | ❓ Unknown | ⚙️ Customizable |
| **Pathfinding** | ✅ Built-in | ❓ Unknown | ❓ Unknown | ❌ No | ❓ Unknown | ⚙️ Customizable |
| **Documentation** | ✅ Mod portal | ❓ Limited | ❓ GitHub | ❓ GitHub | ❓ GitHub | ⚙️ Self-document |
| **Active Maintenance** | ✅ Yes (v0.1.3, Factorio 2.0) | ❓ Unknown | ❓ Unknown | ❓ Unknown | ❓ Unknown | ⚙️ Self-maintained |
| **License** | ✅ MIT | ❓ Unknown | ❓ Unknown | ❓ Unknown | ❓ Unknown | ⚙️ Your choice |
| **Learning Curve** | 🟢 Medium | 🟡 Unknown | 🟢 Medium | 🔴 High (C++/OpenCV) | 🟡 Unknown | 🔴 High (Lua API) |
| **Best For** | LLM agents, research | AI experiments | General automation | Computer vision research | Desktop automation | Full control |

## Feature Categories

### Core Capabilities
- **Movement**: Ability to move agents/characters
- **Mining**: Extract resources from the world
- **Crafting**: Create items from recipes
- **Building**: Place entities/buildings
- **Research**: Unlock technologies

### Advanced Features
- **Multi-Agent**: Support multiple agents simultaneously
- **Pathfinding**: Automatic route calculation
- **Async Actions**: Non-blocking operations
- **Machine Config**: Configure assemblers, inserters, etc.

### Integration
- **External API**: Can be controlled from outside Factorio
- **Headless Server**: Works without GUI
- **Computer Vision**: Visual detection capabilities
- **Log Reading**: Parse game logs for state

### Reliability
- **Hot Reload**: Survives mod reloads
- **Persistent State**: Saves agent state
- **Active Maintenance**: Currently maintained

## Recommendations by Use Case

### 🤖 LLM/AI Agent Research
**Best: FV Embodied Agent**
- Full remote interface for external control
- Multi-agent support
- Async actions with completion callbacks
- Well-documented and maintained

### 👥 LLM-Controlled NPCs (Multiple NPCs)
**Best: FV Embodied Agent** ⭐ **RECOMMENDED FOR YOUR USE CASE**
- ✅ **Multi-agent support** with unique IDs - create multiple NPCs
- ✅ **Remote interface** via RCON - connect LLMs/scripts externally
- ✅ **Persistent state** - NPCs survive game sessions
- ✅ **Async actions** - perfect for LLM decision-making loops
- ✅ **Individual control** - each NPC can be controlled independently
- ✅ **Proven implementation** - Factorio-LLM-Testing project demonstrates this exact use case

**Real-World Example**: The [Factorio-LLM-Testing](https://josh2sing.github.io/Factorio-LLM-Testing/) project successfully uses this approach:
- Java program sends prompts to OpenAI API
- Commands parsed and sent to Factorio via RCON
- Game state returned to inform next LLM decision
- Custom DSL for command abstraction

### 🏭 Factory Automation
**Best: factorio-automation**
- Comprehensive action set
- Research and combat support
- Good for general automation tasks

### 👁️ Computer Vision Research
**Best: factorio-ai-bot**
- OpenCV integration
- Screen capture and template matching
- Hybrid log + vision approach

### 🎯 Full Custom Control
**Best: Custom Mod**
- Complete control over all features
- Can combine best parts of other mods
- Requires Lua API knowledge

## Implementation Complexity

| Approach | Setup Time | Maintenance | Flexibility | External Integration |
|----------|------------|-------------|-------------|---------------------|
| FV Embodied Agent | 🟢 Low | 🟢 Low | 🟡 Medium | 🟢 Easy (RCON) |
| factorio-automation | 🟢 Low | 🟢 Low | 🟡 Medium | 🟢 Easy (Remote) |
| factorio-ai-bot | 🔴 High | 🔴 High | 🔴 Low | 🔴 Hard (GUI only) |
| Custom Mod | 🔴 High | 🔴 High | 🟢 High | 🟡 Medium |

## Notes

- ❌ = Not supported
- ✅ = Supported
- ❓ = Unknown/Unclear from available documentation
- ⚙️ = Customizable/Implementable
- 🟢 = Easy/Low
- 🟡 = Medium
- 🔴 = Hard/High

## LLM-Controlled NPCs Implementation Guide

### Architecture Overview

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐      ┌─────────────┐
│   LLM API   │─────▶│ Control Script│─────▶│    RCON     │─────▶│   Factorio  │
│ (OpenAI/etc)│      │  (Python/Java)│      │   Server    │      │  + FV Mod   │
└─────────────┘      └──────────────┘      └─────────────┘      └─────────────┘
       ▲                      │                      │                    │
       │                      │                      │                    │
       └──────────────────────┴──────────────────────┴────────────────────┘
                        Game State Feedback Loop
```

### Implementation Steps

1. **Install FV Embodied Agent Mod**
   - Download from: https://mods.factorio.com/mod/fv_embodied_agent
   - Install in Factorio mods folder
   - Enable in mod settings

2. **Set Up Headless Server** (optional but recommended)
   - Run Factorio headless for 24/7 operation
   - Configure RCON port and password
   - Enable FV Embodied Agent mod

3. **Create NPCs via Remote Interface**
   ```lua
   -- Via RCON or mod script
   remote.call("fv_embodied_agent", "create_agent", {
     agent_id = "npc_1",
     position = {x = 0, y = 0},
     force = "player"
   })
   ```

4. **Build Control Script with Ollama** (Python example)

   **Option A: Using Official Ollama Python Library** (Recommended)
   ```python
   import ollama
   from factorio_rcon import FactorioRcon
   
   # Connect to Factorio RCON
   factorio = FactorioRcon("localhost", 27015, "your_password")
   
   # Get game state
   state = factorio.send_command("/sc game.print(serpent.block(game.players))")
   
   # Send to Ollama (local LLM)
   response = ollama.chat(
       model="llama3.1",  # or any model you have installed
       messages=[
           {"role": "system", "content": "You are an NPC in Factorio. Make decisions based on game state."},
           {"role": "user", "content": f"Game state: {state}. What should NPC do?"}
       ]
   )
   
   # Parse and execute command
   command = parse_llm_response(response['message']['content'])
   factorio.send_command(f"/sc remote.call('fv_embodied_agent', '{command}')")
   ```

   **Option B: Using REST API (requests library)**
   ```python
   import requests
   import json
   from factorio_rcon import FactorioRcon
   
   # Connect to Factorio RCON
   factorio = FactorioRcon("localhost", 27015, "your_password")
   
   # Get game state
   state = factorio.send_command("/sc game.print(serpent.block(game.players))")
   
   # Send to Ollama via REST API
   url = "http://localhost:11434/api/chat"
   payload = {
       "model": "llama3.1",
       "messages": [
           {"role": "system", "content": "You are an NPC in Factorio."},
           {"role": "user", "content": f"Game state: {state}. What should NPC do?"}
       ],
       "stream": False
   }
   
   response = requests.post(url, json=payload)
   result = response.json()
   
   # Parse and execute command
   command = parse_llm_response(result['message']['content'])
   factorio.send_command(f"/sc remote.call('fv_embodied_agent', '{command}')")
   ```

   **Installation:**
   ```bash
   pip install ollama factorio-rcon-py
   # Make sure Ollama is running: ollama serve
   # Pull a model: ollama pull llama3.1
   ```

5. **Observe-Act Loop**
   - Query agent state via remote interface
   - Send state to LLM with context
   - Parse LLM response into actions
   - Execute via remote interface
   - Wait for async action completion
   - Repeat

### Key Remote Interface Commands (FV Embodied Agent)

**Agent Management:**
- `create_agent(agent_id, position, force)` - Create new NPC
- `remove_agent(agent_id)` - Remove NPC
- `get_agent_state(agent_id)` - Get NPC position, inventory, etc.

**Actions:**
- `walk_to(agent_id, position)` - Move NPC (async, returns via UDP)
- `mine_resource(agent_id, position)` - Mine resource (async)
- `craft_enqueue(agent_id, recipe, count)` - Queue crafting (async)
- `place_entity(agent_id, entity_name, position)` - Place building (sync)
- `set_entity_recipe(agent_id, entity, recipe)` - Configure machine (sync)

### Tips for LLM Integration with Ollama

1. **State Observation**: Create a mod that exposes game state via remote interface
2. **Action Abstraction**: Build a DSL layer between LLM and Factorio commands
3. **Error Handling**: Parse Factorio errors and feed back to LLM
4. **Async Coordination**: Use UDP callbacks or polling for async action completion
5. **Context Management**: Maintain conversation history for each NPC
6. **Ollama-Specific Tips**:
   - **Model Selection**: Use models like `llama3.1`, `mistral`, `qwen2.5`, or `phi3` for good performance
   - **Streaming**: Use `stream=True` for real-time responses (better UX)
   - **System Prompts**: Define NPC personality/role in system message
   - **Local Processing**: No API costs, but ensure you have enough RAM/VRAM
   - **Multiple NPCs**: Run separate Ollama instances or use different model contexts per NPC
   - **Performance**: Larger models (7B+) give better decisions but slower responses

### Alternative: Hybrid Approach

You could combine **FV Embodied Agent** (for NPCs) with **factorio-automation** (for additional actions like research/combat) by calling both mods' remote interfaces from your control script.

## Resources

- **Feature charts by component**: [feature_charts_by_component.md](feature_charts_by_component.md) — compare mods, HTTP→RCON layer, RCON client, and circuit options per part of the stack (“did I pick the wrong mod?”).
- **Existing work slot-in guide**: [existing_work_slot_in_guide.md](existing_work_slot_in_guide.md) — HTTP→RCON services, alternative mods, circuit APIs we can reuse.
- **FV Embodied Agent**: https://mods.factorio.com/mod/fv_embodied_agent
- **Factorio-LLM-Testing Project**: https://josh2sing.github.io/Factorio-LLM-Testing/ (real working example!)
- **Factorio Lua API**: https://lua-api.factorio.com/
- **Remote Interface Tutorial**: https://wiki.factorio.com/Tutorial:Script_interfaces
- **RCON Documentation**: Factorio headless server docs
- **Python RCON Library**: `factorio-rcon-py` (pip install factorio-rcon-py)
- **Ollama**: https://ollama.com/ (local LLM runner)
- **Ollama Python Library**: `pip install ollama`
- **Ollama API Docs**: https://docs.ollama.com/api
