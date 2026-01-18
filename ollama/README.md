# Ollama Configuration

Ollama is a tool for running large language models locally on your machine.

## Installation

Ollama is installed via Homebrew and managed in the `Brewfile`.

**CLI Tool**:
```bash
brew install ollama
```

**Desktop GUI App** (installed):
```bash
brew install --cask ollama-app
```

The desktop app provides a graphical interface for managing models and chatting with LLMs. Both the CLI and GUI can be used together - they share the same backend service.

**Status**: ✅ Desktop app is installed and available in Applications folder.

## Service Management

Start Ollama as a background service:

```bash
brew services start ollama
```

Stop the service:

```bash
brew services stop ollama
```

Or run it manually (without background service):

```bash
ollama serve
```

## Usage

### Common Commands

- **List installed models**: `ollama list`
- **Pull a model**: `ollama pull <model-name>`
- **Run a model**: `ollama run <model-name>`
- **Show model info**: `ollama show <model-name>`
- **List running models**: `ollama ps`
- **Stop a model**: `ollama stop <model-name>`
- **Remove a model**: `ollama rm <model-name>`

### Popular Models

- `llama3.2` - Meta's Llama 3.2 (3B parameters, fast)
- `llama3.1` - Meta's Llama 3.1 (8B parameters)
- `mistral` - Mistral AI's 7B model
- `codellama` - Code-focused Llama variant
- `phi3` - Microsoft's Phi-3 (small, fast)
- `gemma2` - Google's Gemma 2

### API Access

Ollama runs a local API server on `http://localhost:11434` by default.

Example API call:

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Why is the sky blue?",
  "stream": false
}'
```

## Configuration

Ollama stores models and data in `~/.ollama/` directory. This directory is created automatically when you first use Ollama.

### Environment Variables

- `OLLAMA_HOST` - Set the host and port (default: `localhost:11434`)
- `OLLAMA_MODELS` - Set custom models directory
- `OLLAMA_FLASH_ATTENTION` - Enable flash attention (set to `1`)
- `OLLAMA_KV_CACHE_TYPE` - Set KV cache type (e.g., `q8_0`)

### Aliases

Useful aliases are available in `.zshrc`:
- `ollama-list` - List all installed models
- `ollama-ps` - Show running models
- `ollama-pull` - Pull a model (usage: `ollama-pull llama3.2`)

### Atlas - Private Life Manager

**Status**: ✅ Configured and ready to use

Atlas is a custom-configured Dolphin-Mistral-Nemo 12B model optimized for private life management with ADHD-friendly communication.

**Model Details**:
- **Base**: Dolphin-2.9.3-Mistral-Nemo 12B (Q6_K quantization)
- **Context Window**: 32k tokens (leverages 128k native support)
- **Temperature**: 0.2 (low randomness for reliable scheduling)
- **RAM Usage**: ~9-11GB (leaves ~7GB overhead on 18GB system)

**Quick Start**:
```bash
# Run Atlas
atlas

# Edit system prompt
atlas-prompt

# Reload model after prompt changes
atlas-reload
```

**Configuration Files**:
- `system_prompt.txt` - Modular system prompt (edit to customize behavior)
- `Modelfile.dolphin-mistral-nemo` - Model configuration

**Features**:
- Direct, factual communication (no filler or apologies)
- ADHD accommodations (brevity, structure, scannable responses)
- Life management focus (scheduling, task prioritization, organization)
- Large context window for memory retention across sessions

**Customization**:
1. Edit `system_prompt.txt` to adjust communication style or add requirements
2. Run `atlas-reload` to apply changes
3. Test with `atlas` to verify behavior

See `private_life_manager_architecture.md` for detailed architecture and rationale.

## Desktop GUI App

The Ollama desktop app (`ollama-app`) provides:

- **Chat Interface**: Clean, modern chat UI for interacting with models
- **Model Management**: Download, delete, and switch between models visually
- **File Support**: Drag and drop text, Markdown, PDFs, and code files
- **Streaming Responses**: Real-time streaming of model responses
- **Multimodal Support**: Context-aware conversations with file attachments

Launch the app from Applications or via:
```bash
open -a Ollama
```

## Remote Access via Tailscale

Access Atlas from other devices on your Tailscale network:

**Quick Setup:**
1. Set `OLLAMA_HOST=0.0.0.0:11434` in your environment
2. Restart Ollama: `brew services restart ollama`
3. Get your Tailscale IP: `tailscale ip -4`
4. Connect from remote device: `export OLLAMA_HOST=http://<your-tailscale-ip>:11434`

**Full Guide**: See `tailscale_access.md` for detailed instructions, security considerations, and troubleshooting.

**Security Notes:**
- ✅ All processing remains local on your Mac
- ✅ Traffic encrypted via Tailscale (WireGuard)
- ✅ Only accessible to devices on your Tailscale network
- ⚠️ No built-in authentication (rely on Tailscale ACLs)

## Atlas Proxy

The Atlas Proxy (`proxy/`) adds persistence, file operations, and context injection to Atlas:

- **Variable Persistence**: Variables persist across sessions
- **File Operations**: Create, read, update, delete, move, copy, search, list, and archive files
- **Context Injection**: Automatic injection of file listings and variables into prompts
- **Conversation Logging**: Daily JSON logs of all conversations

**Setup**: See `proxy/README.md` for installation and usage instructions.

**Service Management**:
- Start: `atlas-proxy-start`
- Stop: `atlas-proxy-stop`
- Status: `atlas-proxy-status`
- Logs: `atlas-proxy-logs`

## Integration

Ollama can be integrated with:
- **Desktop GUI**: Native macOS app for visual interaction
- **Cursor IDE**: Use Ollama as a local AI assistant
- **Command line**: Direct CLI access for quick queries
- **API clients**: Any HTTP client can interact with the API
- **Web UIs**: Third-party web interfaces like Open WebUI
- **Atlas Proxy**: Enhanced Atlas with persistence and file operations (see `proxy/README.md`)
- **Other tools**: Many tools support Ollama as a backend
- **Tailscale Network**: Access from remote devices securely (see `tailscale_access.md`)

## Notes

- Models are stored in `~/.ollama/models/` and can be large (several GB each)
- The service runs on port 11434 by default
- First model pull may take time depending on internet speed
- GPU acceleration is automatically used if available

