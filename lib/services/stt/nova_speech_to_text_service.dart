// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
import 'dart:async';

import '../../core/audio_runtime/audio_capture_request.dart';
import '../../core/audio_runtime/nova_listening_mode.dart';
import '../../core/audio_runtime/nova_stt_result.dart';
import '../asr/nova_streaming_asr_runtime_service.dart';
import '../audio_runtime/nova_audio_input_policy_service.dart';
import '../audio_runtime/nova_native_audio_bridge_service.dart';
import '../audio_runtime/nova_playback_echo_filter_service.dart';
import '../runtime/nova_identity_runtime_service.dart';

enum NovaSttMode { light, enhanced }

class NovaSpeechToTextService {
  final NovaNativeAudioBridgeService nativeBridge;
  final NovaStreamingAsrRuntimeService streamingAsrRuntimeService;
  final NovaAudioInputPolicyService audioInputPolicyService;
  final NovaPlaybackEchoFilterService playbackGuardService;
  final NovaIdentityRuntimeService identityRuntimeService =
      const NovaIdentityRuntimeService();

  NovaSpeechToTextService({
    required this.nativeBridge,
    NovaStreamingAsrRuntimeService? streamingAsrRuntimeService,
    NovaAudioInputPolicyService? audioInputPolicyService,
    NovaPlaybackEchoFilterService? playbackGuardService,
  }) : streamingAsrRuntimeService =
           streamingAsrRuntimeService ?? NovaStreamingAsrRuntimeService(),
       audioInputPolicyService =
           audioInputPolicyService ??
           NovaAudioInputPolicyService(nativeBridge: nativeBridge),
       playbackGuardService =
           playbackGuardService ??
           const NovaPlaybackEchoFilterService();

  Future<NovaSttResult> transcribe({
    NovaSttMode mode = NovaSttMode.light,
    String targetDescription = '',
    bool useCallCompanionAudioPolicy = false,
    bool preferExtendedConversationWindow = false,
    bool rejectSyntheticPlayback = true,
    bool keepPassiveSessionOpen = false,
  }) async {
    if (rejectSyntheticPlayback) {
      final released = await playbackGuardService.waitUntilPlaybackInactive(
        timeout: const Duration(milliseconds: 2200),
      );
      if (!released) {
        await playbackGuardService.registerEchoAttempt();
        return NovaSttResult(
          success: false,
          recognizedText: '',
          detectedLocale: 'tr-TR',
          message:
              '${identityRuntimeService.currentDisplayName} kendi konuşmasını yeniden duymamak için kısa bir an bekliyor.',
        );
      }
    }

    if (useCallCompanionAudioPolicy) {
      await audioInputPolicyService.prepareCallCompanionListening();
    } else if (!keepPassiveSessionOpen) {
      await audioInputPolicyService.preparePassiveListening();
    }

    try {
      final resolvedTargetDescription = targetDescription.trim().isEmpty
          ? '${identityRuntimeService.currentDisplayName} günlük komutu'
          : identityRuntimeService.replaceAssistantLabel(targetDescription);

      final primary = await _transcribeInternal(
        mode: mode,
        targetDescription: resolvedTargetDescription,
        preferExtendedConversationWindow: preferExtendedConversationWindow,
      );

      if (primary.success && primary.recognizedText.trim().length >= 2) {
        final ownSpeech = await playbackGuardService.isLikelyOwnSpeech(
          primary.recognizedText,
        );
        if (!ownSpeech) {
          return primary;
        }
        if (rejectSyntheticPlayback) {
          return NovaSttResult(
            success: false,
            recognizedText: '',
            detectedLocale: 'tr-TR',
            message:
                '${identityRuntimeService.currentDisplayName} kendi son konuşmasını komut sanmadı; dinlemeye devam ediyor.',
          );
        }
      }

      return primary;
    } finally {
      if (useCallCompanionAudioPolicy) {
        await audioInputPolicyService.finishCallCompanionListening();
      } else if (!keepPassiveSessionOpen) {
        await audioInputPolicyService.finishPassiveListening();
      }
    }
  }

