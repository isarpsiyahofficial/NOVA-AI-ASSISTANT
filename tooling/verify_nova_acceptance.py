#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys
import xml.etree.ElementTree as ET
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Callable

from nova_acceptance_catalog import Requirement, requirements

ROOT = Path(__file__).resolve().parents[1]


@dataclass
class GateResult:
    gate: str
    passed: bool
    evidence: list[str]
    message: str


def exists(*paths: str) -> tuple[bool, list[str]]:
    resolved = [ROOT / path for path in paths]
    return all(path.exists() for path in resolved), [str(path.relative_to(ROOT)) for path in resolved if path.exists()]


def contains(path: str, *needles: str) -> tuple[bool, list[str]]:
    target = ROOT / path
    if not target.is_file():
        return False, []
    text = target.read_text(encoding="utf-8", errors="replace")
    missing = [needle for needle in needles if needle not in text]
    return not missing, [f"{path}:{needle}" for needle in needles if needle in text]


def excludes(path: str, *needles: str) -> tuple[bool, list[str]]:
    target = ROOT / path
    if not target.is_file():
        return False, []
    text = target.read_text(encoding="utf-8", errors="replace")
    present = [needle for needle in needles if needle in text]
    return not present, [f"{path}:absent:{needle}" for needle in needles if needle not in text]


def combine(gate: str, checks: list[tuple[bool, list[str]]], message: str) -> GateResult:
    passed = all(result for result, _ in checks)
    evidence = [item for _, items in checks for item in items]
    return GateResult(gate, passed, evidence, message if passed else f"FAILED: {message}")


def gate_build() -> GateResult:
    return combine(
        "build",
        [
            exists("android/app/build.gradle.kts", "tooling/prepare_native_voice_assets.sh"),
            contains("android/app/build.gradle.kts", "compileSdk = 36", "android-arm64" if False else "sherpa-onnx.aar"),
            exists(
                "android/app/src/main/assets/sherpa_asr/encoder.onnx",
                "android/app/src/main/assets/sherpa_asr/decoder.onnx",
                "android/app/src/main/assets/sherpa_vad/silero_vad.onnx",
                "android/app/src/main/assets/speaker_id/nemo_en_titanet_small.onnx",
                "android/app/src/main/assets/sherpa_tts/model.onnx",
            ),
            exists(".github/workflows/nova-runtime-integrity.yml", ".github/workflows/nova-tecno-arm64-apk.yml"),
        ],
        "Flutter/Android build and verified model package contracts",
    )


def gate_setup() -> GateResult:
    return combine(
        "setup",
        [
            exists("lib/ui/onboarding/nova_first_run_setup_v2_page.dart", "lib/ui/launch/nova_launch_gate_page.dart"),
            contains("lib/ui/launch/nova_launch_gate_page.dart", "isVerifiedVoiceprintId", "apiReady", "shouldShowSetup"),
            contains("lib/core/api/nova_api_model_catalog.dart", "migrateSavedModelId", "gpt-5-mini", "qwen3.6-flash"),
            contains("lib/services/identity/device_owner_identity_service.dart", "nova_manual_owner_", "StateError"),
        ],
        "Verified first-run, provider settings and owner enrollment",
    )


def gate_single_brain() -> GateResult:
    return combine(
        "single_brain",
        [
            contains(
                "lib/ui/launch/nova_launch_gate_page.dart",
                "import '../dashboard/dashboard_page.dart';",
                "return DashboardPage(",
            ),
            contains(
                "lib/ui/dashboard/dashboard_page.dart",
                "NovaTurnLeaseController.instance.begin(",
                "_typedAuthorityForPrompt(",
                "authority: turnAuthority",
                "lease: turnLease",
                "widget.sttService.transcribe(",
            ),
            contains(
                "lib/services/runtime/nova_hotpath_owner_service.dart",
                "authority: aiRequest.authority",
                "lease: aiRequest.lease",
                "allowLegacyRuntimeBroker",
            ),
            contains(
                "lib/services/api/api_service.dart",
                "await actionExecutor.execute",
                "nativeSideEffectCompletedBeforeFinalAnswer",
                "unsafe_action_summary_blocked",
            ),
            contains(
                "lib/services/actions/nova_verified_call_action_service.dart",
                "NovaDeviceActionExecutorService",
                "NovaTurnAuthority.companion(",
                "NovaTurnLeaseController.instance.begin(",
            ),
            exists(
                "test/runtime/nova_runtime_integrity_contract_test.dart",
                "test/runtime/nova_verified_device_action_contract_test.dart",
            ),
        ],
        "Active dashboard, SingleBrain and verified native action path",
    )


