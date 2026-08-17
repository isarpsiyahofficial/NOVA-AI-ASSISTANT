#!/usr/bin/env python3
"""Exhaustive static decision-graph audit for NOVA.

The audit walks every source/config/test file in the Git checkout and records:
- files, line counts, hashes and imports;
- decision-producing classes/methods and their call sites;
- construction of AI/API roots;
- provider HTTP access;
- native phone/action/TTS/STT bridges;
- authority and confirmation metadata flows;
- timer, receiver, service and background trigger surfaces.

It also enforces architectural invariants that prevent a second brain, forged
owner authority, unverified side effects and speech outside the final TTS gate.
The report is evidence, not a claim that presence of a class means it works.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]

SOURCE_SUFFIXES = {
    ".dart",
    ".kt",
    ".kts",
    ".java",
    ".py",
    ".cpp",
    ".cc",
    ".c",
    ".h",
    ".hpp",
    ".xml",
    ".yaml",
    ".yml",
    ".sh",
    ".gradle",
    ".properties",
    ".conf",
    ".template",
}
SPECIAL_SOURCE_NAMES = {
    "Dockerfile",
    "CMakeLists.txt",
    "pubspec.yaml",
    "analysis_options.yaml",
}
EXCLUDED_PARTS = {
    ".git",
    ".dart_tool",
    ".gradle",
    "build",
    ".cache",
    "runtime",
    "node_modules",
    ".idea",
}
BINARY_OR_MODEL_SUFFIXES = {
    ".onnx",
    ".aar",
    ".so",
    ".jar",
    ".apk",
    ".wav",
    ".bin",
    ".zip",
    ".gz",
    ".tar",
    ".png",
    ".jpg",
    ".jpeg",
    ".webp",
    ".ttf",
    ".otf",
}


@dataclass
class Finding:
    severity: str
    rule: str
    path: str
    line: int
    message: str
    evidence: str
    category: str


@dataclass
class SourceFile:
    path: str
    suffix: str
    bytes: int
    lines: int
    sha256: str
    imports: list[str] = field(default_factory=list)
    classes: list[str] = field(default_factory=list)
    functions: list[str] = field(default_factory=list)
    decision_symbols: list[str] = field(default_factory=list)
    triggers: list[str] = field(default_factory=list)
    authority_keys: list[str] = field(default_factory=list)


@dataclass
class Rule:
    id: str
    severity: str
    category: str
    description: str
    check: callable


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def is_source(path: Path) -> bool:
    if not path.is_file():
        return False
    if any(part in EXCLUDED_PARTS for part in path.relative_to(ROOT).parts):
        return False
    if path.suffix.lower() in BINARY_OR_MODEL_SUFFIXES:
        return False
    return path.suffix.lower() in SOURCE_SUFFIXES or path.name in SPECIAL_SOURCE_NAMES


def safe_read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="replace")


def line_of(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def snippets(text: str, pattern: re.Pattern[str]) -> Iterable[tuple[int, str, re.Match[str]]]:
    lines = text.splitlines()
    for match in pattern.finditer(text):
        line = line_of(text, match.start())
        evidence = lines[line - 1].strip() if 0 < line <= len(lines) else match.group(0)
        yield line, evidence[:500], match


def unique(values: Iterable[str]) -> list[str]:
    return sorted({value for value in values if value})


def classify(path: str) -> str:
    if path.startswith("lib/core/"):
        return "dart_core"
    if path.startswith("lib/services/"):
        return "dart_service"
    if path.startswith("lib/ui/"):
        return "dart_ui"
    if path.startswith("android/"):
        return "android_native"
    if path.startswith("infra/call-bridge/"):
        return "call_bridge"
    if path.startswith("test/"):
        return "test"
    if path.startswith("tooling/"):
        return "tooling"
    if path.startswith(".github/workflows/"):
        return "workflow"
    return "other"


IMPORT_PATTERNS = [
    re.compile(r"^\s*import\s+['\"]([^'\"]+)['\"]", re.MULTILINE),
    re.compile(r"^\s*#include\s+[<\"]([^>\"]+)[>\"]", re.MULTILINE),
    re.compile(r"^\s*from\s+([A-Za-z0-9_\.]+)\s+import\s+", re.MULTILINE),
    re.compile(r"^\s*import\s+([A-Za-z0-9_\.]+)\s*$", re.MULTILINE),
]
CLASS_PATTERNS = [
    re.compile(r"\bclass\s+([A-Za-z_][A-Za-z0-9_]*)"),
    re.compile(r"\bobject\s+([A-Za-z_][A-Za-z0-9_]*)"),
    re.compile(r"\benum\s+([A-Za-z_][A-Za-z0-9_]*)"),
]
FUNCTION_PATTERNS = [
    re.compile(
        r"(?:Future<[^>]+>|Future|void|bool|String|int|double|Map<[^\n]+?>|List<[^\n]+?>|[A-Za-z_][A-Za-z0-9_<>, ?]*)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\("
    ),
    re.compile(r"^\s*(?:async\s+)?def\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", re.MULTILINE),
    re.compile(r"^\s*fun\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", re.MULTILINE),
]
DECISION_NAME = re.compile(
    r"(?:Decision|Policy|Authority|Brain|Router|Orchestrator|Executor|Controller|Guard|Gate|Resolver|Classifier|Planner|Reasoner|Manager)",
    re.IGNORECASE,
)
DECISION_METHOD = re.compile(
    r"^(?:process|handle|handleInput|processUserTurn|decide|evaluate|execute|authorize|route|resolve|dispatch|classify|plan|select|should|may|allow|trigger|run|accept)",
    re.IGNORECASE,
)
AUTHORITY_KEYS = [
    "ownerVerified",
    "voiceOwnerVerified",
    "ownerConfidence",
    "ownerMatched",
    "voiceIdentityChecked",
    "localCompanionAuthorityProof",
    "knownContact",
    "authorizedContact",
    "explicitlyAllowedContact",
    "callAnswerAllowed",
    "userConfirmedThisAction",
    "userInitiated",
    "trustedSource",
    "singleBrainAuthority",
    "singleBrainAllowed",
    "actionVerified",
]
TRIGGER_PATTERNS = {
    "timer": re.compile(r"\b(?:Timer|Timer\.periodic|scheduleAtFixedRate|asyncio\.sleep)\b"),
    "receiver": re.compile(r"\b(?:BroadcastReceiver|onReceive\s*\(|BOOT_COMPLETED|PHONE_STATE)\b"),
    "foreground_service": re.compile(r"\b(?:ForegroundService|startForeground|foregroundServiceType)\b"),
    "background_service": re.compile(r"\b(?:BackgroundService|WorkManager|AlarmManager|JobScheduler)\b"),
    "method_channel": re.compile(r"\b(?:MethodChannel|invokeMethod|setMethodCallHandler)\b"),
    "tts": re.compile(r"\b(?:FlutterTts|TextToSpeech|\.speak\s*\(|synthesize|OfflineTts|Piper)\b"),
    "stt": re.compile(r"\b(?:SpeechRecognizer|RecognizerIntent|transcribe|Whisper|OfflineRecognizer)\b"),
    "phone_action": re.compile(r"\b(?:answerRingingCall|rejectRingingCall|disconnectCurrentCall|placeCall|startActivity|performGlobalAction|dispatchMediaKey|setMuted|routeToSpeaker)\b"),
    "provider_http": re.compile(r"(?:generativelanguage\.googleapis\.com|api\.openai\.com|dashscope|chat/completions|/v1/responses|generateContent)"),
}


def inventory() -> tuple[list[SourceFile], dict[str, str]]:
    files: list[SourceFile] = []
    texts: dict[str, str] = {}
    for path in sorted(ROOT.rglob("*")):
        if not is_source(path):
            continue
        text = safe_read(path)
        path_key = rel(path)
        texts[path_key] = text
        imports: list[str] = []
        for pattern in IMPORT_PATTERNS:
            imports.extend(match.group(1) for match in pattern.finditer(text))
        classes: list[str] = []
        for pattern in CLASS_PATTERNS:
            classes.extend(match.group(1) for match in pattern.finditer(text))
        functions: list[str] = []
        for pattern in FUNCTION_PATTERNS:
            functions.extend(match.group(1) for match in pattern.finditer(text))
        decisions = [name for name in classes + functions if DECISION_NAME.search(name) or DECISION_METHOD.search(name)]
        triggers = [name for name, pattern in TRIGGER_PATTERNS.items() if pattern.search(text)]
        authority_keys = [key for key in AUTHORITY_KEYS if key in text]
        encoded = text.encode("utf-8", errors="replace")
        files.append(
            SourceFile(
                path=path_key,
                suffix=path.suffix.lower() or path.name,
                bytes=len(encoded),
                lines=text.count("\n") + (1 if text else 0),
                sha256=hashlib.sha256(encoded).hexdigest(),
                imports=unique(imports),
                classes=unique(classes),
                functions=unique(functions),
                decision_symbols=unique(decisions),
                triggers=unique(triggers),
                authority_keys=unique(authority_keys),
            )
        )
    return files, texts


def add_matches(
    findings: list[Finding],
    texts: dict[str, str],
    *,
    rule: str,
    severity: str,
    category: str,
    pattern: re.Pattern[str],
    message: str,
    include: callable | None = None,
    exclude: callable | None = None,
) -> None:
    for path, text in texts.items():
        if include and not include(path):
            continue
        if exclude and exclude(path):
            continue
        for line, evidence, _ in snippets(text, pattern):
            findings.append(Finding(severity, rule, path, line, message, evidence, category))


def exact_file_rule(
    findings: list[Finding],
    texts: dict[str, str],
    *,
    path: str,
    rule: str,
    severity: str,
    category: str,
    pattern: re.Pattern[str],
    message: str,
) -> None:
    text = texts.get(path, "")
    for line, evidence, _ in snippets(text, pattern):
        findings.append(Finding(severity, rule, path, line, message, evidence, category))


def build_findings(files: list[SourceFile], texts: dict[str, str]) -> list[Finding]:
    findings: list[Finding] = []

    # Exactly one production constructor is allowed, inside the runtime graph factory.
    add_matches(
        findings,
        texts,
        rule="DG001_SECOND_AI_ROOT",
        severity="error",
        category="decision_root",
        pattern=re.compile(r"\bNovaAiService\s*\("),
        message="NovaAiService is constructed outside the single runtime graph factory.",
        include=lambda p: p.startswith("lib/") and p not in {
            "lib/core/ai/nova_ai_service.dart",
            "lib/services/runtime/nova_runtime_graph_service.dart",
        },
    )

    # ApiService instances are configuration-bearing provider roots. Production code
    # may create them only in main/runtime graph bootstrap; tests are exempt.
    add_matches(
        findings,
        texts,
        rule="DG002_SECOND_API_ROOT",
        severity="error",
        category="decision_root",
        pattern=re.compile(r"\bApiService\s*\("),
        message="ApiService is constructed outside approved bootstrap files.",
        include=lambda p: p.startswith("lib/"),
        exclude=lambda p: p in {
            "lib/main.dart",
            "lib/services/api/api_service.dart",
            "lib/services/runtime/nova_runtime_graph_service.dart",
        },
    )

    add_matches(
        findings,
        texts,
        rule="DG003_DIRECT_API_SEND",
        severity="error",
        category="decision_bypass",
        pattern=re.compile(r"\b(?:apiService|_apiService|ApiService\([^\n]*\))\s*\.\s*send\s*\("),
        message="A surface calls ApiService.send directly instead of NovaCoreTurnController/SingleBrain.",
        include=lambda p: p.startswith("lib/"),
        exclude=lambda p: p == "lib/core/ai/nova_ai_service.dart",
    )

    add_matches(
        findings,
        texts,
        rule="DG004_PROVIDER_HTTP_OUTSIDE_GATEWAY",
        severity="error",
        category="provider_bypass",
        pattern=TRIGGER_PATTERNS["provider_http"],
        message="Provider endpoint appears outside approved API/media gateway modules.",
        exclude=lambda p: p in {
            "lib/services/api/api_service.dart",
            "lib/core/api/nova_ai_provider_type.dart",
            "android/app/src/main/kotlin/com/example/nova/NovaSystemBoundaryGuard.kt",
            "infra/call-bridge/media_gateway/service.py",
        } or p.startswith("test/") or p.startswith("tooling/"),
    )

    # Default approval must always be false; call sites must opt in with evidence.
    exact_file_rule(
        findings,
        texts,
        path="lib/core/ai/ai_request.dart",
        rule="AUTH001_APPROVAL_DEFAULT_TRUE",
        severity="error",
        category="authority",
        pattern=re.compile(r"this\.userConfirmedThisAction\s*=\s*true"),
        message="AiRequest defaults user confirmation to true.",
    )
    exact_file_rule(
        findings,
        texts,
        path="lib/core/ai/ai_request.dart",
        rule="AUTH002_INITIATED_DEFAULT_TRUE",
        severity="error",
        category="authority",
        pattern=re.compile(r"this\.userInitiated\s*=\s*true"),
        message="AiRequest defaults user initiation to true instead of requiring explicit provenance.",
    )

    # Raw mutable metadata cannot mint authority. Reads are permitted only in a
    # dedicated authority normalizer once that component exists.
    authority_read = re.compile(
        r"(?:metadata|context)\s*\[\s*['\"](?:ownerVerified|voiceOwnerVerified|ownerConfidence|ownerMatched|voiceIdentityChecked|localCompanionAuthorityProof|knownContact|authorizedContact|explicitlyAllowedContact|callAnswerAllowed|userConfirmedThisAction|trustedSource)['\"]\s*\]"
    )
    add_matches(
        findings,
        texts,
        rule="AUTH003_RAW_METADATA_AUTHORITY",
        severity="error",
        category="authority",
        pattern=authority_read,
        message="Mutable metadata/context is read as an authority fact outside a typed authority evidence guard.",
        include=lambda p: p.startswith("lib/"),
        exclude=lambda p: p in {
            "lib/services/runtime/nova_turn_authority_guard_service.dart",
            "lib/core/turn/nova_turn_authority.dart",
            "lib/services/actions/nova_action_intent_guard_service.dart",
        },
    )

    exact_file_rule(
        findings,
        texts,
        path="lib/services/runtime/nova_single_brain_authority_service.dart",
        rule="AUTH004_NAME_BASED_OWNER",
        severity="error",
        category="authority",
        pattern=re.compile(r"name\.contains\(['\"](?:ibrahim|patron)['\"]\)"),
        message="A display name can promote a speaker to device_owner without cryptographic/local voice evidence.",
    )
    exact_file_rule(
        findings,
        texts,
        path="lib/services/runtime/nova_single_brain_authority_service.dart",
        rule="AUTH005_RELATION_LABEL_OWNER",
        severity="error",
        category="authority",
        pattern=re.compile(r"relation\.contains\(['\"](?:owner|sahip)['\"]\)"),
        message="A relationship label can promote a speaker to device_owner without verified voice evidence.",
    )

    exact_file_rule(
        findings,
        texts,
        path="lib/core/turn/nova_core_turn_controller.dart",
        rule="DG005_FALLBACK_ROOT_FACTORY",
        severity="error",
        category="decision_root",
        pattern=re.compile(r"factory:\s*\(\)\s*=>\s*NovaRuntimeGraphService\.buildAiService"),
        message="Core turn controller can construct a fallback decision root when bootstrap is missing.",
    )

    exact_file_rule(
        findings,
        texts,
        path="lib/services/runtime/nova_runtime_graph_service.dart",
        rule="DG006_ASSERT_ONLY_DUPLICATE_REJECTION",
        severity="error",
        category="decision_root",
        pattern=re.compile(r"assert\s*\(\s*\(\)\s*\{\s*throw\s+StateError", re.DOTALL),
        message="Duplicate decision root rejection depends on assert and disappears in release mode.",
    )

    exact_file_rule(
        findings,
        texts,
        path="lib/services/actions/nova_device_action_executor_service.dart",
        rule="AUTH006_SCREEN_LOCK_FORCED_FALSE",
        severity="error",
        category="authority",
        pattern=re.compile(r"localCompanionProof\s*\?\s*false\s*:"),
        message="Companion proof forces screenLocked=false instead of using the measured device state.",
    )

    exact_file_rule(
        findings,
        texts,
        path="lib/services/actions/nova_device_action_executor_service.dart",
        rule="ACT001_NATIVE_INITIATED_LITERAL_TRUE",
        severity="error",
        category="device_action",
        pattern=re.compile(r"userInitiated:\s*true"),
        message="Native action receives a hard-coded userInitiated=true rather than the verified request authority.",
    )

    exact_file_rule(
        findings,
        texts,
        path="lib/services/actions/nova_device_action_executor_service.dart",
        rule="ACT002_SUCCESS_WITHOUT_VERIFICATION",
        severity="error",
        category="device_action",
        pattern=re.compile(r"success:\s*true,\s*\n\s*verified:\s*verification\.verified"),
        message="Device action result can be success=true while postcondition verification is false.",
    )

    # Direct native phone controls should stay inside designated bridge/adapters.
    phone_methods = re.compile(
        r"\b(?:answerRingingCall|rejectRingingCall|disconnectCurrentCall|setMuted|routeToSpeaker|toggleHold|registerOwnerApprovedOutbound|dispatchMediaKey|performGlobalAction)\s*\("
    )
    approved_phone = {
        "lib/services/actions/nova_device_action_executor_service.dart",
        "lib/services/actions/nova_phone_control_bridge_service.dart",
        "lib/services/call/nova_call_control_bridge_service.dart",
        "android/app/src/main/kotlin/com/example/nova/NovaCallControlBridgePlugin.kt",
        "android/app/src/main/kotlin/com/example/nova/NovaPhoneControlBridge.kt",
        "android/app/src/main/kotlin/com/example/nova/NovaAccessibilityService.kt",
        "android/app/src/main/kotlin/com/example/nova/NovaCallActionReceiver.kt",
        "android/app/src/main/kotlin/com/example/nova/NovaCallControlBridge.kt",
        "android/app/src/main/kotlin/com/example/nova/NovaCallUiActivity.kt",
        "android/app/src/main/kotlin/com/example/nova/NovaIncomingCallBannerService.kt",
        "android/app/src/main/kotlin/com/example/nova/NovaIncomingCallBannerActivity.kt",
        "android/app/src/main/kotlin/com/example/nova/NovaCarrierBoundaryGuard.kt",
        "android/app/src/debug/kotlin/com/example/nova/testing/NovaDebugControlReceiver.kt",
    }
    add_matches(
        findings,
        texts,
        rule="ACT003_DIRECT_NATIVE_PHONE_CONTROL",
        severity="error",
        category="device_action",
        pattern=phone_methods,
        message="Phone action bypasses the approved policy/executor/bridge chain.",
        include=lambda p: p.startswith("lib/") or p.startswith("android/"),
        exclude=lambda p: p in approved_phone or p.startswith("test/"),
    )

    # Production MethodChannel calls are inventoried as warnings unless they are
    # action-like commands outside known bridge services.
    invoke_pattern = re.compile(r"invokeMethod(?:<[^>]+>)?\s*\(\s*['\"]([^'\"]+)['\"]")
    approved_method_channel_fragments = {
        "lib/services/actions/nova_phone_control_bridge_service.dart",
        "lib/services/call/nova_call_control_bridge_service.dart",
        "lib/services/call/nova_call_state_service.dart",
        "lib/services/system/nova_overlay_bridge_service.dart",
        "lib/services/asr/nova_streaming_asr_runtime_service.dart",
        "lib/services/audio_runtime/nova_native_audio_bridge_service.dart",
        "lib/services/identity/nova_voice_identity_bridge_service.dart",
        "lib/services/tts/nova_tts_service.dart",
        "lib/services/voice/",
    }
    action_word = re.compile(r"(?:call|answer|reject|hang|mute|speaker|media|tap|text|home|back|notification|quick|package|overlay)", re.IGNORECASE)
    for path, text in texts.items():
        if not path.startswith("lib/"):
            continue
        for line, evidence, match in snippets(text, invoke_pattern):
            method = match.group(1)
            approved = any(path == item or path.startswith(item) for item in approved_method_channel_fragments)
            if action_word.search(method) and not approved:
                findings.append(
                    Finding(
                        "error",
                        "ACT004_METHOD_CHANNEL_ACTION_BYPASS",
                        path,
                        line,
                        f"Action-like MethodChannel method {method!r} is invoked outside approved bridges.",
                        evidence,
                        "device_action",
                    )
                )

    # TTS may be emitted only from NovaTtsService/native engine or explicit call bridge.
    tts_emit = re.compile(r"(?:\.speak\s*\(|TextToSpeech\s*\(|OfflineTts\s*\(|tts\.generate\s*\()")
    approved_tts = {
        "lib/services/tts/nova_tts_service.dart",
        "lib/services/speech/tts_service.dart",
        "lib/ui/nova/nova_dashboard_page.dart",
        "android/app/src/main/kotlin/com/example/nova/NovaAndroidTtsMouthBridgePlugin.kt",
        "android/app/src/main/kotlin/com/example/nova/NovaAndroidTtsMouthEngine.kt",
        "android/app/src/main/kotlin/com/example/nova/NovaXttsBridgePlugin.kt",
        "android/app/src/main/kotlin/com/example/nova/NovaXttsEngine.kt",
        "infra/call-bridge/media_gateway/service.py",
        "infra/call-bridge/media_gateway/speech_runtime.py",
    }
    add_matches(
        findings,
        texts,
        rule="TTS001_DIRECT_SPEECH_BYPASS",
        severity="error",
        category="speech",
        pattern=tts_emit,
        message="Speech is emitted outside the final TTS authority gate.",
        include=lambda p: p.startswith("lib/") or p.startswith("android/") or p.startswith("infra/"),
        exclude=lambda p: p in approved_tts or p.startswith("test/") or p.startswith("tooling/"),
    )

    # Android platform SpeechRecognizer must not be a hidden production fallback.
    add_matches(
        findings,
        texts,
        rule="STT001_PLATFORM_RECOGNIZER_PRESENT",
        severity="warning",
        category="speech",
        pattern=re.compile(r"\bSpeechRecognizer\b"),
        message="Platform SpeechRecognizer exists; verify it cannot become an independent/fallback STT decision path.",
        include=lambda p: p.startswith("android/app/src/main/") or p.startswith("lib/"),
    )

    # A decision wrapper that can speak must explicitly require SingleBrain before speech.
    wrapper_pattern = re.compile(
        r"registerDecisionWrapper\s*\(.*?canProduceSpokenText:\s*true.*?requiresSingleBrainBeforeSpeech:\s*false",
        re.DOTALL,
    )
    add_matches(
        findings,
        texts,
        rule="TTS002_SPEAKING_WRAPPER_WITHOUT_GATE",
        severity="error",
        category="speech",
        pattern=wrapper_pattern,
        message="A speaking decision wrapper is registered without a SingleBrain-before-speech requirement.",
        include=lambda p: p.startswith("lib/"),
    )

    # Independent decision-like service methods are an inventory warning; the
    # report shows every occurrence for manual graph comparison.
    decision_call = re.compile(
        r"\.\s*(process|handleInput|decide|evaluate|execute|authorize|route|resolve|dispatch|classify|plan|select)\s*\("
    )
    approved_central = {
        "lib/core/turn/nova_core_turn_controller.dart",
        "lib/core/ai/nova_ai_service.dart",
        "lib/services/runtime/nova_single_brain_authority_service.dart",
        "lib/services/api/api_service.dart",
        "lib/services/actions/nova_device_action_executor_service.dart",
    }
    for path, text in texts.items():
        if not path.startswith("lib/") or path in approved_central:
            continue
        for line, evidence, match in snippets(text, decision_call):
            findings.append(
                Finding(
                    "info",
                    "INV001_DECISION_CALLSITE",
                    path,
                    line,
                    f"Decision-like call .{match.group(1)}() requires graph review.",
                    evidence,
                    "inventory",
                )
            )

    # Background triggers are inventoried because they can start independent turns.
    for item in files:
        if any(trigger in item.triggers for trigger in ("timer", "receiver", "foreground_service", "background_service")):
            findings.append(
                Finding(
                    "info",
                    "INV002_ASYNC_TRIGGER_SURFACE",
                    item.path,
                    1,
                    f"Async trigger surface: {', '.join(item.triggers)}",
                    ", ".join(item.decision_symbols[:8]),
                    "inventory",
                )
            )

    # Duplicate class names can indicate parallel implementations.
    class_paths: dict[str, list[str]] = defaultdict(list)
    for item in files:
        for class_name in item.classes:
            class_paths[class_name].append(item.path)
    for class_name, paths in sorted(class_paths.items()):
        if len(paths) <= 1:
            continue
        findings.append(
            Finding(
                "warning",
                "DG007_DUPLICATE_CLASS_NAME",
                paths[0],
                1,
                f"Class/object {class_name} is defined in multiple files: {paths}",
                class_name,
                "decision_root" if DECISION_NAME.search(class_name) else "structure",
            )
        )

    return findings


def build_import_graph(files: list[SourceFile]) -> dict[str, list[str]]:
    all_paths = {item.path for item in files}
    graph: dict[str, list[str]] = {}
    for item in files:
        edges: list[str] = []
        source_path = Path(item.path)
        for imported in item.imports:
            if imported.startswith("dart:") or "://" in imported or imported.startswith("package:"):
                continue
            candidate = (ROOT / source_path.parent / imported).resolve()
            try:
                target = candidate.relative_to(ROOT).as_posix()
            except ValueError:
                continue
            if target in all_paths:
                edges.append(target)
        graph[item.path] = unique(edges)
    return graph


def active_dart_graph(
    files: list[SourceFile],
    texts: dict[str, str],
    graph: dict[str, list[str]],
) -> set[str]:
    roots = ["lib/main.dart"] if "lib/main.dart" in graph else []
    for path, text in texts.items():
        if not path.endswith(".dart") or path == "lib/main.dart":
            continue
        if "@pragma('vm:entry-point')" in text or '@pragma("vm:entry-point")' in text:
            roots.append(path)
    active: set[str] = set()
    stack = roots[:]
    while stack:
        path = stack.pop()
        if path in active:
            continue
        active.add(path)
        stack.extend(graph.get(path, ()))
    return active


def downgrade_dormant_dart_findings(
    findings: list[Finding], active_paths: set[str]
) -> None:
    for finding in findings:
        if (
            finding.severity == "error"
            and finding.path.startswith("lib/")
            and finding.path.endswith(".dart")
            and finding.path not in active_paths
        ):
            finding.severity = "warning"
            finding.category = f"dormant_{finding.category}"
            finding.message = (
                "Dormant import-graph quarantine: " + finding.message
            )


def decision_inventory(files: list[SourceFile]) -> list[dict[str, object]]:
    result: list[dict[str, object]] = []
    for item in files:
        if item.decision_symbols or item.authority_keys or item.triggers:
            result.append(
                {
                    "path": item.path,
                    "category": classify(item.path),
                    "decision_symbols": item.decision_symbols,
                    "authority_keys": item.authority_keys,
                    "triggers": item.triggers,
                }
            )
    return result


def markdown_report(report: dict[str, object]) -> str:
    summary = report["summary"]
    findings: list[dict[str, object]] = report["findings"]  # type: ignore[assignment]
    lines = [
        "# NOVA Exhaustive Decision Graph Audit",
        "",
        f"- Commit: `{report['commit_sha']}`",
        f"- Source/config files scanned: **{summary['files_scanned']}**",
        f"- Lines scanned: **{summary['lines_scanned']}**",
        f"- Decision/authority/trigger surfaces: **{summary['decision_surfaces']}**",
        f"- Errors: **{summary['errors']}**",
        f"- Warnings: **{summary['warnings']}**",
        f"- Informational call sites: **{summary['infos']}**",
        "",
        "## Architecture verdict",
        "",
        "**PASS**" if summary["errors"] == 0 else "**FAIL — independent or forgeable decision paths remain.**",
        "",
        "## Error and warning findings",
        "",
        "| Severity | Rule | File:line | Category | Evidence |",
        "|---|---|---|---|---|",
    ]
    for item in findings:
        if item["severity"] == "info":
            continue
        evidence = str(item["evidence"]).replace("|", "\\|").replace("\n", " ")
        message = str(item["message"]).replace("|", "\\|")
        lines.append(
            f"| {item['severity']} | {item['rule']} | `{item['path']}:{item['line']}` | {item['category']} | {message}<br><code>{evidence}</code> |"
        )
    lines.extend(["", "## Inventory counts", ""])
    for key, value in sorted(report["file_categories"].items()):  # type: ignore[union-attr]
        lines.append(f"- `{key}`: {value}")
    lines.extend(["", "## Decision surface inventory", ""])
    for item in report["decision_inventory"]:  # type: ignore[assignment]
        symbols = ", ".join(item["decision_symbols"][:12])
        keys = ", ".join(item["authority_keys"])
        triggers = ", ".join(item["triggers"])
        lines.append(
            f"- `{item['path']}` — symbols: {symbols or '-'}; authority: {keys or '-'}; triggers: {triggers or '-'}"
        )
    lines.extend(["", "## Informational decision call sites", ""])
    for item in findings:
        if item["severity"] != "info":
            continue
        lines.append(
            f"- `{item['path']}:{item['line']}` {item['message']} — `{str(item['evidence']).replace('`', '')}`"
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", default="build/nova-decision-audit")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    files, texts = inventory()
    import_graph = build_import_graph(files)
    active_paths = active_dart_graph(files, texts, import_graph)
    findings = build_findings(files, texts)
    downgrade_dormant_dart_findings(findings, active_paths)
    findings.sort(key=lambda item: (item.severity != "error", item.severity != "warning", item.rule, item.path, item.line))
    errors = sum(item.severity == "error" for item in findings)
    warnings = sum(item.severity == "warning" for item in findings)
    infos = sum(item.severity == "info" for item in findings)
    inventory_items = decision_inventory(files)
    commit_sha = os.getenv("GITHUB_SHA", "").strip()
    if not commit_sha:
        try:
            import subprocess

            commit_sha = subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
            ).strip()
        except Exception:
            commit_sha = "unknown"

    category_counts = Counter(classify(item.path) for item in files)
    suffix_counts = Counter(item.suffix for item in files)
    report = {
        "schema": 1,
        "commit_sha": commit_sha,
        "summary": {
            "files_scanned": len(files),
            "lines_scanned": sum(item.lines for item in files),
            "bytes_scanned": sum(item.bytes for item in files),
            "decision_surfaces": len(inventory_items),
            "errors": errors,
            "warnings": warnings,
            "infos": infos,
            "strict_passed": errors == 0,
            "active_dart_files": len(active_paths),
            "dormant_dart_files": sum(
                item.path.endswith(".dart") and item.path not in active_paths
                for item in files
            ),
        },
        "file_categories": dict(sorted(category_counts.items())),
        "suffix_counts": dict(sorted(suffix_counts.items())),
        "files": [asdict(item) for item in files],
        "import_graph": import_graph,
        "active_dart_graph": sorted(active_paths),
        "decision_inventory": inventory_items,
        "findings": [asdict(item) for item in findings],
    }

    output_dir = ROOT / args.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "NOVA_DECISION_GRAPH_AUDIT.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (output_dir / "NOVA_DECISION_GRAPH_AUDIT.md").write_text(
        markdown_report(report), encoding="utf-8"
    )
    (output_dir / "NOVA_SOURCE_FILE_MANIFEST.json").write_text(
        json.dumps([asdict(item) for item in files], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(
        json.dumps(
            {
                "files_scanned": len(files),
                "lines_scanned": sum(item.lines for item in files),
                "decision_surfaces": len(inventory_items),
                "errors": errors,
                "warnings": warnings,
                "infos": infos,
            },
            indent=2,
        )
    )
    return 1 if args.strict and errors else 0


if __name__ == "__main__":
    sys.exit(main())