  Future<NovaSttResult> _transcribeInternal({
    required NovaSttMode mode,
    required String targetDescription,
    required bool preferExtendedConversationWindow,
  }) async {
    final waitSeconds = switch (mode) {
      NovaSttMode.light => preferExtendedConversationWindow ? 18 : 12,
      NovaSttMode.enhanced => preferExtendedConversationWindow ? 26 : 18,
    };

    await streamingAsrRuntimeService.ensureInitialized();
    if (!streamingAsrRuntimeService.isStarted) {
      final started = await streamingAsrRuntimeService.start();
      if (!started) {
        return nativeBridge.decodeStreamingSnapshot(
          AudioCaptureRequest(
            mode: NovaListeningMode.normalCommandListening,
            maxDurationSeconds: waitSeconds.clamp(6, 18).toInt(),
            targetDescription: targetDescription,
          ),
        );
      }
    }

    final completer = Completer<NovaSttResult>();
    StreamSubscription? sub;
    Timer? timer;

    Future<void> finish(NovaSttResult result) async {
      if (completer.isCompleted) return;
      timer?.cancel();
      await sub?.cancel();
      completer.complete(result);
    }

    sub = streamingAsrRuntimeService.events.listen((event) async {
      final text = event.transcript.text.trim();
      if (text.isEmpty) return;
      if (event.isFinal ||
          (mode == NovaSttMode.enhanced &&
              event.isPartial &&
              text.length >= 12)) {
        await finish(
          NovaSttResult(
            success: true,
            recognizedText: text,
            detectedLocale: event.transcript.detectedLocale.trim().isEmpty
                ? 'tr-TR'
                : event.transcript.detectedLocale.trim(),
            message: 'Streaming Sherpa transcript alındı: $targetDescription',
          ),
        );
      }
    });

    timer = Timer(Duration(seconds: waitSeconds), () async {
      try {
        // Event akışı gelmezse snapshot sadece playback kesin pasifse denenir.
        // Bu fallback, Nova'nın kendi TTS sesini veya eski ring-buffer kalıntısını
        // kullanıcı komutu sanmamak için güvenli kapıdan geçmek zorunda.
        final playbackReleased = await playbackGuardService.waitUntilPlaybackInactive(
          timeout: const Duration(milliseconds: 350),
        );
        if (!playbackReleased) {
          await playbackGuardService.registerEchoAttempt();
          await finish(
            NovaSttResult(
              success: false,
              recognizedText: '',
              detectedLocale: 'tr-TR',
              message:
                  '${identityRuntimeService.currentDisplayName} snapshot ASR denemesini playback echo riski nedeniyle engelledi.',
            ),
          );
          return;
        }
        final snapshot = await nativeBridge.decodeStreamingSnapshot(
          AudioCaptureRequest(
            mode: NovaListeningMode.normalCommandListening,
            maxDurationSeconds: waitSeconds.clamp(4, 10).toInt(),
            targetDescription: targetDescription,
          ),
        );
        if (snapshot.success && snapshot.recognizedText.trim().length >= 2) {
          await finish(snapshot);
          return;
        }
        await finish(
          NovaSttResult(
            success: false,
            recognizedText: '',
            detectedLocale: 'tr-TR',
            message:
                '${identityRuntimeService.currentDisplayName} streaming ASR zincirinden taze konuşma alamadı. Snapshot fallback: ${snapshot.message}',
          ),
        );
      } catch (error) {
        await finish(
          NovaSttResult(
            success: false,
            recognizedText: '',
            detectedLocale: 'tr-TR',
            message:
                '${identityRuntimeService.currentDisplayName} streaming ASR snapshot fallback sırasında hata aldı: $error',
          ),
        );
      }
    });

    return completer.future;
  }
}
