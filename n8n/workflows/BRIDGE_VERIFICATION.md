# Cursor API Bridge v2 – Verification

Ensures the bridge at `POST /webhook/cursor-workflow-api` is working and does what it’s supposed to.

**No-script checks:** See **PRACTICAL_TESTS.md** for tests you can run without any helper script: **ping** (does any response reach the client?), **Bridge Self-Test** workflow (run in n8n UI, inspect execution), and **Execution history** (did the bridge run correctly even when the client got empty?). That doc also explains how to tell if **TrueNAS/container isolation** is blocking response bodies.

**Run verify_bridge.sh from a host that receives webhook response bodies.** From some clients (e.g. Mac on LAN) the body can arrive empty; use the NAS, another LAN host, or a browser.

## Contract

| Operation | Request body | Bridge action | Success response |
|-----------|--------------|---------------|-------------------|
| **ping** | `{"operation":"ping"}` | None (immediate respond) | `{ "success": true, "pong": true }` |
| **list** | `{"operation":"list"}` | GET /api/v1/workflows (with API key) | `{ "success": true, "data": { "data": [...], "nextCursor" } }` |
| **create** | `{"operation":"create","name","nodes","connections","settings"?}` | POST /api/v1/workflows | `{ "success": true, "data": <created workflow> }` |
| **update** | `{"operation":"update","workflowId","name","nodes","connections","settings"?}` | PUT /api/v1/workflows/:id | `{ "success": true, "data": <updated workflow> }` |
| **delete** | `{"operation":"delete","workflowId"}` | DELETE /api/v1/workflows/:id | `{ "success": true, "data": ... }` |
| *other* | any | fallback | `{ "success": false, "error": "Invalid operation. Must be 'list', 'create', 'update', or 'delete'." }` |

On HTTP or API errors, the bridge routes to Respond Error and returns  
`{ "success": false, "error": "<message>" }`.

## Quick check

```bash
cd ~/dotfiles/n8n/workflows
./verify_bridge.sh
```

Expect: **list** and **fallback** both PASS. If you see “empty response” or FAIL, run from a host that gets full webhook bodies (e.g. on the NAS).

## Manual checks

**1. List workflows**

```bash
curl -s -X POST "http://192.168.0.158:30109/webhook/cursor-workflow-api" \
  -H "Content-Type: application/json" \
  -d '{"operation":"list"}'
```

Expected: JSON with `"success": true` and a `"data"` object (e.g. `data.data` array of workflows).

**2. Invalid operation (fallback)**

```bash
curl -s -X POST "http://192.168.0.158:30109/webhook/cursor-workflow-api" \
  -H "Content-Type: application/json" \
  -d '{"operation":"notanop"}'
```

Expected: `{"success":false,"error":"Invalid operation. Must be 'list', 'create', 'update', or 'delete'."}` (or equivalent).

**3. Create** – use a minimal workflow JSON; success = `success: true` and workflow in `data`.

**4. Update** – use `operation: "update"`, `workflowId`, and full workflow payload; success = `success: true` and updated workflow in `data`.

**5. Delete** – use `operation: "delete"` and `workflowId`; success = `success: true`.

## Prerequisites

- Bridge workflow imported and **active** in n8n.
- API key in the bridge’s HTTP Request nodes matches n8n Settings → API.
- Bridge webhook URL is reachable (e.g. `http://192.168.0.158:30109/webhook/cursor-workflow-api` for the NAS instance).

## Troubleshooting

- **401 from n8n API** – API key wrong or expired; regenerate in n8n and update every HTTP node in the bridge.
- **Empty response body** – Call the webhook from the NAS or another host where response bodies are returned (e.g. `curl` from NAS, or browser + DevTools).
- **“Invalid operation” for `list`** – Re-import `cursor-api-bridge-v2.json`; the deployed workflow may not include the `list` branch yet.
- **"Bad request" on HTTP Create Workflow** – That node runs only when the request has `"operation": "create"`. The error usually means the body was missing or invalid `name`, `nodes`, or `connections`. For a **ping** request only **Respond Ping** runs; if you only sent `{"operation":"ping"}`, that create error is from a **different execution**. Check the execution input/trigger to see which operation was sent.
