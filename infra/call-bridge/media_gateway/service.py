#!/usr/bin/env python3
"""NOVA bidirectional Asterisk AudioSocket media gateway.

The gateway receives signed-linear PCM from an Asterisk call, performs real
Sherpa-ONNX Whisper transcription, obtains an AI decision, synthesizes a real
Turkish Piper response and writes PCM back into the same call channel.

It is intentionally independent from Android call-audio capture restrictions.
A carrier call reaches this service through a SIP/PSTN trunk or call-forwarded
DID connected to Asterisk.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import math
import os
import re
import struct
import sys
import threading
import time
import urllib.error
import urllib.request
import uuid
import wave
from dataclasses import asdict, dataclass, field
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

import numpy as np
import sherpa_onnx
import soundfile as sf

AUDIO_SOCKET_TERMINATE = 0x00
AUDIO_SOCKET_UUID = 0x01
AUDIO_SOCKET_DTMF = 0x03
AUDIO_SOCKET_PCM_8K = 0x10
AUDIO_SOCKET_PCM_16K = 0x12

LOG = logging.getLogger("nova-call-media")


def env_bool(name: str, default: bool) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


def normalize_text(value: str) -> str:
    folded = value.strip().lower().translate(
        str.maketrans({"ı": "i", "ğ": "g", "ü": "u", "ş": "s", "ö": "o", "ç": "c"})
    )
    return re.sub(r"[^a-z0-9]+", " ", folded).strip()


def pcm16_rms(pcm: bytes) -> float:
    if not pcm:
        return 0.0
    samples = np.frombuffer(pcm, dtype="<i2").astype(np.float32)
    if samples.size == 0:
        return 0.0
    return float(np.sqrt(np.mean(np.square(samples))))


def resample_pcm16(pcm: bytes, source_rate: int, target_rate: int) -> bytes:
    if not pcm or source_rate == target_rate:
        return pcm
    source = np.frombuffer(pcm, dtype="<i2").astype(np.float32)
    if source.size < 2:
        return pcm
    target_size = max(1, int(round(source.size * target_rate / source_rate)))
    old_axis = np.arange(source.size, dtype=np.float64)
    new_axis = np.linspace(0, source.size - 1, target_size, dtype=np.float64)
    target = np.interp(new_axis, old_axis, source)
    return np.clip(target, -32768, 32767).astype("<i2").tobytes()


def write_wav(path: Path, pcm: bytes, sample_rate: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(pcm)


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
        self.lock = threading.Lock()
        self.sessions: dict[str, SessionReport] = {}
        self.models_ready = False
        self.startup_error = ""

    def save(self, report: SessionReport) -> None:
        report.completed_at = report.completed_at or time.time()
        with self.lock:
            self.sessions[report.session_id] = report
        self.report_dir.mkdir(parents=True, exist_ok=True)
        target = self.report_dir / f"{report.session_id}.json"
        target.write_text(json.dumps(asdict(report), ensure_ascii=False, indent=2), encoding="utf-8")

    def latest(self) -> SessionReport | None:
        with self.lock:
            if not self.sessions:
                files = sorted(self.report_dir.glob("*.json"), key=lambda item: item.stat().st_mtime)
                if not files:
                    return None
                data = json.loads(files[-1].read_text(encoding="utf-8"))
                return SessionReport(**data)
            return max(self.sessions.values(), key=lambda item: item.started_at)


class SherpaSpeechEngine:
    def __init__(self) -> None:
        asr_encoder = os.getenv("NOVA_ASR_ENCODER", "/models/asr/encoder.onnx")
        asr_decoder = os.getenv("NOVA_ASR_DECODER", "/models/asr/decoder.onnx")
        asr_tokens = os.getenv("NOVA_ASR_TOKENS", "/models/asr/tokens.txt")
        tts_model = os.getenv("NOVA_TTS_MODEL", "/models/tts/model.onnx")
        tts_tokens = os.getenv("NOVA_TTS_TOKENS", "/models/tts/tokens.txt")
        tts_data = os.getenv("NOVA_TTS_DATA", "/models/tts/espeak-ng-data")
        required = [asr_encoder, asr_decoder, asr_tokens, tts_model, tts_tokens, tts_data]
        missing = [path for path in required if not Path(path).exists()]
        if missing:
            raise FileNotFoundError(f"NOVA speech model paths are missing: {missing}")

        feature_class = getattr(sherpa_onnx, "OfflineFeatureExtractorConfig", None)
        if feature_class is None:
            feature_class = getattr(sherpa_onnx, "FeatureConfig")
        try:
            feature_config = feature_class(sampling_rate=16000, feature_dim=80)
        except TypeError:
            feature_config = feature_class(sample_rate=16000, feature_dim=80)

        whisper = sherpa_onnx.OfflineWhisperModelConfig(
            encoder=asr_encoder,
            decoder=asr_decoder,
            language="tr",
            task="transcribe",
        )
        model = sherpa_onnx.OfflineModelConfig(
            whisper=whisper,
            tokens=asr_tokens,
            num_threads=int(os.getenv("NOVA_SPEECH_THREADS", "2")),
            provider="cpu",
            model_type="whisper",
        )
        recognizer_config = sherpa_onnx.OfflineRecognizerConfig(
            feat_config=feature_config,
            model_config=model,
            decoding_method="greedy_search",
            max_active_paths=4,
        )
        if hasattr(recognizer_config, "validate") and not recognizer_config.validate():
            raise ValueError("Sherpa Whisper configuration validation failed")
        self.recognizer = sherpa_onnx.OfflineRecognizer(recognizer_config)

        vits = sherpa_onnx.OfflineTtsVitsModelConfig(
            model=tts_model,
            tokens=tts_tokens,
            data_dir=tts_data,
            noise_scale=0.667,
            noise_scale_w=0.8,
            length_scale=float(os.getenv("NOVA_TTS_LENGTH_SCALE", "1.0")),
        )
        tts_model_config = sherpa_onnx.OfflineTtsModelConfig(
            vits=vits,
            num_threads=int(os.getenv("NOVA_SPEECH_THREADS", "2")),
            provider="cpu",
            debug=False,
        )
        tts_config = sherpa_onnx.OfflineTtsConfig(model=tts_model_config)
        if hasattr(tts_config, "validate") and not tts_config.validate():
            raise ValueError("Sherpa Piper TTS configuration validation failed")
        self.tts = sherpa_onnx.OfflineTts(tts_config)

    def transcribe_8k_pcm(self, pcm: bytes) -> str:
        pcm16 = resample_pcm16(pcm, 8000, 16000)
        samples = np.frombuffer(pcm16, dtype="<i2").astype(np.float32) / 32768.0
        stream = self.recognizer.create_stream()
        stream.accept_waveform(16000, samples)
        self.recognizer.decode_stream(stream)
        result = stream.result
        return str(getattr(result, "text", "")).strip()

    def synthesize_8k_pcm(self, text: str) -> bytes:
        audio = self.tts.generate(text=text, sid=0, speed=1.0)
        samples = np.asarray(audio.samples, dtype=np.float32)
        source_rate = int(audio.sample_rate)
        pcm = np.clip(samples * 32767.0, -32768, 32767).astype("<i2").tobytes()
        return resample_pcm16(pcm, source_rate, 8000)

    def synthesize_wav(self, text: str, output: Path) -> None:
        audio = self.tts.generate(text=text, sid=0, speed=1.0)
        output.parent.mkdir(parents=True, exist_ok=True)
        sf.write(str(output), np.asarray(audio.samples, dtype=np.float32), int(audio.sample_rate), subtype="PCM_16")


@dataclass
class Decision:
    reply: str
    hangup: bool = True
    metadata: dict[str, Any] = field(default_factory=dict)


class AiDecisionEngine:
    def __init__(self) -> None:
        self.provider = os.getenv("NOVA_CALL_AI_PROVIDER", "mock").strip().lower()
        self.api_key = os.getenv("NOVA_CALL_AI_KEY", "").strip()
        self.model = os.getenv("NOVA_CALL_AI_MODEL", "").strip()
        self.endpoint = os.getenv("NOVA_CALL_AI_ENDPOINT", "").strip()

    def decide(self, transcript: str, session_id: str) -> Decision:
        if self.provider == "mock":
            return Decision(
                reply=os.getenv(
                    "NOVA_CALL_MOCK_REPLY",
                    "NOVA çift yönlü çağrı medya testi başarıyla tamamlandı.",
                ),
                hangup=env_bool("NOVA_CALL_HANGUP_AFTER_REPLY", True),
                metadata={"provider": "mock", "session_id": session_id},
            )
        if not self.api_key and self.provider != "generic":
            raise RuntimeError(f"{self.provider} API key is missing")
        if self.provider == "openai":
            return self._openai(transcript)
        if self.provider == "gemini":
            return self._gemini(transcript)
        if self.provider == "qwen":
            return self._qwen(transcript)
        if self.provider == "generic":
            return self._generic(transcript, session_id)
        raise RuntimeError(f"Unsupported call AI provider: {self.provider}")

    def _system_prompt(self) -> str:
        return (
            "Sen NOVA çağrı asistanısın. Yalnız Türkçe, kısa ve doğal konuş. "
            "Arayan kişinin söylemediği bilgiyi uydurma. Finansal, kimlik veya özel "
            "bilgileri paylaşma. Yanıtını yalnız konuşulacak düz metin olarak ver."
        )

    def _request_json(self, url: str, body: dict[str, Any], headers: dict[str, str]) -> dict[str, Any]:
        request = urllib.request.Request(
            url,
            data=json.dumps(body).encode("utf-8"),
            headers={"Content-Type": "application/json", **headers},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                payload = response.read().decode("utf-8")
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"AI HTTP {error.code}: {detail[:500]}") from error
        decoded = json.loads(payload)
        if not isinstance(decoded, dict):
            raise RuntimeError("AI response is not a JSON object")
        return decoded

    def _openai(self, transcript: str) -> Decision:
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
            parts: list[str] = []
            for item in data.get("output", []):
                if not isinstance(item, dict):
                    continue
                for part in item.get("content", []):
                    if isinstance(part, dict) and part.get("text"):
                        parts.append(str(part["text"]))
            text = "\n".join(parts).strip()
        if not text:
            raise RuntimeError("OpenAI returned no speakable text")
        return Decision(text, env_bool("NOVA_CALL_HANGUP_AFTER_REPLY", False), {"provider": "openai", "model": model})

    def _gemini(self, transcript: str) -> Decision:
        model = self.model or "gemini-3.5-flash-lite"
        endpoint = self.endpoint or f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={self.api_key}"
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
            packet_type, payload = await asyncio.wait_for(self.read_packet(reader), timeout=25)
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


def start_health_server(state: SharedState) -> ThreadingHTTPServer:
    handler = type("NovaHealthHandler", (HealthHandler,), {"state": state})
    server = ThreadingHTTPServer(("0.0.0.0", int(os.getenv("NOVA_HEALTH_PORT", "8080"))), handler)
    threading.Thread(target=server.serve_forever, name="nova-health", daemon=True).start()
    return server


def command_serve() -> int:
    report_dir = Path(os.getenv("NOVA_REPORT_DIR", "/reports"))
    state = SharedState(report_dir)
    start_health_server(state)
    try:
        speech = SherpaSpeechEngine()
        state.models_ready = True
    except Exception as error:  # noqa: BLE001
        state.startup_error = f"{type(error).__name__}: {error}"
        LOG.exception("Speech engine initialization failed")
        return 2
    server = NovaAudioSocketServer(speech, AiDecisionEngine(), state)
    asyncio.run(server.serve())
    return 0


def command_synthesize(args: argparse.Namespace) -> int:
    engine = SherpaSpeechEngine()
    output = Path(args.output)
    engine.synthesize_wav(args.text, output)
    print(json.dumps({"output": str(output), "bytes": output.stat().st_size, "text": args.text}, ensure_ascii=False))
    return 0


def command_assert_latest(args: argparse.Namespace) -> int:
    state = SharedState(Path(args.report_dir))
    latest = state.latest()
    if latest is None:
        raise SystemExit("No call session report was produced")
    failures: list[str] = []
    if not latest.success:
        failures.append(f"session success=false errors={latest.errors}")
    if latest.incoming_bytes < args.min_incoming_bytes:
        failures.append(f"incoming bytes {latest.incoming_bytes} < {args.min_incoming_bytes}")
    if latest.outgoing_bytes < args.min_outgoing_bytes:
        failures.append(f"outgoing bytes {latest.outgoing_bytes} < {args.min_outgoing_bytes}")
    if latest.incoming_rms < args.min_rms:
        failures.append(f"incoming RMS {latest.incoming_rms:.2f} < {args.min_rms}")
    if latest.outgoing_rms < args.min_rms:
        failures.append(f"outgoing RMS {latest.outgoing_rms:.2f} < {args.min_rms}")
    transcript = normalize_text(latest.transcript)
    expected = [normalize_text(token) for token in args.expect_token]
    if expected and not any(token and token in transcript for token in expected):
        failures.append(f"transcript {latest.transcript!r} did not contain any expected token {args.expect_token}")
    print(json.dumps(asdict(latest), ensure_ascii=False, indent=2))
    if failures:
        raise SystemExit("; ".join(failures))
    return 0


def command_inspect_wav(args: argparse.Namespace) -> int:
    paths = sorted(Path(args.directory).glob(args.pattern), key=lambda item: item.stat().st_mtime)
    if not paths:
        raise SystemExit(f"No WAV matched {args.directory}/{args.pattern}")
    path = paths[-1]
    with wave.open(str(path), "rb") as wav:
        frames = wav.readframes(wav.getnframes())
        channels = wav.getnchannels()
        width = wav.getsampwidth()
        rate = wav.getframerate()
        duration = wav.getnframes() / max(1, rate)
    if width != 2:
        raise SystemExit(f"Expected 16-bit recording, got sample width {width}")
    if channels > 1:
        samples = np.frombuffer(frames, dtype="<i2").reshape(-1, channels).mean(axis=1).astype("<i2")
        frames = samples.tobytes()
    rms = pcm16_rms(frames)
    result = {"path": str(path), "bytes": path.stat().st_size, "duration": duration, "rms": rms, "sample_rate": rate}
    print(json.dumps(result, indent=2))
    if duration < args.min_duration or rms < args.min_rms:
        raise SystemExit(f"Recorded caller audio failed thresholds: {result}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="NOVA call media gateway")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("serve")
    synth = sub.add_parser("synthesize")
    synth.add_argument("--text", required=True)
    synth.add_argument("--output", required=True)
    check = sub.add_parser("assert-latest")
    check.add_argument("--report-dir", default="/reports")
    check.add_argument("--expect-token", action="append", default=[])
    check.add_argument("--min-incoming-bytes", type=int, default=4000)
    check.add_argument("--min-outgoing-bytes", type=int, default=4000)
    check.add_argument("--min-rms", type=float, default=40.0)
    inspect = sub.add_parser("inspect-wav")
    inspect.add_argument("--directory", default="/shared/recordings")
    inspect.add_argument("--pattern", default="*.wav")
    inspect.add_argument("--min-duration", type=float, default=1.0)
    inspect.add_argument("--min-rms", type=float, default=20.0)
    return parser


def main() -> int:
    logging.basicConfig(
        level=os.getenv("NOVA_LOG_LEVEL", "INFO").upper(),
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    args = build_parser().parse_args()
    if args.command == "serve":
        return command_serve()
    if args.command == "synthesize":
        return command_synthesize(args)
    if args.command == "assert-latest":
        return command_assert_latest(args)
    if args.command == "inspect-wav":
        return command_inspect_wav(args)
    return 2


if __name__ == "__main__":
    sys.exit(main())
