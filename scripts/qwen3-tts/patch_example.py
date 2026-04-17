#!/usr/bin/env python3
"""Patch Qwen3-TTS example for 0.6B, MPS, local ref audio, and sync. Run from repo root."""
import os
import re
import sys

EXAMPLE = "examples/test_model_12hz_base.py"
REF_AUDIO_DIR = os.environ.get("QWEN3_TTS_REF_AUDIO_DIR", "")

if not REF_AUDIO_DIR:
    print("Set QWEN3_TTS_REF_AUDIO_DIR to the ref_audio directory", file=sys.stderr)
    sys.exit(1)

with open(EXAMPLE, "r") as f:
    content = f.read()

# Skip only if fully patched (model + _sync helper present, no raw cuda.synchronize)
if "Qwen3-TTS-12Hz-0.6B-Base" in content and "def _sync():" in content and " torch.cuda.synchronize()" not in content:
    print("Already patched.", file=sys.stderr)
    sys.exit(0)

# 1) Model and device / attention
content = content.replace(
    'MODEL_PATH = "Qwen/Qwen3-TTS-12Hz-1.7B-Base/"',
    'MODEL_PATH = "Qwen/Qwen3-TTS-12Hz-0.6B-Base"',
)
content = content.replace(
    'device = "cuda:0"',
    'device = "mps" if (hasattr(torch.backends, "mps") and torch.backends.mps.is_available()) else ("cuda:0" if torch.cuda.is_available() else "cpu")',
)
content = content.replace(
    'attn_implementation="flash_attention_2"',
    'attn_implementation="sdpa"',
)

# 2) Ref audio: use local dir
content = content.replace(
    'ref_audio_path_1 = "https://qianwen-res.oss-cn-beijing.aliyuncs.com/Qwen3-TTS-Repo/clone_2.wav"',
    f'ref_audio_path_1 = os.path.join(os.environ.get("QWEN3_TTS_REF_AUDIO_DIR", {repr(REF_AUDIO_DIR)}), "clone_2.wav")',
)
content = content.replace(
    'ref_audio_path_2 = "https://qianwen-res.oss-cn-beijing.aliyuncs.com/Qwen3-TTS-Repo/clone_1.wav"',
    f'ref_audio_path_2 = os.path.join(os.environ.get("QWEN3_TTS_REF_AUDIO_DIR", {repr(REF_AUDIO_DIR)}), "clone_1.wav")',
)

# 3) Sync: add _sync() helper and replace both torch.cuda.synchronize() lines with _sync()
_sync_helper = '''
def _sync():
    if torch.cuda.is_available():
        torch.cuda.synchronize()
    elif getattr(torch.backends, "mps", None) and torch.backends.mps.is_available():
        torch.mps.synchronize()
'''

if "def _sync():" not in content:
    content = content.replace(
        "from qwen_tts import Qwen3TTSModel\n\n\ndef ensure_dir",
        "from qwen_tts import Qwen3TTSModel\n" + _sync_helper + "\ndef ensure_dir",
    )
# Normalize any existing _sync() in run_case to single space (fixes prior bad patch)
content = re.sub(r"\n\s+_sync\(\)\s*\n", "\n _sync()\n", content)

# Replace raw sync lines: keep same leading whitespace as original line (often 1 space in this file)
content = re.sub(
    r"\n(\s+)torch\.cuda\.synchronize\(\)\s*\n",
    r"\n\1_sync()\n",
    content,
    count=2,
)
# If we already inserted the if/elif block (broken indent), replace whole block with _sync() using 1 space
content = re.sub(
    r"\n if torch\.cuda\.is_available\(\):.*?torch\.mps\.synchronize\(\)\s*\n",
    "\n _sync()\n",
    content,
    count=2,
    flags=re.DOTALL,
)

# Normalize every _sync() call line to exactly 1 leading space (run_case body indent)
content = re.sub(r"\n\s*_sync\(\)\s*\n", "\n _sync()\n", content)

with open(EXAMPLE, "w") as f:
    f.write(content)
print("Patched.", file=sys.stderr)
