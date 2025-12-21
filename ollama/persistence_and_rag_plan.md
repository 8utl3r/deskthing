# Atlas Persistence & RAG Implementation Plan

## Overview

Add two capabilities to Atlas:
1. **Cross-Session Persistence**: Variables and context survive terminal restarts
2. **RAG (Retrieval Augmented Generation)**: Search past conversations and documents for relevant context

## Part 1: Cross-Session Persistence

### Architecture (Non-Terminal Usage)

**Problem**: User uses Atlas via web client, desktop app, or other methods - not terminal. Shell aliases won't work.

**Solution**: API Proxy/Middleware that intercepts Ollama requests and injects context.

**Storage Structure**:
```
ollama/
├── data/
│   ├── variables.json       # Persistent variable storage
│   ├── context.json        # Session summaries, key facts
│   └── history/            # Conversation logs (for RAG)
│       └── YYYY-MM-DD.json # Daily conversation logs
├── proxy/
│   ├── atlas-proxy.js      # Node.js proxy server (or Python)
│   └── package.json        # Dependencies
```

**How It Works**:
1. Variables stored in `variables.json` (JSON format)
2. **Proxy Service** runs on different port (e.g., 11435)
   - Intercepts all requests to Ollama API
   - Reads `variables.json` before each request
   - Formats as: "**Variables**: x=10, y=3, project_deadline=2025-12-20"
   - Prepends to user message in chat request
   - After response, parses Atlas output for variable updates
   - Updates `variables.json` if variables were set
3. Clients connect to proxy instead of Ollama directly
4. Proxy forwards requests to Ollama (localhost:11434) with injected context
5. Variables persist across sessions

**Implementation Options**:

### Option 1: Node.js Proxy (Recommended)
- Lightweight, fast
- Easy HTTP request interception
- Good JSON handling
- Can use existing Node.js ecosystem

### Option 2: Python Proxy
- If you prefer Python
- Flask/FastAPI for HTTP
- Good for ChromaDB integration (if chosen)

### Option 3: Go Proxy
- Fastest, most efficient
- Single binary
- More complex to implement

**Proxy Flow**:
```
Client → Proxy (11435) → Ollama (11434)
         ↓
    Inject variables
    Inject RAG context
    Log conversation
    Update variables
```

**Client Configuration**:
- Web clients: Point to `http://localhost:11435` instead of `http://localhost:11434`
- Desktop app: May need proxy or custom endpoint configuration
- Terminal: Can still use `atlas` alias (bypasses proxy) or use proxy directly

**Proxy Implementation Details**:

**Node.js Proxy Example** (`atlas-proxy.js`):
```javascript
// Intercepts /api/chat requests
// Reads variables.json
// Prepends variables to first user message
// Forwards to Ollama
// Logs conversation
// Updates variables.json if Atlas sets any
```

**Service Management**:
- Run as background service (similar to Ollama)
- Can use `brew services` or LaunchAgent
- Auto-start with system
- Health check endpoint

**Client Compatibility**:
- ✅ Web UIs (Open WebUI, etc.): Configure to use proxy port
- ✅ Desktop App: May need manual endpoint config or proxy wrapper
- ✅ Terminal: `atlas` alias can use proxy or direct Ollama
- ✅ API Clients: Point to proxy endpoint
- ✅ Cursor IDE: Configure Ollama endpoint to proxy

**Fallback**: If proxy not running, clients can still use Ollama directly (without persistence/RAG)

---

## Part 2: RAG (Retrieval Augmented Generation)

### Architecture

**Components**:
1. **Embedding Model**: Use Ollama's embedding model (`mxbai-embed-large` or `nomic-embed-text`)
2. **Vector Database**: SQLite with `sqlite-vec` extension (lightweight, local)
3. **Storage**: Conversation chunks, documents, key facts
4. **Retrieval**: Search relevant context before each query

**Storage Structure**:
```
ollama/
├── data/
│   ├── rag.db              # SQLite database with vector store
│   ├── documents/          # User documents to index
│   └── history/            # Conversation logs
```

**How It Works**:
1. **Indexing Phase**:
   - Conversations are chunked and embedded
   - Stored in SQLite vector database with metadata (date, topic, etc.)
   - Documents can be added: `atlas-index <file>` command

