// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals_to_create_immutables, duplicate_ignore, prefer_const_constructors
// NOVA_TOTAL_LIFTOFF_ALL_SYSTEMS_REPAIR_V2

import '../../core/ai/ai_response.dart';
import '../../core/speech/nova_final_text_contract.dart';
import '../../services/runtime/nova_identity_runtime_service.dart';

class NovaVoiceOutputDecision {
  final bool shouldSpeak;
  final String spokenText;
  final String uiText;

  const NovaVoiceOutputDecision({
    required this.shouldSpeak,
    required this.spokenText,
    required this.uiText,
  });
}

class NovaVoiceInteractionPolicyService {
  final NovaIdentityRuntimeService identityRuntimeService;

  const NovaVoiceInteractionPolicyService({
    this.identityRuntimeService = const NovaIdentityRuntimeService(),
  });

  // NOVA_VOICE_POLICY_AUTHORITATIVE_MODEL_ONLY_V2
  // NOVA_TTS_FALLBACK_SPEECH_BLOCKED_V4
  NovaVoiceOutputDecision decideForAiResponse(
    AiResponse response, {
    required bool requestCameFromVoice,
  }) {
    final rawDisplay = response.displayText.trim();
    final display = rawDisplay.isEmpty
        ? (response.errorMessage ?? '')
        : identityRuntimeService.replaceAssistantLabel(rawDisplay);

    if (!requestCameFromVoice || !_isAuthoritativeAiSpeech(response)) {
      return NovaVoiceOutputDecision(
        shouldSpeak: false,
        spokenText: '',
        uiText: display,
      );
    }

    return NovaVoiceOutputDecision(
      shouldSpeak: display.trim().isNotEmpty,
      spokenText: '',
      uiText: display,
    );
  }

  NovaVoiceOutputDecision decideForSystemMessage(String text) {
    final safe = text.trim().isEmpty
        ? identityRuntimeService.defaultWakeReply()
        : identityRuntimeService.replaceAssistantLabel(text.trim());

    return NovaVoiceOutputDecision(
      shouldSpeak: false,
      spokenText: '',
      uiText: safe,
    );
  }

  NovaVoiceOutputDecision decideForPermissionPrompt(String text) {
    final safe = text.trim().isEmpty
        ? 'Efendim, onayınızı rica ediyorum.'
        : identityRuntimeService.replaceAssistantLabel(text.trim());

    return NovaVoiceOutputDecision(
      shouldSpeak: false,
      spokenText: '',
      uiText: safe,
    );
  }

  bool _isAuthoritativeAiSpeech(AiResponse response) {
    if (response.isError) return false;
    final text = response.text.trim();
    if (text.isEmpty) return false;
    if (_looksStaticOrFallback(text)) return false;

    final meta = response.metadata;
    if (_safeBool(meta['rawStringNativeModelBlocked'])) return false;
    if (_safeBool(meta['blocked_non_ai_speech'])) return false;
    if (_safeBool(meta['singleBrainFallback'])) return false;
    if (_safeBool(meta['recoverySuppressed'])) return false;

    final route = (meta['route']?.toString() ?? '').toLowerCase();
    final source = (meta['tts_source']?.toString() ?? '').toLowerCase();
    final responseSource = (meta['responseSource']?.toString() ?? '')
        .toLowerCase();

    if (route.contains('fallback') ||
        route.contains('recovery') ||
        route.contains('error')) {
      return false;
    }
    if (responseSource.contains('fallback') ||
        responseSource.contains('recovery')) {
      return false;
    }

    final nativeProof = response.hasAuthoritativeBrainProof;
    final singleBrainProof =
        _safeBool(meta['singleBrainAllowed']) &&
        _safeBool(meta['singleBrainAuthority']) &&
        NovaFinalTextContract.maySpeakMetadata(meta) &&
        source == 'brain_decision_ai_output' &&
        _safeBool(meta['modelUsed']) &&
        nativeProof;

    return singleBrainProof;
  }

  bool _safeBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }

  bool _looksStaticOrFallback(String text) {
    final normalized = text.toLowerCase().trim();
    const blocked = <String>[
      'şu an uygun bir cevap oluşturamadım',
      'buyurun efendim...',
      'güvenli fallback',
      'komut algılanamadı',
      'model gerçek cevap üretmedi',
      'recovery/fallback',
      'fallback cevap',
      'statik fallback',
      'ai_required_block',
      'local_model_failed_strict',
      'no_model_recovery_reply',
      'api_recovery_reply',
      'sistem niyetim',
      'sistem niyeti',
      'sistemin niyetini',
      'aktif kurulum sorusu',
      'önceliklerini sürdür',
      'onceliklerini surdur',
      'tek beyin sözleşmesi',
      'tek beyin sozlesmesi',
      '145 katman',
      '110+ katman',
      'streaming asr',
      'native inference',
      'promptchars',
      'systemchars',
    ];
    return blocked.any(normalized.contains);
  }
}
