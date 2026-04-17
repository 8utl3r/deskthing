# Factorio LLM NPC Quick Start

## Prerequisites Check

1. **Factorio server is running** ✅ (on TrueNAS at 192.168.0.158:34197)
2. **RCON is enabled** ✅ (port 27015, password configured)
3. **Ollama is running** (check with `ollama list`)
4. **FV Embodied Agent mod** (needs to be installed on Factorio server)

## Step 1: Install Python Dependencies

```bash
cd /Users/pete/dotfiles/factorio
pip install -r requirements.txt
```

This installs:
- `ollama` - Python client for Ollama
- `factorio-rcon-py` - Python client for Factorio RCON

## Step 2: Verify Configuration

Check `config.py`:
- ✅ RCON_HOST = "192.168.0.158" (NAS IP)
- ✅ RCON_PASSWORD = "4hyZA96uO9PuWl" (from server logs)
- ✅ OLLAMA_MODEL = "mistral" (or your preferred model)
- ✅ OLLAMA_HOST = "localhost" (Ollama on your Mac)

## Step 3: Test Connections

Run the test script to verify everything works:

```bash
python test_connections.py
```

This will test:
- ✅ Configuration loading
- ✅ RCON connection to Factorio
- ✅ Ollama connection and model availability

## Step 4: Verify FV Embodied Agent Mod

The mod must be installed on the Factorio server. Check:

1. **SSH to TrueNAS:**
   ```bash
   ssh truenas_admin@192.168.0.158
   ```

2. **Check mods directory:**
   ```bash
   ls -la /mnt/boot-pool/apps/factorio/mods/
   ```

3. **Look for:** `fv-embodied-agent_*.zip`

If not installed:
- Download from: https://mods.factorio.com/mod/fv_embodied_agent
- Upload to: `/mnt/boot-pool/apps/factorio/mods/`
- Restart Factorio server

## Step 5: Run NPC Controller

Once all tests pass:

```bash
python factorio_ollama_npc_controller.py
```

This will:
1. Connect to Factorio via RCON
2. Create an NPC named "npc_1" at position (0, 0)
3. Start the observe-act loop (every 5 seconds)
4. NPC will make decisions using Ollama LLM

## Troubleshooting

### RCON Connection Fails
- Check Factorio server is running: `docker ps | grep factorio`
- Check RCON password in config.py matches server logs
- Test network: `telnet 192.168.0.158 27015`

### Ollama Connection Fails
- Start Ollama: `ollama serve` (or `brew services start ollama`)
- Check model exists: `ollama list`
- Pull model if missing: `ollama pull mistral`

### NPC Not Created
- Verify FV Embodied Agent mod is installed
- Check Factorio server logs: `docker logs factorio`
- Try creating NPC manually via RCON:
  ```python
  from factorio_rcon import FactorioRcon
  rcon = FactorioRcon("192.168.0.158", 27015, "4hyZA96uO9PuWl")
  rcon.send_command("/sc remote.call('fv_embodied_agent', 'create_agent', 'test_npc', {x=0, y=0}, 'player')")
  ```

## Next Steps

- Create multiple NPCs with different personalities
- Customize system prompts for different NPC types
- Adjust decision interval (faster = more CPU intensive)
- Monitor NPC behavior in Factorio game
