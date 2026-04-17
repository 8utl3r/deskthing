# Ollama Connection - Not MCP

## Clarification

**Ollama is NOT an MCP connection.** It's a local HTTP API server.

### What is Ollama?

**Ollama** is a local LLM (Large Language Model) server that runs on your machine. It provides:
- Local model inference (no cloud API needed)
- HTTP REST API at `http://localhost:11434`
- Python library (`ollama` package) that wraps the HTTP API

### What is MCP?

**MCP (Model Context Protocol)** is a protocol used by Cursor IDE for tool integration. It's a different thing entirely:
- Used for Cursor IDE extensions
- Allows AI assistants to call tools/functions
- Examples in your setup: `qdrant-mcp`, `n8n-mcp` (in `cursor/mcp.json`)

### How Ollama Works in This Project

```
Python Controller → HTTP Request → Ollama Server (localhost:11434) → LLM Model → Response
```

**Connection Method**: HTTP REST API, not MCP

**Python Usage**:
```python
import ollama

# This makes an HTTP POST request to http://localhost:11434/api/chat
response = ollama.chat(
    model="mistral",
    messages=[
        {"role": "user", "content": "What should I do?"}
    ]
)
```

**Under the hood**, the `ollama` Python library:
1. Makes HTTP POST to `http://localhost:11434/api/chat`
2. Sends JSON payload with model name and messages
3. Receives JSON response with LLM output
4. Returns parsed response

### Why the Confusion?

You might see MCP mentioned because:
- Cursor IDE uses MCP for tool integration
- You have MCP servers configured in `cursor/mcp.json`
- But Ollama itself is just an HTTP API server

### Architecture

```
┌─────────────────┐
│  Factorio       │
│  Server         │
│  (RCON)         │
└────────┬────────┘
         │ TCP 27015
         │
┌────────▼────────┐
│  Python         │
│  Controller     │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    │         │
┌───▼───┐ ┌──▼──────┐
│ Ollama│ │ Factorio│
│ HTTP  │ │ RCON    │
│ API   │ │ Client  │
└───────┘ └─────────┘
```

### Summary

- **Ollama**: HTTP API server (port 11434)
- **MCP**: Protocol for Cursor IDE tool integration
- **Our Setup**: Python controller uses Ollama's HTTP API, not MCP
- **Connection**: Direct HTTP requests via `ollama` Python library