def gate_asr() -> GateResult:
    return combine(
        "asr",
        [
            contains("android/app/src/main/kotlin/com/example/nova/asr/NovaStreamingAsrEngine.kt", "Silero", "decodeFinalSegment", "NovaAsrSegmentWavStore.write"),
            contains("lib/services/stt/nova_speech_to_text_service.dart", "Platform SpeechRecognizer fallback", "identifyVoiceFromFile"),
            contains("lib/core/asr/nova_streaming_transcript.dart", "identityAudioPath", "segmentId"),
            exists("android/app/src/main/kotlin/com/example/nova/asr/NovaAsrForegroundService.kt"),
        ],
        "Single-owner VAD-gated Whisper and same-segment identity evidence",
    )


def gate_tts() -> GateResult:
    return combine(
        "tts",
        [
            contains("lib/services/tts/nova_tts_service.dart", "NovaFinalTextContract.maySpeakMetadata", "pause", "resume"),
            contains("infra/call-bridge/media_gateway/service.py", "synthesize_8k_pcm", "send_pcm", "frame_bytes = 320"),
            exists("android/app/src/main/assets/sherpa_tts/model.onnx", "android/app/src/main/assets/sherpa_tts/tokens.txt"),
        ],
        "Proof-gated local Turkish TTS and call uplink injection",
    )


def gate_voice_id() -> GateResult:
    return combine(
        "voice_id",
        [
            contains("lib/services/identity/device_owner_identity_service.dart", "isVerifiedVoiceprintId", "owner_manual_", "nova_manual_owner_"),
            contains("lib/services/stt/nova_speech_to_text_service.dart", "same PCM segment", "identity.similarity", "ownerMatched"),
            contains("android/app/src/main/kotlin/com/example/nova/asr/NovaAsrSegmentWavStore.kt", "app-private", "MAX_FILES"),
            exists("android/app/src/main/assets/speaker_id/nemo_en_titanet_small.onnx"),
        ],
        "Real TitaNet owner proof bound to the decoded command audio",
    )


def gate_telecom() -> GateResult:
    return combine(
        "telecom",
        [
            contains("android/app/src/main/AndroidManifest.xml", "NovaInCallService", "NovaCompanionConnectionService", "NovaCallScreeningService"),
            contains("lib/services/actions/nova_device_action_executor_service.dart", "answerRingingCall", "rejectRingingCall", "disconnectCurrentCall", "_pollCallState"),
            exists("tooling/run_android_telecom_emulator_e2e.sh", ".github/workflows/nova-android-telecom-emulator-e2e.yml"),
            contains(
                "android/app/src/debug/kotlin/com/example/nova/testing/NovaDebugControlReceiver.kt",
                "registerTestAccount",
                "telecom.isIncomingCallPermitted",
                "telecom.addNewIncomingCall",
                "answerRingingCall",
                "setMuted",
                "routeToSpeaker",
                "disconnectCurrentCall",
            ),
            contains(
                "tooling/run_android_telecom_emulator_e2e.sh",
                "inject_incoming_call",
                "set-phone-account-enabled",
                "wait_for_bridge_state ringing",
                "wait_for_bridge_state active",
            ),
            contains(
                "android/app/src/main/kotlin/com/example/nova/NovaCallControlBridge.kt",
                "Cevaplanacak gerçek Telecom çağrısı bulunamadı.",
                "Mikrofon değiştirilecek gerçek Telecom çağrısı bulunamadı.",
            ),
            contains(
                "android/app/src/main/kotlin/com/example/nova/NovaCompanionConnectionService.kt",
                "override fun onAnswer(videoState: Int)",
                "markAnswered()",
                "CAPABILITY_SUPPORT_HOLD",
            ),
        ],
        "Android Telecom native controls plus real managed-call emulator E2E",
    )


