# Architecture Options: Controller vs n8n Integration

## Current Architecture

```
n8n Workflow
  ↓ HTTP POST
Python Controller (localhost:8080)
  ↓ RCON (TCP)
Factorio Server
```

## What the Controller Does

### 1. **RCON Connection Management** (Cannot move to n8n easily)
- **What**: Maintains persistent TCP connection to Factorio RCON
- **Why Separate**: RCON is TCP protocol, not HTTP
- **Complexity**: Connection pooling, retry logic, reconnection

### 2. **Action Formatting** (CAN move to n8n)
- **What**: Formats RCON commands from action names
- **Example**: `walk_to` → `/sc remote.call('agent_1', 'walk_to', {x=10, y=10})`
- **Complexity**: Simple string formatting
- **Can Move**: ✅ Yes - Use n8n Code node

### 3. **Error Handling** (CAN move to n8n)
- **What**: Parses RCON responses, detects errors
- **Complexity**: String matching for error keywords
- **Can Move**: ✅ Yes - Use n8n Switch/IF nodes

### 4. **HTTP Endpoint** (CAN move to n8n)
- **What**: Provides HTTP API for n8n to call
- **Complexity**: Simple HTTP server
- **Can Move**: ✅ Yes - n8n IS the HTTP endpoint (webhook)

## Option 1: Keep Separate Controller (Current) ✅ RECOMMENDED

### Architecture
```
n8n Workflow (webhook)
  ↓ HTTP POST
Python Controller (:8080)
  - RCON connection management
  - Action formatting
  - Error handling
  ↓ RCON (TCP)
Factorio Server
```

### Pros
- ✅ **Clean separation**: RCON logic isolated
- ✅ **Reusable**: Controller can be used by other systems
- ✅ **Connection pooling**: Persistent RCON connection
- ✅ **Simple n8n**: n8n just makes HTTP calls
- ✅ **Easy debugging**: Can test controller independently

### Cons
- ❌ **Extra service**: Need to run Python controller
- ❌ **Network dependency**: n8n must reach controller

### When to Use
- ✅ **Recommended** - Best for production
- ✅ Multiple systems need RCON access
- ✅ Want to reuse controller logic

---

## Option 2: Move Everything to n8n Code Node

### Architecture
```
n8n Workflow (webhook)
  ↓ Code Node (Python)
  - RCON connection (per execution)
  - Action formatting
  - Error handling
  ↓ RCON (TCP)
Factorio Server
```

### Implementation
Use n8n **Code Node** with Python:
```python
import factorio_rcon

# Connect to RCON
rcon = factorio_rcon.RCONClient("192.168.0.158", 27015, "password")
rcon.connect()

# Format command
agent_id = $json.body.agent_id
action = $json.body.action
params = $json.body.params

if action == "walk_to":
    command = f"/sc remote.call('agent_{agent_id}', 'walk_to', {{x={params.x}, y={params.y}}})"
elif action == "mine_resource":
    command = f"/sc remote.call('agent_{agent_id}', 'mine_resource', '{params.resource}', {params.count})"

# Execute
response = rcon.send_command(command)

# Parse response
if "error" in response.lower():
    return {"success": False, "message": response}
else:
    return {"success": True, "message": response}
```

### Pros
- ✅ **No separate service**: Everything in n8n
- ✅ **Simpler deployment**: One less thing to manage
- ✅ **Visual debugging**: See RCON calls in n8n UI

### Cons
- ❌ **Connection overhead**: New RCON connection per execution
- ❌ **Code in n8n**: Harder to version control
- ❌ **Limited reuse**: Can't use from other systems
- ❌ **n8n dependency**: Must install Python packages in n8n container

### When to Use
- ✅ Simple use case, single system
- ✅ Don't need persistent connections
- ✅ Want everything in one place

---

## Option 3: Hybrid - Minimal Controller

### Architecture
```
n8n Workflow (webhook)
  ↓ HTTP POST
Minimal Python Controller (:8080)
  - ONLY RCON connection management
  - Simple pass-through
  ↓ RCON (TCP)
Factorio Server
```

### Implementation
Controller just formats and forwards:
```python
# Minimal controller - just RCON bridge
def execute_action(agent_id, action, params):
    command = format_command(agent_id, action, params)
    return rcon.send_command(command)
```

n8n handles:
- Action formatting (Code node)
- Error parsing (Switch node)
- Response formatting (Code node)

### Pros
- ✅ **Thin controller**: Minimal code
- ✅ **Flexible n8n**: Can change logic without controller changes
- ✅ **Persistent connection**: Still get connection pooling

### Cons
- ❌ **Still need controller**: Extra service
- ❌ **Split logic**: Some logic in n8n, some in controller

---

## Recommendation: **Option 1 (Keep Separate Controller)**

### Why?
1. **RCON is TCP**: n8n doesn't handle TCP connections well
2. **Connection management**: Persistent connections are more efficient
3. **Reusability**: Controller can be used by other systems
4. **Separation of concerns**: RCON logic separate from workflow logic
5. **Easier testing**: Can test controller independently

### What to Keep in Controller
- ✅ RCON connection management
- ✅ Action formatting (can move, but keep for consistency)
- ✅ Error handling (can move, but keep for consistency)
- ✅ HTTP endpoint

### What Could Move to n8n (but don't need to)
- ⚠️ Action formatting - Simple enough to keep in controller
- ⚠️ Error parsing - Simple enough to keep in controller

### Current Controller is Good
The current controller is well-designed:
- ✅ Clean HTTP API
- ✅ Proper error handling
- ✅ Connection management
- ✅ Easy to test

**Recommendation**: Keep the separate controller. It's the right architecture.

---

## If You Want to Eliminate Controller

If you really want everything in n8n:

1. **Install Python packages in n8n container**:
   ```bash
   # In n8n container
   pip install factorio-rcon-py
   ```

2. **Use Code Node** for RCON calls:
   - Add Python Code node
   - Import `factorio_rcon`
   - Connect, execute, return result

3. **Tradeoffs**:
   - New RCON connection per execution (slower)
   - Code in n8n (harder to version control)
   - Can't reuse from other systems

**But**: The separate controller is better architecture. Keep it.
