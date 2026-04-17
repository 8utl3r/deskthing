#!/usr/bin/env bash
# Run Qwen3-TTS 0.6B example. By default runs with no network (sandbox).
# First time: run with --allow-network to download the model (~2.5GB).
set -e
INSTALL_DIR="${QWEN3_TTS_HOME:-$HOME/.local/share/qwen3-tts}"
REPO_DIR="$INSTALL_DIR/repo"
REF_AUDIO_DIR="$INSTALL_DIR/ref_audio"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_SCRIPT="$SCRIPT_DIR/../sandbox/run-no-network.sh"

ALLOW_NETWORK=false
if [[ "${1:-}" == "--allow-network" ]]; then
  ALLOW_NETWORK=true
  shift
fi

if [[ ! -d "$INSTALL_DIR/.venv" ]] || [[ ! -d "$REPO_DIR" ]]; then
  echo "Run setup first: $SCRIPT_DIR/setup.sh" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$INSTALL_DIR/.venv/bin/activate"
export QWEN3_TTS_REF_AUDIO_DIR="$REF_AUDIO_DIR"
cd "$REPO_DIR"

if [[ "$ALLOW_NETWORK" == true ]]; then
  echo "Running with network (model download if needed)..."
  exec python "$SCRIPT_DIR/run_example.py" "$@"
else
  echo "Running with no network (sandbox)..."
  exec "$SANDBOX_SCRIPT" -- python "$SCRIPT_DIR/run_example.py" "$@"
fi
