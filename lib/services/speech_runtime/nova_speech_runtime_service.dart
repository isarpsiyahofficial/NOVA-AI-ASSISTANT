// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_TTS_FALLBACK_SPEECH_BLOCKED_V3: generated fallback speech disabled; only authoritative model output may be spoken.
// NOVA_TTS_FALLBACK_SPEECH_BLOCKED_V2: SingleBrainAuthority dışı fallback TTS engellendi.
import '../../core/speech_runtime/nova_speech_request.dart';
import '../../core/speech_runtime/nova_speech_result.dart';
import '../../core/ai/ai_response.dart';
import '../../core/speech/nova_final_text_contract.dart';
import '../asr/nova_streaming_asr_bridge_service.dart';
import '../audio_runtime/nova_native_audio_bridge_service.dart';
import '../presence/nova_presence_service.dart';
import '../settings/nova_settings_service.dart';
import '../runtime/nova_identity_runtime_service.dart';
import '../runtime/nova_literal_sweep_service.dart';
import '../runtime/nova_single_brain_authority_service.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import '../runtime/nova_runtime_signal_service.dart';
import '../speech/tts_service.dart';
import 'turkish_speech_style_service.dart';
import 'voice_profile_runtime_service.dart';

class NovaSpeechRuntimeService {
  final TtsService ttsService;
  final VoiceProfileRuntimeService voiceProfileRuntimeService;
  final TurkishSpeechStyleService turkishSpeechStyleService;
  final NovaPresenceService presenceService;
  final NovaSettingsService settingsService;
  final NovaNativeAudioBridgeService nativeAudioBridgeService;
  final NovaIdentityRuntimeService identityRuntimeService;
  final NovaLiteralSweepService literalSweepService;
  final NovaStreamingAsrBridgeService streamingAsrBridgeService;

  const NovaSpeechRuntimeService({
    required this.ttsService,
    required this.voiceProfileRuntimeService,
    required this.turkishSpeechStyleService,
    required this.presenceService,
    required this.settingsService,
    required this.nativeAudioBridgeService,
    this.identityRuntimeService = const NovaIdentityRuntimeService(),
    this.literalSweepService = const NovaLiteralSweepService(),
    this.streamingAsrBridgeService = const NovaStreamingAsrBridgeService(),
  });

  Future<NovaSpeechResult> speak(NovaSpeechRequest request) async {
    if (!request.hasUsableText) {
      return const NovaSpeechResult(
        success: false,
        usedFallback: false,
        message: 'Konuşulacak metin boş.',
        appliedVoiceProfileId: '',
      );
    }

    final settings = await settingsService.load();
    final localeCode = turkishSpeechStyleService.preferredLocale(
      request.localeCode,
    );
    final activeVoiceProfileId = await voiceProfileRuntimeService
        .resolveActiveVoiceProfileId(
          requestedVoiceProfileId: request.voiceProfileId,
        );
    final activeSpeakerPath = await voiceProfileRuntimeService
        .resolveActiveSpeakerPath(
          requestedVoiceProfileId: request.voiceProfileId,
        );

    final capabilities = await nativeAudioBridgeService.getXttsCapabilities();
    final supportsReferenceAudio =
        capabilities['supportsReferenceAudio'] as bool? ?? false;

    await identityRuntimeService.ensureLoaded();
    final rawAuthorityText =
        request.authorityResponse?.displayText.trim() ?? request.text;
    final textForAuthority =
        request.authorityResponse != null &&
            !AiResponse.authorityTextMatches(
              request.text,
              request.authorityResponse,
            )
        ? rawAuthorityText
        : request.text;
    final authorityGateText = AiResponse.normalizeAuthorityText(
      textForAuthority,
    );
    final normalizedText = authorityGateText;

    final turkishVoiceLocked = localeCode.toLowerCase().startsWith('tr');
    final speakerPathForRuntime = turkishVoiceLocked
        ? ''
        : (supportsReferenceAudio ? activeSpeakerPath : '');
    if (turkishVoiceLocked && activeSpeakerPath.trim().isNotEmpty) {
      await NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.tts,
        level: NovaRuntimeSignalLevel.info,
        code: 'speech_runtime_turkish_platform_voice_locked',
        message:
            'Türkçe normal runtime konuşması explicit native speakerPath yerine doğrulanmış platform kadın sesine yönlendirildi.',
        technicalDetails:
            'activeVoiceProfileId=$activeVoiceProfileId activeSpeakerPathPresent=${activeSpeakerPath.trim().isNotEmpty}',
        diagnosticCandidate: false,
        metadata: <String, dynamic>{
          'source': 'nova_speech_runtime_service',
          'localeCode': localeCode,
          'speakerPathSuppressedForTurkish': true,
        },
      );
    }

