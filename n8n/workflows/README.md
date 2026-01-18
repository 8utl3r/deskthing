# n8n Workflows

This directory contains n8n workflow definitions that can be imported into your n8n instance.

## Cursor API Bridge

**File**: `cursor-api-bridge-v2.json` (Recommended) | `cursor-api-bridge-v1.json`

A workflow that exposes an HTTP endpoint to manage n8n workflows programmatically. This bridges the gap between Cursor (AI assistant) and n8n's API.

**Version History:**
- **v2**: Improved version using Switch node for routing. Only executes the matching operation branch, eliminating false errors. Includes proper error handling.
- **v1**: Initial working version using HTTP Request nodes with parallel If nodes. Fixed: removed `active` field from create operation (read-only field). Note: May show errors from non-matching branches.

### Features

- **Create Workflows**: POST workflow definitions to create new workflows
- **Update Workflows**: Update existing workflows by ID
- **Delete Workflows**: Delete workflows by ID

### Setup

1. **Import the workflow**:
   - Open n8n at `http://localhost:5678`
   - Go to Workflows → Click "Add workflow" → "Import from File"
   - Select `cursor-api-bridge-v2.json` (recommended) or `cursor-api-bridge-v1.json`
   - The workflow will be imported but not active yet

2. **Configure API key**:
   - In n8n, go to Settings → API
   - Generate an API key if you don't have one
   - Go back to the workflow
   - Click on each HTTP Request node (Create, Update, Delete)
   - In the Headers section, find `X-N8N-API-KEY`
   - Replace `YOUR_API_KEY_HERE` with your actual API key
   - Save the workflow

3. **Activate the workflow**:
   - Toggle the workflow to "Active" (top right)
   - Click on the Webhook node to see the webhook URL
   - The URL will be something like: `http://localhost:5678/webhook/cursor-workflow-api`
   - Copy this URL - you'll need it for the helper script

4. **Test the connection**:
   ```bash
   cd ~/dotfiles/n8n/workflows
   ./cursor-api-helper.sh create example-simple-workflow-v1.json
   ```

### Usage

**Create a workflow**:
```bash
curl -X POST http://localhost:5678/webhook/cursor-workflow-api \
  -H "Content-Type: application/json" \
  -d '{
    "operation": "create",
    "name": "My New Workflow",
    "nodes": [...],
    "connections": {...},
    "settings": {}
  }'
```

**Update a workflow**:
```bash
curl -X POST http://localhost:5678/webhook/cursor-workflow-api \
  -H "Content-Type: application/json" \
  -d '{
    "operation": "update",
    "workflowId": "123",
    "name": "Updated Name",
    "nodes": [...],
    "connections": {...}
  }'
```

**Delete a workflow**:
```bash
curl -X POST http://localhost:5678/webhook/cursor-workflow-api \
  -H "Content-Type: application/json" \
  -d '{
    "operation": "delete",
    "workflowId": "123"
  }'
```

### Response Format

**Success**:
```json
{
  "success": true,
  "data": { /* workflow data */ }
}
```

**Error**:
```json
{
  "success": false,
  "error": "Error message"
}
```

## Notes

- Workflows in this directory are version-controlled
- Import them into n8n to use them
- The webhook URL will be available once the workflow is activated
- For test mode, use `/webhook-test/` instead of `/webhook/`