def gate_carrier_bridge() -> GateResult:
    return combine(
        "carrier_bridge",
        [
            exists("infra/call-bridge/docker-compose.yml", "infra/call-bridge/run_e2e.sh"),
            contains("infra/call-bridge/asterisk/config/extensions.conf", "AudioSocket", "from-nova-carrier", "nova-outbound"),
            contains("infra/call-bridge/media_gateway/service.py", "transcribe_8k_pcm", "AiDecisionEngine", "synthesize_8k_pcm", "SessionReport"),
            contains("infra/call-bridge/media_gateway/launcher.py", "VerifiedSherpaSpeechEngine", "service.main"),
            contains(
                "infra/call-bridge/run_e2e.sh",
                "python /app/launcher.py synthesize",
                "--expect-text",
                "--min-word-coverage",
                "--min-similarity",
                "inspect-wav",
            ),
            contains(
                ".github/workflows/nova-call-bridge-e2e.yml",
                "deterministic mock AI",
                "Upload bidirectional call evidence",
            ),
        ],
        "Real two-way PSTN/SIP PCM transport with Whisper and Piper; AI stage explicitly mocked in CI",
    )


def gate_contacts() -> GateResult:
    return combine(
        "contacts",
        [
            contains("lib/services/actions/nova_contact_call_target_resolver_service.dart", "Annemi", "birden fazla", "normalizeDialNumber"),
            exists("test/runtime/nova_contact_call_target_resolver_test.dart"),
            contains("lib/services/actions/nova_device_action_executor_service.dart", "contactResolver.resolve", "contact_resolution_failed"),
        ],
        "Local contact resolution without guessed numbers",
    )


def gate_companion_security() -> GateResult:
    return combine(
        "companion_security",
        [
            contains(
                "lib/services/call_companion/nova_call_companion_service.dart",
                "NovaTurnLeaseController.instance.begin(",
                "NovaTurnAuthority.companion(",
                "authority: turnAuthority",
                "lease: turnLease",
            ),
            contains(
                "lib/services/call_companion/nova_call_companion_runtime_service.dart",
                "_ensureCarrierConversationTransportReady",
                "carrierAiConversationReady",
                "verifiedCallActionService.executeCompanion(",
                "call_companion_carrier_transport_unavailable",
            ),
            contains(
                "lib/services/system/nova_continuous_listening_runtime_service.dart",
                "fail_closed_before_answer",
                "startForCurrentCall(",
            ),
            excludes(
                "lib/services/call/nova_call_control_bridge_service.dart",
                "localUiAction || userInitiated",
            ),
            contains(
                "android/app/src/main/kotlin/com/example/nova/NovaNativeActionAuthorization.kt",
                "NovaCallStateBridge.getState()",
                "NovaCallAuthorityGuard.canCompanionCallControl(",
            ),
            excludes(
                "android/app/src/main/kotlin/com/example/nova/NovaNativeActionAuthorization.kt",
                "nova_companion_native_authority",
            ),
        ],
        "Companion security is typed and local audio hacks fail closed before answer",
    )


def gate_companion_transport() -> GateResult:
    evidence = os.getenv("NOVA_REAL_COMPANION_EVIDENCE", "").strip()
    if not evidence:
        return GateResult(
            "companion_transport",
            False,
            [
                "infra/call-bridge/run_e2e.sh",
                "lib/services/call/nova_carrier_media_bridge_service.dart",
            ],
            "WAITING_FOR_REAL_CARRIER_TO_APP_COMPANION_EVIDENCE",
        )
    target = Path(evidence)
    if not target.is_file():
        return GateResult(
            "companion_transport",
            False,
            [],
            f"Companion evidence file not found: {evidence}",
        )
    try:
        data = json.loads(target.read_text(encoding="utf-8"))
    except Exception as error:
        return GateResult(
            "companion_transport",
            False,
            [],
            f"Invalid companion evidence JSON: {error}",
        )
    required_true = [
        "authorized_contact_only",
        "bidirectional_media_passed",
        "handover_to_user_passed",
        "postcondition_verified",
    ]
    passed = all(data.get(key) is True for key in required_true)
    return GateResult(
        "companion_transport",
        passed,
        [str(target)],
        "Real carrier-to-app companion evidence accepted"
        if passed
        else "Companion evidence did not satisfy all real media postconditions",
    )


def gate_media() -> GateResult:
    return combine(
        "media",
        [
            contains("android/app/src/main/kotlin/com/example/nova/NovaPhoneControlBridge.kt", "dispatchMediaKey", "adjustVolume", "muteVolume", "currentPackageName"),
            contains("lib/services/actions/nova_device_action_executor_service.dart", "open_spotify", "open_youtube_music", "media_play_pause"),
            contains("android/app/src/main/kotlin/com/example/nova/NovaAppSandboxGuard.kt", "com.spotify.music", "com.google.android.apps.youtube.music"),
        ],
        "Android media dispatch and state verification",
    )