    final speechAllowed = NovaSingleBrainAuthorityService.instance
        .authorizeSpeech(
          source: request.authoritySource,
          text: authorityGateText,
          response: request.authorityResponse,
          allowOperational: request.allowOperationalSpeech,
        );
    if (!speechAllowed) {
      await NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.tts,
        level: NovaRuntimeSignalLevel.warning,
        code: 'tts_wrong_source_speech_runtime_blocked',
        message:
            'SpeechRuntime SingleBrain/AiResponse kanıtı olmadan konuşmayı reddetti.',
        technicalDetails:
            'source=${request.authoritySource} hasAuthorityResponse=${request.authorityResponse != null} singleBrainApproved=${request.singleBrainApproved} allowOperationalSpeech=${request.allowOperationalSpeech}',
        diagnosticCandidate: true,
        metadata: <String, dynamic>{
          'source': 'nova_speech_runtime_service',
          'authoritySource': request.authoritySource,
        },
      );
      return NovaSpeechResult(
        success: false,
        usedFallback: false,
        message: 'Konuşma SingleBrainAuthority tarafından engellendi.',
        appliedVoiceProfileId: activeVoiceProfileId,
      );
    }
    if (request.authorityResponse == null ||
        !NovaFinalTextContract.maySpeakMetadata(
          request.authorityResponse!.metadata,
        ) ||
        !AiResponse.authorityTextMatches(
          normalizedText,
          request.authorityResponse,
        )) {
      await NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.tts,
        level: NovaRuntimeSignalLevel.warning,
        code: 'speech_runtime_final_text_contract_blocked',
        message: 'SpeechRuntime final text contract olmadan TTS yapmadı.',
        technicalDetails:
            'source=${request.authoritySource} hasAuthorityResponse=${request.authorityResponse != null}',
        diagnosticCandidate: true,
        metadata: <String, dynamic>{
          'source': 'nova_speech_runtime_service',
          'authoritySource': request.authoritySource,
        },
      );
      return NovaSpeechResult(
        success: false,
        usedFallback: false,
        message: 'Konuşma final text contract tarafından engellendi.',
        appliedVoiceProfileId: activeVoiceProfileId,
      );
    }
    await NovaRuntimeSignalService.instance.record(
      kind: NovaRuntimeSignalKind.tts,
      level: NovaRuntimeSignalLevel.info,
      code: 'SPEECH_PROVENANCE_TTS_GATE',
      message: 'SPEECH_PROVENANCE source=brain_decision_ai_output',
      technicalDetails: 'source=${request.authoritySource}',
      diagnosticCandidate: false,
      metadata: <String, dynamic>{
        'source': 'nova_speech_runtime_service',
        'authoritySource': request.authoritySource,
        'tts_source': NovaSingleBrainAuthorityService.brainTtsSource,
      },
    );

    try {
      presenceService.setStateSafe(NovaPresenceState.speaking);

      if (request.interruptCurrentSpeech) {
        await ttsService.stop();
      }

      await ttsService.setLanguage(localeCode);
      await ttsService.setSpeechRate(
        settings.speechRate > 0
            ? settings.speechRate
            : turkishSpeechStyleService.preferredSpeechRate(localeCode),
      );
      await ttsService.setPitch(
        settings.speechPitch > 0
            ? settings.speechPitch
            : turkishSpeechStyleService.preferredPitch(localeCode),
      );

      await streamingAsrBridgeService.pause();
      await streamingAsrBridgeService.clearBuffer();
      await ttsService.speak(
        normalizedText,
        speakerPath: speakerPathForRuntime,
        allowPlatformFallback: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 550));
      await streamingAsrBridgeService.clearBuffer();
      await streamingAsrBridgeService.resume();

      presenceService.setStateSafe(NovaPresenceState.idle);

      return NovaSpeechResult(
        success: true,
        usedFallback: false,
        message: supportsReferenceAudio
            ? 'Konuşma tamamlandı.'
            : 'Konuşma tamamlandı. Aktif ses için gerçek model routing kullanıldı; zero-shot clone modeli bulunmuyor.',
        appliedVoiceProfileId: activeVoiceProfileId,
      );
    } catch (_) {
      await streamingAsrBridgeService.clearBuffer();
      await streamingAsrBridgeService.resume();
      presenceService.setStateSafe(NovaPresenceState.idle);

      if (!request.allowFallback) {
        return NovaSpeechResult(
          success: false,
          usedFallback: false,
          message: 'Konuşma başarısız oldu.',
          appliedVoiceProfileId: activeVoiceProfileId,
        );
      }

      return NovaSpeechResult(
        success: false,
        usedFallback: false,
        message:
            'NOVA_TTS_FALLBACK_SPEECH_BLOCKED_V3: SingleBrainAuthority dışı fallback TTS engellendi.',
        appliedVoiceProfileId: activeVoiceProfileId,
      );
    }
  }
}
