# Connection Verification Flow

**Goal:** Prove each link works in order. Stop at the first failure and fix it before moving on.

**Note:** n8n is not used. Step 3 is kept for reference only. Use **Step 1 (RCON)** and **Step 2 (HTTP controller)** — and run `./verify_connections.sh` for a one-shot check.

**Stack (all on NAS with host networking):**
```
[optional n8n] → http://localhost:8080 → HTTP controller (host net) → RCON → Factorio (host net)
                        ↑                         ↑                         ↑
                    Step 3                    Step 2                      Step 1
```

---

## Where to run checks

- **From NAS (SSH):** Best. Use `RCON_HOST=127.0.0.1` (script default). Run `./verify_connections.sh` from the `factorio/` dir (see [Verify script](#verify-script) below). Steps 1–3 use `localhost` / `127.0.0.1`.
- **From Mac:** You can run the script with `RCON_HOST=192.168.0.158` and `CONTROLLER_URL=http://192.168.0.158:8080` to test Step 1 (RCON to NAS) and Step 2 (controller HTTP) only if 8080 is reachable from the Mac. If the controller is host-bound on the NAS and 8080 is not published, run the script from the NAS.

---

## Step 1: Factorio RCON is reachable

**Link:** Controller (or your machine) → Factorio RCON (TCP 27015).

**From NAS (SSH):**
```bash
# 1a. Port open
nc -zv 127.0.0.1 27015
# Expect: "Connection to 127.0.0.1 27015 port [tcp/*] succeeded"
```

```bash
# 1b. RCON auth + command (uses config.py for host/port/password)
cd /Users/pete/dotfiles/factorio
python3 verify_rcon_password.py
# Expect: "Connection successful!" and "Command test successful!"
```

**If Step 1 fails:**
- Port closed → Factorio app not running or not listening on 27015. In TrueNAS: **Apps → factorio** → Start; check app **Ports** for `27015/tcp`.
- Auth error → Wrong `RCON_PASSWORD`. Get it from the Factorio app env in TrueNAS or from the container/config where Factorio is defined.
- From Mac, use `192.168.0.158` instead of `127.0.0.1`; if that fails, firewall/NAT may be blocking 27015.

---

## Step 2: Controller is up and RCON-connected

**Link:** Controller process is running and has an open RCON connection to Factorio.

**From NAS (same host as controller):**
```bash
curl -s http://127.0.0.1:8080/health
# Expect: {"status":"healthy","rcon":"connected","service":"factorio-http-controller"}
```

**If Step 2 fails:**
- Connection refused / no route → Controller app not running or not listening on 8080. In TrueNAS: **Apps → controller** (or your controller app name) → Start. Confirm the app uses **host** network and port 8080.
- `"rcon":"disconnected"` → Controller is up but RCON to Factorio failed. Fix Step 1 first; then set the controller’s env `RCON_HOST`, `RCON_PORT`, `RCON_PASSWORD` to match Factorio (use `127.0.0.1` and 27015 if both are host-network on the NAS). Restart the controller app.

---

## Step 3: n8n can reach the controller

**Link:** n8n (host network) → `http://localhost:8080`.

**Check:** n8n must use **host** network so that `localhost` is the NAS. Then any request from n8n to `http://localhost:8080/...` goes to the controller.

**From NAS (simulates what n8n should see):**
```bash
curl -s http://localhost:8080/health
# Same as Step 2. If this works, n8n on host network can reach the controller.
```

**End-to-end action test:**
```bash
curl -s -X POST http://localhost:8080/execute-action \
  -H 'Content-Type: application/json' \
  -d '{"agent_id":"1","action":"walk_to","params":{"x":0,"y":0}}'
# Expect: JSON with "success" true or a clear error (e.g. "Unknown interface: agent_1" if no agent exists yet).
```

**If Step 3 fails:**
- n8n not on host network → Change n8n app to use **host** network (see your n8n TrueNAS/k8s config). Then n8n uses `http://localhost:8080/execute-action`.
- n8n still can’t reach 8080 → From a shell on the NAS, `curl http://localhost:8080/health`. If that works but n8n doesn’t, n8n is not on the host network.

---

## Step 4: (Optional) Ollama

If workflows call Ollama (e.g. for LLM steps), the controller must reach Ollama. From the controller’s perspective, `OLLAMA_HOST`/`OLLAMA_PORT` must be reachable. If Ollama runs on your Mac at 192.168.0.30:11434, ensure the NAS can reach it:

```bash
# From NAS
curl -s http://192.168.0.30:11434/api/tags
# Expect: JSON list of models
```

---

## Verify script

Use the script to run Steps 1–3 in one go:

```bash
cd /Users/pete/dotfiles/factorio
export RCON_PASSWORD='your_rcon_password'   # or rely on config.py when run from Mac
./verify_connections.sh
```

Script behaviour:
- **Step 1:** TCP to RCON port, then RCON auth+command if `RCON_PASSWORD` is set.
- **Step 2:** `GET /health` and check `rcon` is `connected`.
- **Step 3:** `POST /execute-action` with a harmless `walk_to` and check JSON response.

It exits at the first failure and prints what to fix. See script header for env vars (e.g. `RCON_HOST`, `CONTROLLER_URL`).

---

## Order of fixes

1. **Factorio RCON (Step 1)** — Must work first. Without it, the controller will show `rcon: disconnected`.
2. **Controller app (Step 2)** — Image/entrypoint correct, env vars set, host network, 8080 bound.
3. **n8n → controller (Step 3)** — n8n on host network, workflow URL = `http://localhost:8080/execute-action`.

Do not debug n8n workflows or FV mod behaviour until Steps 1–3 all pass.
