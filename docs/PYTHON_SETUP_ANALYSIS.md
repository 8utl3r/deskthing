# Python Setup Analysis and Consolidation Plan

**Date:** 2026-02-07

---

## Why Hammerspoon Doesn't See Python (Honestly)

**Short answer:** macOS GUI apps (including Hammerspoon) are launched by `launchd` with a **minimal environment**. Their `PATH` is typically:

```
/usr/bin:/bin:/usr/sbin:/sbin
```

That PATH does **not** include:
- `/opt/homebrew/bin` (Homebrew)
- `~/.local/share/mise/installs/python/3.12.11/bin` (Mise)
- Any shell profile config (`~/.zshrc`, etc.)

Your terminal gets a rich PATH because your shell runs `~/.zshrc`, which runs `eval "$(brew shellenv)"` and `eval "$(mise activate zsh)"`. GUI apps never run those. They inherit whatever `launchd` gives them.

So when Hammerspoon runs a script with shebang `#!/usr/bin/env python3`, the `env` program looks for `python3` in PATH. With minimal PATH, it finds `/usr/bin/python3` (Apple's Python 3.9.6). That *should* work—but in practice, `env` or the script invocation can fail in subtle ways depending on how `hs.execute` spawns the process. Using an explicit Python path avoids that entirely.

---

## Your Python Instances (4 total)

| # | Source | Path | Version | Used by |
|---|--------|------|---------|---------|
| 1 | **Apple** | `/usr/bin/python3` | 3.9.6 | GUI apps (minimal PATH), system scripts |
| 2 | **Mise** | `~/.local/share/mise/installs/python/3.12.11/bin/python3` | 3.12.11 | Your shell (default), dotfiles scripts, atlas-proxy |
| 3 | **Homebrew** | `/opt/homebrew/bin/python3` | 3.14.2 | Homebrew formulae, anything that explicitly uses it |
| 4 | **Homebrew** | `/opt/homebrew/bin/python3.13` | 3.13.9 | Version-pinned scripts |

### How They Got There

- **Apple** — Comes with Xcode Command Line Tools (or macOS). Can’t be removed without breaking system tools.
- **Mise** — Installed by `mise install python@3.12` per `runtimes/mise.toml`. Your shell’s default.
- **Homebrew 3.14** — `brew install python` (or `python@3.14`) makes this the default `python3`.
- **Homebrew 3.13** — `brew install python@3.13` for version-pinned stuff.

### The “Two Python 3s” in System Settings

Most likely:
1. **Xcode Command Line Tools** — Provides `/usr/bin/python3` (3.9.6).
2. **Homebrew** — Adds `/opt/homebrew/bin/python3` (3.14).

These are separate: one from Apple, one from Homebrew.

---

## Problems With Multiple Pythons

1. **Confusion** — Hard to know which `python3` runs where.
2. **GUI apps** — Don’t see shell PATH, so they miss Homebrew/Mise.
3. **Version drift** — 3.9, 3.12, 3.13, 3.14 can cause compatibility issues.
4. **Disk use** — Several full Python installs.

---

## Consolidation Plan

### Phase 1: Pick a Canonical Python (Recommended)

**Recommendation:** Use **Mise Python 3.12** as your main Python.

- Already in `runtimes/mise.toml`
- Used by atlas-proxy and other dotfiles scripts
- Version 3.12 is stable and widely supported
- Reproducible via `mise install`

**Action:** Standardize on Mise 3.12 for new scripts and tooling.

### Phase 2: Remove or Deprioritize Others

| Python | Action | Reason |
|--------|--------|--------|
| **Homebrew 3.14** | Keep for now, or `brew unlink python@3.14` | Some formulae may depend on it; can remove later if unused |
| **Homebrew 3.13** | `brew uninstall python@3.13` if nothing uses it | Duplicate of 3.14 for most use cases |
| **Apple 3.9** | Keep | Needed for system tools; don’t remove |

Check usage before removing:

```bash
# See what uses Homebrew Python
brew uses python@3.14 --installed
brew uses python@3.13 --installed
```

### Phase 3: Give GUI Apps a Proper PATH (Optional)

To make Hammerspoon and other GUI apps see Homebrew/Mise, you can set PATH for your user session:

```bash
# Add to ~/.zprofile (runs at login, before GUI apps)
export PATH="/opt/homebrew/bin:$HOME/.local/share/mise/installs/python/3.12.11/bin:$PATH"
```

Note: `launchd` does not always apply `~/.zprofile` to GUI apps. A more reliable approach is to **launch Hammerspoon from a wrapper** that sets PATH:

```bash
#!/bin/bash
# ~/bin/hammerspoon-with-env
export PATH="/opt/homebrew/bin:$HOME/.local/share/mise/installs/python/3.12.11/bin:$PATH"
open -a Hammerspoon
```

Then use this wrapper instead of launching Hammerspoon directly. For most cases, **using an explicit Python path in script invocations** (as we did for lg-monitor) is simpler and doesn’t require changing how Hammerspoon is launched.

### Phase 4: Document the Canonical Path

**Canonical Python:** `~/.local/share/mise/installs/python/3.12.11/bin/python3`

**Used for:** scripts, services, Hammerspoon-invoked commands, MCP servers (sand-graphics, godot, qdrant).

**Config:** `scripts/lib/python-config.sh` — source in shell scripts to get `PYTHON3_PATH`.

Use this path when you need a specific Python in services, launchd plists, Hammerspoon, or MCP configs.

---

## Summary

| Question | Answer |
|----------|--------|
| Why can’t Hammerspoon see Python? | GUI apps get minimal PATH; Homebrew/Mise paths aren’t there. |
| Do you have multiple Pythons? | Yes: Apple 3.9, Mise 3.12, Homebrew 3.14, Homebrew 3.13. |
| What to do? | Standardize on Mise 3.12; use explicit path in Hammerspoon; optionally remove Homebrew 3.13 if unused. |

---

## Quick Reference: Python Paths

```bash
# Mise (canonical)
~/.local/share/mise/installs/python/3.12.11/bin/python3

# Homebrew
/opt/homebrew/bin/python3        # 3.14
/opt/homebrew/bin/python3.13     # 3.13

# Apple (don’t remove)
/usr/bin/python3                 # 3.9.6
```

---

## Python Version Requirements Report

**Canonical:** Mise Python 3.12.11

| Project | Min Version | Notes | Upgrade to 3.12? |
|---------|-------------|-------|------------------|
| **factorio** | 3.8+ | README; ollama, factorio-rcon-py, requests | ✅ Yes — 3.12 is fine |
| **ollama/proxy** | Not specified | FastAPI, uvicorn, httpx, pydantic | ✅ Yes |
| **ollama/qdrant-mcp** | Not specified | mcp, httpx | ✅ Yes |
| **scripts/servarr-pi5-*** | Not specified | Runs on Pi (remote); uses `python3` on Pi | N/A — remote |
| **atlas-kb** | Own venv | `/Users/pete/atlas/.venv/bin/python` | Leave as-is — isolated |

**Conclusion:** Nothing requires a different Python than Mise 3.12. All dotfiles Python code can use the canonical interpreter.

**Homebrew Python:** `python@3.13` is used by `httpie`; keep it. `python@3.14` is used by `copyparty` and `httpie`; keep it. Don’t uninstall these — they’re needed by formulae.
