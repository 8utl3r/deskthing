# Start Here - Running the Factorio NPC Controller

## Quick Start

### 1. Install Dependencies

```bash
cd /Users/pete/dotfiles/factorio
pip install -r requirements.txt
```

### 2. Verify Ollama is Running

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# If not running, start it:
ollama serve
# Or as a service:
brew services start ollama
```

### 3. Pull the Model

```bash
# Check what model is configured
grep OLLAMA_MODEL config.py

# Pull the model (default is "mistral")
ollama pull mistral

# Or pull a different model:
ollama pull llama3.1
ollama pull qwen2.5:7b
```

### 4. Verify Factorio Server is Running

```bash
# Test RCON connection
python verify_rcon_password.py
```

Should show: ✅ Connection successful!

### 5. Run the Controller

**Option A: Use the startup script (recommended)**
```bash
./run_controller.sh
```

This script:
- Checks all dependencies
- Verifies Ollama is running
- Checks model is available
- Tests RCON connection
- Starts the controller

**Option B: Run directly**
```bash
python factorio_ollama_npc_controller.py
```

## What Happens When You Run It

1. **Connects to Factorio** via RCON
2. **Creates an agent** (agent_1) at spawn
3. **Starts observe-act loop**:
   - Every 5 seconds (configurable)
   - Gets agent state and reachable entities
   - Sends context to Ollama LLM
   - LLM decides what to do
   - Executes the action
   - Repeats

## Configuration

Edit `config.py` to customize:
- `OLLAMA_MODEL`: Which LLM model to use
- `DEFAULT_DECISION_INTERVAL`: How often to make decisions (seconds)
- `RCON_HOST`, `RCON_PORT`, `RCON_PASSWORD`: Factorio server connection

## Troubleshooting

### Ollama Not Running
```bash
ollama serve
# Or
brew services start ollama
```

### Model Not Found
```bash
ollama list  # See available models
ollama pull mistral  # Pull the model
```

### RCON Connection Failed
```bash
# Test connection
python verify_rcon_password.py

# Check Factorio server is running
ssh truenas_admin@192.168.0.158 "docker ps | grep factorio"
```

### Agent Not Created
- Make sure FV Embodied Agent mod is installed and enabled
- Check server logs: `sudo docker logs factorio | tail -20`

## Expected Output

```
Created NPC: agent_1
Starting control loop for NPC: 1
[Observe] Getting game state...
[Think] Querying LLM...
[Act] Executing action: walk_to
Executed walk_to for 1: None
[Wait] Sleeping for 5.0 seconds...
```

The agent will now make decisions based on:
1. Defense (enemies detected)
2. Building (blueprints detected)
3. Gathering (resources when idle)

## Stopping the Controller

Press `Ctrl+C` to stop gracefully.

The agent will remain in Factorio (it's persistent), but the controller will stop making decisions for it.
