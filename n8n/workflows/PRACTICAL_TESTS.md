# Practical Tests: Bridge + Empty Response / TrueNAS Isolation

No scripts required. Use these to see whether the bridge works and whether **TrueNAS/container isolation** is blocking response bodies from reaching your client.

---

## 1. Ping test (does *any* response reach the client?)

From your Mac (or wherever you usually get empty bodies):

```bash
curl -s -X POST "http://192.168.0.158:30109/webhook/cursor-workflow-api" \
  -H "Content-Type: application/json" \
  -d '{"operation":"ping"}'
```

- **You see `{"success":true,"pong":true}`**  
  → The path from n8n back to your client is fine. Empty bodies on `list`/other are likely due to something else (timeout, size, or that branch).

- **You see nothing / 0 bytes**  
  → Responses from n8n are not reaching this client. That *can* be TrueNAS/container networking (e.g. how webhook responses are sent back through the stack).

*Requires the bridge to have the `ping` operation (re-import `cursor-api-bridge-v2.json` if needed).*

---

## 2. Bridge Self-Test workflow (does the bridge work when n8n calls itself?)

Runs entirely inside n8n; you only look at the execution result.

1. In n8n: **Workflows → Add workflow → Import from File** → choose `bridge-self-test.json`.
2. **Save** the workflow.
3. Click **Test workflow** (or **Execute workflow**).
4. Open the **Call Bridge List** node in the run and check its **Output**).
   - You see `{ "success": true, "data": { "data": [ ... ] } }` (or similar with workflow list)  
     → The bridge works when n8n calls itself. So the bridge and internal HTTP call are OK; the issue is only “n8n → your Mac (or other external client)”.
   - You see an error or empty output  
     → The bridge or the request from this workflow is failing (e.g. n8n container can’t reach `192.168.0.158:30109`, or API key/problem inside the bridge).

*Uses `http://192.168.0.158:30109`; if n8n runs in a container that can’t reach that IP, change the URL in the node to whatever n8n can use (e.g. `http://localhost:30109` if n8n is on the host).*

---

## 3. Execution history (did the bridge itself run correctly?)

Use this to check the bridge *even when the client gets an empty body*.

1. Trigger the bridge from the outside (browser or `curl` from your Mac), e.g.:
   ```bash
   curl -s -X POST "http://192.168.0.158:30109/webhook/cursor-workflow-api" \
     -H "Content-Type: application/json" -d '{"operation":"list"}'
   ```
2. In n8n: **Executions** → open **Cursor API Bridge v2** → latest execution.
3. Open that run and look at:
   - **HTTP List Workflows** (or **Respond Success**) output.

- **Those nodes show data** (e.g. workflow list, or success payload)  
  → The bridge ran correctly; the “empty” part is only that the response didn’t make it back to your client. That fits **response path / TrueNAS isolation** (or proxy/NAT) between n8n and the client.

- **Those nodes show error or no data**  
  → The bridge or its internal API call failed; isolation may still play a role if the bridge calls “out” to `192.168.0.158:30109` from a container.

---

## Is it TrueNAS network isolation?

Interpretation:

| Ping (Mac) | Self-Test (in n8n) | Bridge execution (internal nodes) | Likely cause |
|------------|-------------------|------------------------------------|--------------|
| Empty      | Has body          | Has body                           | **Response path** from n8n to client blocked or altered (TrueNAS/containers/proxy). |
| Empty      | Empty / error     | Error / no data                    | **Internal** problem: n8n→bridge or bridge→n8n API (e.g. container can’t reach `192.168.0.158:30109` or API key). |
| Has body   | Has body          | Has body                           | Path is fine; earlier empty body was likely transient or from another path. |

So: **yes, it can be TrueNAS/container setup** if (a) ping from the Mac is empty, and (b) Self-Test and/or bridge execution history show that the bridge *did* return data internally. Then the next place to check is how n8n is exposed (port mapping, proxy, host vs bridge networking) and whether webhook responses are treated differently from normal HTTP.

---

## Quick reference

- **Ping**: `curl -s -X POST "http://192.168.0.158:30109/webhook/cursor-workflow-api" -H "Content-Type: application/json" -d '{"operation":"ping"}'`
- **Self-Test**: Import `bridge-self-test.json` → Test workflow → Inspect **Call Bridge List** output. The HTTP node is set to **response format: text** so you see the raw body (no JSON parse). If you get "Invalid JSON in response body" or "Cannot read properties of undefined (reading 'data')", re-import the latest `bridge-self-test.json` (it now uses text mode so the bridge’s actual response is shown).
- **Execution history**: Trigger bridge from client → n8n **Executions** → **Cursor API Bridge v2** → latest run → Inspect **HTTP List Workflows** / **Respond Success**.
