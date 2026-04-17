# Qwen3-TTS 0.6B (no phone-home)

Runs **Qwen3-TTS 0.6B** on macOS with **MPS** (Metal), patched so ref audio is local and inference can run with **no network** (sandbox).

## One-time setup (requires network)

```bash
./scripts/qwen3-tts/setup.sh
```

- Installs Homebrew deps: `portaudio`, `ffmpeg`, `sox`
- Clones [Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS) to `~/.local/share/qwen3-tts/repo`
- Creates a venv and installs `qwen-tts`
- Downloads reference audio for voice clone (so later runs need no network)
- Patches the example script: **0.6B** model, **MPS**/sdpa, local ref audio, `mps.synchronize()` fix

Override install location:

```bash
QWEN3_TTS_HOME=~/opt/qwen3-tts ./scripts/qwen3-tts/setup.sh
```

## First run (download model; needs network)

Downloads the ~2.5GB model once:

```bash
./scripts/qwen3-tts/run.sh --allow-network
```

## Later runs (no network)

Runs the example under the no-network sandbox so the process cannot reach the internet:

```bash
./scripts/qwen3-tts/run.sh
```

Output WAVs go to `qwen3_tts_test_voice_clone_output_wav/` in the repo directory (under your install dir).

## What gets patched

- **Model:** `Qwen/Qwen3-TTS-12Hz-0.6B-Base`
- **Device:** MPS if available, else CUDA, else CPU
- **Attention:** `sdpa` (Mac-compatible; no FlashAttention)
- **Ref audio:** Local files under `$QWEN3_TTS_REF_AUDIO_DIR` (set by run.sh)
- **Sync:** `torch.mps.synchronize()` when on MPS

## Configuration

Settings (model, output dir, temperature, top_k, etc.) are controlled by **environment variables**. See **[CONFIG.md](CONFIG.md)** for the full list and examples.

## Requirements

- macOS (for MPS and sandbox)
- Python 3.9+
- 18 GB RAM is enough for 0.6B
