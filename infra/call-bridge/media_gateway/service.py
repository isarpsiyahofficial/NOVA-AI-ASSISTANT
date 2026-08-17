#!/usr/bin/env python3
from __future__ import annotations

import argparse
import difflib
import asyncio
import audioop
import json
import logging
import math
import os
import re
import socket
import struct
import sys
import threading
import time
import urllib.error
import urllib.request
import uuid
import wave
from array import array
from dataclasses import asdict, dataclass, field
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

import numpy as np
import sherpa_onnx
import soundfile as sf

LOG = logging.getLogger("nova-call-media")
AUDIO_SOCKET_TERMINATE = 0x00
AUDIO_SOCKET_UUID = 0x01
AUDIO_SOCKET_DTMF = 0x03
AUDIO_SOCKET_PCM_8K = 0x10
AUDIO_SOCKET_PCM_16K = 0x12


def env_bool(name: str, default: bool) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


def safe_token(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def pcm16_rms(pcm: bytes) -> float:
    if not pcm:
        return 0.0
    usable = pcm[: len(pcm) - (len(pcm) % 2)]
    if not usable:
        return 0.0
    return float(audioop.rms(usable, 2))


def resample_pcm16(pcm: bytes, source_rate: int, target_rate: int) -> bytes:
    if source_rate == target_rate:
        return pcm
    converted, _ = audioop.ratecv(pcm, 2, 1, source_rate, target_rate, None)
    return converted


def write_wav(path: Path, pcm: bytes, sample_rate: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(sample_rate)
        handle.writeframes(pcm)


def wav_to_pcm16(path: Path, target_rate: int) -> bytes:
    audio, source_rate = sf.read(path, dtype="float32", always_2d=False)
    if isinstance(audio, np.ndarray) and audio.ndim > 1:
        audio = np.mean(audio, axis=1)
    samples = np.asarray(audio, dtype=np.float32)
    if source_rate != target_rate:
        samples = np.asarray(
            sherpa_onnx.resample(samples, source_rate, target_rate),
            dtype=np.float32,
        )
    samples = np.clip(samples, -1.0, 1.0)
    return (samples * 32767.0).astype("<i2").tobytes()


@dataclass
class SessionReport:
    session_id: str
    peer: str
    started_at: float
    completed_at: float = 0.0
    success: bool = False
    transcript: str = ""
    reply: str = ""
    incoming_bytes: int = 0
    outgoing_bytes: int = 0
    incoming_rms: float = 0.0
    outgoing_rms: float = 0.0
    stt_ms: int = 0
    ai_ms: int = 0
    tts_ms: int = 0
    turns: int = 0
    dtmf: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)
    metadata: dict[str, Any] = field(default_factory=dict)


class SharedState:
    def __init__(self, report_dir: Path) -> None:
        self.report_dir = report_dir
        self.report_dir.mkdir(parents=True, exist_ok=True)
        self._lock = threading.Lock()
        self._latest: SessionReport | None = None
        self.models_ready = False
        self.startup_error = ""

    def save(self, report: SessionReport) -> None:
        with self._lock:
            self._latest = report
        target = self.report_dir / f"{report.session_id}.json"
        temp = target.with_suffix(".json.tmp")
        temp.write_text(json.dumps(asdict(report), ensure_ascii=False, indent=2), encoding="utf-8")
        temp.replace(target)

    def latest(self) -> SessionReport | None:
        with self._lock:
            return self._latest


class SherpaSpeechEngine:
    def __init__(self) -> None:
        self.asr_encoder = Path(os.environ["NOVA_ASR_ENCODER"])
        self.asr_decoder = Path(os.environ["NOVA_ASR_DECODER"])
        self.asr_tokens = Path(os.environ["NOVA_ASR_TOKENS"])
        self.tts_model = Path(os.environ["NOVA_TTS_MODEL"])
        self.tts_tokens = Path(os.environ["NOVA_TTS_TOKENS"])
        self.tts_data = Path(os.environ["NOVA_TTS_DATA"])
        required = [
            self.asr_encoder,
            self.asr_decoder,
            self.asr_tokens,
            self.tts_model,
            self.tts_tokens,
            self.tts_data,
        ]
        missing = [str(path) for path in required if not path.exists()]
        if missing:
            raise FileNotFoundError(f"Missing verified speech assets: {missing}")
        self.recognizer = sherpa_onnx.OfflineRecognizer.from_transducer(
            encoder=str(self.asr_encoder),
            decoder=str(self.asr_decoder),
            joiner=str(self.asr_decoder.parent / "joiner.onnx"),
            tokens=str(self.asr_tokens),
            num_threads=max(1, min(4, os.cpu_count() or 1)),
            sample_rate=16000,
            feature_dim=80,
            decoding_method="greedy_search",
            debug=False,
        )
        tts_config = sherpa_onnx.OfflineTtsConfig(
            model=sherpa_onnx.OfflineTtsModelConfig(
                vits=sherpa_onnx.OfflineTtsVitsModelConfig(
                    model=str(self.tts_model),
                    tokens=str(self.tts_tokens),
                    data_dir=str(self.tts_data),
                ),
                num_threads=max(1, min(4, os.cpu_count() or 1)),
                debug=False,
                provider="cpu",
            )
        )
        if not tts_config.validate():
            raise RuntimeError("Invalid verified Piper TTS configuration")
        self.tts = sherpa_onnx.OfflineTts(tts_config)

    def transcribe_8k_pcm(self, pcm: bytes) -> str:
        if not pcm:
            return ""
        samples = np.frombuffer(pcm, dtype="<i2").astype(np.float32) / 32768.0
        samples_16k = np.asarray(sherpa_onnx.resample(samples, 8000, 16000), dtype=np.float32)
        stream = self.recognizer.create_stream()
        stream.accept_waveform(16000, samples_16k)
        self.recognizer.decode_stream(stream)
        return str(stream.result.text or "").strip()

    def synthesize_8k_pcm(self, text: str) -> bytes:
        audio = self.tts.generate(text, sid=0, speed=1.0)
        samples = np.asarray(audio.samples, dtype=np.float32)
        if int(audio.sample_rate) != 8000:
            samples = np.asarray(
                sherpa_onnx.resample(samples, int(audio.sample_rate), 8000),
                dtype=np.float32,
            )
        samples = np.clip(samples, -1.0, 1.0)
        return (samples * 32767.0).astype("<i2").tobytes()


@dataclass
class Decision:
    reply: str
    hangup: bool
    metadata: dict[str, Any]


class AiDecisionEngine:
    def __init__(self) -> None:
        self.provider = os.getenv("NOVA_CALL_AI_PROVIDER", "mock").strip().lower()
        self.api_key = os.getenv("NOVA_CALL_AI_KEY", "").strip()
        self.model = os.getenv("NOVA_CALL_AI_MODEL", "").strip()
        self.endpoint = os.getenv("NOVA_CALL_AI_ENDPOINT", "").strip()
        self.mock_reply = os.getenv(
            "NOVA_CALL_MOCK_REPLY",
            "NOVA çift yönlü çağrı medya testi başarıyla tamamlandı.",
        ).strip()

    def decide(self, transcript: str, session_id: str) -> Decision:
        if self.provider == "mock":
            return Decision(
                reply=self.mock_reply,
                hangup=env_bool("NOVA_CALL_HANGUP_AFTER_REPLY", True),
                metadata={"provider": "mock", "session_id": session_id},
            )
        if self.provider == "openai":
            return self._openai(transcript)
        if self.provider == "gemini":
            return self._gemini(transcript)
        if self.provider == "qwen":
            return self._qwen(transcript)
        if self.provider == "generic":
            return self._generic(transcript, session_id)
        raise RuntimeError(f"Unsupported NOVA_CALL_AI_PROVIDER={self.provider}")

    @staticmethod
    def _system_prompt() -> str:
        return (
            "You are NOVA's authorized telephone conversation engine. "
            "Return only short, natural Turkish speech. Never claim a device action "
            "was completed unless the trusted call-control service already verified it."
        )

    @staticmethod
    def _request_json(url: str, body: dict[str, Any], headers: dict[str, str]) -> dict[str, Any]:
        payload = json.dumps(body).encode("utf-8")
        request = urllib.request.Request(
            url,
            data=payload,
            headers={"Content-Type": "application/json", **headers},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=25) as response:
                data = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            details = error.read().decode("utf-8", errors="replace")[:1000]
            raise RuntimeError(f"AI HTTP {error.code}: {details}") from error
        if not isinstance(data, dict):
            raise RuntimeError("AI response was not a JSON object")
        return data

    def _openai(self, transcript: str) -> Decision:
        if not self.api_key:
            raise RuntimeError("NOVA_CALL_AI_KEY is required for OpenAI")
        model = self.model or "gpt-5-mini"
        data = self._request_json(
            self.endpoint or "https://api.openai.com/v1/responses",
            {
                "model": model,
                "instructions": self._system_prompt(),
                "input": transcript,
                "max_output_tokens": 160,
            },
            {"Authorization": f"Bearer {self.api_key}"},
        )
        text = str(data.get("output_text") or "").strip()
        if not text:
            for item in data.get("output", []):
                for content in item.get("content", []) if isinstance(item, dict) else []:
                    if isinstance(content, dict) and content.get("text"):
                        text += str(content["text"])
        text = text.strip()
        if not text:
            raise RuntimeError("OpenAI returned no speakable text")
        return Decision(text, env_bool("NOVA_CALL_HANGUP_AFTER_REPLY", False), {"provider": "openai", "model": model})

    def _gemini(self, transcript: str) -> Decision:
        if not self.api_key:
            raise RuntimeError("NOVA_CALL_AI_KEY is required for Gemini")
        model = self.model or "gemini-2.5-flash"
        endpoint = self.endpoint or f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
        data = self._request_json(
            endpoint,
            {
                "systemInstruction": {"parts": [{"text": self._system_prompt()}]},
                "contents": [{"role": "user", "parts": [{"text": transcript}]}],
                "generationConfig": {"temperature": 0.25, "maxOutputTokens": 160},
            },
            {"x-goog-api-key": self.api_key},
        )
        text_parts: list[str] = []
        for candidate in data.get("candidates", []):
            if not isinstance(candidate, dict):
                continue
            content = candidate.get("content", {})
            for part in content.get("parts", []) if isinstance(content, dict) else []:
                if isinstance(part, dict) and part.get("text"):
                    text_parts.append(str(part["text"]))
        text = "\n".join(text_parts).strip()
        if not text:
            raise RuntimeError("Gemini returned no speakable text")
        return Decision(text, env_bool("NOVA_CALL_HANGUP_AFTER_REPLY", False), {"provider": "gemini", "model": model})

    def _qwen(self, transcript: str) -> Decision:
        model = self.model or "qwen3.6-flash"
        data = self._request_json(
            self.endpoint or "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions",
            {
                "model": model,
                "messages": [
                    {"role": "system", "content": self._system_prompt()},
                    {"role": "user", "content": transcript},
                ],
                "temperature": 0.25,
                "max_tokens": 160,
            },
            {"Authorization": f"Bearer {self.api_key}"},
        )
        choices = data.get("choices", [])
        message = choices[0].get("message", {}) if choices and isinstance(choices[0], dict) else {}
        text = str(message.get("content") or "").strip()
        if not text:
            raise RuntimeError("Qwen returned no speakable text")
        return Decision(text, env_bool("NOVA_CALL_HANGUP_AFTER_REPLY", False), {"provider": "qwen", "model": model})

    def _generic(self, transcript: str, session_id: str) -> Decision:
        if not self.endpoint:
            raise RuntimeError("NOVA_CALL_AI_ENDPOINT is required for generic provider")
        data = self._request_json(
            self.endpoint,
            {"session_id": session_id, "transcript": transcript, "language": "tr-TR"},
            {"Authorization": f"Bearer {self.api_key}"} if self.api_key else {},
        )
        reply = str(data.get("reply") or "").strip()
        if not reply:
            raise RuntimeError("Generic AI endpoint returned no reply")
        return Decision(reply, bool(data.get("hangup", False)), {"provider": "generic", **dict(data.get("metadata") or {})})


class NovaAudioSocketServer:
    def __init__(self, speech: SherpaSpeechEngine, decision: AiDecisionEngine, state: SharedState) -> None:
        self.speech = speech
        self.decision = decision
        self.state = state
        self.host = os.getenv("NOVA_AUDIO_SOCKET_HOST", "0.0.0.0")
        self.port = int(os.getenv("NOVA_AUDIO_SOCKET_PORT", "9019"))
        self.rms_threshold = float(os.getenv("NOVA_SPEECH_RMS_THRESHOLD", "180"))
        self.silence_ms = int(os.getenv("NOVA_ENDPOINT_SILENCE_MS", "850"))
        self.min_speech_ms = int(os.getenv("NOVA_MIN_SPEECH_MS", "450"))
        self.max_utterance_ms = int(os.getenv("NOVA_MAX_UTTERANCE_MS", "18000"))
        self.max_turns = int(os.getenv("NOVA_MAX_CALL_TURNS", "4"))

    async def serve(self) -> None:
        server = await asyncio.start_server(self.handle_client, self.host, self.port)
        addresses = ", ".join(str(sock.getsockname()) for sock in server.sockets or [])
        LOG.info("AudioSocket listening on %s", addresses)
        async with server:
            await server.serve_forever()

    async def handle_client(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        peer = str(writer.get_extra_info("peername"))
        report = SessionReport(session_id=str(uuid.uuid4()), peer=peer, started_at=time.time())
        try:
            first_type, first_payload = await self.read_packet(reader)
            if first_type != AUDIO_SOCKET_UUID or len(first_payload) != 16:
                raise RuntimeError("AudioSocket connection did not begin with a 16-byte UUID")
            report.session_id = str(uuid.UUID(bytes=first_payload))
            LOG.info("Call session %s connected from %s", report.session_id, peer)

            for _ in range(self.max_turns):
                utterance = await self.read_utterance(reader, report)
                if not utterance:
                    break
                report.turns += 1
                report.incoming_rms = max(report.incoming_rms, pcm16_rms(utterance))
                incoming_path = self.state.report_dir / f"{report.session_id}-turn-{report.turns}-in.wav"
                write_wav(incoming_path, utterance, 8000)

                started = time.perf_counter()
                transcript = await asyncio.to_thread(self.speech.transcribe_8k_pcm, utterance)
                report.stt_ms += int((time.perf_counter() - started) * 1000)
                report.transcript = transcript
                if not transcript:
                    raise RuntimeError("Whisper returned an empty transcript")

                started = time.perf_counter()
                decision = await asyncio.to_thread(self.decision.decide, transcript, report.session_id)
                report.ai_ms += int((time.perf_counter() - started) * 1000)
                report.reply = decision.reply
                report.metadata.update(decision.metadata)

                started = time.perf_counter()
                outgoing = await asyncio.to_thread(self.speech.synthesize_8k_pcm, decision.reply)
                report.tts_ms += int((time.perf_counter() - started) * 1000)
                report.outgoing_bytes += len(outgoing)
                report.outgoing_rms = max(report.outgoing_rms, pcm16_rms(outgoing))
                outgoing_path = self.state.report_dir / f"{report.session_id}-turn-{report.turns}-out.wav"
                write_wav(outgoing_path, outgoing, 8000)
                await self.send_pcm(writer, outgoing)

                if decision.hangup:
                    await self.write_packet(writer, AUDIO_SOCKET_TERMINATE, b"")
                    break

            report.success = bool(report.transcript and report.reply and report.outgoing_bytes > 0)
        except asyncio.IncompleteReadError:
            report.errors.append("AudioSocket peer closed the connection")
        except Exception as error:  # noqa: BLE001 - report every call failure
            LOG.exception("Call session %s failed", report.session_id)
            report.errors.append(f"{type(error).__name__}: {error}")
            try:
                await self.write_packet(writer, 0xFF, b"nova-media-error")
            except Exception:
                pass
        finally:
            report.completed_at = time.time()
            self.state.save(report)
            writer.close()
            try:
                await writer.wait_closed()
            except Exception:
                pass
            LOG.info("Call session %s completed success=%s", report.session_id, report.success)

    async def read_utterance(self, reader: asyncio.StreamReader, report: SessionReport) -> bytes:
        buffer = bytearray()
        speech_started = False
        speech_ms = 0
        silence_after_speech_ms = 0
        started_at = time.monotonic()
        while True:
            try:
                # AudioSocket peers are allowed to omit explicit silence frames.
                # Use a short media-idle boundary once speech has started, while
                # retaining the longer first-speech window for real callers.
                packet_type, payload = await asyncio.wait_for(
                    self.read_packet(reader),
                    timeout=1.25 if speech_started else 25.0,
                )
            except asyncio.TimeoutError:
                if speech_started and speech_ms >= self.min_speech_ms:
                    return bytes(buffer)
                if not speech_started and time.monotonic() - started_at > 20:
                    return b""
                continue
            except asyncio.IncompleteReadError:
                # Asterisk may close the media channel immediately after the
                # caller fixture or a real caller hangs up. Never discard an
                # already verified speech buffer merely because no trailing
                # silence packet was emitted.
                return bytes(buffer) if speech_started else b""
            if packet_type == AUDIO_SOCKET_TERMINATE:
                return bytes(buffer) if speech_started else b""
            if packet_type == AUDIO_SOCKET_DTMF:
                report.dtmf.append(payload.decode("ascii", errors="ignore"))
                continue
            if packet_type not in {AUDIO_SOCKET_PCM_8K, AUDIO_SOCKET_PCM_16K}:
                continue
            sample_rate = 8000 if packet_type == AUDIO_SOCKET_PCM_8K else 16000
            pcm = payload if sample_rate == 8000 else resample_pcm16(payload, 16000, 8000)
            report.incoming_bytes += len(pcm)
            frame_ms = max(1, int(len(pcm) / 2 / 8000 * 1000))
            energy = pcm16_rms(pcm)
            # Record packet-level energy immediately. Previously this field was
            # only populated after a complete utterance returned, which hid
            # valid media whenever the peer closed without trailing silence.
            report.incoming_rms = max(report.incoming_rms, energy)
            if energy >= self.rms_threshold:
                speech_started = True
                silence_after_speech_ms = 0
                speech_ms += frame_ms
                buffer.extend(pcm)
            elif speech_started:
                buffer.extend(pcm)
                silence_after_speech_ms += frame_ms
                if speech_ms >= self.min_speech_ms and silence_after_speech_ms >= self.silence_ms:
                    return bytes(buffer)
            if speech_started and len(buffer) / 2 / 8000 * 1000 >= self.max_utterance_ms:
                return bytes(buffer)
            if not speech_started and time.monotonic() - started_at > 20:
                return b""

    @staticmethod
    async def read_packet(reader: asyncio.StreamReader) -> tuple[int, bytes]:
        header = await reader.readexactly(3)
        packet_type = header[0]
        length = struct.unpack(">H", header[1:3])[0]
        payload = await reader.readexactly(length) if length else b""
        return packet_type, payload

    @staticmethod
    async def write_packet(writer: asyncio.StreamWriter, packet_type: int, payload: bytes) -> None:
        if len(payload) > 65535:
            raise ValueError("AudioSocket packet payload exceeds 65535 bytes")
        writer.write(bytes([packet_type]) + struct.pack(">H", len(payload)) + payload)
        await writer.drain()

    async def send_pcm(self, writer: asyncio.StreamWriter, pcm: bytes) -> None:
        frame_bytes = 320  # 20 ms, signed linear 16-bit mono at 8 kHz
        for offset in range(0, len(pcm), frame_bytes):
            frame = pcm[offset : offset + frame_bytes]
            if len(frame) < frame_bytes:
                frame += b"\x00" * (frame_bytes - len(frame))
            await self.write_packet(writer, AUDIO_SOCKET_PCM_8K, frame)
            await asyncio.sleep(0.02)


class HealthHandler(BaseHTTPRequestHandler):
    state: SharedState

    def do_GET(self) -> None:  # noqa: N802 - BaseHTTPRequestHandler API
        if self.path == "/health":
            status = 200 if self.state.models_ready else 503
            self.respond(status, {"ready": self.state.models_ready, "error": self.state.startup_error})
            return
        if self.path == "/sessions/latest":
            latest = self.state.latest()
            self.respond(200 if latest else 404, asdict(latest) if latest else {"error": "no sessions"})
            return
        self.respond(404, {"error": "not found"})

    def log_message(self, format: str, *args: Any) -> None:
        LOG.debug("HTTP " + format, *args)

    def respond(self, status: int, body: dict[str, Any]) -> None:
        payload = json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


def inspect_wav(directory: Path, pattern: str, min_duration: float, min_rms: float) -> int:
    files = sorted(directory.glob(pattern), key=lambda path: path.stat().st_mtime)
    if not files:
        raise SystemExit(f"No WAV matched {directory / pattern}")
    target = files[-1]
    with wave.open(str(target), "rb") as handle:
        frames = handle.readframes(handle.getnframes())
        duration = handle.getnframes() / max(1, handle.getframerate())
        rms = pcm16_rms(frames) if handle.getsampwidth() == 2 else 0.0
        channels = handle.getnchannels()
        sample_rate = handle.getframerate()
    result = {
        "file": str(target),
        "duration_seconds": duration,
        "rms": rms,
        "channels": channels,
        "sample_rate": sample_rate,
        "passed": duration >= min_duration and rms >= min_rms and channels == 1,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["passed"] else 1


def assert_latest(
    report_dir: Path,
    tokens: list[str],
    expected_text: str,
    min_word_coverage: float,
    min_similarity: float,
    min_incoming: int,
    min_outgoing: int,
    min_rms: float,
) -> int:
    reports = sorted(report_dir.glob("*.json"), key=lambda path: path.stat().st_mtime)
    if not reports:
        raise SystemExit(f"No session report found in {report_dir}")
    data = json.loads(reports[-1].read_text(encoding="utf-8"))
    transcript = safe_token(str(data.get("transcript") or ""))
    token_checks = {token: safe_token(token) in transcript for token in tokens}

    normalized_expected = safe_token(expected_text)
    expected_words = [word for word in normalized_expected.split() if word]
    transcript_words = [word for word in transcript.split() if word]
    matched_words: dict[str, dict[str, object]] = {}
    for expected_word in expected_words:
        best_word = ""
        best_ratio = 0.0
        for actual_word in transcript_words:
            ratio = difflib.SequenceMatcher(None, expected_word, actual_word).ratio()
            if ratio > best_ratio:
                best_ratio = ratio
                best_word = actual_word
        matched_words[expected_word] = {
            "actual": best_word,
            "similarity": round(best_ratio, 4),
            "matched": best_ratio >= 0.72,
        }
    matched_count = sum(1 for value in matched_words.values() if value["matched"])
    word_coverage = matched_count / len(expected_words) if expected_words else 1.0
    sequence_similarity = difflib.SequenceMatcher(
        None, normalized_expected, transcript
    ).ratio() if normalized_expected else 1.0

    provider = str((data.get("metadata") or {}).get("provider") or "").strip().lower()
    passed = (
        data.get("success") is True
        and int(data.get("incoming_bytes") or 0) >= min_incoming
        and int(data.get("outgoing_bytes") or 0) >= min_outgoing
        and float(data.get("incoming_rms") or 0.0) >= min_rms
        and float(data.get("outgoing_rms") or 0.0) >= min_rms
        and all(token_checks.values())
        and word_coverage >= min_word_coverage
        and sequence_similarity >= min_similarity
        and provider in {"mock", "openai", "gemini", "qwen", "generic"}
    )
    result = {
        "passed": passed,
        "report": data,
        "provider": provider,
        "token_checks": token_checks,
        "expected_text": expected_text,
        "normalized_transcript": transcript,
        "matched_words": matched_words,
        "word_coverage": round(word_coverage, 4),
        "min_word_coverage": min_word_coverage,
        "sequence_similarity": round(sequence_similarity, 4),
        "min_similarity": min_similarity,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if passed else 1


def synthesize_fixture(text: str, output: Path) -> int:
    engine = SherpaSpeechEngine()
    pcm = engine.synthesize_8k_pcm(text)
    write_wav(output, pcm, 8000)
    result = {
        "output": str(output),
        "bytes": len(pcm),
        "rms": pcm16_rms(pcm),
        "sample_rate": 8000,
        "text": text,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if len(pcm) > 6000 and result["rms"] > 30 else 1


def run_server() -> int:
    logging.basicConfig(
        level=getattr(logging, os.getenv("NOVA_LOG_LEVEL", "INFO").upper(), logging.INFO),
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    report_dir = Path(os.getenv("NOVA_REPORT_DIR", "/reports"))
    state = SharedState(report_dir)
    try:
        speech = SherpaSpeechEngine()
        decision = AiDecisionEngine()
        state.models_ready = True
    except Exception as error:  # noqa: BLE001
        state.startup_error = f"{type(error).__name__}: {error}"
        LOG.exception("Failed to initialize verified speech runtime")
        raise

    HealthHandler.state = state
    health_host = os.getenv("NOVA_HEALTH_HOST", "0.0.0.0")
    health_port = int(os.getenv("NOVA_HEALTH_PORT", "8080"))
    health_server = ThreadingHTTPServer((health_host, health_port), HealthHandler)
    threading.Thread(target=health_server.serve_forever, daemon=True).start()
    LOG.info("Health API listening on %s:%s", health_host, health_port)
    try:
        asyncio.run(NovaAudioSocketServer(speech, decision, state).serve())
    finally:
        health_server.shutdown()
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="NOVA verified AudioSocket media gateway")
    sub = parser.add_subparsers(dest="command")
    sub.add_parser("serve")
    synth = sub.add_parser("synthesize")
    synth.add_argument("--text", required=True)
    synth.add_argument("--output", type=Path, required=True)
    assertion = sub.add_parser("assert-latest")
    assertion.add_argument("--report-dir", type=Path, required=True)
    assertion.add_argument("--expect-token", action="append", default=[])
    assertion.add_argument("--expect-text", default="")
    assertion.add_argument("--min-word-coverage", type=float, default=0.5)
    assertion.add_argument("--min-similarity", type=float, default=0.62)
    assertion.add_argument("--min-incoming-bytes", type=int, default=6000)
    assertion.add_argument("--min-outgoing-bytes", type=int, default=6000)
    assertion.add_argument("--min-rms", type=float, default=30.0)
    inspect = sub.add_parser("inspect-wav")
    inspect.add_argument("--directory", type=Path, required=True)
    inspect.add_argument("--pattern", required=True)
    inspect.add_argument("--min-duration", type=float, default=2.0)
    inspect.add_argument("--min-rms", type=float, default=15.0)
    args = parser.parse_args()
    command = args.command or "serve"
    if command == "serve":
        return run_server()
    if command == "synthesize":
        return synthesize_fixture(args.text, args.output)
    if command == "assert-latest":
        return assert_latest(
            args.report_dir,
            args.expect_token,
            args.expect_text,
            args.min_word_coverage,
            args.min_similarity,
            args.min_incoming_bytes,
            args.min_outgoing_bytes,
            args.min_rms,
        )
    if command == "inspect-wav":
        return inspect_wav(args.directory, args.pattern, args.min_duration, args.min_rms)
    parser.error(f"Unknown command {command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
