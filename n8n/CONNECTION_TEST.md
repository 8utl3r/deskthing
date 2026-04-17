# n8n Connection Test Results

## Connection Overview

There are **three ways** to connect Cursor to n8n:

1. **MCP Server** (`user-n8n-mcp`) - Read/search operations via Cursor tools
2. **API Bridge Workflow** (`cursor-api-bridge-v2.json`) - Write operations via webhook
3. **Direct n8n API** - Write operations via direct HTTP calls

---

## 1. MCP Server Connection

**Status**: ✅ Configured | ⚠️ Needs Testing

**Configuration**: `cursor/mcp.json`
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

**Available Tools** (from `n8n-mcp-prompt-template.md`):
- `search_workflows` - Find workflows by name/description
- `get_workflow_details` - Get complete workflow info

**Test Command**:
```bash
# Test MCP endpoint directly
curl -X GET "http://192.168.0.158:30109/mcp-server/http" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Usage in Cursor**:
- Agent can call: `search_workflows(query="patrol")`
- Agent can call: `get_workflow_details(workflowId="...")`

---

## 2. API Bridge Workflow

**Status**: ✅ Active | ⚠️ Response Handling Issue

**Workflow ID**: `Tu94HXP-8VYmeXkkRH7O8`
**Webhook URL**: `http://192.168.0.158:30109/webhook/cursor-workflow-api`
**File**: `n8n/workflows/cursor-api-bridge-v2.json`

**Configuration**:
- ✅ API key embedded in HTTP Request nodes
- ✅ Removed `active` field from update operations (read-only)
- ✅ Fixed response body expressions

**Operations**:
- `create` - Create new workflow
- `update` - Update existing workflow
- `delete` - Delete workflow

**Test Commands**:
```bash
# Test create operation
curl -X POST http://192.168.0.158:30109/webhook/cursor-workflow-api \
  -H "Content-Type: application/json" \
  -d '{
    "operation": "create",
    "name": "Test Workflow",
    "nodes": [...],
    "connections": {},
    "settings": {}
  }'

# Test update operation
curl -X POST http://192.168.0.158:30109/webhook/cursor-workflow-api \
  -H "Content-Type: application/json" \
  -d '{
    "operation": "update",
    "workflowId": "g8aXomSRr4Mr6D7XWBCH3",
    "name": "Updated Name",
    "nodes": [...],
    "connections": {},
    "settings": {}
  }'

# Test invalid operation (should return error)
curl -X POST http://192.168.0.158:30109/webhook/cursor-workflow-api \
  -H "Content-Type: application/json" \
  -d '{"operation": "invalid"}'
```

**Known Issues**:
- ⚠️ Returns empty response body (HTTP 200 but no JSON)
- ⚠️ Response nodes may not be properly wired
- ✅ Workflow executes successfully (updates work via direct API)

---

## 3. Direct n8n API

**Status**: ✅ Working

**Base URL**: `http://192.168.0.158:30109/api/v1/workflows`
**API Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1MzFiMGE1OS01NTU1LTQyOTAtOTJjOC0zM2E1MWIyOTg1NTAiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwianRpIjoiNGMzOWU1NTEtMGY1ZS00MGQ2LWJmNzUtNDg5NDg3NTFkYjcyIiwiaWF0IjoxNzY5NDY0MTMzfQ.URWtGNi42brs8s8Z3CkmWLFXGbJNLiphujaVl0h1oPA`

**Test Commands**:
```bash
# List all workflows
curl -X GET "http://192.168.0.158:30109/api/v1/workflows" \
  -H "X-N8N-API-KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Get specific workflow
curl -X GET "http://192.168.0.158:30109/api/v1/workflows/g8aXomSRr4Mr6D7XWBCH3" \
  -H "X-N8N-API-KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Update workflow
curl -X PUT "http://192.168.0.158:30109/api/v1/workflows/g8aXomSRr4Mr6D7XWBCH3" \
  -H "X-N8N-API-KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d @workflow.json
```

**Note**: `active` field is read-only - cannot be set in PUT requests.

---

## Current Workflows

1. **Factorio Patrol Square**
   - ID: `g8aXomSRr4Mr6D7XWBCH3`
   - Status: ✅ Active
   - Webhook: `http://192.168.0.158:30109/webhook/patrol-square`
   - Last Updated: `2026-01-26T21:55:40.711Z`

2. **Cursor API Bridge v2**
   - ID: `Tu94HXP-8VYmeXkkRH7O8`
   - Status: ✅ Active
   - Webhook: `http://192.168.0.158:30109/webhook/cursor-workflow-api`

---

## Testing Checklist

### MCP Connection
- [ ] Test `search_workflows` tool from Cursor
- [ ] Test `get_workflow_details` tool from Cursor
- [ ] Verify MCP endpoint responds correctly

### API Bridge
- [ ] Test create operation (should return success JSON)
- [ ] Test update operation (should return success JSON)
- [ ] Test delete operation (should return success JSON)
- [ ] Test invalid operation (should return error JSON)
- [ ] Fix response body handling in workflow

### Direct API
- [x] List workflows - ✅ Working
- [x] Get workflow - ✅ Working
- [x] Update workflow - ✅ Working
- [ ] Create workflow - Needs test
- [ ] Delete workflow - Needs test

---

## Troubleshooting

### MCP Not Working
1. Check if `npx supergateway` is installed
2. Verify n8n MCP endpoint is accessible
3. Check bearer token is valid
4. Restart Cursor IDE

### API Bridge Empty Responses
1. Check workflow execution logs in n8n UI
2. Verify Respond nodes are properly connected
3. Check response body expressions
4. Verify HTTP Request nodes succeed

### Direct API Errors
1. Verify API key is correct
2. Check `active` field is not included in PUT requests
3. Verify workflow JSON structure is valid

---

## Next Steps

1. **Fix API Bridge Response Handling**
   - Debug why Respond nodes return empty
   - Check execution logs in n8n
   - Verify data flow through workflow

2. **Test MCP Tools**
   - Use `search_workflows` to find workflows
   - Use `get_workflow_details` to inspect workflows
   - Document any issues

3. **Complete Direct API Testing**
   - Test create operation
   - Test delete operation
   - Document all endpoints
