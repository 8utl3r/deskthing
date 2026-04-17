# Testing the Cursor API Bridge Workflow

## Step 4: Test the Connection

This step tests that your Cursor API Bridge workflow is working correctly by creating a simple test workflow.

### Prerequisites

1. **Cursor API Bridge workflow is active**:
   - Open n8n at `http://192.168.0.158:30109` (TrueNAS NAS instance)
   - Find the "Cursor API Bridge v1" workflow
   - Make sure it's toggled to "Active" (top right)
   - Note the webhook URL from the Webhook node (e.g., `http://192.168.0.158:30109/webhook/cursor-workflow-api`)

2. **API key is configured**:
   - Make sure you've replaced `YOUR_API_KEY_HERE` with your actual API key in all three HTTP Request nodes

3. **Authentication**:
   - Use your n8n login credentials configured during NAS installation

### Method 1: Using the Helper Script (Recommended)

1. **Open a terminal** and navigate to the workflows directory:
   ```bash
   cd ~/dotfiles/n8n/workflows
   ```

2. **Make sure the script is executable**:
   ```bash
   chmod +x cursor-api-helper.sh
   ```

3. **Set your n8n credentials** (if required by helper script):
   - Use your n8n login credentials configured during NAS installation
   - Update `cursor-api-helper.sh` to use NAS URL: `http://192.168.0.158:30109`

4. **Run the test**:
   ```bash
   ./cursor-api-helper.sh create example-simple-workflow-v1.json
   ```

5. **Expected result**:
   You should see a JSON response like:
   ```json
   {
     "success": true,
     "data": {
       "id": "123",
       "name": "Example Simple Workflow v1",
       "nodes": [...],
       ...
     }
   }
   ```

6. **Verify in n8n**:
   - Go to n8n workflows list
   - You should see "Example Simple Workflow v1" in your workflows
   - Click on it to verify it was created correctly

### Method 2: Using curl Directly

If you prefer to use curl directly:

1. **Get your webhook URL** from the n8n workflow (e.g., `http://192.168.0.158:30109/webhook/cursor-workflow-api`)

2. **Use your n8n login credentials** configured during NAS installation

3. **Run the curl command**:
   ```bash
   curl -X POST http://192.168.0.158:30109/webhook/cursor-workflow-api \
     -u "your_username:your_password" \
     -H "Content-Type: application/json" \
     -d @example-simple-workflow-v1.json | jq .
   ```

### Troubleshooting

**Error: "webhook not registered"**
- Make sure the workflow is **Active** (not just saved)
- For test mode, click "Execute workflow" first, then immediately run the test

**Error: "unauthorized" or 401**
- Check your n8n login credentials
- Make sure you're using the correct username and password configured during NAS installation

**Error: "Bad request" or 400**
- Check that your API key is correctly set in the HTTP Request nodes
- Verify the API key is valid in n8n Settings → API

**Error: "jq: command not found"**
- Install jq: `brew install jq` (macOS) or your package manager
- Or remove `| jq .` from the command to see raw JSON

### Next Steps

Once the test succeeds:
- You can create more complex workflows by modifying the JSON files
- Use the helper script for create, update, and delete operations
- Integrate this into your automation workflows

