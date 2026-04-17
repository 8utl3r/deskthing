# Open-Source Voice / TTS AI Comparison (2025–2026)

Feature matrix and review summary for **VibeVoice** (Microsoft), **Chatterbox** (Resemble AI), and **Qwen3-TTS** (Alibaba).

---

## Feature Matrix

| Feature | VibeVoice (Microsoft) | Chatterbox (Resemble AI) | Qwen3-TTS (Alibaba) |
|--------|------------------------|---------------------------|----------------------|
| **License** | MIT | MIT | Apache-2.0 |
| **Primary use case** | Long-form, multi-speaker (podcasts, audiobooks) | Real-time, apps, voice cloning | Streaming TTS, voice design & cloning |
| **Max length / context** | ~90 min, 2–4 speakers | Short/medium (real-time oriented) | Streaming + long-form in one model |
| **Voice cloning** | Multi-speaker (built-in voices) | Zero-shot from seconds of audio | 3 s zero-shot cloning |
| **Languages** | English, Chinese focus | ~23 languages | ~10 (EN, ZH, JA, KO, DE, FR, RU, PT, ES, IT + Chinese dialects) |
| **Model sizes** | 1.5B, 7B | ~350M (Turbo), larger variants | 0.6B, 1.7B |
| **First-packet / latency** | Not optimized for ultra-low | Sub-200 ms (Turbo ~75 ms) | ~97 ms (0.6B) |
| **Streaming** | Long-form batch style | Yes (Turbo) | Yes (native) |
| **Emotion / expressiveness** | Prosody via tokenizers + LLM | Emotion control, paralinguistic tags ([laugh], [cough]) | Natural-language voice design |
| **Watermarking** | — | PerTH (built-in) | — |
| **Hardware** | Heavier (7B) | Lighter (350M Turbo) | 4GB+ VRAM, FlashAttention2 for best speed |
| **API / hosted** | — | Resemble ecosystem | Alibaba API (~$0.013/1k chars) |
| **Repo / code status** | TTS code disabled Sep 2025 (misuse); ASR/Realtime still referenced | Active (GitHub, Hugging Face) | Active (GitHub, Hugging Face, ModelScope) |

---

## Benchmark / Quality (reported)

| Metric / aspect | VibeVoice | Chatterbox | Qwen3-TTS |
|-----------------|-----------|------------|-----------|
| **Vendor benchmarks** | Top MOS/PESQ/STOI/UTMOS; preferred over ElevenLabs v3, Gemini-2.5-Pro in some evals | Human A/B vs ElevenLabs, Cartesia, VibeVoice (Podonos); “consistently outperform ElevenLabs” in blind evals | PESQ ~3.21/3.68, STOI ~0.96, UTMOS ~4.16; >5M hours training |
| **Speaker similarity** | — | Strong zero-shot | Vendor ~0.95; one reviewer ~0.789 cross-language |
| **Independent verdict** | Strong in controlled tests; real-world instability (artifacts, multi-speaker issues) | Good for real-time and prototyping; not always “studio” fidelity | Competes with or beats some commercial (e.g. ElevenLabs, MiniMax) on cloning; occasional “anime-like” English artifacts |

---

## Reviews & Tradeoffs

### VibeVoice (Microsoft)

- **Pros:** Frontier long-form, multi-speaker TTS; leading benchmark scores; strong prosody/expressiveness in demos; MIT.
- **Cons:** Full TTS code disabled Sep 2025 due to misuse; real-world reviews report audio artifacts, inconsistent quality, multi-speaker failures; better for research/hobby than production.
- **Verdict:** Major research milestone; “promising for experimentation, not yet production-ready.” Access to full pipeline is unclear (official disable vs mirrors/community).

### Chatterbox (Resemble AI)

- **Pros:** MIT; small footprint (Turbo ~350M); very low latency; zero-shot cloning from seconds; emotion and paralinguistic control; built-in watermarking; public Podonos benchmarks vs ElevenLabs/Cartesia/VibeVoice.
- **Cons:** Positioned as “developer-focused”; not always top studio-level naturalness; throughput over max fidelity.
- **Verdict:** Strong for real-time and resource-constrained apps, rapid prototyping, and when you want transparent quality benchmarks.

### Qwen3-TTS (Alibaba)

- **Pros:** Very low first-packet latency (~97 ms); 3 s cloning; natural-language voice design; 10 languages + Chinese dialects; Apache-2.0; heavy Reddit/community adoption and benchmarks; can match or beat some commercial systems in tests.
- **Cons:** Fewer languages than Chatterbox; some reviews note minor prosody/“emotional hallucination” and occasional “anime-like” English; best with GPU + FlashAttention2.
- **Verdict:** Best all-round open-source choice for streaming + cloning + multilingual in 2026; strong for self-hosted and cost-sensitive use.

