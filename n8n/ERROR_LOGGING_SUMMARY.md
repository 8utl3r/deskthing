# Error Logging System - Summary

## ✅ Status: Working

The Error Logger workflow is **active** and **ready to use**.

- **Workflow ID**: `H2v3DsOvDiCzuaTR`
- **Webhook**: `POST http://192.168.0.158:30109/webhook/error-log`
- **MCP Enabled**: ✅ Yes
- **Status**: ✅ Active

## Quick Test

```bash
curl -X POST http://192.168.0.158:30109/webhook/error-log \
  -H "Content-Type: application/json" \
  -d '{
    "workflow_name": "Test Workflow",
    "node_name": "Test Node",
    "error_message": "Test error message",
    "error_details": {"test": true},
    "context": {"agent_id": "test-1"},
    "severity": "error"
  }'
```

**Response**:
```json
{
  "success": true,
  "logged": true,
  "log_id": "2026-01-26T22:43:59.954Z-mph2p",
  "log_entry": {
    "timestamp": "2026-01-26T22:43:59.954Z",
    "severity": "error",
    "workflow": "Test Workflow",
    "node": "Test Node",
    "error": "Test error message",
    "details": {"test": true},
    "context": {"agent_id": "test-1"}
  },
  "log_text": "2026-01-26T22:43:59.954Z [ERROR] Test Workflow::Test Node - Test error message | Details: {\"test\":true} | Context: {\"agent_id\":\"test-1\"}"
}
```

## How to Use

### From Other Workflows

Add an HTTP Request node to send errors:

```json
{
  "name": "Log Error",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "url": "http://192.168.0.158:30109/webhook/error-log",
    "method": "POST",
    "jsonBody": {
      "workflow_name": "={{ $workflow.name }}",
      "node_name": "={{ $('HTTP Request').name }}",
      "error_message": "={{ $json.error.message }}",
      "error_details": "={{ $json.error }}",
      "context": "={{ $json }}",
      "severity": "error"
    }
  }
}
```

### Error Output Connection

Connect error outputs to the logger:

```json
{
  "connections": {
    "HTTP Request": {
      "error": [
        [
          {
            "node": "Log Error",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

## Viewing Logs

### Method 1: n8n UI
1. Open `http://192.168.0.158:30109`
2. Go to **Workflows** → **Error Logger**
3. Click **Executions** tab
4. View each execution to see logged errors

### Method 2: MCP Tools
```javascript
// Search for error logger
search_workflows(query: "error")
get_workflow_details(workflowId: "H2v3DsOvDiCzuaTR")
```

### Method 3: Direct API
```bash
# Get executions
curl -X GET "http://192.168.0.158:30109/api/v1/executions?workflowId=H2v3DsOvDiCzuaTR" \
  -H "X-N8N-API-KEY: ..."
```

## Next Steps

1. ✅ Error Logger workflow created and active
2. ⏳ Integrate into patrol workflow (add error logging)
3. ⏳ Integrate into other workflows as needed
4. ⏳ Use logs to debug issues

## Benefits

- **Centralized**: All errors in one place
- **Structured**: Consistent format
- **Queryable**: Search via n8n UI or MCP
- **Traceable**: Unique log IDs
- **Contextual**: Includes workflow, node, details, context

Now you have the full dev cycle: **program → test → view errors → modify → repeat**! 🎉