2. **Query Phase** (before each Atlas request - in proxy):
   - Generate embedding for user query (via Ollama embedding API)
   - Search vector DB for top N relevant chunks
   - Inject retrieved context into prompt: "**Relevant Context**: [retrieved chunks]"
   - Proxy prepends context to user message
   - Atlas uses this context to answer

3. **Automatic Indexing**:
   - After each conversation, chunk and index the exchange
   - Build searchable knowledge base over time

**Implementation Options**:

### Option A: Lightweight (SQLite + sqlite-vec)
- **Pros**: No external services, simple, local
- **Cons**: Requires sqlite-vec extension (may need compilation)
- **Best for**: Getting started quickly

### Option B: ChromaDB (Python-based)
- **Pros**: Easy to use, good Python ecosystem
- **Cons**: Requires Python, more dependencies
- **Best for**: If you're comfortable with Python

### Option C: Qdrant (Dedicated vector DB)
- **Pros**: Most powerful, production-ready
- **Cons**: Separate service to run, more complex
- **Best for**: Large-scale, production use

### Option D: Simple File-Based (No Vector DB)
- **Pros**: Simplest, no dependencies
- **Cons**: Less efficient, limited search
- **How**: Store conversations in JSON, use text search
- **Best for**: Minimal setup, small scale

---

## Recommended Approach: Hybrid

**Phase 1: Simple Persistence (Start Here)**
- File-based variable storage
- Modified `atlas` alias injects variables
- Conversation logging to JSON files
- Simple text search for recent conversations

**Phase 2: Add RAG (When Needed)**
- Add embedding model via Ollama
- Implement SQLite vector store
- Automatic conversation indexing
- Document indexing capability

---

## Implementation Details

### Variable Persistence

**File Format** (`variables.json`):
```json
{
  "x": 10,
  "y": 3,
  "project_deadline": "2025-12-20",
  "_metadata": {
    "updated": "2025-12-17T22:00:00Z"
  }
}
```

**Proxy Implementation** (Node.js example):
```javascript
// atlas-proxy.js
// 1. Listen on port 11435
// 2. Intercept POST /api/chat
// 3. Read variables.json
// 4. Generate RAG context (if enabled)
// 5. Inject into messages array
// 6. Forward to Ollama (localhost:11434)
// 7. Log response
// 8. Parse and update variables.json if needed
// 9. Return response to client
```

**Terminal Alias** (optional, for direct use):
```bash
atlas() {
  # Option 1: Use proxy
  curl -X POST http://localhost:11435/api/chat \
    -d "{\"model\": \"atlas\", \"messages\": [{\"role\": \"user\", \"content\": \"$*\"}]}"
  
  # Option 2: Direct (no persistence)
  ollama run atlas "$@"
}
```

### RAG Implementation

**Conversation Logging**:
- After each exchange, log to `data/history/YYYY-MM-DD.json`
- Format: `{"timestamp": "...", "user": "...", "atlas": "...", "variables_used": [...]}`

**Embedding & Search**:
- Use Ollama API for embeddings: `curl http://localhost:11434/api/embeddings`
- Store in SQLite with sqlite-vec
- Before query: search top 3-5 relevant chunks
- Inject as context

---

## Questions

1. **RAG Priority**: Start with simple persistence, or implement RAG immediately?
2. **Vector DB Choice**: See `rag_feature_matrix.md` for detailed comparison
3. **Indexing Scope**: Just conversations, or also documents/files?
4. **Search Granularity**: How many context chunks to retrieve per query? (3-5 recommended)
5. **Proxy Language**: Node.js, Python, or Go? (Node.js recommended for simplicity)

---

## Next Steps

1. **Create proxy service** (Node.js recommended)
   - Intercept Ollama API requests
   - Inject variables from `variables.json`
   - Forward to Ollama
   - Log conversations
   - Update variables after responses

2. **Set up data directory structure**
   - Create `ollama/data/` directory
   - Initialize `variables.json`
   - Create `history/` directory for logs

3. **Configure proxy as service**
   - LaunchAgent or `brew services`
   - Auto-start on boot
   - Health check endpoint

4. **Test with web client/desktop app**
   - Point client to proxy port (11435)
   - Verify variables are injected
   - Test variable persistence

5. **Add RAG (Phase 2)**
   - Choose vector DB (see `rag_feature_matrix.md`)
   - Implement embedding generation
   - Add vector search to proxy
   - Auto-index conversations

**See `rag_feature_matrix.md` for detailed RAG option comparison.**

