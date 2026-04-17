# API Bridge Debugging Notes

## Issue
API Bridge workflow returns HTTP 200 but empty response body.

## Root Cause Analysis

### HTTP Request Node Response Format
- HTTP Request nodes in n8n return the response body in `$json` (not `$json.body`)
- For JSON responses, the data is already parsed and available directly in `$json`
- The Respond to Webhook node should use `$json` directly

### Current Response Body Expression
```json
"responseBody": "={{ { \"success\": true, \"data\": $json } }}"
```

This should work, but the issue might be:
1. HTTP Request node not configured to parse JSON response
2. Response not reaching the Respond node
3. Workflow execution timing out
4. Data not flowing through connections correctly

## Fixes Applied

1. **Simplified Respond Success expression**:
   - Changed from `$json.body || $json` to just `$json`
   - HTTP Request nodes return data directly in `$json`

2. **Added response format option** (if needed):
   ```json
   "options": {
     "response": {
       "response": {
         "responseFormat": "json"
       }
     }
   }
   ```

## Testing Steps

1. **Re-import the updated workflow** into n8n
2. **Test create operation**:
   ```bash
   curl -X POST http://192.168.0.158:30109/webhook/cursor-workflow-api \
     -H "Content-Type: application/json" \
     -d '{"operation": "create", "name": "Test", ...}'
   ```

3. **Check n8n execution logs**:
   - Open the API Bridge workflow in n8n
   - Check "Executions" tab
   - Look for the latest execution
   - Verify:
     - HTTP Request node succeeds
     - Data flows to Respond Success node
     - Response is sent

4. **Verify workflow was created**:
   ```bash
   curl -X GET "http://192.168.0.158:30109/api/v1/workflows" \
     -H "X-N8N-API-KEY: ..." | jq '.data[] | select(.name == "Test")'
   ```

## Alternative: Use Direct API

If the API Bridge continues to have issues, use the Direct n8n API which is fully working:

```bash
# Create
curl -X POST "http://192.168.0.158:30109/api/v1/workflows" \
  -H "X-N8N-API-KEY: ..." \
  -H "Content-Type: application/json" \
  -d @workflow.json

# Update
curl -X PUT "http://192.168.0.158:30109/api/v1/workflows/{id}" \
  -H "X-N8N-API-KEY: ..." \
  -H "Content-Type: application/json" \
  -d @workflow.json

# Delete
curl -X DELETE "http://192.168.0.158:30109/api/v1/workflows/{id}" \
  -H "X-N8N-API-KEY: ..."
```

## Next Steps

1. Re-import `cursor-api-bridge-v2.json` into n8n
2. Test with a simple create operation
3. Check execution logs in n8n UI
4. If still not working, check if Respond node is properly connected
5. Verify webhook response mode is set to "responseNode"