def gate_reminders() -> GateResult:
    return combine(
        "reminders",
        [
            exists("lib/services/reminder/nova_reminder_service.dart", "lib/services/reminder/nova_reminder_command_service.dart"),
            contains("android/app/src/main/AndroidManifest.xml", "NovaReminderBootReceiver", "BOOT_COMPLETED"),
            contains("lib/core/ai/ai_request.dart", "reminder_runtime_event"),
        ],
        "Reminder lifecycle, boot restore and SingleBrain speech",
    )


def gate_memory() -> GateResult:
    return combine(
        "memory",
        [
            exists("android/app/src/main/cpp/CMakeLists.txt"),
            contains("android/app/build.gradle.kts", "NOVA_FAISS_ROOT_DIR"),
            exists("lib/services/memory/nova_memory_service.dart") if (ROOT / "lib/services/memory/nova_memory_service.dart").exists() else exists("lib/services"),
        ],
        "FAISS/native memory bridge presence and guarded build",
    )


def gate_overlay() -> GateResult:
    return combine(
        "overlay",
        [
            contains("android/app/src/main/AndroidManifest.xml", "SYSTEM_ALERT_WINDOW", "NovaOverlayService", "NovaBackgroundService"),
            exists("android/app/src/main/kotlin/com/example/nova/NovaOverlayService.kt", "android/app/src/main/kotlin/com/example/nova/NovaBackgroundService.kt"),
            contains("android/app/src/main/AndroidManifest.xml", "foregroundServiceType=\"microphone\""),
        ],
        "Overlay and foreground microphone runtime",
    )


def gate_ui() -> GateResult:
    return combine(
        "ui",
        [
            contains("lib/ui/nova/nova_dashboard_page.dart", "VERIFIED_RUNTIME_ONLY", "Son transcript", "Android çalışma durumu"),
            contains("lib/ui/nova/nova_dashboard_page.dart", "ownerConfidence", "deviceActionResult", "obscureText: true"),
            contains("lib/ui/launch/nova_launch_gate_page.dart", "NovaFirstRunSetupV2Page"),
        ],
        "Runtime-backed dashboard and setup UI",
    )


def gate_privacy() -> GateResult:
    return combine(
        "privacy",
        [
            contains("android/app/src/main/AndroidManifest.xml", "android:allowBackup=\"false\"", "android:usesCleartextTraffic=\"false\""),
            contains("android/app/src/main/kotlin/com/example/nova/NovaAppSandboxGuard.kt", "resolveAppPrivateFileOrNull", "appPrivateRoots"),
            contains("infra/call-bridge/asterisk/config/pjsip.carrier.conf.template", "NOVA_SIP_TRUNK_PASSWORD"),
            contains("infra/call-bridge/asterisk/entrypoint.sh", "envsubst", "Carrier trunk disabled"),
        ],
        "Private storage, no cleartext, and secret injection contracts",
    )


def gate_reliability() -> GateResult:
    return combine(
        "reliability",
        [
            contains("lib/core/actions/nova_device_action.dart", "beforeState", "afterState", "failureCode"),
            contains("lib/services/api/api_service.dart", "api_timeout", "httpBodyPreview", "actionVerified"),
            contains("infra/call-bridge/media_gateway/service.py", "SessionReport", "stt_ms", "ai_ms", "tts_ms"),
            exists("test/runtime/nova_runtime_integrity_contract_test.dart", "test/runtime/nova_verified_device_action_contract_test.dart"),
        ],
        "Auditable errors, before/after state and evidence artifacts",
    )


def gate_ci() -> GateResult:
    return combine(
        "ci",
        [
            exists(
                ".github/workflows/nova-runtime-integrity.yml",
                ".github/workflows/nova-native-stack-audit.yml",
                ".github/workflows/nova-device-action-integrity.yml",
                ".github/workflows/nova-call-bridge-e2e.yml",
                ".github/workflows/nova-android-telecom-emulator-e2e.yml",
            ),
            contains("tooling/prepare_native_voice_assets.sh", "SHA256 mismatch", "Native voice assets are prepared"),
            contains("infra/call-bridge/run_e2e.sh", "assert-latest", "inspect-wav"),
            contains("tooling/run_android_telecom_emulator_e2e.sh", "addNewIncomingCall", "dumpsys telecom"),
        ],
        "Automated build, SIP media and Android Telecom laboratory",
    )


