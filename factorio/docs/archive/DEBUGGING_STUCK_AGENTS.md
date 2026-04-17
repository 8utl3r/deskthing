# Debugging Stuck Agents

## Common Causes of Stuck Agents

### 1. Action Timeout Issues
**Problem**: Actions take longer than expected, causing workflows to timeout.

**Symptoms**:
- Agent reports "busy" but never completes
- Workflows timeout waiting for actions
- Agent position doesn't change

**Debug**:
```bash
# Monitor agent state in real-time
python debug_agent_state.py [agent_id]

# Test individual actions
python test_workflow_actions.py
```

**Solutions**:
- Increase timeout values in workflows
- Check if action actually completed (agent might be idle but workflow thinks it's busy)
- Verify `is_agent_busy()` is working correctly

### 2. Range Constraint Blocking
**Problem**: Agent tries to move/interact but is blocked by range constraints.

**Symptoms**:
- Actions return "beyond range" errors
- Agent keeps trying same action repeatedly
- Agent position doesn't change

**Debug**:
```python
# Check constructed entities
constructed = controller.get_constructed_entities(agent_id)
print(f"Found {len(constructed)} constructed entities")

# Check if position is in range
in_range = controller.is_within_range_of_any_construction((x, y), constructed)
print(f"Position ({x}, {y}) in range: {in_range}")
```

**Solutions**:
- Verify chests/buildings count as construction
- Check if agent is too far from any construction
- Consider expanding search radius for constructions

### 3. Action Execution Failures
**Problem**: Actions fail silently or return unclear errors.

**Symptoms**:
- Actions return `True` but nothing happens
- Error messages are unclear
- Agent state doesn't reflect action

**Debug**:
```bash
# Test each action individually
python test_workflow_actions.py
```

**Solutions**:
- Check RCON command format
- Verify mod interface names (`agent_1` vs `Agent-1`)
- Check Factorio server logs for errors

### 4. State Detection Issues
**Problem**: `is_agent_busy()` doesn't accurately reflect agent state.

**Symptoms**:
- Agent appears busy but is actually idle
- Workflows wait forever for completion
- Agent state shows inconsistent information

**Debug**:
```python
# Check agent state directly
state = controller.get_agent_state(agent_id)
print(json.dumps(state, indent=2))

# Check busy detection
is_busy = controller.is_agent_busy(agent_id)
print(f"Agent busy: {is_busy}")
```

**Solutions**:
- Verify state structure matches expected format
- Check if mod returns state in different format
- Add more detailed state logging

### 5. Workflow Logic Errors
**Problem**: Workflows have logic errors causing infinite loops or dead ends.

**Symptoms**:
- Workflow never completes
- Workflow keeps retrying same step
- Workflow reports success but agent doesn't do anything

**Debug**:
```bash
# Test workflows individually
python test_workflow_actions.py
```

**Solutions**:
- Add more error handling in workflows
- Add timeout checks for each workflow step
- Verify workflow parameters are correct

## Testing Tools

### 1. `test_workflow_actions.py`
Comprehensive test suite for all actions and workflows:
```bash
python test_workflow_actions.py
```

Tests:
- Basic actions (walk_to, etc.)
- All workflows
- Agent state tracking
- Action completion detection

### 2. `debug_agent_state.py`
Real-time agent state monitoring:
```bash
python debug_agent_state.py [agent_id] [duration]
```

Features:
- Continuous state monitoring
- Stuck detection (same position)
- State change detection
- Busy/idle status

### 3. Manual Testing
Test individual actions via Python:
```python
from factorio_ollama_npc_controller import FactorioNPCController
from config import RCON_HOST, RCON_PORT, RCON_PASSWORD

controller = FactorioNPCController(RCON_HOST, RCON_PORT, RCON_PASSWORD)
agent_id = "1"

# Test walk_to
result = controller.execute_action(agent_id, 'walk_to', {'x': 10, 'y': 10})
print(f"Result: {result}")

# Check if busy
is_busy = controller.is_agent_busy(agent_id)
print(f"Busy: {is_busy}")

# Get state
state = controller.get_agent_state(agent_id)
print(f"State: {state}")
```

## Common Fixes

### Fix 1: Increase Timeouts
If actions are timing out, increase timeout values:
```python
# In workflows.py
max_wait = 60  # Increase from 30 to 60 seconds
```

### Fix 2: Add Retry Logic
If actions fail intermittently, add retry logic:
```python
# Retry failed actions
for attempt in range(3):
    result = controller.execute_action(agent_id, action, params)
    if result is True:
        break
    time.sleep(1)
```

### Fix 3: Better Error Messages
Improve error messages to identify issues:
```python
# In execute_action
if isinstance(result, str):
    print(f"Action {action} returned: {result}")
    if 'error' in result.lower():
        print(f"  Full error: {result}")
```

### Fix 4: Verify State Structure
Check if state structure matches expectations:
```python
# Add validation
if not isinstance(agent_state, dict):
    print(f"⚠️  Unexpected state format: {type(agent_state)}")
    return False
```

## Related Projects

### Factorio-LLM-Testing
- **URL**: https://josh2sing.github.io/Factorio-LLM-Testing/
- **Approach**: Custom Java control server + Lua mod + GPT-4
- **Key Features**: 
  - Iterative prompting with real-time feedback
  - Custom DSL for command abstraction
  - Overlap prevention and orientation logic

### factorio-agent (GitHub)
- **URL**: https://github.com/lvshrd/factorio-agent
- **Approach**: AI-based autonomous game state analysis
- **Key Features**: Learning tasks, remembering as skills

### factorio-automation (GitHub)
- **URL**: https://github.com/naklecha/factorio-automation
- **Approach**: Remote interfaces for controlling player actions
- **Key Features**: Resource management, complex automation

## Next Steps

1. **Run test suite**: `python test_workflow_actions.py`
2. **Monitor agent**: `python debug_agent_state.py [agent_id]`
3. **Check logs**: Look at Factorio server logs for errors
4. **Verify mod**: Ensure FV Embodied Agent mod is working correctly
5. **Test actions**: Test each action individually to identify problematic ones
