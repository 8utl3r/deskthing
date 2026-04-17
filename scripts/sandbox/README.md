# Sandbox scripts (macOS)

Run commands with restricted capabilities using `sandbox-exec`.

## no-network.sb

Profile that allows normal file/process access but **denies all network**. Useful for running untrusted or unverified apps (e.g. Qwen3-TTS) after initial model download so they cannot phone home during inference.

## run-no-network.sh

Wrapper that runs a command under the no-network sandbox.

```bash
# From this repo (or set SCRIPT_DIR)
./run-no-network.sh -- python /path/to/examples/test_model_12hz_base.py

# Or from anywhere, call with absolute path to script and profile
/path/to/dotfiles/scripts/sandbox/run-no-network.sh -- python -c "import urllib.request; urllib.request.urlopen('https://example.com')"
# → will fail with sandbox denial
```

**Requirements:** macOS (sandbox-exec is not available on Linux). The sandbox is undocumented/deprecated; use at your own risk.

**Qwen3-TTS workflow:** Download models first with network allowed, then for subsequent runs use this wrapper so the process cannot reach the internet.
