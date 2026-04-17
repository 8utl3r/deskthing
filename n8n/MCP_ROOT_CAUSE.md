# MCP Connection Root Cause - SOLVED ✅

## Discovery: MCP Endpoint IS Working!

The MCP endpoint successfully returned the tools list:
- ✅ `search_workflows` - Available
- ✅ `execute_workflow` - Available  
- ✅ `get_workflow_details` - Available

**The connection works!** The token is valid and the endpoint is responding.

---

## Root Cause: Workflows Not Enabled for MCP

### The Problem
When calling `search_workflows`, it returns empty results because:
- **Workflows must be explicitly enabled for MCP access**
- Current status: All workflows have `availableInMCP: false`

### Evidence
```json
{
  "id": "g8aXomSRr4Mr6D7XWBCH3",
  "name": "Factorio Patrol Square",
  "active": true,
  "settings": false  // ← availableInMCP is false!
}
```

---

## Solution

### Step 1: Enable Workflows for MCP Access

**Option A: Via n8n UI**
1. Open workflow: `Factorio Patrol Square`
2. Click `...` menu (top-right) > **Settings**
3. Toggle **Available in MCP** ON
4. Repeat for `Cursor API Bridge v2`

**Option B: Via API** (I can do this for you)
```bash
# Enable Factorio Patrol Square
curl -X PUT "http://192.168.0.158:30109/api/v1/workflows/g8aXomSRr4Mr6D7XWBCH3" \
  -H "X-N8N-API-KEY: ..." \
  -H "Content-Type: application/json" \
  -d '{"name": "Factorio Patrol Square", "nodes": [...], "connections": {...}, "settings": {"availableInMCP": true}}'
```

### Step 2: Verify Instance-Level MCP is Enabled
1. Go to: Settings > Instance-level MCP
2. Verify: "Enable MCP access" toggle is ON
3. If not, enable it

### Step 3: Test Again
After enabling workflows, the MCP tools should find them:
- `search_workflows(query="patrol")` should return results
- `get_workflow_details(workflowId="...")` should work

---

## Workflow Eligibility Checklist

For a workflow to appear in MCP search:

- ✅ **Published** (active: true) - Both workflows meet this
- ✅ **Has supported trigger** (Webhook) - Both workflows have this
- ❌ **MCP access enabled** (`availableInMCP: true`) - **MISSING!**

---

## Token Status

**Current Token**: The token being used appears to be working (MCP endpoint responds)
- Token audience: `mcp-server-api`
- Connection: ✅ Successful
- Tools list: ✅ Retrieved

**Note**: According to docs, you should use a "Personal MCP Access Token" from Settings > Instance-level MCP. However, the current token seems to work. If issues persist, get the Personal MCP Access Token.

---

## Summary

**Status**: ✅ MCP connection is working
**Issue**: ❌ Workflows not enabled for MCP access
**Fix**: Enable `availableInMCP: true` for workflows you want to search
**Next**: Enable workflows, then test MCP tools again

The tools exist and the connection works - we just need to enable the workflows!
