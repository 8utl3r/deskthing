# Factorio Server Setup on TrueNAS NAS

## Architecture

```
Local Mac                          TrueNAS NAS
├── Ollama (LLM)                   ├── Factorio Server (Docker)
├── Python Controller               │   ├── FV Embodied Agent Mod
└── Connects via RCON ────────────▶│   └── RCON enabled (port 27015)
```

## Prerequisites

- ✅ TrueNAS Scale with Apps enabled
- ✅ NAS has x86_64 CPU (Intel N100 - confirmed compatible)
- ✅ Network access from Mac to NAS (192.168.0.158)

## Step 1: Install Factorio on TrueNAS

### Option A: Custom App via YAML (Recommended)

1. **In TrueNAS Web UI:**
   - Go to **Apps** → **Discover Apps**
   - Click the **three-dot menu** (⋮) in the top right
   - Select **"Install via YAML"**

2. **Application Name:**
   - Enter: `factorio`

3. **Paste Docker Compose YAML:**
   - Open `truenas_custom_app.yaml` from this directory
   - **IMPORTANT**: Before pasting, edit these values:
     - Replace `CHANGE_THIS_PASSWORD` with your secure RCON password
     - **Storage path**: The YAML uses `/mnt/boot-pool/apps/factorio` (NVMe, fastest)
   - Copy the entire YAML and paste into TrueNAS

4. **Review Configuration:**
   - Verify ports: 27015 (TCP) and 34197 (UDP)
   - Verify storage path matches your pool
   - Verify RCON password is set

5. **Deploy** the app

### Option B: Docker Compose (If you have shell access)

If you prefer command-line setup via SSH:

```bash
# SSH to NAS
ssh pete@192.168.0.158

# Create directory
sudo mkdir -p /mnt/[pool]/apps/factorio
cd /mnt/[pool]/apps/factorio

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3'
services:
  factorio:
    image: goofball222/factorio:latest
    container_name: factorio
    restart: unless-stopped
    ports:
      - "27015:27015/tcp"    # RCON
      - "34197:34197/udp"    # Game
    volumes:
      - ./factorio:/factorio
    environment:
      - FACTORIO_RCON_PASSWORD=your_secure_password_here
      - FACTORIO_SAVE=my-save
EOF

# Run with docker-compose (if available)
# Or use TrueNAS Custom App with this config
```

## Step 2: Install FV Embodied Agent Mod

1. **Download the mod:**
   - Visit: https://mods.factorio.com/mod/fv_embodied_agent
   - Download the `.zip` file

2. **Upload to NAS:**
   - Via SMB share or SSH
   - Place in: `/mnt/[pool]/apps/factorio/factorio/mods/`

3. **Extract the mod:**
   ```bash
   # SSH to NAS
   cd /mnt/[pool]/apps/factorio/factorio/mods/
   unzip fv_embodied_agent_*.zip
   ```

4. **Enable in Factorio:**
   - The mod should auto-enable on next server start
   - Or edit `factorio/mods/mod-list.json` to enable it

## Step 3: Configure RCON

RCON should be enabled automatically via the `FACTORIO_RCON_PASSWORD` environment variable.

**Verify RCON is working:**
```bash
# From your Mac, test connection
telnet 192.168.0.158 27015
# Should connect (won't authenticate without password, but connection works)
```

## Step 4: Create Initial Save (Optional)

If you want to start with a specific save:

1. **Create save via Factorio client:**
   - Launch Factorio on your Mac
   - Create a new game or load existing
   - Save the game

2. **Upload save to NAS:**
   - Copy save file to: `/mnt/[pool]/apps/factorio/factorio/saves/`
   - Update `FACTORIO_SAVE` env var to match save name

## Step 5: Configure Controller for Remote NAS

Update the Python controller to connect to NAS:

```python
# In factorio_ollama_npc_controller.py main()
RCON_HOST = "192.168.0.158"  # NAS IP
RCON_PORT = 27015
RCON_PASSWORD = "your_secure_password_here"  # Same as FACTORIO_RCON_PASSWORD
```

## Step 6: Test Connection

```bash
# From your Mac
cd /Users/pete/dotfiles/factorio
python3 -c "
from factorio_rcon import FactorioRcon
rcon = FactorioRcon('192.168.0.158', 27015, 'your_password')
response = rcon.send_command('/sc game.print(\"Hello from RCON!\")')
print(response)
"
```

## Troubleshooting

### RCON Connection Failed
- Check firewall on NAS (port 27015 TCP)
- Verify Factorio container is running: `docker ps | grep factorio`
- Check container logs: `docker logs factorio`

### Mod Not Loading
- Verify mod is in correct directory: `factorio/mods/`
- Check mod-list.json: `cat factorio/mods/mod-list.json`
- Check Factorio logs for mod errors

### Save Not Found
- Verify save file exists in `factorio/saves/`
- Check `FACTORIO_SAVE` env var matches save name (without `.zip`)

## Network Configuration

**From Mac to NAS:**
- RCON: `192.168.0.158:27015` (TCP)
- Game: `192.168.0.158:34197` (UDP) - if you want to play directly

**Firewall Rules (if needed):**
- Allow TCP port 27015 (RCON)
- Allow UDP port 34197 (Game)

## Next Steps

1. ✅ Factorio server running on NAS
2. ✅ FV Embodied Agent mod installed
3. ✅ RCON configured and tested
4. ⏭️ Pull Ollama model (if not done)
5. ⏭️ Configure Python controller
6. ⏭️ Test NPC creation
