# API Bridge Fix - Step by Step Guide

## What Was Fixed

### Fix #1: Simplified Respond Success Expression
**Before**:
```json
"responseBody": "={{ { \"success\": true, \"data\": $json.body || $json } }}"
```

**After**:
```json
"responseBody": "={{ { \"success\": true, \"data\": $json } }}"
```

**Why**: HTTP Request nodes in n8n return the response body directly in `$json`, not `$json.body`. The fallback was unnecessary and potentially confusing.

### Fix #2: Added Response Format to HTTP Request Nodes
**Added to all 3 HTTP Request nodes** (Create, Update, Delete):
```json
"options": {
  "response": {
    "response": {
      "responseFormat": "json"
    }
  }
}
```

**Why**: This ensures HTTP Request nodes properly parse JSON responses and make them available to the Respond nodes.

### Fix #3: Removed `active` Field from Updates
**Before**: Update operations tried to set `active: true` in the request body
**After**: Removed `active` field (it's read-only in n8n API)

---

## Step-by-Step: Re-import and Test

### Step 1: Open n8n
1. Go to `http://192.168.0.158:30109`
2. Log in if needed

### Step 2: Delete Old API Bridge (Optional)
1. Go to **Workflows**
2. Find "Cursor API Bridge v2" (ID: `Tu94HXP-8VYmeXkkRH7O8`)
3. Click the three dots → **Delete** (or keep it and update)

### Step 3: Import Updated Workflow
1. Click **Add workflow** → **Import from File**
2. Select: `/Users/pete/dotfiles/n8n/workflows/cursor-api-bridge-v2.json`
3. Click **Import**

### Step 4: Activate Workflow
1. Toggle the workflow to **Active** (top right)
2. The webhook URL will be: `http://192.168.0.158:30109/webhook/cursor-workflow-api`

### Step 5: Test Create Operation
Run this command:
```bash
curl -X POST http://192.168.0.158:30109/webhook/cursor-workflow-api \
  -H "Content-Type: application/json" \
  -d '{
    "operation": "create",
    "name": "API Bridge Test",
    "nodes": [
      {
        "id": "manual",
        "name": "Manual Trigger",
        "type": "n8n-nodes-base.manualTrigger",
        "typeVersion": 1,
        "position": [250, 300]
      }
    ],
    "connections": {},
    "settings": {}
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "id": "...",
    "name": "API Bridge Test",
    ...
  }
}
```

### Step 6: Verify Workflow Was Created
```bash
curl -X GET "http://192.168.0.158:30109/api/v1/workflows" \
  -H "X-N8N-API-KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1MzFiMGE1OS01NTU1LTQyOTAtOTJjOC0zM2E1MWIyOTg1NTAiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwianRpIjoiNGMzOWU1NTEtMGY1ZS00MGQ2LWJmNzUtNDg5NDg3NTFkYjcyIiwiaWF0IjoxNzY5NDY0MTMzfQ.URWtGNi42brs8s8Z3CkmWLFXGbJNLiphujaVl0h1oPA" \
  -s | jq '.data[] | select(.name == "API Bridge Test")'
```

### Step 7: Check Execution Logs (If Response Still Empty)
1. In n8n, open the "Cursor API Bridge v2" workflow
2. Click **Executions** tab
3. Find the latest execution
4. Click on it to see:
   - Did HTTP Request node succeed? (green checkmark)
   - Did data flow to Respond Success node?
   - What data is in each node?

---

## Troubleshooting

### If Response is Still Empty

1. **Check Execution Logs**:
   - Open workflow → Executions tab
   - Look for errors in HTTP Request nodes
   - Verify data reaches Respond Success node

2. **Verify Connections**:
   - HTTP Create/Update/Delete → Respond Success (main output)
   - HTTP Create/Update/Delete → Respond Error (error output)
   - Switch Operation → Respond Invalid Operation (fallback output)

3. **Check Response Body Expression**:
   - Open Respond Success node
   - Verify: `{{ { "success": true, "data": $json } }}`
   - Test expression in n8n's expression editor

4. **Verify Webhook Response Mode**:
   - Webhook node should have: `"responseMode": "responseNode"`
   - This means it waits for a Respond node

### If Workflow Creation Fails

1. **Check API Key**: Verify it's correct in HTTP Request headers
2. **Check Request Body**: Ensure JSON is valid
3. **Check n8n API**: Test direct API call to verify it works

---

## Success Criteria

✅ **API Bridge is working if**:
- Create operation returns: `{"success": true, "data": {...}}`
- Update operation returns: `{"success": true, "data": {...}}`
- Delete operation returns: `{"success": true, "data": {...}}`
- Invalid operation returns: `{"success": false, "error": "..."}`

---

## Quick Test Script

Save this as `test_api_bridge.sh`:

```bash
#!/bin/bash

API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1MzFiMGE1OS01NTU1LTQyOTAtOTJjOC0zM2E1MWIyOTg1NTAiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwianRpIjoiNGMzOWU1NTEtMGY1ZS00MGQ2LWJmNzUtNDg5NDg3NTFkYjcyIiwiaWF0IjoxNzY5NDY0MTMzfQ.URWtGNi42brs8s8Z3CkmWLFXGbJNLiphujaVl0h1oPA"
BASE_URL="http://192.168.0.158:30109"

echo "Testing API Bridge Create..."
RESPONSE=$(curl -X POST "$BASE_URL/webhook/cursor-workflow-api" \
  -H "Content-Type: application/json" \
  -d '{
    "operation": "create",
    "name": "API Bridge Test",
    "nodes": [{"id": "m", "name": "Manual", "type": "n8n-nodes-base.manualTrigger", "typeVersion": 1, "position": [250, 300]}],
    "connections": {},
    "settings": {}
  }' -s)

echo "Response: $RESPONSE"
echo ""

if echo "$RESPONSE" | jq -e '.success == true' > /dev/null 2>&1; then
  echo "✅ API Bridge is working!"
  WORKFLOW_ID=$(echo "$RESPONSE" | jq -r '.data.id')
  echo "Created workflow ID: $WORKFLOW_ID"
  
  # Clean up
  echo "Deleting test workflow..."
  curl -X DELETE "$BASE_URL/api/v1/workflows/$WORKFLOW_ID" \
    -H "X-N8N-API-KEY: $API_KEY" -s > /dev/null
  echo "✅ Test complete"
else
  echo "❌ API Bridge returned empty or error response"
  echo "Check n8n execution logs"
fi
```

Run with: `bash test_api_bridge.sh`
