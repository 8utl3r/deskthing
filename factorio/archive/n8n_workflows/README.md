# Factorio n8n workflows

Workflows for n8n → controller → Factorio (RCON). Import into n8n on the NAS (host network, so controller is `http://localhost:8080`).

## Workflows

- **Factorio Action Executor** – Webhook `POST /webhook/factorio-action-executor`. Forwards `{ agent_id, action, params }` to the controller `POST /execute-action`. Supports `walk_to`; fallback responds with JSON for unsupported actions.
- **Factorio Gather Resource** – Uses `GET /get-reachable?agent_id=...` and can call the Action Executor webhook.
- **Factorio Patrol Square** – Patrol logic; calls the Action Executor webhook.

## Factorio Action Executor – empty-response fix (Jan 2026)

The webhook was returning HTTP 200 with an empty body. Changes made:

1. **Webhook body shape** – Use `($json.body || $json)` for `action`, `agent_id`, `params` so it works whether the webhook puts the JSON body in `body` or at root.
2. **Switch** – Switched to Rules mode with one rule (`walk_to`) and **Fallback output** = “fallback”, wired to “Respond Unsupported”, so every request gets a JSON response.
3. **Respond node** – Response body uses a defensive expression so the controller output is always returned as JSON.

### How to apply the fix in n8n

**Option A – Re-import (replace)**

1. In n8n, open the “Factorio Action Executor” workflow.
2. Menu → Import from File (or overwrite): use `factorio_action_executor.json` from this folder.
3. Save and activate.

**Option B – Update via Cursor API Bridge**

Run from a host that receives webhook response bodies (from this Mac the body often arrives empty; use the NAS, another LAN host, or the helper script there):

```bash
cd factorio/n8n_workflows

# 1) Get workflow IDs (find Factorio Action Executor and copy its "id")
./apply_action_executor_fix.sh list

# 2) Push the fixed workflow (replace <id> with the Factorio Action Executor id)
./apply_action_executor_fix.sh update <id>
```

Or manually: get the workflow ID from the n8n URL when the workflow is open; then build the payload with the `jq` command in Option B and `POST` it to `http://192.168.0.158:30109/webhook/cursor-workflow-api`.

## URLs

- n8n (NAS): `http://192.168.0.158:30109`
- Action Executor webhook: `POST http://192.168.0.158:30109/webhook/factorio-action-executor`
- Controller (from n8n on NAS): `http://localhost:8080`
