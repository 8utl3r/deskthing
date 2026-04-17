# Debugging Guide - Why Agent Stopped

## Common Issues

### 1. Agent Moved But Stopped

**Possible Causes:**
- LLM not responding (Ollama connection issue)
- LLM returning invalid JSON
- LLM returning no action
- Model not loaded properly

**Debug Steps:**
1. Check controller output for error messages
2. Look for "No valid decision from LLM" messages
3. Check if Ollama is responding: `ollama list`
4. Test Ollama directly: `ollama run mistral "test"`

### 2. System Prompt Not Working

**Check:**
- Look for "System prompt initialized" message when agent is created
- Check context messages count in debug output
- Verify system message is first in `npc_contexts[agent_id]`

**The system prompt IS being set** in `create_npc()` at line 70-136.

### 3. Model Issues

**Current Setup:**
- Config says: `mistral`
- But `mistral` may not be fully downloaded yet
- `atlas` is available but slower (12B vs 7B)

**Fix:**
```bash
# Check if mistral finished downloading
ollama list | grep mistral

# If not there, wait for download or use atlas temporarily
# To use atlas: Edit config.py → OLLAMA_MODEL = "atlas"
```

### 4. LLM Not Returning Valid JSON

**Symptoms:**
- "Failed to parse JSON from LLM response"
- "No valid decision from LLM"

**Debug:**
- Check the actual LLM response in controller output
- May need to improve JSON extraction
- Model might be ignoring `format="json"` parameter

### 5. Agent Not Making Decisions

**Check:**
- Is `get_reachable()` returning data?
- Is agent state being retrieved?
- Are there enemies/blueprints/resources to act on?

**Enhanced Debugging Added:**
- Cycle count tracking
- State information logging
- LLM response logging
- Action execution logging

## Running with Debug Output

The controller now has enhanced debugging. You'll see:
```
[Cycle 1] Observing game state...
[Cycle 1] Game state retrieved
  Agent position: {...}
  Reachable: X entities, Y resources
[Cycle 1] Querying LLM (model: mistral)...
  Context messages: 3
[Cycle 1] LLM decision: walk_to with params: {...}
[Cycle 1] Action executed: True
[Cycle 1] Waiting 5.0 seconds before next cycle...
```

This will help identify where the agent is getting stuck.
