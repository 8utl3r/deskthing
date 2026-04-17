#!/usr/bin/env bash
# One-time setup for Qwen3-TTS 0.6B on macOS (MPS). Run with network.
# After this, use run.sh (no network) for inference.
set -e
INSTALL_DIR="${QWEN3_TTS_HOME:-$HOME/.local/share/qwen3-tts}"
REPO_DIR="$INSTALL_DIR/repo"
REF_AUDIO_DIR="$INSTALL_DIR/ref_audio"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_SANDBOX="${SCRIPT_DIR}/../sandbox"

echo "Install dir: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR" "$REF_AUDIO_DIR"
cd "$INSTALL_DIR"

# --- System deps (macOS) ---
if [[ "$(uname)" == "Darwin" ]]; then
  if ! command -v sox &>/dev/null || ! command -v ffmpeg &>/dev/null; then
    echo "Installing Homebrew deps (portaudio, ffmpeg, sox)..."
    brew install portaudio ffmpeg sox
  fi
fi

# --- Clone repo ---
if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "Cloning Qwen3-TTS..."
  git clone --depth 1 https://github.com/QwenLM/Qwen3-TTS.git "$REPO_DIR"
fi
cd "$REPO_DIR"

# --- Venv and pip install ---
if [[ ! -d "$INSTALL_DIR/.venv" ]]; then
  echo "Creating venv..."
  python3 -m venv "$INSTALL_DIR/.venv"
fi
# shellcheck source=/dev/null
source "$INSTALL_DIR/.venv/bin/activate"
pip install -U pip -q
pip install -e . -q

# --- Download ref audio (required for no-network runs) ---
for name in clone_1 clone_2; do
  if [[ ! -f "$REF_AUDIO_DIR/${name}.wav" ]]; then
    echo "Downloading ref audio ${name}.wav..."
    curl -sSfL "https://qianwen-res.oss-cn-beijing.aliyuncs.com/Qwen3-TTS-Repo/${name}.wav" -o "$REF_AUDIO_DIR/${name}.wav"
  fi
done

# --- Patch example script: 0.6B, MPS, local ref audio, sync ---
EXAMPLE="$REPO_DIR/examples/test_model_12hz_base.py"
if [[ -f "$EXAMPLE" ]]; then
  echo "Patching example script for 0.6B and MPS..."
  export QWEN3_TTS_REF_AUDIO_DIR="$REF_AUDIO_DIR"
  (cd "$REPO_DIR" && python3 "$SCRIPT_DIR/patch_example.py")
fi

echo "Setup done. Next:"
echo "  1) First run (downloads ~2.5GB model; needs network):"
echo "     $SCRIPT_DIR/run.sh --allow-network"
echo "  2) Later runs (no network):"
echo "     $SCRIPT_DIR/run.sh"
echo "Install dir: $INSTALL_DIR"
