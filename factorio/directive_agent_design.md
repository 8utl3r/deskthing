# Directive-driven agent design

**Goal:** Set up an agent, give them a **directive** (e.g. "produce 100 iron gears"), and have the LLM **figure out how** to get there. The LLM learns and creates/updates its own workflows for efficiency. The controller supports **queued action chains** and **reports results** back so the LLM can adapt.

---

## Design pillars

1. **Controller: queue + results**  
   - LLM submits **action chains** (ordered lists of actions), not one-off calls.  
   - Controller **queues** them, runs them (or streams results as they complete), and **reports outcomes** (success/fail, state delta, errors) back to the LLM.  
   - Enables complex plans without round-tripping after every single action.

2. **Directive → plan → execute → report → learn**  
   - Human (or system) gives a **directive** (high-level goal).  
   - LLM **plans** a chain of actions, possibly using stored "workflows" it has learned.  
   - Controller runs the chain (or the next chunk of it), **reports results**.  
   - LLM **observes** results and can **refine plans** or **update its own workflow memory** for next time.

3. **Knowledge: minimal instructions + Qdrant memory**  
   - **Few hand-written rules** about how to play—enough to avoid nonsense, not so much that the LLM can’t explore.  
   - **Factorio wiki + mod docs** (and later, run logs, successful plans) are processed into **Qdrant**.  
   - At run time, **inject context** via semantic search (e.g. "how do I craft X?", "what does walk_to do?") so the LLM has a **memory** without a huge static prompt.

---

## Components

| Component | Role |
|-----------|------|
| **Controller** | Queue actions per agent, execute (via RCON), return structured results (success, message, game-state snippets). Extend API: e.g. `POST /queue-actions` body `{ agent_id, actions: [{ action, params }, ...] }`, and optionally `GET /agent/<id>/result-stream` or poll `GET /agent/<id>/last-results`. |
| **Agent runner / LLM loop** | Accepts a directive, optionally pulls Qdrant context, calls LLM to produce an action chain (or next segment), sends it to the controller, gets results, feeds results back into LLM for next step or for learning. |
| **Qdrant** | Store chunks from Factorio wiki, FV Embodied Agent (and other mod) docs. At request time, query by directive or current situation and inject retrieved chunks into the LLM context. Reuse existing `ollama/qdrant-mcp` and indexing patterns; add a Factorio-specific collection and pipeline (e.g. wiki HTML → text → chunks → embed → Qdrant). |
| **Minimal game instructions** | Short doc or prompt fragment: coordinate system, "you control an agent via actions", list of action names and one-line semantics, how results are reported. No full walkthrough—leave room for the LLM to use Qdrant and experimentation to learn. |

---

## Phased plan

**Phase 1 – Controller verification and action I/O**  
- Treat the controller as the single source of truth.  
- For **each** supported action (see `CONTROLLER_API_REFERENCE.md`): add a small test (or script) that sends the correct request and asserts on the **response shape and semantics** (e.g. `walk_to` returns success when valid; invalid params return a clear error).  
- Fix any action whose input or output is wrong or underspecified so all actions are **individually** correct before adding queueing.  
- **Status:** `factorio/agent_scripts/verify_actions.py` exercises all 13 actions (canonical params per API ref); asserts response has `success` and `message`. Run with `CONTROLLER_URL=http://192.168.0.158:8080 python verify_actions.py` when testing against NAS. Any action I/O fixes from runs go here.

**Phase 2 – Action queue and result reporting**  
- Add controller API for **queued chains**: e.g. `POST /queue-actions` with `{ agent_id, actions: [...] }`.  
- Execution: run actions in order; on async actions (e.g. walk, mine), wait for completion (or use FV mod’s UDP/completion behavior) and capture result.  
- Report back: **per-step or per-chain** result payload (e.g. `{ step_index, action, success, message?, state_snapshot? }`).  
- Document the new endpoints and response format; keep existing `POST /execute-action` for single-action compatibility.  
- **Status:** Implemented. `POST /queue-actions` in controller; request `{ agent_id, actions: [{ action, params }, ...] }`, response `{ results, overall_success }`. Client: `queue_actions(agent_id, actions)` in `controller_client.py`. Smoke test: `verify_queue.py` (same run pattern as verify_actions). See `CONTROLLER_API_REFERENCE.md` → “Queue Actions (Phase 2)”.

**Phase 3 – Directive loop and workflow learning**  
- Implement a **directive loop**: directive in → LLM (with Qdrant context) → plan (action chain or next segment) → controller → results back → LLM updates plan or decides "done" / "retry" / "learn".  
- Add a **workflow memory**: when the LLM finishes a directive successfully, it can store a compact "workflow" (e.g. name + ordered action template) in Qdrant or a small store, and later **retrieve and refine** it for similar directives.  
- Start with a simple loop (one directive → one chain → one report); later add iteration and workflow read/write.

**Phase 4 – Qdrant as Factorio memory**  
- **Collections:** e.g. `factorio_wiki`, `factorio_mod_fv_embodied_agent`, optionally `factorio_workflows` (learned procedures).  
- **Ingest:** process Factorio wiki (and mod docs) into chunks; embed (e.g. via Ollama embeddings or existing qdrant-mcp path); upsert into Qdrant with metadata (source, section, type).  
- **At runtime:** given current directive and/or game state, run semantic search, inject top-k chunks into the LLM context so it can reason about recipes, entities, and mod actions without bloating the base prompt.

---

## Out of scope for this doc

- Exact API schemas for queue/result (those go in `CONTROLLER_API_REFERENCE.md` or a new `CONTROLLER_QUEUE_API.md` once Phase 2 is designed).  
- Ollama vs other LLM backends (design is LLM-agnostic).  
- n8n: the directive-driven, queue-and-report flow is **Python-first**; n8n can still call the controller if we keep the HTTP API consistent.

---

## References

- **Controller API (current):** `factorio/CONTROLLER_API_REFERENCE.md`  
- **FV Embodied Agent:** `factorio/fv_embodied_agent_api_guide.md`  
- **Qdrant MCP + indexing:** `ollama/qdrant-mcp/README.md`, `index_wikipedia.py` (pattern for chunking and embedding); add Factorio-specific ingest scripts and collection names.  
- **Minimal game instructions:** to be drafted in Phase 1–2 and kept short; Qdrant holds the rest.
