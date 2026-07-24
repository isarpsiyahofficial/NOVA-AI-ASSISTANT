// NOVA_TTS_LOW_LATENCY_HANDOFF_V2_SHERPA_PRIMARY
// NOVA_TTS_LOW_LATENCY_HANDOFF_V3_VERIFIED_SHERPA_PRIMARY
import 'package:flutter/foundation.dart';

import '../../core/ai/ai_response.dart';
import '../../core/runtime/freshness_controller.dart';
import '../../core/speech/nova_final_text_contract.dart';
import '../asr/nova_streaming_asr_bridge_service.dart';
import '../audio_runtime/nova_playback_echo_filter_service.dart';
import '../runtime/nova_emotion_prosody_fuser_service.dart';
import '../runtime/nova_identity_runtime_service.dart';
import '../runtime/nova_literal_sweep_service.dart';
import '../runtime/nova_pause_renderer_service.dart';
import '../runtime/nova_single_brain_authority_service.dart';
import '../runtime/nova_spoken_quality_eval_tr_service.dart';
import '../runtime/nova_turkish_voice_persona_layer_service.dart';
import '../runtime/nova_turkish_voice_quality_metrics_service.dart';
import '../settings/nova_settings_service.dart';
import '../speech/tts_service.dart';
import '../voice_clone/turkish_expressive_voice_service.dart';
import 'nova_prosody_planner_service.dart';
import 'nova_ssml_renderer_service.dart';

enum NovaTtsMode { system, neuralLocal, cloned }

/// The only normal Nova speech gateway.
///
/// A string is never spoken merely because an API returned it. The response
/// must still carry the current SingleBrain/model-output proof, must match the
/// sealed final text, and must not be stale. ASR microphone ownership is paused
/// before playback and resumed immediately after playback without a fixed
/// post-speech sleep.
class NovaTtsService {
  final TtsService ttsService;
  final NovaSettingsService settingsService;
  final NovaPlaybackEchoFilterService playbackGuardService;
  final TurkishExpressiveVoiceService expressiveVoiceService;
  final NovaProsodyPlannerService prosodyPlannerService;
  final NovaSsmlRendererService ssmlRendererService;
  final NovaPauseRendererService pauseRendererService;
  final NovaTurkishVoiceQualityMetricsService turkishVoiceQualityMetricsService;
  final NovaEmotionProsodyFuserService emotionProsodyFuserService;
  final NovaTurkishVoicePersonaLayerService turkishVoicePersonaLayerService;
  final NovaSpokenQualityEvalTrService spokenQualityEvalTrService;
  final NovaIdentityRuntimeService identityRuntimeService;
  final NovaLiteralSweepService literalSweepService;
  final NovaStreamingAsrBridgeService streamingAsrBridgeService;

  const NovaTtsService({
    required this.ttsService,
    required this.settingsService,
    this.playbackGuardService = const NovaPlaybackEchoFilterService(),
    this.expressiveVoiceService = const TurkishExpressiveVoiceService(),
    this.prosodyPlannerService = const NovaProsodyPlannerService(),
    this.ssmlRendererService = const NovaSsmlRendererService(),
    this.pauseRendererService = const NovaPauseRendererService(),
    this.turkishVoiceQualityMetricsService =
        const NovaTurkishVoiceQualityMetricsService(),
    this.emotionProsodyFuserService = const NovaEmotionProsodyFuserService(),
    this.turkishVoicePersonaLayerService =
        const NovaTurkishVoicePersonaLayerService(),
    this.spokenQualityEvalTrService = const NovaSpokenQualityEvalTrService(),
    this.identityRuntimeService = const NovaIdentityRuntimeService(),
    this.literalSweepService = const NovaLiteralSweepService(),
    this.streamingAsrBridgeService = const NovaStreamingAsrBridgeService(),
  });