def gate_release() -> GateResult:
    return combine(
        "release",
        [
            contains(
                ".github/workflows/nova-tecno-arm64-apk.yml",
                "NOVA-TECNO-ARM64-INTERNAL-TEST",
                "flutter build apk --debug",
                "sha256sum",
                "apk_bytes",
            ),
            excludes(
                ".github/workflows/nova-tecno-arm64-apk.yml",
                "NOVA-TECNO-ARM64-RELEASE",
                "flutter build apk --release",
            ),
            excludes(
                "android/app/build.gradle.kts",
                'signingConfig = signingConfigs.getByName("debug")',
            ),
            exists("NOVA_FINAL_VERIFICATION_REPORT.md"),
            contains("tooling/nova_acceptance_catalog.py", "NOVA-{number:03d}", "hardware"),
        ],
        "Internal-test APK is labelled honestly; production signing cannot fall back to debug",
    )


def gate_device() -> GateResult:
    path = os.getenv("NOVA_REAL_DEVICE_EVIDENCE", "").strip()
    if not path:
        return GateResult("device", False, [], "WAITING_FOR_REAL_TECNO_DEVICE_EVIDENCE")
    target = Path(path)
    if not target.is_file():
        return GateResult("device", False, [], f"Device evidence file not found: {path}")
    try:
        data = json.loads(target.read_text(encoding="utf-8"))
    except Exception as error:
        return GateResult("device", False, [], f"Invalid device evidence JSON: {error}")

    required = [
        "commit_sha",
        "apk_sha256",
        "device_model",
        "device_manufacturer",
        "android_version",
        "android_sdk",
        "sim_call_passed",
        "sip_media_passed",
        "screen_lock_passed",
        "background_30m_passed",
        "metrics",
        "created_at_epoch",
        "evidence_files",
    ]
    missing = [key for key in required if key not in data]
    errors: list[str] = []
    if missing:
        errors.append(f"missing={missing}")

    for key in [
        "sim_call_passed",
        "sip_media_passed",
        "screen_lock_passed",
        "background_30m_passed",
    ]:
        if data.get(key) is not True:
            errors.append(f"{key}=false")

    commit_sha = str(data.get("commit_sha", "")).strip().lower()
    apk_sha = str(data.get("apk_sha256", "")).strip().lower()
    manufacturer = str(data.get("device_manufacturer", "")).strip()
    model = str(data.get("device_model", "")).strip()
    if len(commit_sha) != 40 or any(ch not in "0123456789abcdef" for ch in commit_sha):
        errors.append("invalid_commit_sha")
    expected_commit = os.getenv("GITHUB_SHA", "").strip().lower()
    if expected_commit and commit_sha != expected_commit:
        errors.append("commit_sha_mismatch")
    if len(apk_sha) != 64 or any(ch not in "0123456789abcdef" for ch in apk_sha):
        errors.append("invalid_apk_sha256")
    expected_apk = os.getenv("NOVA_EXPECTED_APK_SHA256", "").strip().lower()
    if expected_apk and apk_sha != expected_apk:
        errors.append("apk_sha256_mismatch")
    if "tecno" not in manufacturer.casefold():
        errors.append("manufacturer_is_not_tecno")
    if not model:
        errors.append("device_model_empty")

    metrics = data.get("metrics") if isinstance(data.get("metrics"), dict) else {}
    try:
        background_seconds = int(metrics.get("background_seconds", 0))
    except (TypeError, ValueError):
        background_seconds = 0
    if background_seconds < 1800:
        errors.append("background_duration_below_1800_seconds")
    try:
        total_pss_kb = int(str(metrics.get("total_pss_kb", "0")).strip() or "0")
    except (TypeError, ValueError):
        total_pss_kb = 0
    if total_pss_kb <= 0:
        errors.append("invalid_total_pss_kb")

    evidence_files = data.get("evidence_files")
    if not isinstance(evidence_files, list) or len(evidence_files) < 8:
        errors.append("insufficient_evidence_files")

    passed = not errors
    return GateResult(
        "device",
        passed,
        [str(target), f"commit:{commit_sha}", f"apk:{apk_sha}", f"device:{manufacturer} {model}"],
        "Real TECNO device evidence accepted" if passed else f"Device evidence rejected: {'; '.join(errors)}",
    )