---

## When to Choose Which

- **Long-form / multi-speaker (podcasts, audiobooks):** VibeVoice is the only one designed for 90-min, 2–4 speaker flows—but code status and stability are caveats.
- **Real-time apps / low latency / small deploy:** Chatterbox (especially Turbo): sub-200 ms, small model, good for production latency and resource limits.
- **Voice cloning + streaming + “best open-source all-rounder”:** Qwen3-TTS: 3 s cloning, ~97 ms latency, 10 languages, active community and benchmarks.
- **Maximum transparency on quality:** Chatterbox (Podonos reports) and Qwen3-TTS (many independent tests); VibeVoice has strong vendor numbers but limited current independent real-world reviews due to takedown.

---

## Qwen3-TTS on M3 MacBook Pro: Safest, most performant setup

**Why not Docker on Mac?** Docker on macOS runs Linux in a VM; there is no Metal/GPU passthrough. The container would run CPU-only and be slower. For best performance on M3 you must run **native** and use **Metal (MPS)**.

**Safest way to run native:** Use an isolated environment (conda/venv), optional network block for the process, and avoid `sudo`. You trade some isolation vs Docker but gain full MPS acceleration.

### 1. System deps (required for audio)

```bash
brew install portaudio ffmpeg sox
```

(Skipping `sox` often causes `sox: command not found` during generation.)

### 2. Isolated environment (Python 3.12)

```bash
conda create -n qwen3-tts python=3.12 -y
conda activate qwen3-tts
pip install -U qwen-tts
```

Or with venv:

```bash
python3.12 -m venv ~/venvs/qwen3-tts
source ~/venvs/qwen3-tts/bin/activate
pip install -U qwen-tts
```

### 3. Clone repo (for MPS fixes)

The default scripts assume CUDA. You need small edits for MPS:

```bash
git clone https://github.com/QwenLM/Qwen3-TTS.git
cd Qwen3-TTS
pip install -e .
```

### 4. M3/MPS code changes

In `examples/test_model_12hz_base.py` (or whichever script you run):

- **Model load:** Use `device_map="mps"`, `attn_implementation="sdpa"`, `torch_dtype=torch.bfloat16`. Do **not** use `flash_attention_2` (not MPS-compatible).
- **Sync:** Replace any `torch.cuda.synchronize()` with:

  ```python
  if torch.cuda.is_available():
      torch.cuda.synchronize()
  elif torch.backends.mps.is_available():
      torch.mps.synchronize()
  ```

Model path: use `"Qwen/Qwen3-TTS-12Hz-0.6B-Base"` or `"Qwen/Qwen3-TTS-12Hz-1.7B-Base"` (no trailing slash).

### 5. Model choice by RAM

| M3 MacBook Pro RAM | Prefer |
|--------------------|--------|
| 8 GB unified      | 0.6B only |
| 16 GB+            | 0.6B (faster) or 1.7B (better quality) |

### 6. Optional: block network for the process

To reduce exfil risk: download the model once with network on, then run inference with no network.

**Using dotfiles sandbox (recommended):** From the repo, run Qwen3-TTS under the no-network sandbox:

```bash
# First time: run without wrapper to download the model.
python examples/test_model_12hz_base.py

# Later runs: use the wrapper so the process cannot reach the internet.
/path/to/dotfiles/scripts/sandbox/run-no-network.sh -- python examples/test_model_12hz_base.py
```

See `scripts/sandbox/README.md` for details. Alternatives: Little Snitch / Lulu (block by app) or `pf` (firewall).

### 7. Verify MPS

```python
import torch
print(torch.backends.mps.is_available())  # True on M3
```

### 8. Run

```bash
cd examples
python test_model_12hz_base.py
```

If you hit driver oddities (hangs, weird errors), a reboot often fixes MPS state.

---

## Sources (summary)

- VibeVoice: Microsoft project page, GitHub, AllAboutAI review, “vanished overnight” coverage, KDnuggets guide.
- Chatterbox: Resemble AI site, GitHub, Podonos case studies (benchmarks vs ElevenLabs, Cartesia, VibeVoice).
- Qwen3-TTS: Alibaba/Hugging Face/ModelScope, Gaga.art review, AIToolAnalysis review, QuickLeap vs ElevenLabs, AI Rockstars, Medium guides.
- Landscape: Qcall.ai “Top 21 Open Source TTS”, GoodVibeCode 2026 comparison.

*Last updated: 2026-02-11*
