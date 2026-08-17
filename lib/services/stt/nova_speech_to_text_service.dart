// NOVA_STREAMING_ASR_NO_FALLBACK_V1
// NOVA_STT_SAME_SEGMENT_TITANET_AUTHORITY_V1
// ACCEPTANCE_CONTRACT: Platform SpeechRecognizer fallback is prohibited.
// ACCEPTANCE_CONTRACT: Whisper transcript and TitaNet use the same PCM segment.
import 'dart:async';

import '../../core/audio_runtime/nova_stt_result.dart';
import '../asr/nova_streaming_asr_runtime_service.dart';
import '../audio_runtime/nova_audio_input_policy_service.dart';
import '../audio_runtime/nova_native_audio_bridge_service.dart';
import '../audio_runtime/nova_playback_echo_filter_service.dart';
import '../identity/device_owner_identity_service.dart';
import '../identity/nova_voice_identity_bridge_service.dart';
import '../runtime/nova_identity_runtime_service.dart';

enum NovaSttMode { light, enhanced }

class NovaSpeechToTextService {
  final NovaNativeAudioBridgeService nativeBridge;
  final NovaStreamingAsrRuntimeService streamingAsrRuntimeService;
  final NovaAudioInputPolicyService audioInputPolicyService;
  final NovaPlaybackEchoFilterService playbackGuardService;
  final NovaVoiceIdentityBridgeService voiceIdentityBridgeService;
  final DeviceOwnerIdentityService ownerIdentityService;
  final NovaIdentityRuntimeService identityRuntimeService =
      const NovaIdentityRuntimeService();

