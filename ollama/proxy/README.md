# Atlas Proxy

HTTP proxy service for Atlas private life manager that adds persistence, file operations, and context injection.

## Overview

The Atlas Proxy intercepts requests to Ollama, injects context (variables, file listings), forwards to Ollama, parses responses for commands, executes file operations, updates variables, and logs conversations.

## Components

- **Config** (`components/config.py`) - Configuration management with environment variable support
- **VariableManager** (`components/variable_manager.py`) - Persistent variable storage and parsing
- **FileOperationsManager** (`components/file_ops.py`) - Secure file CRUD operations
- **CommandParser** (`components/command_parser.py`) - Parses FILE_* commands and variable assignments
- **ContextInjector** (`components/context_injector.py`) - Loads and injects file context into prompts
- **ConversationLogger** (`components/conversation_logger.py`) - Logs conversations to daily JSON files
- **HTTP Proxy Server** (`atlas_proxy.py`) - FastAPI server that integrates all components

## Installation

1. Install dependencies:
```bash
cd /Users/pete/dotfiles/ollama/proxy
pip install -r requirements.txt
```

2. Install LaunchAgent:
```bash
cp homebrew.mxcl.atlas-proxy.plist ~/Library/LaunchAgents/
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.atlas-proxy.plist
```

3. Start the proxy:
```bash
atlas-proxy-start
```

Or run manually:
```bash
python3 main.py
```

## Configuration

Configuration is managed via environment variables (with `ATLAS_` prefix) or `config.json`:

- `ATLAS_PROXY_PORT` - Proxy server port (default: 11435)
- `ATLAS_OLLAMA_URL` - Ollama API URL (default: http://localhost:11434)
- `ATLAS_DATA_DIR` - Data directory (default: ~/dotfiles/ollama/data)
- `ATLAS_MAX_CONTEXT_SIZE` - Max context size in characters (default: 2000)
- `ATLAS_LOG_RETENTION_DAYS` - Log retention period (default: 30)

## Usage

### Via Proxy (Recommended)

Point your Ollama client to `http://localhost:11435` instead of `http://localhost:11434`.

The proxy adds:
- Variable persistence across sessions
- File operation commands (FILE_CREATE, FILE_READ, etc.)
- Context injection (file listings, variables)
- Conversation logging

### Shell Aliases

- `atlas-proxy-start` - Start the proxy service
- `atlas-proxy-stop` - Stop the proxy service
- `atlas-proxy-restart` - Restart the proxy service
- `atlas-proxy-status` - Check if proxy is running
- `atlas-proxy-logs` - View proxy logs

## File Operations

Atlas can perform file operations using structured commands:

- `**FILE_CREATE** path "content"` - Create a new file
- `**FILE_READ** path` - Read file content
- `**FILE_UPDATE** path "content"` - Replace entire file
- `**FILE_APPEND** path "content"` - Append to file
- `**FILE_DELETE** path` - Delete file
- `**FILE_MOVE** old_path "new_path"` - Move/rename file
- `**FILE_COPY** src_path "dst_path"` - Copy file
- `**FILE_SEARCH** directory "term"` - Search for text in files
- `**FILE_LIST** directory` - List files in directory
- `**FILE_ARCHIVE** path` - Move to archive/

Files are stored in `data/files/` and restricted to `.txt` and `.md` extensions by default.

## Variable Management

Variables persist across sessions in `data/variables.json`. Atlas can:

- Set variables: "x = 10", "set y to 3", "remember z is 5"
- Use variables in calculations: "what is y-x?"
- Variables are automatically injected into prompts

## Testing

Run all component tests:
```bash
cd /Users/pete/dotfiles/ollama/proxy
python3 -m pytest components/tests/ -v
```

Run proxy tests:
```bash
python3 -m pytest tests/ -v
```

## Architecture

```
Client → Proxy (11435) → Ollama (11434)
         ↓
    [Context Injection]
    [Command Parsing]
    [File Operations]
    [Variable Updates]
    [Conversation Logging]
```

## Development

All components are in `components/` with tests in `components/tests/`. The proxy server integrates all components in `atlas_proxy.py`.
