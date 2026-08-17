#!/usr/bin/env python3
"""Verified Sherpa-ONNX speech runtime for the NOVA call bridge."""

from __future__ import annotations

import os
from pathlib import Path

import numpy as np
import sherpa_onnx
import soundfile as sf


def _resample_pcm16(pcm: bytes, source_rate: int, target_rate: int) -> bytes:
    if not pcm or source_rate == target_rate:
        return pcm
    source = np.frombuffer(pcm, dtype="<i2").astype(np.float32)
    if source.size < 2:
        return pcm
    target_size = max(1, int(round(source.size * target_rate / source_rate)))
    source_axis = np.arange(source.size, dtype=np.float64)
    target_axis = np.linspace(0, source.size - 1, target_size, dtype=np.float64)
    target = np.interp(target_axis, source_axis, source)
    return np.clip(target, -32768, 32767).astype("<i2").tobytes()


class VerifiedSherpaSpeechEngine:
    """Whisper STT and Piper TTS using sherpa-onnx's supported public API."""

    def __init__(self) -> None:
        asr_encoder = os.getenv("NOVA_ASR_ENCODER", "/models/asr/encoder.onnx")
        asr_decoder = os.getenv("NOVA_ASR_DECODER", "/models/asr/decoder.onnx")
        asr_tokens = os.getenv("NOVA_ASR_TOKENS", "/models/asr/tokens.txt")
        tts_model = os.getenv("NOVA_TTS_MODEL", "/models/tts/model.onnx")
        tts_tokens = os.getenv("NOVA_TTS_TOKENS", "/models/tts/tokens.txt")
        tts_data = os.getenv("NOVA_TTS_DATA", "/models/tts/espeak-ng-data")
        required = [
            asr_encoder,
            asr_decoder,
            asr_tokens,
            tts_model,
            tts_tokens,
            tts_data,
        ]
        missing = [path for path in required if not Path(path).exists()]
        if missing:
            raise FileNotFoundError(f"NOVA speech model paths are missing: {missing}")

        threads = max(1, int(os.getenv("NOVA_SPEECH_THREADS", "2")))
        self.recognizer = sherpa_onnx.OfflineRecognizer.from_whisper(
            encoder=asr_encoder,
            decoder=asr_decoder,
            tokens=asr_tokens,
            num_threads=threads,
            decoding_method="greedy_search",
            debug=False,
            language="tr",
            task="transcribe",
            tail_paddings=20,
            provider="cpu",
        )

        tts_config = sherpa_onnx.OfflineTtsConfig(
            model=sherpa_onnx.OfflineTtsModelConfig(
                vits=sherpa_onnx.OfflineTtsVitsModelConfig(
                    model=tts_model,
                    tokens=tts_tokens,
                    data_dir=tts_data,
                ),
                provider="cpu",
                debug=False,
                num_threads=threads,
            ),
            max_num_sentences=1,
        )
        if not tts_config.validate():
            raise ValueError("Sherpa Piper TTS configuration validation failed")
        self.tts = sherpa_onnx.OfflineTts(tts_config)
        self.tts_speed = float(os.getenv("NOVA_TTS_SPEED", "1.0"))
        self.tts_silence_scale = float(
            os.getenv("NOVA_TTS_SILENCE_SCALE", "0.2")
        )

    def transcribe_8k_pcm(self, pcm: bytes) -> str:
        if not pcm:
            return ""
        pcm16 = _resample_pcm16(pcm, 8000, 16000)
        samples = np.frombuffer(pcm16, dtype="<i2").astype(np.float32) / 32768.0
        if samples.size == 0:
            return ""
        stream = self.recognizer.create_stream()
        stream.accept_waveform(16000, samples)
        self.recognizer.decode_stream(stream)
        return str(stream.result.text or "").strip()

    def _generate(self, text: str):
        clean = text.strip()
        if not clean:
            raise ValueError("Piper TTS input text is empty")
        generation = sherpa_onnx.GenerationConfig()
        generation.sid = 0
        generation.speed = self.tts_speed
        generation.silence_scale = self.tts_silence_scale
        audio = self.tts.generate(clean, generation)
        samples = np.asarray(audio.samples, dtype=np.float32)
        sample_rate = int(audio.sample_rate)
        if samples.size == 0 or sample_rate <= 0:
            raise RuntimeError("Sherpa Piper TTS returned empty audio")
        if not np.isfinite(samples).all():
            raise RuntimeError("Sherpa Piper TTS returned non-finite samples")
        return samples, sample_rate

    def synthesize_8k_pcm(self, text: str) -> bytes:
        samples, source_rate = self._generate(text)
        pcm = np.clip(samples * 32767.0, -32768, 32767).astype("<i2").tobytes()
        output = _resample_pcm16(pcm, source_rate, 8000)
        if len(output) < 320:
            raise RuntimeError("Sherpa Piper TTS output is too short for AudioSocket")
        return output

    def synthesize_wav(self, text: str, output: Path) -> None:
        samples, sample_rate = self._generate(text)
        output.parent.mkdir(parents=True, exist_ok=True)
        sf.write(
            str(output),
            samples,
            samplerate=sample_rate,
            subtype="PCM_16",
        )
        if not output.is_file() or output.stat().st_size <= 44:
            raise RuntimeError("Sherpa Piper WAV output was not written")
