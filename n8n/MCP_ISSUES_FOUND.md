# MCP Connection Issues - Root Cause Analysis

## Critical Issues Found

### Issue #1: Workflows Not Enabled for MCP ❌
**Status**: All workflows have `availableInMCP: false`

**Current Workflows**:
- `Factorio Patrol Square` (active: true, mcp: false)
- `Cursor API Bridge v2` (active: true, mcp: false)
- `Test` (active: false, mcp: false)
- `Simple Webhook Test` (active: false, mcp: false)

**Fix Required**: Enable MCP access for workflows that should be searchable.

### Issue #2: Token Type May Be Wrong ❓
**Current Token**: API key with audience `mcp-server-api`
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1MzFiMGE1OS01NTU1LTQyOTAtOTJjOC0zM2E1MWIyOTg1NTAiLCJpc3MiOiJuOG4iLCJhdWQiOiJtY3Atc2VydmVyLWFwaSIsImp0aSI6ImE1YzUwYzY0LWU2YjItNDhlMC04ODRmLTdlOGFmNWMxYzQ4YyIsImlhdCI6MTc2OTQ2MDE5N30.4xrBCv9XHV3i_FxqQ_JrQVaMJGAhE2V4YaLAwxUSj9c
```

**Should Be**: Personal MCP Access Token (generated in Settings > Instance-level MCP)

**Location**: n8n UI > Settings > Instance-level MCP > Connection details > Access Token tab

### Issue #3: Accept Header Required ✅
**Fixed**: MCP endpoint requires `Accept: application/json, text/event-stream`

The `supergateway` tool should handle this automatically, but we verified the endpoint needs it.

### Issue #4: Instance-Level MCP May Not Be Enabled ❓
**Check**: Settings > Instance-level MCP > Enable MCP access toggle

---

## Required Actions

### Step 1: Verify Instance-Level MCP is Enabled
1. Open n8n: `http://192.168.0.158:30109`
2. Go to: **Settings > Instance-level MCP**
3. Verify: **Enable MCP access** is toggled ON
4. If not enabled, toggle it ON

### Step 2: Get Personal MCP Access Token
1. In MCP settings page, click **Connection details** button (top-right)
2. Go to **Access Token** tab
3. **Copy the token immediately** (only visible once!)
4. If token is already redacted, click **Generate new token**

### Step 3: Enable Workflows for MCP
For workflows you want to search:
- **Factorio Patrol Square** (has Webhook trigger ✅)
- **Cursor API Bridge v2** (has Webhook trigger ✅)

**Option A: Via UI**
1. Open workflow
2. Click `...` menu > **Settings**
3. Toggle **Available in MCP** ON

**Option B: Via API**
```bash
# Enable Factorio Patrol Square
curl -X PUT "http://192.168.0.158:30109/api/v1/workflows/g8aXomSRr4Mr6D7XWBCH3" \
  -H "X-N8N-API-KEY: ..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Factorio Patrol Square",
    "nodes": [...],
    "connections": {...},
    "settings": {
      "availableInMCP": true
    }
  }'
```

### Step 4: Update Cursor MCP Config
Replace token in `/Users/pete/dotfiles/cursor/mcp.json`:
```json
"n8n-mcp": {
  "command": "npx",
  "args": [
    "-y",
    "supergateway",
    "--streamableHttp",
    "http://192.168.0.158:30109/mcp-server/http",
    "--header",
    "authorization:Bearer <PERSONAL_MCP_ACCESS_TOKEN>"
  ]
}
```

### Step 5: Restart Cursor
After updating config, restart Cursor IDE to reload MCP connection.

---

## Workflow Eligibility Requirements

For a workflow to be available via MCP, it must:

1. ✅ **Be published** (active: true)
2. ✅ **Have a supported trigger**:
   - Webhook ✅
   - Schedule
   - Chat
   - Form
3. ❌ **Be enabled for MCP** (`availableInMCP: true`) ← **MISSING**

Both "Factorio Patrol Square" and "Cursor API Bridge v2" meet criteria 1 and 2, but need criterion 3.

---

## Testing After Fixes

1. **Test MCP endpoint directly**:
   ```bash
   curl -X POST "http://192.168.0.158:30109/mcp-server/http" \
     -H "Authorization: Bearer <MCP_TOKEN>" \
     -H "Content-Type: application/json" \
     -H "Accept: application/json, text/event-stream" \
     -d '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}'
   ```

2. **Test from Cursor**:
   - "Search for workflows with 'patrol'"
   - "Get details for workflow g8aXomSRr4Mr6D7XWBCH3"

---

## Summary

**Root Causes**:
1. Workflows not enabled for MCP access
2. Possibly wrong token type (API key vs MCP Access Token)
3. Possibly instance-level MCP not enabled

**Priority Fixes**:
1. Enable instance-level MCP (if not enabled)
2. Get Personal MCP Access Token
3. Enable workflows for MCP access
4. Update Cursor config
5. Restart Cursor
