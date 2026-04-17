# Qwen3-TTS runner configuration

`run_example.py` (and thus `run.sh`) can be configured via **environment variables**. Set them before running, e.g. in your shell or in a small wrapper script.

---

## What the settings mean (plain English)

The model doesn’t output one fixed “answer” for a sentence; it **samples** from a distribution of possible next sounds. These knobs control that sampling.

- **Temperature**  
  How “random” vs “confident” the choices are.  
  - **Lower (e.g. 0.5–0.7):** more stable, consistent, sometimes flatter.  
  - **Higher (e.g. 0.9–1.0):** more varied, expressive, but can be less consistent or weirder.  
  Start with the default (0.9); try **0.7** if it sounds too all over the place, or **0.95** if it sounds too flat.

- **Top‑K**  
  “Only consider the K most likely next options.”  
  - **Lower:** more focused, can sound repetitive or samey.  
  - **Higher:** more options, more variety, can get noisier.  
  Default 50 is a good middle ground; you rarely need to change it.

- **Top‑P (nucleus)**  
  “Only consider options until we’ve covered P of the total probability.”  
  Similar idea to top‑K but in probability space. 1.0 = “consider everything”; lower = more focused. Usually leave at 1.0 unless you’re tuning for a specific effect.

- **Repetition penalty**  
  Discourages repeating the same sound/phrase over and over.  
  - **Higher (e.g. 1.1):** less repetition, but can sound a bit forced.  
  - **Lower:** more natural repetition, but can get stuck in a loop.  
  Default 1.05 is usually fine.

- **Max new tokens**  
  Upper limit on how long one generated clip can be (in “token” units, roughly related to duration). 2048 is enough for normal sentences; increase only if you’re generating very long passages and it’s cutting off.

- **Subtalker temperature / top‑K / top‑P**  
  The model has an internal “subtalker” that influences **rhythm, emphasis, and pacing** (not the words themselves). These are the same kind of knobs but for that part.  
  - Same intuition: **lower subtalker temperature** = more steady pacing; **higher** = more variation in speed and emphasis.  
  Most people can leave these at default unless they’re chasing a specific sound (e.g. “less bouncy” → try lowering subtalker temperature a bit).

**TL;DR:** If you only change one thing, try **temperature** (and maybe **subtalker_temperature**): lower = more stable, higher = more expressive. The rest can stay at default unless you have a specific issue (repetition, length, etc.).

---

## Required

| Variable | Description |
|----------|-------------|
| `QWEN3_TTS_REF_AUDIO_DIR` | Directory containing reference WAVs for voice clone (e.g. `clone_1.wav`, `clone_2.wav`). Set by `run.sh` from your install dir. |

## Model and output

| Variable | Default | Description |
|----------|---------|-------------|
| `QWEN3_TTS_MODEL` | `Qwen/Qwen3-TTS-12Hz-0.6B-Base` | HuggingFace model id. Use `Qwen/Qwen3-TTS-12Hz-1.7B-Base` for higher quality (needs more RAM). |
| `QWEN3_TTS_OUT_DIR` | `qwen3_tts_test_voice_clone_output_wav` | Output directory for WAVs (relative to current working dir when you run the script). |

## Generation (sampling)

These control how the model generates speech. Lower temperature = more deterministic; higher = more varied.

| Variable | Default | Description |
|----------|---------|-------------|
| `QWEN3_TTS_TEMPERATURE` | `0.9` | Main sampling temperature (higher ⇒ more random). |
| `QWEN3_TTS_TOP_K` | `50` | Top-k sampling. |
| `QWEN3_TTS_TOP_P` | `1.0` | Nucleus (top-p) sampling. |
| `QWEN3_TTS_REPETITION_PENALTY` | `1.05` | Penalty for repeating tokens. |
| `QWEN3_TTS_MAX_NEW_TOKENS` | `2048` | Max tokens per generation (affects max audio length). |

## Subtalker (prosody / style)

Internal “subtalker” sampling; affects rhythm and expression.

| Variable | Default | Description |
|----------|---------|-------------|
| `QWEN3_TTS_SUBTALKER_TOP_K` | `50` | Subtalker top-k. |
| `QWEN3_TTS_SUBTALKER_TOP_P` | `1.0` | Subtalker top-p. |
| `QWEN3_TTS_SUBTALKER_TEMPERATURE` | `0.9` | Subtalker temperature. |

## Examples

**Use the 1.7B model (better quality, ~18 GB RAM):**
```bash
export QWEN3_TTS_MODEL=Qwen/Qwen3-TTS-12Hz-1.7B-Base
/Users/pete/dotfiles/scripts/qwen3-tts/run.sh
```

**Lower temperature for more stable/consistent output:**
```bash
export QWEN3_TTS_TEMPERATURE=0.7
export QWEN3_TTS_SUBTALKER_TEMPERATURE=0.7
/Users/pete/dotfiles/scripts/qwen3-tts/run.sh --allow-network
```

**Custom output directory:**
```bash
export QWEN3_TTS_OUT_DIR=/tmp/my_tts_output
/Users/pete/dotfiles/scripts/qwen3-tts/run.sh
```

**One-liner with overrides:**
```bash
QWEN3_TTS_TEMPERATURE=0.75 QWEN3_TTS_MODEL=Qwen/Qwen3-TTS-12Hz-1.7B-Base /Users/pete/dotfiles/scripts/qwen3-tts/run.sh
```
