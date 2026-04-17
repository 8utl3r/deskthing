#!/usr/bin/env python3
"""Qwen3-TTS 0.6B example runner: MPS/sdpa, local ref audio. Run from repo dir with venv active.
Config via env: QWEN3_TTS_REF_AUDIO_DIR (required), QWEN3_TTS_MODEL, QWEN3_TTS_OUT_DIR,
QWEN3_TTS_TEMPERATURE, QWEN3_TTS_TOP_K, QWEN3_TTS_TOP_P, QWEN3_TTS_REPETITION_PENALTY,
QWEN3_TTS_MAX_NEW_TOKENS, subtalker_* (see CONFIG.md)."""
import os
import time
import torch
import soundfile as sf

from qwen_tts import Qwen3TTSModel


def _env_float(key: str, default: float) -> float:
    v = os.environ.get(key)
    return float(v) if v is not None else default


def _env_int(key: str, default: int) -> int:
    v = os.environ.get(key)
    return int(v) if v is not None else default


def _sync():
    if torch.cuda.is_available():
        torch.cuda.synchronize()
    elif getattr(torch.backends, "mps", None) and torch.backends.mps.is_available():
        torch.mps.synchronize()


def ensure_dir(d: str):
    os.makedirs(d, exist_ok=True)


def run_case(tts, out_dir: str, case_name: str, call_fn):
    _sync()
    t0 = time.time()
    wavs, sr = call_fn()
    _sync()
    t1 = time.time()
    print(f"[{case_name}] time: {t1 - t0:.3f}s, n_wavs={len(wavs)}, sr={sr}")
    for i, w in enumerate(wavs):
        sf.write(os.path.join(out_dir, f"{case_name}_{i}.wav"), w, sr)


def main():
    ref_audio_dir = os.environ.get("QWEN3_TTS_REF_AUDIO_DIR", "")
    if not ref_audio_dir:
        raise SystemExit("Set QWEN3_TTS_REF_AUDIO_DIR to the ref_audio directory")
    ref_audio_path_1 = os.path.join(ref_audio_dir, "clone_2.wav")
    ref_audio_path_2 = os.path.join(ref_audio_dir, "clone_1.wav")

    device = "mps" if (getattr(torch.backends, "mps", None) and torch.backends.mps.is_available()) else ("cuda:0" if torch.cuda.is_available() else "cpu")
    model_path = os.environ.get("QWEN3_TTS_MODEL", "Qwen/Qwen3-TTS-12Hz-0.6B-Base")
    out_dir = os.environ.get("QWEN3_TTS_OUT_DIR", "qwen3_tts_test_voice_clone_output_wav")
    ensure_dir(out_dir)

    tts = Qwen3TTSModel.from_pretrained(
        model_path,
        device_map=device,
        dtype=torch.bfloat16,
        attn_implementation="sdpa",
    )

    ref_audio_single = ref_audio_path_1
    ref_audio_batch = [ref_audio_path_1, ref_audio_path_2]
    ref_text_single = "Okay. Yeah. I resent you. I love you. I respect you. But you know what? You blew it! And thanks to you."
    ref_text_batch = [
        ref_text_single,
        "甚至出现交易几乎停滞的情况。",
    ]
    syn_text_single = "Good one. Okay, fine, I'm just gonna leave this sock monkey here. Goodbye."
    syn_lang_single = "Auto"
    syn_text_batch = [
        syn_text_single,
        "其实我真的有发现，我是一个特别善于观察别人情绪的人。",
    ]
    syn_lang_batch = ["Chinese", "English"]
    common_gen_kwargs = dict(
        max_new_tokens=_env_int("QWEN3_TTS_MAX_NEW_TOKENS", 2048),
        do_sample=True,
        top_k=_env_int("QWEN3_TTS_TOP_K", 50),
        top_p=_env_float("QWEN3_TTS_TOP_P", 1.0),
        temperature=_env_float("QWEN3_TTS_TEMPERATURE", 0.9),
        repetition_penalty=_env_float("QWEN3_TTS_REPETITION_PENALTY", 1.05),
        subtalker_dosample=True,
        subtalker_top_k=_env_int("QWEN3_TTS_SUBTALKER_TOP_K", 50),
        subtalker_top_p=_env_float("QWEN3_TTS_SUBTALKER_TOP_P", 1.0),
        subtalker_temperature=_env_float("QWEN3_TTS_SUBTALKER_TEMPERATURE", 0.9),
    )

    for xvec_only in [False, True]:
        mode_tag = "xvec_only" if xvec_only else "icl"
        run_case(
            tts, out_dir, f"case1_promptSingle_synSingle_direct_{mode_tag}",
            lambda: tts.generate_voice_clone(
                text=syn_text_single,
                language=syn_lang_single,
                ref_audio=ref_audio_single,
                ref_text=ref_text_single,
                x_vector_only_mode=xvec_only,
                **common_gen_kwargs,
            ),
        )
        run_case(
            tts, out_dir, f"case2_promptSingle_synBatch_direct_{mode_tag}",
            lambda: tts.generate_voice_clone(
                text=syn_text_batch,
                language=syn_lang_batch,
                ref_audio=ref_audio_single,
                ref_text=ref_text_single,
                x_vector_only_mode=xvec_only,
                **common_gen_kwargs,
            ),
        )
        run_case(
            tts, out_dir, f"case3_promptBatch_synBatch_direct_{mode_tag}",
            lambda: tts.generate_voice_clone(
                text=syn_text_batch,
                language=syn_lang_batch,
                ref_audio=ref_audio_batch,
                ref_text=ref_text_batch,
                x_vector_only_mode=[xvec_only, xvec_only],
                **common_gen_kwargs,
            ),
        )
    print("Output dir:", os.path.abspath(out_dir))


if __name__ == "__main__":
    main()
