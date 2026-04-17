# n8n API Configuration

## API Key
Stored securely for workflow automation assistance.

**API Endpoint:** `https://n8n.xcvr.link/api/v1` (via Cloudflare Tunnel)  
**Alternative:** `http://192.168.0.158:30109/api/v1` (direct internal)

**API Key:** (stored in session, user can revoke via n8n Settings → API)

## Usage

Use `X-N8N-API-KEY` header for all API requests:

```bash
curl -H "X-N8N-API-KEY: <key>" https://n8n.xcvr.link/api/v1/workflows
```

## Capabilities

- ✅ Create workflows programmatically
- ✅ Update existing workflows
- ✅ List all workflows
- ✅ Execute workflows
- ✅ Manage credentials
- ✅ Debug workflow issues

## Security

- User can revoke key anytime via n8n Settings → API
- Key stored for this session only
- Never commit API keys to git
