You are building the HTTP Proxy Server for Atlas. This integrates all components into a FastAPI server.

**FIRST STEP:** Create a file `proxy/agents/http_proxy/PROMPT.md` and copy this entire prompt into it for future reference.

**Goal:** Build a FastAPI server that intercepts Ollama requests, injects context, forwards to Ollama, parses responses, executes commands, updates variables, logs conversations.

**Requirements:**

- Create `proxy/atlas_proxy.py` with FastAPI app
- Create `proxy/main.py` as entry point
- Endpoints:
  - `POST /api/chat` - Main endpoint (intercept, process, forward)
  - `GET /health` - Health check
  - All other routes - Proxy directly to Ollama (11434)

**Flow for /api/chat:**

1. Load variables (VariableManager)
2. Load file context (ContextInjector)
3. Format context (ContextInjector)
4. Inject into messages (ContextInjector)
5. Forward to Ollama (httpx client)
6. Parse response (CommandParser)
7. Execute file commands (FileOperationsManager)
8. Update variables (VariableManager)
9. Log conversation (ConversationLogger)
10. Return response

**Implementation Notes:**

- Initialize all components with Config
- Use httpx.AsyncClient for Ollama requests
- Handle errors gracefully (return error responses)
- Add CORS middleware for web clients
- Log requests/responses for debugging
- Use async/await for HTTP operations

**Testing:**

- Create `proxy/tests/test_proxy.py`
- Test /health endpoint
- Test /api/chat endpoint (mock Ollama)
- Test error handling
- Test CORS headers

**Deliverables:**

- `proxy/atlas_proxy.py` (working FastAPI server)
- `proxy/main.py` (entry point that starts server)
- `proxy/tests/test_proxy.py` (basic tests)
- Brief note in `proxy/agents/http_proxy/COMPLETED.md`

**Success Criteria:**

- Server starts successfully
- /health endpoint works
- /api/chat implements full flow
- Other routes proxy to Ollama
- CORS configured
- Basic error handling
- Get it working - refine later




