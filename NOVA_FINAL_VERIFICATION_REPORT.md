# NOVA API-FIRST FINAL VERIFICATION REPORT

Date: 2026-05-21
Package scope: `lib/` + `android/` replacement package.

## 1. Final operating model

This package is API-first for the Nova brain while keeping the local phone-side audio/control layers:

- Brain / answer generation: Gemini or OpenAI API.
- Wake / listening / ASR: local Sherpa/streaming ASR path is preserved.
- Voice ID / speaker verification: local Nemo/TitaNet speaker embedding path is preserved.
- Freshness and stale-response protection: local `NovaFreshnessController` + `NovaSingleBrainAuthorityService`.
- Final speech authority: TTS only speaks text bound to an authoritative SingleBrain/API-native proof.
- Call and media control: Android phone/control bridges and manifest services are preserved.
- FAISS/native semantic bridge: restored and guarded.
- Legacy Gemma/LiteRT local LLM generation: disabled/stubbed.
- Old security shield / kill / quarantine / decommission services: passive and not registered in manifest.

## 2. Readiness work-package coverage

Readiness package comparison:

- WP-001 cache cleanup: cache/env files are not part of this replacement package.
- WP-002 provider/settings/API permission: completed. INTERNET and ACCESS_NETWORK_STATE kept because API brain requires network.
- WP-003 API router: completed using dart:io HttpClient, no new pubspec dependency required.
- WP-004 AI request/response proof contract: completed. API proof is accepted as authoritative brain proof.
- WP-005 SingleBrain + freshness: completed. Static/fallback/proofless speech is blocked before TTS.
- WP-006 local model compatibility stub: completed. Local Gemma/LiteRT generation is disabled without breaking old callers.
- WP-007 native detachment: updated by user requirement. Local LLM is detached, but Sherpa ASR, Nemo/TitaNet Voice ID, and FAISS are preserved.

## 3. API provider verification

Gemini:

- Default free/dÃ¼ÅŸÃ¼k maliyet model: `gemini-3.1-flash-lite`.
- Balanced stable preset: `gemini-3.5-flash`.
- Compatibility presets: `gemini-2.5-flash`, `gemini-2.5-flash-lite`.
- Live preview preset: `gemini-3.1-flash-live-preview`.
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`.
- API key is sent via query parameter and header for compatibility.

OpenAI:

- Low-cost model preset: `gpt-5.4-mini`.
- Strong model preset: `gpt-5.5`.
- Endpoint: `https://api.openai.com/v1/responses`.

Token storage:

- No new `flutter_secure_storage` dependency is required.
- Token abstraction uses existing SharedPreferences-compatible project dependency.
- Raw API key is not required inside hardcoded source.

## 4. Local ASR / wake / voice identity verification

Sherpa ASR remains local and is not replaced by API ASR.

Included in this package:

- `android/app/libs/sherpa-onnx.aar`
- `android/app/src/main/assets/sherpa_asr/config.json`
- `android/app/src/main/assets/sherpa_asr/tokens.txt`
- `android/app/src/main/assets/sherpa_asr/README.txt`

Required large model files NOT included because they were not uploaded:

- `android/app/src/main/assets/sherpa_asr/encoder.onnx`
- `android/app/src/main/assets/sherpa_asr/decoder.onnx`

Voice ID / speaker verification remains local.

Required large model file NOT included because it was not uploaded:

- `android/app/src/main/assets/speaker_id/nemo_en_titanet_small.onnx`
  OR
- `android/app/src/main/assets/speaker_id/nemo_titanet_small/nemo_en_titanet_small.onnx`

The locator also checks compatibility paths under `nova_asr/`, `models/asr/`, `models/speaker_id/`, `models/voice_id/`, and `voice_id/`.

## 5. Single brain / TTS gate verification

Final rule:

- API transcript alone does not authorize a command.
- API response alone does not directly speak.
- TTS only speaks if the response has authoritative brain proof, text-bound proof, freshness proof, and `tts_source=brain_decision_ai_output`.
- Static setup/dashboard/fallback text is blocked unless rerouted through SingleBrain/API authority.
- Call mode high-risk command checks require fresh voice authorization, not just transcript.

The call trusted speaker reuse window was tightened to 20 seconds.

## 6. Call system verification

Manifest keeps the call-critical components:

- `NovaCompanionConnectionService`
- `NovaInCallService`
- `NovaCallScreeningService`
- `NovaCallActionReceiver`
- `NovaReminderBootReceiver`
- phone/call/contacts launch activities

Call companion generation uses API-only brain requests and passes the result through authority proof before TTS.

## 7. Media control verification

Media command bridge remains intact:

- `media_next`
- `media_previous`
- `media_pause`
- `media_resume`
- `media_play_pause`
- volume up/down/mute
- open package
- call/speaker commands

The native bridge uses Android key events/audio manager and was not removed.

## 8. FAISS/native bridge verification

FAISS is preserved. The previous over-detach risk was corrected.

Final state:

- `nova-lib` remains loaded.
- `CMakeLists.txt` keeps FAISS/native bridge build.
- `NOVA_HAS_REAL_FAISS` macro checks use `#if` / `#if !` instead of incorrect `#ifdef` behavior.
- Kotlin FAISS method channel is wrapped with safe runtime guards so missing native symbols do not crash Nova.

## 9. Security shield verification

Old shield services/classes are passive:

- Kill switch returns passive success.
- Decommission/internet/night-watch/security services stop immediately if started.
- Security boot receiver no-ops.
- Manifest does not register those old security shield services.
- API/network access is not blocked by the old security layer.

## 10. Build verification limitation

This environment does not contain Dart/Flutter CLI. Gradle wrapper attempted to download Gradle but external network is unavailable here. Therefore APK build was not completed inside this sandbox.

Local build order on your machine:

```bash
flutter clean
flutter pub get
flutter analyze
flutter build apk --debug
```

Before running the build, copy the missing large model files listed in section 4.

## 11. Final replacement instruction

You can replace the project `lib/` and `android/` folders with the package contents.

Do not forget after replacement:

1. Copy your corpus/icon/app asset folders as you already planned.
2. Copy `encoder.onnx` and `decoder.onnx` into `android/app/src/main/assets/sherpa_asr/`.
3. Copy `nemo_en_titanet_small.onnx` into `android/app/src/main/assets/speaker_id/`.
4. Keep `android/app/libs/sherpa-onnx.aar` in place.
5. Gemini/OpenAI key must be entered from settings/runtime; it is not hardcoded.