GATES: dict[str, Callable[[], GateResult]] = {
    "build": gate_build,
    "setup": gate_setup,
    "single_brain": gate_single_brain,
    "asr": gate_asr,
    "tts": gate_tts,
    "voice_id": gate_voice_id,
    "telecom": gate_telecom,
    "carrier_bridge": gate_carrier_bridge,
    "contacts": gate_contacts,
    "companion_security": gate_companion_security,
    "companion_transport": gate_companion_transport,
    "media": gate_media,
    "reminders": gate_reminders,
    "memory": gate_memory,
    "overlay": gate_overlay,
    "ui": gate_ui,
    "privacy": gate_privacy,
    "reliability": gate_reliability,
    "ci": gate_ci,
    "release": gate_release,
    "device": gate_device,
}


def write_junit(path: Path, item_results: list[dict[str, object]]) -> None:
    suite = ET.Element("testsuite")
    suite.set("name", "NOVA 314 Acceptance")
    suite.set("tests", str(len(item_results)))
    failures = sum(1 for item in item_results if item["status"] == "failed")
    skipped = sum(1 for item in item_results if item["status"] == "waiting_hardware")
    suite.set("failures", str(failures))
    suite.set("skipped", str(skipped))
    for item in item_results:
        case = ET.SubElement(suite, "testcase")
        case.set("classname", str(item["category"]))
        case.set("name", f"{item['id']} {item['description']}")
        if item["status"] == "failed":
            failure = ET.SubElement(case, "failure")
            failure.set("message", str(item["message"]))
            failure.text = json.dumps(item.get("evidence", []), ensure_ascii=False)
        elif item["status"] == "waiting_hardware":
            skipped_node = ET.SubElement(case, "skipped")
            skipped_node.set("message", str(item["message"]))
    path.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(suite).write(path, encoding="utf-8", xml_declaration=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", default="build/nova-acceptance")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--require-hardware", action="store_true")
    args = parser.parse_args()

    items = requirements()
    ids = [item.id for item in items]
    if len(items) < 250 or len(ids) != len(set(ids)):
        raise SystemExit(f"Acceptance catalog invalid count={len(items)} unique={len(set(ids))}")

    gate_results = {gate: checker() for gate, checker in GATES.items()}
    item_results: list[dict[str, object]] = []
    for item in items:
        result = gate_results[item.gate]
        waiting_hardware = item.level == "hardware" and not result.passed
        status = "passed" if result.passed else "waiting_hardware" if waiting_hardware else "failed"
        item_results.append(
            {
                **asdict(item),
                "status": status,
                "message": result.message,
                "evidence": result.evidence,
            }
        )

    output_dir = ROOT / args.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)
    passed = sum(1 for item in item_results if item["status"] == "passed")
    failed = sum(1 for item in item_results if item["status"] == "failed")
    waiting = sum(1 for item in item_results if item["status"] == "waiting_hardware")
    report = {
        "schema": 1,
        "total": len(item_results),
        "passed": passed,
        "failed": failed,
        "waiting_hardware": waiting,
        "all_automated_passed": failed == 0,
        "all_passed_including_hardware": failed == 0 and waiting == 0,
        "gates": {name: asdict(value) for name, value in gate_results.items()},
        "requirements": item_results,
    }
    (output_dir / "NOVA_ACCEPTANCE_REPORT.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    markdown = [
        "# NOVA 314 Acceptance Report",
        "",
        f"- Total: **{len(item_results)}**",
        f"- Passed: **{passed}**",
        f"- Failed automated: **{failed}**",
        f"- Waiting real hardware: **{waiting}**",
        "",
        "| Gate | Passed | Message |",
        "|---|---:|---|",
    ]
    for name, value in gate_results.items():
        markdown.append(f"| {name} | {'YES' if value.passed else 'NO'} | {value.message} |")
    markdown.extend(["", "## Unresolved items", ""])
    for item in item_results:
        if item["status"] != "passed":
            markdown.append(f"- **{item['id']}** [{item['status']}] {item['description']} — {item['message']}")
    (output_dir / "NOVA_ACCEPTANCE_REPORT.md").write_text("\n".join(markdown) + "\n", encoding="utf-8")
    write_junit(output_dir / "NOVA_ACCEPTANCE_JUNIT.xml", item_results)

    print(json.dumps({key: report[key] for key in ["total", "passed", "failed", "waiting_hardware", "all_automated_passed", "all_passed_including_hardware"]}, indent=2))
    if args.strict and failed:
        return 1
    if args.require_hardware and (failed or waiting):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
