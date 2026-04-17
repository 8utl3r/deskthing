# Error Logging System Setup

## Overview

The Error Logger workflow provides centralized error reporting for all n8n workflows. Errors are logged with full context and can be queried via MCP tools or n8n execution logs.

## Architecture

### Error Logger Workflow
- **Webhook**: `POST /webhook/error-log`
- **Purpose**: Receives error reports, formats them, and stores them
- **Response**: Returns log entry with ID for tracking

### Log Storage
- Logs are stored in n8n's execution history
- Each error gets a unique ID (timestamp + random)
- Logs include: timestamp, severity, workflow, node, error message, details, context

## Usage

### From Other Workflows

Add an HTTP Request node to send errors to the logger:

```json
{
  "url": "http://192.168.0.158:30109/webhook/error-log",
  "method": "POST",
  "jsonBody": {
    "workflow_name": "My Workflow",
    "node_name": "HTTP Request",
    "error_message": "Connection timeout",
    "error_details": {
      "url": "https://api.example.com",
      "status": 504
    },
    "context": {
      "agent_id": "1",
      "attempt": 3
    },
    "severity": "error"
  }
}
```

### Error Payload Format

```json
{
  "workflow_name": "string (required)",
  "node_name": "string (required)",
  "error_message": "string (required)",
  "error_details": "object (optional)",
  "context": "object (optional)",
  "severity": "string (optional, default: 'error')"
}
```

**Field Mappings**:
- `workflow_name` or `workflow` → workflow name
- `node_name` or `node` → node name
- `error_message` or `error` or `message` → error message
- `error_details` or `details` or `data` → additional error data
- `context` or `metadata` → contextual information
- `severity` → error severity (default: "error")

### Severity Levels
- `error` - Critical errors that stop execution
- `warning` - Non-critical issues
- `info` - Informational messages
- `debug` - Debug information

## Querying Logs

### Method 1: n8n Execution Logs
1. Open n8n: `http://192.168.0.158:30109`
2. Go to **Workflows** → **Error Logger**
3. Click **Executions** tab
4. View each execution to see logged errors

### Method 2: MCP Tools
Use the MCP tools to search for error log executions:
```javascript
// Search for error log executions
search_workflows(query: "error")
get_workflow_details(workflowId: "error-logger-id")
```

### Method 3: Direct API
```bash
# Get error logger workflow ID
curl -X GET "http://192.168.0.158:30109/api/v1/workflows" \
  -H "X-N8N-API-KEY: ..." | jq '.data[] | select(.name == "Error Logger")'

# Get executions
curl -X GET "http://192.168.0.158:30109/api/v1/executions?workflowId={id}" \
  -H "X-N8N-API-KEY: ..."
```

## Integration Examples

### Example 1: Error Handling in HTTP Request Node

Add error output connection:

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

Then add a "Log Error" HTTP Request node:

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
      "context": "={{ $json }}"
    }
  }
}
```

### Example 2: Try-Catch Pattern

Use IF node to check for errors, then log:

```json
{
  "name": "Check for Error",
  "type": "n8n-nodes-base.if",
  "parameters": {
    "conditions": {
      "string": [
        {
          "value1": "={{ $json.error }}",
          "operation": "notEmpty"
        }
      ]
    }
  }
}
```

## Response Format

The Error Logger returns:

```json
{
  "success": true,
  "logged": true,
  "log_id": "2026-01-26T22:40:00.000Z-abc123",
  "timestamp": "2026-01-26T22:40:00.000Z",
  "log_entry": {
    "id": "2026-01-26T22:40:00.000Z-abc123",
    "timestamp": "2026-01-26T22:40:00.000Z",
    "severity": "error",
    "workflow": "My Workflow",
    "node": "HTTP Request",
    "error": "Connection timeout",
    "details": {...},
    "context": {...}
  },
  "log_text": "2026-01-26T22:40:00.000Z [ERROR] My Workflow::HTTP Request - Connection timeout | Details: {...}"
}
```

## Benefits

1. **Centralized Logging**: All errors in one place
2. **Full Context**: Includes workflow, node, details, and context
3. **Queryable**: Can search via n8n UI or MCP tools
4. **Traceable**: Each log has unique ID
5. **Structured**: Consistent format for all errors
6. **Accessible**: Available to agents via MCP

## Next Steps

1. ✅ Create Error Logger workflow
2. ✅ Enable MCP access
3. ⏳ Integrate into existing workflows (patrol, etc.)
4. ⏳ Create query workflow for searching logs
5. ⏳ Add log retention/cleanup policy

## Testing

Test the error logger:

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

Expected response:
```json
{
  "success": true,
  "logged": true,
  "log_id": "...",
  "timestamp": "...",
  "log_entry": {...},
  "log_text": "..."
}
```
