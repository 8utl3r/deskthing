# Troubleshooting - Agent Not Doing Anything

## Quick Fixes

### 1. Model Not Available
**Problem**: Config says `mistral` but it's not installed.

**Fix**:
```bash
# Check available models
ollama list

# Option A: Use atlas (already installed)
# Edit config.py → OLLAMA_MODEL = "atlas"

# Option B: Download mistral
ollama pull mistral
# (This takes time - 4.4 GB)
```

### 2. Check What's Happening
The controller now has detailed debug output. Look for:

```
[Cycle 1] Querying LLM (model: atlas)...
  Using model: atlas
  LLM raw response: {...}
  ✅ Parsed JSON decision: {...}
```

Or errors like:
```
❌ Error querying LLM: model not found
❌ Failed to parse JSON from LLM response
```

### 3. Common Issues

**Agent Created But Not Moving:**
- Check if LLM is responding (look for "LLM raw response")
- Check if JSON is being parsed ("✅ Parsed JSON decision")
- Check if action is being executed ("Action executed: True")

**LLM Not Responding:**
- Verify Ollama is running: `curl http://localhost:11434/api/tags`
- Check model exists: `ollama list | grep <model>`
- Test Ollama directly: `ollama run atlas "test"`

**Invalid JSON:**
- LLM might not be following format
- Check "LLM raw response" in debug output
- May need to adjust system prompt or use different model

**No Actions:**
- Check if agent has anything to act on
- Look for "Reachable: X entities, Y resources"
- Agent might be waiting for enemies/blueprints/resources

## Debug Output Explained

```
[Cycle 1] Observing game state...
[Cycle 1] Game state retrieved
  Agent position: {...}
  Reachable: X entities, Y resources
[Cycle 1] Querying LLM (model: atlas)...
  Using model: atlas
  LLM raw response: {...}
  ✅ Parsed JSON decision: {...}
[Cycle 1] LLM decision: walk_to with params: {...}
[Cycle 1] Action executed: True
```

If you see "❌" messages, that's where the problem is.

## Still Not Working?

1. **Check RCON connection:**
   ```bash
   python verify_rcon_password.py
   ```

2. **Check Ollama:**
   ```bash
   curl http://localhost:11434/api/tags
   ollama list
   ```

3. **Test model directly:**
   ```bash
   ollama run atlas '{"action": "test"}'
   ```

4. **Check Factorio server:**
   ```bash
   ssh truenas_admin@192.168.0.158 "docker ps | grep factorio"
   ```
