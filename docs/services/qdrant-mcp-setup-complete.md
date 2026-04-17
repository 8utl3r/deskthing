# Qdrant MCP Server - Complete Setup Guide

## Overview

Qdrant MCP server provides vector database operations to any MCP-compatible agent. It's now fully configured and ready to use.

## ✅ What's Been Set Up

1. **Qdrant running on TrueNAS** ✅
   - URL: `http://192.168.0.158:6333`
   - Status: Running

2. **MCP Server created** ✅
   - Location: `/Users/pete/dotfiles/ollama/qdrant-mcp/qdrant_mcp_server.py`
   - Tools: search, index, health, list collections, get collection info

3. **Cursor MCP config updated** ✅
   - Added to `~/.cursor/mcp.json` (or `~/dotfiles/.cursor/mcp.json`)

## Installation Steps

### 1. Install Dependencies

```bash
cd ~/dotfiles/ollama/qdrant-mcp
pip3 install -r requirements.txt
```

**Or install manually:**
```bash
pip3 install mcp httpx
```

### 2. Install Embedding Model

```bash
ollama pull nomic-embed-text
```

### 3. Verify Configuration

The MCP config is already added to your Cursor config. Check it:

```bash
cat ~/.cursor/mcp.json | grep -A 10 qdrant
```

**Should show:**
```json
"qdrant": {
  "command": "python3",
  "args": [
    "/Users/pete/dotfiles/ollama/qdrant-mcp/qdrant_mcp_server.py"
  ],
  "cwd": "/Users/pete/dotfiles/ollama/qdrant-mcp",
  "env": {
    "QDRANT_URL": "http://192.168.0.158:6333",
    "OLLAMA_URL": "http://localhost:11434",
    "EMBEDDING_MODEL": "nomic-embed-text",
    "QDRANT_COLLECTION": "atlas_conversations"
  }
}
```

### 4. Test the Server

**Test Qdrant connection:**
```bash
curl http://192.168.0.158:6333/health
# Should return: {"status":"ok"}
```

**Test embedding model:**
```bash
curl http://localhost:11434/api/embeddings \
  -d '{"model": "nomic-embed-text", "prompt": "test"}'
# Should return embedding vector
```

**Test MCP server directly:**
```bash
cd ~/dotfiles/ollama/qdrant-mcp
python3 qdrant_mcp_server.py
# Should start without errors
```

### 5. Restart Cursor

**Restart Cursor IDE** to load the new MCP server.

After restart, the Qdrant MCP server should be available to any agent.

## Available Tools

Once connected, any MCP agent can use these tools:

### `qdrant_search`
Search for semantically similar content.

**Example:**
```
Agent: "Search for information about project deadlines"
→ Uses qdrant_search(query="project deadlines")
→ Returns relevant context with source files
```

### `qdrant_index`
Index text with metadata and source file linking.

**Example:**
```
Agent: "Remember this conversation about the project"
→ Uses qdrant_index(text="...", source_file="/path/to/file")
→ Stores in Qdrant for future searches
```

### `qdrant_health`
Check Qdrant server health.

### `qdrant_list_collections`
List all collections.

### `qdrant_get_collection_info`
Get collection information.

## Usage Examples

### In Cursor Chat

Once MCP is connected, you can ask:

```
"Search Qdrant for information about Seafile setup"
→ Agent uses qdrant_search tool
→ Returns relevant context

"Index this conversation about Immich configuration"
→ Agent uses qdrant_index tool
→ Stores conversation for future searches
```

### File Linking

When indexing, include source files:

```python
# Agent can index with file paths
qdrant_index(
    text="The project deadline is December 20, 2025",
    source_file="/mnt/tank/apps/seafile-data/library/Documents/timeline.pdf",
    source_type="seafile",
    metadata={"page": 2, "date": "2025-01-20"}
)
```

When searching, results include source files for verification:

```
Result:
- Source: /mnt/tank/apps/seafile-data/library/Documents/timeline.pdf
- Text: "The project deadline is December 20, 2025"
- Score: 0.85
```

## Troubleshooting

### MCP Server Not Loading

**Check:**
1. Dependencies installed: `pip3 list | grep mcp`
2. Python path correct in mcp.json
3. File permissions: `chmod +x qdrant_mcp_server.py`
4. Cursor restarted

### Connection Errors

**Qdrant connection failed:**
```bash
# Test from Mac
curl http://192.168.0.158:6333/health
ping 192.168.0.158
```

**Ollama connection failed:**
```bash
# Test embedding model
curl http://localhost:11434/api/embeddings \
  -d '{"model": "nomic-embed-text", "prompt": "test"}'
```

### Import Errors

**If `mcp` package not found:**
```bash
pip3 install mcp
```

**If FastMCP import fails:**
```bash
pip3 install --upgrade mcp
```

## Next Steps

1. ✅ Install dependencies
2. ✅ Install embedding model
3. ✅ Restart Cursor
4. 🔲 Test tools in Cursor chat
5. 🔲 Index some test conversations
6. 🔲 Search for indexed content

---

**Qdrant MCP server is ready! Any agent can now connect and use vector search.**