  Future<void> speak(
    String text, {
    String localeCode = 'tr-TR',
    NovaTtsMode mode = NovaTtsMode.neuralLocal,
    bool interruptCurrentSpeech = true,
    String authoritySource = 'legacy_direct_tts',
    AiResponse? authorityResponse,
    bool allowOperationalSpeech = false,
    bool singleBrainApproved = false,
  }) async {
    var source = authoritySource.trim().isEmpty
        ? 'legacy_direct_tts'
        : authoritySource.trim();
    var authorityText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final response = authorityResponse;
    final proofBoundText = response?.displayText.trim() ?? '';

    if (proofBoundText.isNotEmpty &&
        !AiResponse.authorityTextMatches(authorityText, response)) {
      authorityText = proofBoundText;
      source = NovaSingleBrainAuthorityService.brainTtsSource;
    }

    final authorityAllowed = NovaSingleBrainAuthorityService.instance
        .authorizeSpeech(
          source: source,
          text: authorityText,
          response: response,
          allowOperational: allowOperationalSpeech,
        );
    if (!authorityAllowed) {
      debugPrint(
        'NOVA_TTS_AUTHORITY_BLOCK source=$source '
        'hasResponse=${response != null} singleBrainApproved=$singleBrainApproved',
      );
      return;
    }

    if (response == null) {
      debugPrint(
        'NOVA_TTS_FINAL_TEXT_CONTRACT_BLOCK source=$source reason=no_response',
      );
      return;
    }

    if (!NovaFreshnessController.instance.isCurrent(
      response,
      allowMissing: false,
    )) {
      debugPrint(
        'NOVA_TTS_STALE_BLOCK source=$source '
        "token=${response.metadata['freshnessToken']}",
      );
      return;
    }

    if (authorityText.isEmpty ||
        !NovaFinalTextContract.maySpeakMetadata(response.metadata) ||
        !AiResponse.authorityTextMatches(authorityText, response)) {
      final owner = response.metadata['novaFinalTextOwner']?.toString() ?? '';
      debugPrint(
        'NOVA_TTS_FINAL_TEXT_CONTRACT_BLOCK source=$source owner=$owner',
      );
      return;
    }

    await identityRuntimeService.ensureLoaded();
    final settings = await settingsService.load();
    final isTurkish = localeCode.toLowerCase().startsWith('tr');
    if (isTurkish && mode == NovaTtsMode.system) {
      mode = NovaTtsMode.neuralLocal;
    }

    if (interruptCurrentSpeech) {
      await ttsService.stop();
    }

    await ttsService.setLanguage(localeCode);
    await ttsService.setSpeechRate(
      (settings.speechRate > 0
              ? settings.speechRate.clamp(0.56, 0.70)
              : 0.60)
          .toDouble(),
    );
    await ttsService.setPitch(
      (settings.speechPitch > 0
              ? settings.speechPitch.clamp(1.04, 1.18)
              : 1.10)
          .toDouble(),
    );

    debugPrint(
      'NOVA_TTS_FINAL_TEXT source=${NovaSingleBrainAuthorityService.brainTtsSource} '
      'authoritySource=$source mode=$mode '
      'enginePolicy=sherpa_offline_primary_platform_explicit_fallback '
      'textChars=${authorityText.length}',
    );

    await streamingAsrBridgeService.pause();
    await streamingAsrBridgeService.clearBuffer();
    await playbackGuardService.markPlaybackStarted(spokenText: authorityText);

    try {
      switch (mode) {
        case NovaTtsMode.system:
          await ttsService.speakSystem(authorityText);
          return;
        case NovaTtsMode.neuralLocal:
        case NovaTtsMode.cloned:
          try {
            await ttsService.speak(
              authorityText,
              speakerPath: 'sherpa_default',
              allowPlatformFallback: true,
            );
          } catch (_) {
            if (!isTurkish) {
              await ttsService.speakSystem(authorityText);
            } else {
              rethrow;
            }
          }
          return;
      }
    } finally {
      await playbackGuardService.markPlaybackEnded();
      await streamingAsrBridgeService.clearBuffer();
      await streamingAsrBridgeService.resume();
    }
  }

  Future<void> stop() async {
    await ttsService.stop();
    await playbackGuardService.markPlaybackEnded();
    await streamingAsrBridgeService.clearBuffer();
    await streamingAsrBridgeService.resume();
  }
}
