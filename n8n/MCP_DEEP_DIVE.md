# n8n MCP Connection Deep Dive

## Key Findings

### Issue #1: Accept Header Required
The MCP endpoint requires clients to accept both `application/json` and `text/event-stream`:
```
"Not Acceptable: Client must accept both application/json and text/event-stream"
```

**Fix**: Add `Accept: application/json, text/event-stream` header to requests.

### Issue #2: Workflow Requirements for MCP Access
From n8n documentation, workflows must meet ALL of these criteria:

1. ✅ **Be published** (active: true)
2. ✅ **Have a supported trigger**:
   - Webhook
   - Schedule
   - Chat
   - Form
3. ❌ **Be explicitly enabled for MCP** (`settings.availableInMCP: true`)

**Current Status**: Need to check if workflows have `availableInMCP` enabled.

### Issue #3: Token Type
The token being used might be wrong:
- **Current**: Using API key token (audience: `mcp-server-api`)
- **Should be**: Personal MCP Access Token (generated in Settings > Instance-level MCP)

**Location**: Settings > Instance-level MCP > Connection details > Access Token tab

### Issue #4: supergateway Configuration
The `supergateway` tool might need the Accept header configured, or Cursor might not be passing it correctly.

---

## n8n MCP Server Requirements

### Instance-Level Setup
1. **Enable MCP access**: Settings > Instance-level MCP > Toggle ON
2. **Generate MCP Access Token**: Connection details > Access Token tab
3. **Enable workflows**: Each workflow must be explicitly enabled

### Workflow Eligibility
- Must be **published** (active)
- Must have **supported trigger** (Webhook, Schedule, Chat, Form)
- Must have **MCP access enabled** (`availableInMCP: true`)

### Authentication
- **OAuth2**: For interactive clients
- **Access Token**: For programmatic access (what we need)
- Token is **personal** and tied to user account
- Token is **auto-generated** on first visit to MCP settings

---

## Current Configuration Analysis

### Cursor MCP Config (`cursor/mcp.json`)
```json
"n8n-mcp": {
  "command": "npx",
  "args": [
    "-y",
    "supergateway",
    "--streamableHttp",
    "http://192.168.0.158:30109/mcp-server/http",
    "--header",
    "authorization:Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  ]
}
```

**Issues**:
1. ✅ Using `supergateway` (correct)
2. ✅ Using `--streamableHttp` (correct)
3. ✅ Using bearer token (correct format)
4. ❓ Token might be wrong type (API key vs MCP token)
5. ❓ Missing Accept header configuration

---

## Testing Steps

### Step 1: Verify MCP Access is Enabled
1. Go to n8n: `http://192.168.0.158:30109`
2. Navigate to: **Settings > Instance-level MCP**
3. Verify: **Enable MCP access** is toggled ON

### Step 2: Get Personal MCP Access Token
1. In MCP settings, click **Connection details** button
2. Go to **Access Token** tab
3. Copy the token (only visible on first visit!)
4. If already visited, generate a new one

### Step 3: Check Workflow MCP Settings
```bash
curl -X GET "http://192.168.0.158:30109/api/v1/workflows" \
  -H "X-N8N-API-KEY: ..." \
  | jq '.data[] | {name: .name, active: .active, mcp: .settings.availableInMCP}'
```

### Step 4: Enable Workflows for MCP
For each workflow you want to expose:
1. Open workflow in n8n
2. Click `...` menu > **Settings**
3. Toggle **Available in MCP** ON

Or via API:
```bash
curl -X PUT "http://192.168.0.158:30109/api/v1/workflows/{id}" \
  -H "X-N8N-API-KEY: ..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "...",
    "nodes": [...],
    "connections": {...},
    "settings": {
      "availableInMCP": true
    }
  }'
```

### Step 5: Test MCP Endpoint with Correct Headers
```bash
curl -X POST "http://192.168.0.158:30109/mcp-server/http" \
  -H "Authorization: Bearer <MCP_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}'
```

### Step 6: Update Cursor MCP Config
Replace the token in `cursor/mcp.json` with the Personal MCP Access Token.

---

## Expected Tools from n8n MCP

Based on documentation, n8n MCP server should expose:
- Tools to search workflows
- Tools to get workflow details
- Tools to execute workflows

The exact tool names might be different from what we expect (`search_workflows`, `get_workflow_details`).

---

## supergateway Behavior

The `supergateway` tool acts as a bridge between Cursor's MCP client and the HTTP MCP server. It should:
1. Handle the Accept header automatically
2. Convert MCP protocol messages
3. Forward requests to the n8n MCP endpoint

If it's not working, the issue might be:
- Token authentication failing
- Workflows not enabled for MCP
- MCP access not enabled at instance level

---

## Next Steps

1. ✅ Verify MCP access is enabled in n8n
2. ✅ Get Personal MCP Access Token
3. ✅ Check which workflows have MCP enabled
4. ✅ Enable workflows for MCP access
5. ✅ Update Cursor config with correct token
6. ✅ Test MCP endpoint directly
7. ✅ Restart Cursor and test tools
