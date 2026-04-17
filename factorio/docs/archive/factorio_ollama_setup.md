# Factorio + Ollama NPC Setup Guide

Complete setup guide for running LLM-controlled NPCs in Factorio using Ollama.

## Prerequisites

1. **Factorio** (with headless server capability)
2. **FV Embodied Agent Mod** installed
3. **Ollama** installed and running
4. **Python 3.8+**

## Step 1: Install Ollama

```bash
# macOS
brew install ollama

# Or download from https://ollama.com
```

Start Ollama:
```bash
ollama serve
```

Pull a model (choose one):
```bash
# Recommended models for NPCs:
ollama pull llama3.1        # Good balance (8B params)
ollama pull mistral         # Fast and efficient (7B)
ollama pull qwen2.5:7b      # Good reasoning (7B)
ollama pull phi3:medium     # Smaller, faster (3.8B)
```

## Step 2: Install Python Dependencies

```bash
pip install ollama factorio-rcon-py
```

Or use the requirements file:
```bash
pip install -r requirements.txt
```

## Step 3: Set Up Factorio

1. **Install FV Embodied Agent Mod:**
   - Download from: https://mods.factorio.com/mod/fv_embodied_agent
   - Place in Factorio mods folder: `~/.factorio/mods/`
   - Enable in Factorio mod settings

2. **Configure Headless Server (Optional but Recommended):**
   - Create server config file
   - Enable RCON with password
   - Example config:
   ```
   [rcon]
   enable-rcon=true
   rcon-port=27015
   rcon-password=your_secure_password
   ```

3. **Start Factorio Server:**
   ```bash
   ./factorio --start-server saves/my-save.zip
   ```

## Step 4: Configure and Run

1. **Edit `factorio_ollama_npc_controller.py`:**
   - Set `RCON_PASSWORD` to your Factorio RCON password
   - Set `OLLAMA_MODEL` to the model you pulled
   - Adjust `RCON_PORT` if different (default: 27015)

2. **Run the controller:**
   ```bash
   python factorio_ollama_npc_controller.py
   ```

## Usage Examples

### Create Multiple NPCs

```python
controller = FactorioNPCController(
    rcon_password="your_password",
    ollama_model="llama3.1"
)

# Create multiple NPCs
controller.create_npc("miner_bob", position=(10, 10))
controller.create_npc("builder_alice", position=(20, 20))
controller.create_npc("explorer_charlie", position=(0, 0))

# Run control loops (in separate threads/processes)
import threading

threading.Thread(target=controller.run_npc_loop, args=("miner_bob", 5.0)).start()
threading.Thread(target=controller.run_npc_loop, args=("builder_alice", 5.0)).start()
threading.Thread(target=controller.run_npc_loop, args=("explorer_charlie", 5.0)).start()
```

### Custom System Prompts

Modify the system prompt in `create_npc()` to give NPCs different personalities:

```python
# Miner NPC
self.npc_contexts[agent_id] = [
    {
        "role": "system",
        "content": "You are a miner NPC. Your primary goal is to find and mine resources (iron, copper, coal, stone). Always prioritize mining over other activities."
    }
]

# Builder NPC
self.npc_contexts[agent_id] = [
    {
        "role": "system",
        "content": "You are a builder NPC. Your goal is to construct factories and automate production. Focus on placing assemblers, inserters, and production chains."
    }
]
```

## Troubleshooting

### Ollama Connection Issues
- Make sure Ollama is running: `ollama serve`
- Check if model is pulled: `ollama list`
- Test connection: `ollama run llama3.1 "hello"`

### RCON Connection Issues
- Verify RCON is enabled in Factorio config
- Check firewall settings
- Test with: `telnet localhost 27015`

### NPC Not Responding
- Check Factorio console for errors
- Verify FV Embodied Agent mod is enabled
- Check RCON command responses in controller output

### LLM Not Following Format
- Use `format="json"` in ollama.chat() call
- Improve system prompt with clear JSON format examples
- Consider using larger models (7B+) for better instruction following

## Advanced: Multiple NPCs with Different Models

```python
# Use different models for different NPC types
miner_controller = FactorioNPCController(ollama_model="mistral")  # Fast
builder_controller = FactorioNPCController(ollama_model="llama3.1")  # Better reasoning
explorer_controller = FactorioNPCController(ollama_model="qwen2.5:7b")  # Balanced
```

## Performance Tips

1. **Model Selection:**
   - Smaller models (3B-7B): Faster, good for simple NPCs
   - Larger models (8B+): Better decisions, slower responses

2. **Decision Interval:**
   - 5-10 seconds: Good for most NPCs
   - 1-3 seconds: For active NPCs (more CPU intensive)
   - 10-30 seconds: For passive NPCs

3. **Context Management:**
   - Keep conversation history limited (last 5-10 messages)
   - Clear context periodically to avoid token bloat

4. **Streaming:**
   - Use `stream=True` for real-time feedback
   - Better UX but slightly more complex to handle

## Next Steps

- Add state observation mod for richer game state
- Implement action validation and error recovery
- Create NPC personality system
- Add multi-agent coordination
- Build web dashboard for monitoring NPCs
