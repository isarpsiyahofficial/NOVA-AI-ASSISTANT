// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/foundation.dart';
import '../../core/ai/ai_response.dart';
import '../../core/runtime/freshness_controller.dart';
import '../../core/speech/nova_final_text_contract.dart';
import '../asr/nova_streaming_asr_bridge_service.dart';
import '../settings/nova_settings_service.dart';
import '../speech/tts_service.dart';
import '../voice_clone/turkish_expressive_voice_service.dart';
import '../audio_runtime/nova_playback_echo_filter_service.dart';
import 'nova_prosody_planner_service.dart';
import 'nova_ssml_renderer_service.dart';
import '../runtime/nova_pause_renderer_service.dart';
import '../runtime/nova_turkish_voice_quality_metrics_service.dart';
import '../runtime/nova_identity_runtime_service.dart';
import '../runtime/nova_literal_sweep_service.dart';
import '../runtime/nova_emotion_prosody_fuser_service.dart';
import '../runtime/nova_turkish_voice_persona_layer_service.dart';
import '../runtime/nova_spoken_quality_eval_tr_service.dart';
import '../runtime/nova_single_brain_authority_service.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import '../runtime/nova_runtime_signal_service.dart';

enum NovaTtsMode { system, neuralLocal, cloned }

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
    this.playbackGuardService =
        const NovaPlaybackEchoFilterService(),
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
    var normalizedAuthoritySource = authoritySource.trim().isEmpty
        ? 'legacy_direct_tts'
        : authoritySource.trim();
    var authorityText = text.trim();
    AiResponse? resolvedAuthorityResponse = authorityResponse;
    final proofBoundText = resolvedAuthorityResponse?.displayText.trim() ?? '';
    if (proofBoundText.isNotEmpty &&
        !AiResponse.authorityTextMatches(
          authorityText,
          resolvedAuthorityResponse,
        )) {
      authorityText = proofBoundText;
      normalizedAuthoritySource =
          NovaSingleBrainAuthorityService.brainTtsSource;
    }

    const strictTtsPolicy = false;

    bool allowedByAuthority = NovaSingleBrainAuthorityService.instance
        .authorizeSpeech(
          source: normalizedAuthoritySource,
          text: authorityText,
          response: resolvedAuthorityResponse,
          allowOperational: allowOperationalSpeech,
        );

    if (!allowedByAuthority) {
      // NOVA_TTS_NO_REWRITE_BACKDOOR_V1:
      // Static/status/runtime text must not be rescued by sending it back to AI
      // as a rewrite request. Only already-authorized AI final responses may speak.
      debugPrint(
        'NOVA_TTS_AUTHORITY_REROUTE_DISABLED '
        'source=$normalizedAuthoritySource chars=${authorityText.replaceAll(RegExp(r'\s+'), ' ').trim().length}',
      );
    }

    if (!allowedByAuthority) {
      final fallbackStaticBlocked = _looksLikeFallbackOrStaticSource(normalizedAuthoritySource);
      await NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.tts,
        level: NovaRuntimeSignalLevel.warning,
        code: fallbackStaticBlocked
            ? 'FALLBACK_STATIC_SPEECH_BLOCKED'
            : (strictTtsPolicy
                  ? 'tts_wrong_source_policy_enforced'
                  : 'tts_wrong_source_blocked'),
        message: fallbackStaticBlocked
            ? 'Fallback/static konuşma policy gereği TTS yerine status/log olarak bırakıldı.'
            : 'TTS SingleBrain/AiResponse kanıtı olmadan konuşmayı reddetti; reroute da başarılı olamadı.',
        technicalDetails:
            'source=$normalizedAuthoritySource hasAuthorityResponse=${resolvedAuthorityResponse != null} singleBrainApproved=$singleBrainApproved allowOperationalSpeech=$allowOperationalSpeech',
        diagnosticCandidate: true,
        metadata: <String, dynamic>{
          'source': 'nova_tts_service',
          'authoritySource': normalizedAuthoritySource,
          'strictTtsPolicy': strictTtsPolicy,
        },
      );
      debugPrint(
        'NOVA_TTS_AUTHORITY_BLOCK source=$normalizedAuthoritySource '
        'chars=${authorityText.replaceAll(RegExp(r'\s+'), ' ').trim().length}',
      );
      return;
    }

    if (allowedByAuthority &&
        resolvedAuthorityResponse != null &&
        !NovaFreshnessController.instance.isCurrent(
          resolvedAuthorityResponse,
          allowMissing: false,
        )) {
      await NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.tts,
        level: NovaRuntimeSignalLevel.warning,
        code: 'STALE_TTS_RESPONSE_BLOCKED',
        message: 'Geç gelen/eski SingleBrain cevabı TTS öncesi düşürüldü.',
        technicalDetails:
            "source=$normalizedAuthoritySource freshnessToken=${resolvedAuthorityResponse.metadata['freshnessToken']}",
        diagnosticCandidate: false,
        metadata: <String, dynamic>{
          'source': 'nova_tts_service',
          'authoritySource': normalizedAuthoritySource,
          'staleSpeechBlocked': true,
        },
      );
      debugPrint(
        'NOVA_TTS_STALE_BLOCK source=$normalizedAuthoritySource '
        "token=${resolvedAuthorityResponse.metadata['freshnessToken']}",
      );
      return;
    }

    if (allowedByAuthority) {
      await NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.tts,
        level: NovaRuntimeSignalLevel.info,
        code: 'SPEECH_PROVENANCE_TTS_GATE',
        message: 'SPEECH_PROVENANCE source=brain_decision_ai_output',
        technicalDetails:
            'source=$normalizedAuthoritySource contractStrict=$strictTtsPolicy',
        diagnosticCandidate: false,
        metadata: <String, dynamic>{
          'source': 'nova_tts_service',
          'authoritySource': normalizedAuthoritySource,
          'tts_source': NovaSingleBrainAuthorityService.brainTtsSource,
        },
      );
    }

    await identityRuntimeService.ensureLoaded();
    if (localeCode.toLowerCase().startsWith('tr') &&
        mode == NovaTtsMode.system) {
      mode = NovaTtsMode.neuralLocal;
    }
    if (localeCode.toLowerCase().startsWith('tr') &&
        mode == NovaTtsMode.neuralLocal) {
      try {
        await ttsService.prewarmPreferredTurkishVoice();
      } catch (_) {}
    }
    final prepared = authorityText.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (prepared.isEmpty) {
      return;
    }

    if (resolvedAuthorityResponse == null ||
        !NovaFinalTextContract.maySpeakMetadata(
          resolvedAuthorityResponse.metadata,
        ) ||
        !AiResponse.authorityTextMatches(prepared, resolvedAuthorityResponse)) {
      await NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.tts,
        level: NovaRuntimeSignalLevel.warning,
        code: 'FINAL_TEXT_CONTRACT_BLOCKED',
        message: 'TTS final text contract olmadan konu?may? reddetti.',
        technicalDetails:
            'source=$normalizedAuthoritySource hasResponse=${resolvedAuthorityResponse != null}',
        diagnosticCandidate: true,
        metadata: <String, dynamic>{
          'source': 'nova_tts_service',
          'authoritySource': normalizedAuthoritySource,
          'finalTextOwner':
              resolvedAuthorityResponse?.metadata['novaFinalTextOwner'],
        },
      );
      debugPrint(
        'NOVA_TTS_FINAL_TEXT_CONTRACT_BLOCK source=$normalizedAuthoritySource',
      );
      return;
    }

    final quality = turkishVoiceQualityMetricsService.evaluate(prepared);
    final personaMode = turkishVoicePersonaLayerService.resolve(
      contextMode: 'casual',
      socialMode: 'casual',
      dominantEmotion: _inferEmotionHint(prepared, 'voice'),
    );
    final settings = await settingsService.load();

    if (interruptCurrentSpeech) {
      await ttsService.stop();
    }

    await ttsService.setLanguage(localeCode);
    final baseRate = settings.speechRate > 0
        ? settings.speechRate.clamp(0.56, 0.70)
        : 0.60;
    final basePitch = settings.speechPitch > 0
        ? settings.speechPitch.clamp(1.04, 1.18)
        : 1.10;

    final emotionHint = _inferEmotionHint(prepared, personaMode.mode);
    final fused = emotionProsodyFuserService.fuse(
      raw: prepared,
      dominantEmotion: emotionHint,
      shortFormPreferred: personaMode.preferShortSentences,
    );
    final expressiveRate = _emotionRateMultiplier(emotionHint);
    final expressivePitch = _emotionPitchMultiplier(emotionHint);
    final mergedPlan = prosodyPlannerService.plan(
      prepared,
      baseSpeechRate:
          (quality.estimatedFlatnessRisk >= 2
                  ? baseRate * 0.97
                  : baseRate * fused.rateMultiplier * expressiveRate)
              .toDouble(),
      basePitch:
          (quality.respectsDiscourseMarkers
                  ? basePitch * 1.01
                  : basePitch * fused.pitchMultiplier * expressivePitch)
              .toDouble(),
    );
    final renderedSpeech = prepared;
    debugPrint(
      'NOVA_HUMAN_PROSODY_APPLIED mode=$mode persona=${personaMode.mode} emotion=$emotionHint rate=${mergedPlan.speechRate.toStringAsFixed(3)} pitch=${mergedPlan.pitch.toStringAsFixed(3)} flatness=${quality.estimatedFlatnessRisk} textChars=${renderedSpeech.length}',
    );
    debugPrint(
      'NOVA_TTS_FINAL_TEXT source=${NovaSingleBrainAuthorityService.brainTtsSource} '
      'authoritySource=$normalizedAuthoritySource mode=$mode '
      'enginePolicy=verified_turkish_female_platform_default textChars=${renderedSpeech.length}',
    );

    await ttsService.setSpeechRate(mergedPlan.speechRate);
    await ttsService.setPitch(mergedPlan.pitch);

    await streamingAsrBridgeService.pause();
    await streamingAsrBridgeService.clearBuffer();
    await playbackGuardService.markPlaybackStarted(spokenText: renderedSpeech);
    try {
      switch (mode) {
        case NovaTtsMode.system:
          await ttsService.speakSystem(renderedSpeech);
          return;
        case NovaTtsMode.neuralLocal:
          try {
            await ttsService.speak(renderedSpeech, allowPlatformFallback: true);
          } catch (_) {
            if (!localeCode.toLowerCase().startsWith('tr')) {
              await ttsService.speakSystem(renderedSpeech);
            } else {
              rethrow;
            }
          }
          return;
        case NovaTtsMode.cloned:
          try {
            await ttsService.speak(renderedSpeech, allowPlatformFallback: true);
          } catch (_) {
            if (!localeCode.toLowerCase().startsWith('tr')) {
              await ttsService.speakSystem(renderedSpeech);
            } else {
              rethrow;
            }
          }
          return;
      }
    } finally {
      await playbackGuardService.markPlaybackEnded();
      await Future<void>.delayed(const Duration(milliseconds: 550));
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

  bool _looksLikeFallbackOrStaticSource(String source) {
    final value = source.trim().toLowerCase();
    return value.contains('fallback') ||
        value.contains('static') ||
        value.contains('setup') ||
        value.contains('dashboard') ||
        value.contains('status') ||
        value.contains('repair') ||
        value.contains('legacy');
  }

  String _inferEmotionHint(String text, String personaMode) {
    final lower = text.toLowerCase();
    if (lower.contains('üzgün') ||
        lower.contains('yorucu') ||
        lower.contains('zor') ||
        lower.contains('geçmiş olsun') ||
        lower.contains('kırıld') ||
        lower.contains('sakin ol')) {
      return 'sad';
    }
    if (lower.contains('harika') ||
        lower.contains('mükemmel') ||
        lower.contains('sevindim') ||
        lower.contains('güzel') ||
        lower.contains('ne güzel') ||
        lower.contains('çok iyi')) {
      return 'happy';
    }
    if (lower.contains('dikkat') ||
        lower.contains('acil') ||
        lower.contains('hemen') ||
        lower.contains('şimdi') ||
        lower.contains('beklemeden')) {
      return 'serious';
    }
    if (lower.contains('merak etme') ||
        lower.contains('yanındayım') ||
        lower.contains('buradayım') ||
        lower.contains('anlıyorum') ||
        lower.contains('haklısın')) {
      return 'warm';
    }
    if (text.contains('!')) {
      return 'animated';
    }
    if (text.contains('?') && text.length < 80) {
      return 'curious';
    }
    if (personaMode.contains('support') || personaMode.contains('warm')) {
      return 'warm';
    }
    return 'neutral';
  }

  double _emotionRateMultiplier(String emotionHint) {
    switch (emotionHint) {
      case 'sad':
        return 0.94;
      case 'warm':
        return 0.98;
      case 'serious':
        return 0.96;
      case 'animated':
        return 1.02;
      case 'happy':
        return 1.01;
      case 'curious':
        return 1.0;
      default:
        return 1.0;
    }
  }

  double _emotionPitchMultiplier(String emotionHint) {
    switch (emotionHint) {
      case 'sad':
        return 0.98;
      case 'warm':
        return 1.02;
      case 'serious':
        return 0.99;
      case 'animated':
        return 1.05;
      case 'happy':
        return 1.04;
      case 'curious':
        return 1.03;
      default:
        return 1.0;
    }
  }

  String _humanize(String raw, {String personaMode = 'formal_helper_tr'}) {
    final normalized = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' ...', '…')
        .replaceAll('...', '…')
        .replaceAll(' .', '.')
        .replaceAll(' ,', ',')
        .replaceAll(':', ': ')
        .replaceAll(' - ', ', ')
        .replaceAll(';', '; ')
        .replaceAllMapped(RegExp(r'([.!?])(?=\S)'), (m) => '${m.group(1)} ')
        .replaceAllMapped(RegExp(r'([,:;])(?=\S)'), (m) => '${m.group(1)} ')
        .trim();

    final shaped = normalized
        .replaceAllMapped(
          RegExp(
            r'([^.!?])\s+(ama|fakat|ancak|çünkü|cunku|yalnız|yalniz)\s+',
            caseSensitive: false,
          ),
          (m) => '${m.group(1)}. ${_capitalizeToken(m.group(2) ?? '')} ',
        )
        .replaceAllMapped(
          RegExp(
            r'([^.!?])\s+(ve sonra|ardından|ardindan|sonra da)\s+',
            caseSensitive: false,
          ),
          (m) => '${m.group(1)}. ${_capitalizeToken(m.group(2) ?? '')} ',
        )
        .replaceAll(RegExp(r'!{2,}'), '!')
        .replaceAll(RegExp(r'…{2,}'), '…')
        .trim();
    if (personaMode == 'warm_daily_tr') {
      return shaped
          .replaceAll(RegExp(r'^Şöyle,\s*', caseSensitive: false), 'Şöyle, ')
          .replaceAll(' Bununla birlikte', ' Ama');
    }
    return shaped;
  }

  String _capitalizeToken(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
