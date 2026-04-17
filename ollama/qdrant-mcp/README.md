# Qdrant MCP Server

MCP server for Qdrant vector database operations. Provides tools for any MCP-compatible agent to:
- Search vectors semantically
- Index text with metadata
- Manage collections
- Health checks

## Installation

```bash
cd ~/dotfiles/ollama/qdrant-mcp
pip install -r requirements.txt
```

## Configuration

Set environment variables:

```bash
export QDRANT_URL="http://192.168.0.158:6333"
export OLLAMA_URL="http://localhost:11434"
export EMBEDDING_MODEL="nomic-embed-text"
export QDRANT_COLLECTION="atlas_conversations"
```

Or edit the defaults in `qdrant_mcp_server.py`.

## Add to Cursor MCP Config

Edit `~/.cursor/mcp.json` (or `~/dotfiles/.cursor/mcp.json`):

```json
{
  "mcpServers": {
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
  }
}
```

## Available Tools

### qdrant_search
Search for semantically similar content.

**Parameters:**
- `query` (required): Search query text
- `collection` (optional): Collection name (default: atlas_conversations)
- `limit` (optional): Max results (default: 5)
- `score_threshold` (optional): Min similarity 0-1 (default: 0.7)

### qdrant_index
Index text with metadata and source file linking.

**Parameters:**
- `text` (required): Text to index
- `source_file` (optional): Path to source file
- `source_type` (optional): Type (conversation, seafile, immich, etc.)
- `collection` (optional): Collection name
- `metadata` (optional): Additional metadata JSON

### qdrant_health
Check Qdrant server health.

### qdrant_list_collections
List all collections.

### qdrant_get_collection_info
Get collection information.

## Usage

Once configured, any MCP-compatible agent can use these tools:

```
Agent: "Search for information about project deadlines"
→ Uses qdrant_search tool
→ Returns relevant context with source files

Agent: "Remember this conversation"
→ Uses qdrant_index tool
→ Stores conversation with metadata
```

## Testing

Test the server directly:

```bash
python3 qdrant_mcp_server.py
```

Then use MCP client tools or test via Cursor.
