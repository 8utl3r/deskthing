# Quick Run Guide

## Option 1: Use Atlas Model (Already Installed)

The `atlas` model is already installed. To use it:

```bash
cd /Users/pete/dotfiles/factorio
./run_controller.sh
```

**Note**: Atlas is a 12B model (larger than mistral's 7B), so it will be slower but may make better decisions.

## Option 2: Wait for Mistral to Download

If you want to use `mistral` (faster, recommended for NPCs):

1. **Check download progress** (in another terminal):
   ```bash
   ollama list
   # Look for mistral in the list
   ```

2. **Once downloaded**, update config:
   ```bash
   # Edit config.py to use mistral
   # Or it's already set to mistral, just wait for download
   ```

3. **Run controller**:
   ```bash
   ./run_controller.sh
   ```

## Option 3: Use a Smaller Model (Fastest)

For fastest responses, use a smaller model:

```bash
# Pull a small, fast model
ollama pull phi3:medium  # 3.8B - very fast

# Update config.py
# OLLAMA_MODEL = "phi3:medium"

# Run
./run_controller.sh
```

## Current Setup

- **Ollama**: ✅ Running
- **Model**: `atlas` (installed) or `mistral` (downloading)
- **RCON**: ✅ Connected
- **Mod**: ✅ Installed and enabled

## Run Now

```bash
cd /Users/pete/dotfiles/factorio
./run_controller.sh
```

The script will check everything and start the controller. The agent will:
1. Connect to Factorio
2. Create an agent
3. Start making decisions every 5 seconds
4. Follow priorities: Defense > Building > Gathering

Press `Ctrl+C` to stop.
