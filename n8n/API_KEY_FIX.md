# API Key Authorization Fix

## Problem
The API Bridge workflow is getting a 401 "Authorization failed" error when the HTTP Request nodes try to call the n8n API.

## Root Cause
The API key works fine with curl, so the issue is how n8n's HTTP Request node sends the header. The header value might need to be an expression.

## Fix Applied
Changed header value from static string to expression by adding `=` prefix:

**Before**:
```json
{
  "name": "X-N8N-API-KEY",
  "value": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**After**:
```json
{
  "name": "X-N8N-API-KEY",
  "value": "=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

The `=` prefix tells n8n to treat it as an expression (even though it's a static value).

## Alternative Solutions

If the expression prefix doesn't work, try:

### Option 1: Use Header Auth Credential
1. In n8n, go to **Credentials** → **New**
2. Select **Header Auth**
3. Name: `X-N8N-API-KEY`
4. Value: Your API key
5. In HTTP Request node, select **Authentication** → **Header Auth** → Select your credential

### Option 2: Use Expression with Quotes
```json
{
  "name": "X-N8N-API-KEY",
  "value": "={{ 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' }}"
}
```

### Option 3: Verify Header is Being Sent
Check the execution logs in n8n to see what headers are actually being sent. The HTTP Request node should show the request details.

## Testing

After applying the fix:

1. **Re-import** the updated workflow
2. **Activate** it
3. **Test** with:
   ```bash
   curl -X POST http://192.168.0.158:30109/webhook/cursor-workflow-api \
     -H "Content-Type: application/json" \
     -d '{"operation": "create", "name": "Test", ...}'
   ```

4. **Check execution logs** in n8n to verify:
   - HTTP Request node succeeds (green checkmark)
   - No 401 errors
   - Response data flows to Respond Success node

## Verification

The API key itself is valid (tested with curl). The fix ensures n8n sends it correctly in the HTTP request headers.
