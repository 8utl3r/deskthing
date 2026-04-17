# Factorio n8n Controller - Service Setup

## Overview

The Python controller needs to run automatically when your Mac starts. It provides the HTTP endpoint (`localhost:8080`) that n8n workflows call to execute RCON commands.

## Architecture

```
Mac (localhost)
├── Ollama (localhost:11434) ✅ Already running
├── Python Controller (localhost:8080) ⏳ Needs to auto-start
└── Connects to:
    ├── n8n (192.168.0.158:30109) ✅ On NAS
    └── Factorio RCON (192.168.0.158:27015) ✅ On NAS
```

## Setup Instructions

### Option 1: Use Setup Script (Recommended)

```bash
cd /Users/pete/dotfiles/factorio
./setup_service.sh
```

This will:
1. Create logs directory
2. Install the launchd service
3. Load and start the service
4. Show status and log locations

### Option 2: Manual Setup

```bash
# 1. Create logs directory
mkdir -p /Users/pete/dotfiles/factorio/logs

# 2. Copy plist to LaunchAgents
cp /Users/pete/dotfiles/factorio/com.pete.factorio-n8n-controller.plist \
   ~/Library/LaunchAgents/

# 3. Load the service
launchctl load ~/Library/LaunchAgents/com.pete.factorio-n8n-controller.plist

# 4. Start the service
launchctl start com.pete.factorio-n8n-controller
```

## Service Management

### Check Status
```bash
launchctl list | grep factorio
```

### View Logs
```bash
# Output log
tail -f /Users/pete/dotfiles/factorio/logs/factorio-controller.log

# Error log
tail -f /Users/pete/dotfiles/factorio/logs/factorio-controller.error.log
```

### Stop Service
```bash
launchctl stop com.pete.factorio-n8n-controller
```

### Start Service
```bash
launchctl start com.pete.factorio-n8n-controller
```

### Restart Service
```bash
launchctl stop com.pete.factorio-n8n-controller
launchctl start com.pete.factorio-n8n-controller
```

### Unload Service (Remove)
```bash
launchctl unload ~/Library/LaunchAgents/com.pete.factorio-n8n-controller.plist
rm ~/Library/LaunchAgents/com.pete.factorio-n8n-controller.plist
```

## Service Behavior

- **Auto-start**: Service starts automatically when Mac boots (`RunAtLoad: true`)
- **Auto-restart**: Service restarts if it crashes (`KeepAlive: true`)
- **Logs**: All output goes to `logs/factorio-controller.log`
- **Errors**: All errors go to `logs/factorio-controller.error.log`

## Testing

After setup, test that the service is running:

```bash
# 1. Check if service is running
launchctl list | grep factorio

# 2. Check if HTTP server is responding
curl http://localhost:8080/execute-action \
  -H "Content-Type: application/json" \
  -d '{"agent_id": "1", "action": "walk_to", "params": {"x": 0, "y": 0}}'

# 3. Check logs
tail -20 /Users/pete/dotfiles/factorio/logs/factorio-controller.log
```

## Troubleshooting

### Service Not Starting

1. **Check logs**:
   ```bash
   tail -50 /Users/pete/dotfiles/factorio/logs/factorio-controller.error.log
   ```

2. **Check if Python path is correct**:
   ```bash
   which python3
   # Update plist if path is different
   ```

3. **Check if dependencies are installed**:
   ```bash
   cd /Users/pete/dotfiles/factorio
   pip3 install -r requirements.txt
   ```

### Service Crashes Immediately

1. **Check error log** for Python errors
2. **Verify config.py** has correct RCON settings
3. **Test manually**:
   ```bash
   cd /Users/pete/dotfiles/factorio
   python3 factorio_n8n_controller.py
   ```

### HTTP Server Not Responding

1. **Check if service is running**:
   ```bash
   launchctl list | grep factorio
   ```

2. **Check if port 8080 is in use**:
   ```bash
   lsof -i :8080
   ```

3. **Check logs** for connection errors

## Dependencies

The service requires:
- ✅ Python 3 with dependencies (`pip install -r requirements.txt`)
- ✅ Ollama running (on localhost:11434)
- ✅ Factorio server running (on 192.168.0.158:27015)
- ✅ n8n running (on 192.168.0.158:30109)

## Next Steps

After setting up the service:
1. ✅ Service auto-starts on boot
2. ✅ HTTP server available at `localhost:8080`
3. ✅ n8n workflows can call the controller
4. ✅ Full connection chain is complete!