  NovaSpeechToTextService({
    required this.nativeBridge,
    NovaStreamingAsrRuntimeService? streamingAsrRuntimeService,
    NovaAudioInputPolicyService? audioInputPolicyService,
    NovaPlaybackEchoFilterService? playbackGuardService,
    this.voiceIdentityBridgeService = const NovaVoiceIdentityBridgeService(),
    this.ownerIdentityService = const DeviceOwnerIdentityService(),
  })  : streamingAsrRuntimeService =
            streamingAsrRuntimeService ?? NovaStreamingAsrRuntimeService(),
        audioInputPolicyService = audioInputPolicyService ??
            NovaAudioInputPolicyService(nativeBridge: nativeBridge),
        playbackGuardService = playbackGuardService ??
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
        timeout: const Duration(milliseconds: 900),
      );
      if (!released) {
        await playbackGuardService.registerEchoAttempt();
        return NovaSttResult(
          success: false,
          recognizedText: '',
          detectedLocale: 'tr-TR',
          message:
              '${identityRuntimeService.currentDisplayName} kendi konuşmasını komut sanmamak için dinlemeyi kısa süreli erteledi.',
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
      final primary = await _transcribeStreamingOnly(
        mode: mode,
        targetDescription: resolvedTargetDescription,
        preferExtendedConversationWindow: preferExtendedConversationWindow,
      );

      if (primary.success && primary.recognizedText.trim().length >= 2) {
        final ownSpeech = await playbackGuardService.isLikelyOwnSpeech(
          primary.recognizedText,
        );
        if (!ownSpeech) return primary;
        if (rejectSyntheticPlayback) {
          return NovaSttResult(
            success: false,
            recognizedText: '',
            detectedLocale: 'tr-TR',
            message:
                '${identityRuntimeService.currentDisplayName} kendi son konuşmasını kullanıcı komutu olarak kabul etmedi.',
            voiceIdentityChecked: primary.voiceIdentityChecked,
            ownerMatched: false,
            speakerVoiceId: primary.speakerVoiceId,
            speakerName: primary.speakerName,
            ownerConfidence: 0,
            relationshipLabel: 'synthetic_playback',
            identityAudioPath: primary.identityAudioPath,
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

  Future<NovaSttResult> _transcribeStreamingOnly({
    required NovaSttMode mode,
    required String targetDescription,
    required bool preferExtendedConversationWindow,
  }) async {
    final waitSeconds = switch (mode) {
      NovaSttMode.light => preferExtendedConversationWindow ? 12 : 7,
      NovaSttMode.enhanced => preferExtendedConversationWindow ? 20 : 12,
    };

    final initialized = await streamingAsrRuntimeService.ensureInitialized();
    if (!initialized) {
      return const NovaSttResult(
        success: false,
        recognizedText: '',
        detectedLocale: 'tr-TR',
        message:
            'Embedded streaming ASR hazırlanamadı. Platform veya snapshot fallback kullanılmadı.',
      );
    }

    if (!streamingAsrRuntimeService.isStarted) {
      final started = await streamingAsrRuntimeService.start(
        owner: 'nova_stt_transcribe',
      );
      if (!started) {
        return const NovaSttResult(
          success: false,
          recognizedText: '',
          detectedLocale: 'tr-TR',
          message:
              'Streaming ASR oturumu başlatılamadı. Başka bir ASR sahibi varsa oturum zorla devralınmadı.',
        );
      }
    }

    final completer = Completer<NovaSttResult>();
    StreamSubscription? sub;
    Timer? timer;
    String lastPartial = '';
    DateTime? lastPartialAt;

    Future<void> finish(NovaSttResult result) async {
      if (completer.isCompleted) return;
      timer?.cancel();
      await sub?.cancel();
      completer.complete(result);
    }

    sub = streamingAsrRuntimeService.events.listen((event) async {
      final text = event.transcript.text.trim();
      if (text.isEmpty) return;

      if (event.isPartial) {
        lastPartial = text;
        lastPartialAt = DateTime.now();
        return;
      }

      if (event.isFinal) {
        final result = await _attachOwnerIdentity(
          recognizedText: text,
          detectedLocale:
              event.transcript.detectedLocale.trim().isEmpty
                  ? 'tr-TR'
                  : event.transcript.detectedLocale.trim(),
          identityAudioPath: event.transcript.identityAudioPath,
          message: 'Embedded streaming ASR final transcript: $targetDescription',
        );
        await finish(result);
      }
    });

    timer = Timer(Duration(seconds: waitSeconds), () async {
      final partialAge = lastPartialAt == null
          ? null
          : DateTime.now().difference(lastPartialAt!);
      final canUseStableEnhancedPartial =
          mode == NovaSttMode.enhanced &&
              lastPartial.trim().length >= 12 &&
              partialAge != null &&
              partialAge >= const Duration(milliseconds: 650);

      if (canUseStableEnhancedPartial) {
        await finish(
          NovaSttResult(
            success: true,
            recognizedText: lastPartial.trim(),
            detectedLocale: 'tr-TR',
            message:
                'Kararlı partial transcript kullanıldı; final PCM kanıtı olmadığı için sahip yetkisi verilmedi: $targetDescription',
            voiceIdentityChecked: false,
            ownerMatched: false,
            ownerConfidence: 0,
            relationshipLabel: 'unverified_partial',
          ),
        );
        return;
      }

      await finish(
        const NovaSttResult(
          success: false,
          recognizedText: '',
          detectedLocale: 'tr-TR',
          message:
              'Streaming ASR zaman penceresinde taze final konuşma üretmedi. Snapshot ve platform fallback devre dışı.',
        ),
      );
    });

    return completer.future;
  }

  Future<NovaSttResult> _attachOwnerIdentity({
    required String recognizedText,
    required String detectedLocale,
    required String identityAudioPath,
    required String message,
  }) async {
    final audioPath = identityAudioPath.trim();
    if (audioPath.isEmpty) {
      return NovaSttResult(
        success: true,
        recognizedText: recognizedText,
        detectedLocale: detectedLocale,
        message: '$message TitaNet kanıt dosyası bulunmadı; telefon eylemi yetkisi verilmedi.',
        voiceIdentityChecked: false,
        ownerMatched: false,
        ownerConfidence: 0,
        relationshipLabel: 'unverified',
      );
    }

    final owner = await ownerIdentityService.loadOwner();
    if (owner == null ||
        !ownerIdentityService.isVerifiedVoiceprintId(owner.ownerVoiceId)) {
      return NovaSttResult(
        success: true,
        recognizedText: recognizedText,
        detectedLocale: detectedLocale,
        message: '$message Doğrulanmış sahip profili bulunmadı.',
        voiceIdentityChecked: false,
        ownerMatched: false,
        ownerConfidence: 0,
        relationshipLabel: 'unconfigured_owner',
        identityAudioPath: audioPath,
      );
    }

    final identity = await voiceIdentityBridgeService.identifyVoiceFromFile(
      audioPath: audioPath,
      minSimilarity: 0.64,
    );
    final matchedOwner = identity.success &&
        identity.matched &&
        identity.voiceId.trim() == owner.ownerVoiceId.trim() &&
        identity.similarity >= 0.64;

    return NovaSttResult(
      success: true,
      recognizedText: recognizedText,
      detectedLocale: detectedLocale,
      message: matchedOwner
          ? '$message Sahip sesi aynı PCM segmentinde TitaNet ile doğrulandı.'
          : '$message Ses işlendi fakat kayıtlı sahip voiceprint’iyle eşleşmedi; telefon eylemi engellenecek.',
      voiceIdentityChecked: identity.success,
      ownerMatched: matchedOwner,
      speakerVoiceId: identity.voiceId.trim(),
      speakerName: identity.displayName.trim(),
      ownerConfidence: matchedOwner ? identity.similarity : 0,
      relationshipLabel: matchedOwner ? 'owner' : 'unknown',
      identityAudioPath: audioPath,
      nativeActionToken: matchedOwner ? identity.nativeActionToken : '',
    );
  }
}
