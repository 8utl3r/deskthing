# Cua (Computer-Use Agent) MCP Server - Cursor Setup

## What Cua is

**Cua** is the [Computer-Use Agent](https://cursor.directory/mcp/cua-computer-use-agent) MCP server. It lets Cursor’s Composer agents run computer-use workflows on **Apple Silicon macOS**: take screenshots, click, type, and run code inside an isolated environment. Agents get tools to run tasks in an isolated macOS sandbox (observe screen, click, type, run code) without driving your host machine directly. It uses Apple’s Virtualization.framework via [Lume](https://cua.ai/docs/lume) for a virtual macOS sandbox.

## Prerequisites

- **macOS on Apple Silicon** (M1/M2/M3/M4) — required for the MCP server’s Lume/macOS sandbox.
- **Python 3.10+** — the Cua install script uses `python3` on your PATH (e.g. you already use 3.12 via mise).
- **A model for the sandbox** — either a **local model** (free, via Ollama) or a **cloud API** (e.g. Anthropic; paid per use). You do **not** have to pay: use Ollama and set `CUA_MODEL_NAME` to an Ollama model (see below).
- **Lume** — used under the hood for the macOS VM; the official install script and Cua stack handle this.

## Install steps

Run once (or on each new machine):

```bash
curl -fsSL https://raw.githubusercontent.com/trycua/cua/main/libs/python/mcp-server/scripts/install_mcp_server.sh | bash
```

This creates:

- **`~/.cua/start_mcp_server.sh`** — startup script for the MCP server.
- **`~/.cua-mcp-venv`** (or `/tmp` if needed) — Python venv where `cua-mcp-server` is installed.

These paths are **not** in dotfiles; dotfiles only add the MCP entry and this documentation.

## Cursor config

The `cua` server entry is in **`cursor/mcp.json`** in this repo. The link script already links that file:

- **Source:** `~/dotfiles/cursor/mcp.json`
- **Target:** `~/.cursor/mcp.json`

So after you run `scripts/system/link` (or `bin/link`), the Cua MCP config is deployed. No change to the link script is required.

Example entry (already added) — using a **local Ollama model** (no API key, no cost):

```json
"cua": {
  "command": "/bin/bash",
  "args": ["/Users/pete/.cua/start_mcp_server.sh"],
  "env": {
    "CUA_MODEL_NAME": "ollama/llava"
  }
}
```

Use a vision-capable Ollama model (e.g. `llava`, `llava:latest`, or another vision model you’ve pulled). No API key needed.

## Environment variables

- **`CUA_MODEL_NAME`** — model used for task execution in the sandbox. Set in `cursor/mcp.json` `env` (no secret).
  - **Local (free):** `ollama/llava`, `ollama/llava:latest`, or another [Ollama vision model](https://ollama.com/library) you have pulled. No API key required.
  - **Cloud (paid):** e.g. `anthropic/claude-sonnet-4-20250514` — requires the corresponding API key in your environment.
- **`ANTHROPIC_API_KEY`** — only needed if `CUA_MODEL_NAME` is an Anthropic model. Do **not** put it in `mcp.json` or commit it. Set it in your environment (e.g. `~/.zshrc`: `export ANTHROPIC_API_KEY="..."`).

**Summary:** You do **not** have to pay. Use `CUA_MODEL_NAME": "ollama/llava"` (or another Ollama vision model) and leave `ANTHROPIC_API_KEY` unset. If you prefer a cloud model, set an Anthropic model name and your API key (usage is billed by Anthropic).

## Verification

1. **One-time install:** Ensure you’ve run the install script so `~/.cua/start_mcp_server.sh` exists.
2. **Link config:** Run `~/dotfiles/scripts/system/link` (or `bin/link`) so `~/.cursor/mcp.json` is linked from dotfiles.
3. **Restart Cursor** so it loads the Cua MCP server.
4. In **Composer**, confirm the Cua MCP server appears and its tools are available (e.g. tools for running computer-use tasks in the sandbox).
5. **Quick test:** Ask the agent to run a simple computer-use task in the sandbox (e.g. “Open the calculator in the Cua sandbox” or similar, per Cua’s tool descriptions).

## How agents use it

In Composer, agents can call Cua’s MCP tools to drive the isolated macOS sandbox: observe the screen, click, type, and run code. The loop continues until the task is done or the agent decides it cannot proceed. The host machine is not controlled; only the sandbox is.

## References

- [Cua – Computer-Use Agent (Cursor Directory)](https://cursor.directory/mcp/cua-computer-use-agent)
- [Cua docs](https://cua.ai/docs)
- [Lume (macOS virtualization)](https://cua.ai/docs/lume)
