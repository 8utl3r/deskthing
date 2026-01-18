# Testing the Cursor API Bridge Workflow

## Step 4: Test the Connection

This step tests that your Cursor API Bridge workflow is working correctly by creating a simple test workflow.

### Prerequisites

1. **Cursor API Bridge workflow is active**:
   - Open n8n at `http://localhost:5678`
   - Find the "Cursor API Bridge v1" workflow
   - Make sure it's toggled to "Active" (top right)
   - Note the webhook URL from the Webhook node (e.g., `http://localhost:5678/webhook/cursor-workflow-api`)

2. **API key is configured**:
   - Make sure you've replaced `YOUR_API_KEY_HERE` with your actual API key in all three HTTP Request nodes

3. **Basic auth credentials** (if using basic auth):
   - Check your `.env` file in `~/dotfiles/n8n/` for `N8N_BASIC_AUTH_USER` and `N8N_BASIC_AUTH_PASSWORD`
   - Or set them as environment variables

### Method 1: Using the Helper Script (Recommended)

1. **Open a terminal** and navigate to the workflows directory:
   ```bash
   cd ~/dotfiles/n8n/workflows
   ```

2. **Make sure the script is executable**:
   ```bash
   chmod +x cursor-api-helper.sh
   ```

3. **Set your basic auth password** (if using basic auth):
   ```bash
   export N8N_BASIC_AUTH_PASSWORD="your_password_here"
   ```
   Or check your `~/dotfiles/n8n/.env` file for the password.

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

1. **Get your webhook URL** from the n8n workflow (e.g., `http://localhost:5678/webhook/cursor-workflow-api`)

2. **Get your basic auth credentials** from `~/dotfiles/n8n/.env`:
   - `N8N_BASIC_AUTH_USER` (usually `admin`)
   - `N8N_BASIC_AUTH_PASSWORD`

3. **Run the curl command**:
   ```bash
   curl -X POST http://localhost:5678/webhook/cursor-workflow-api \
     -u "admin:your_password_here" \
     -H "Content-Type: application/json" \
     -d @example-simple-workflow-v1.json | jq .
   ```

### Troubleshooting

**Error: "webhook not registered"**
- Make sure the workflow is **Active** (not just saved)
- For test mode, click "Execute workflow" first, then immediately run the test

**Error: "unauthorized" or 401**
- Check your basic auth credentials match your `.env` file
- Make sure you're using the correct username and password

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

