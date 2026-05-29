// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/ai/ai_mode.dart';
import '../../core/ai/ai_request.dart';
import '../../core/ai/ai_response.dart';
import '../../core/runtime/freshness_controller.dart';
import '../../core/speech/nova_final_text_contract.dart';

class NovaBrainInput {
  final String text;
  final String source;
  final String mode;
  final String speakerName;
  final String speakerVoiceId;
  final String relationshipLabel;
  final double ownerConfidence;
  final bool primaryTurn;
  final bool allowFallbackSpeech;
  final bool requiresLocalModel;
  final Map<String, dynamic> metadata;

  const NovaBrainInput({
    required this.text,
    required this.source,
    this.mode = 'fastVoice',
    this.speakerName = '',
    this.speakerVoiceId = '',
    this.relationshipLabel = '',
    this.ownerConfidence = 0.0,
    this.primaryTurn = true,
    this.allowFallbackSpeech = false,
    this.requiresLocalModel = false,
    this.metadata = const <String, dynamic>{},
  });
}

class NovaBrainDecisionEnvelope {
  final AiResponse response;
  final String finalText;
  final bool modelUsed;
  final bool allowedToSpeak;
  final String ttsSource;
  final String route;
  final Map<String, dynamic> metadata;

  const NovaBrainDecisionEnvelope({
    required this.response,
    required this.finalText,
    required this.modelUsed,
    required this.allowedToSpeak,
    required this.ttsSource,
    required this.route,
    this.metadata = const <String, dynamic>{},
  });
}

class NovaSingleBrainAuthorityAudit {
  final List<String> registeredSources;
  final List<String> missingCriticalSources;
  final List<String> blockedSpeechSources;
  final Map<String, dynamic> metadata;

  const NovaSingleBrainAuthorityAudit({
    required this.registeredSources,
    required this.missingCriticalSources,
    required this.blockedSpeechSources,
    this.metadata = const <String, dynamic>{},
  });

  bool get healthy => missingCriticalSources.isEmpty;
}

// NOVA_NO_FALLBACK_SUCCESS_V2
class NovaSingleBrainAuthorityService {
  static final NovaSingleBrainAuthorityService instance =
      NovaSingleBrainAuthorityService._internal();

  static const String brainRoute = 'single_brain_authority';
  static const String brainTtsSource = 'brain_decision_ai_output';

  final Map<String, DateTime> _registeredSources = <String, DateTime>{};
  final List<String> _blockedSpeechSources = <String>[];
  String _coreProfile = '';
  String _coreProfileHash = '';
  DateTime? _coreProfileBuiltAt;

  NovaSingleBrainAuthorityService._internal();

  void registerSource(String source) {
    final normalized = source.trim();
    if (normalized.isEmpty) return;
    _registeredSources[normalized] = DateTime.now();
  }

  NovaSingleBrainAuthorityAudit auditSpine() {
    const critical = <String>{
      'dashboard_voice',
      'setup_voice',
      'hotpath_owner',
      'runtime_orchestrator',
      'api_brain',
      'tts_gate',
      'asr_final_transcript',
    };
    final registered = _registeredSources.keys.toList(growable: false)..sort();
    final missing =
        critical
            .where((source) => !_registeredSources.containsKey(source))
            .toList(growable: false)
          ..sort();
    return NovaSingleBrainAuthorityAudit(
      registeredSources: registered,
      missingCriticalSources: missing,
      blockedSpeechSources: List<String>.unmodifiable(_blockedSpeechSources),
      metadata: <String, dynamic>{
        'coreProfileReady': _coreProfile.isNotEmpty,
        'coreProfileHash': _coreProfileHash,
        'coreProfileBuiltAt': _coreProfileBuiltAt?.toIso8601String() ?? '',
        'blockedSpeechCount': _blockedSpeechSources.length,
        'gatewayPolicy':
            'normal_speech_requires_ai_response_provenance_and_text_bound_proof; operational_sources_may_speak_only_with_explicit_allowOperational_flag_and_static_leak_filter; security_speech_requires_explicit_allowSecurity_flag',
      },
    );
  }

  Future<NovaBrainDecisionEnvelope> handleInput({
    required NovaBrainInput input,
    required Future<AiResponse> Function(AiRequest request) runAi,
    AiRequest? baseRequest,
    AiMode mode = AiMode.apiOnly,
  }) async {
    registerSource(input.source);
    registerSource(input.requiresLocalModel ? 'local_model' : 'api_brain');
    _ensureCoreProfile();

    final normalizedText = _normalize(input.text);
    if (normalizedText.isEmpty) {
      return _blockedEnvelope(
        source: input.source,
        message:
            'AI_REQUIRED_BLOCK: boş input için normal Nova cevabı üretilmedi.',
        metadata: input.metadata,
      );
    }

    final speakerPriority = _speakerPriority(input);
    final callerInstruction = _deriveCallerInstruction(
      baseRequest,
      normalizedText,
    );
    final prompt = _buildFastPrompt(
      input,
      normalizedText,
      speakerPriority,
      callerInstruction: callerInstruction,
    );
    final request = _copyOrCreateRequest(
      baseRequest: baseRequest,
      prompt: prompt,
      mode: mode,
      input: input,
      speakerPriority: speakerPriority,
    );

    print(
      'NOVA_SINGLE_BRAIN_INPUT source=${input.source} mode=${input.mode} '
      'primaryTurn=${input.primaryTurn} requireModel=${input.requiresLocalModel} '
      'ownerConfidence=${input.ownerConfidence.toStringAsFixed(2)} '
      'speaker=${_safeLog(input.speakerName)} chars=${normalizedText.length}',
    );

    final response = await runAi(request);
    final responseText = response.displayText.trim();
    final actionDecision = _deriveActionDecision(responseText);
    final modelUsed = !response.isError && response.hasAuthoritativeBrainProof;

    final finalText = _cleanFinalText(responseText);
    final looksStatic = _looksLikeStaticOrFallbackForSource(
      input.source,
      finalText,
    );
    final finalTextContractAllows =
        NovaFinalTextContract.maySpeakMetadata(response.metadata) &&
        AiResponse.authorityTextMatches(finalText, response);
    final allowedToSpeak = !response.isError &&
        finalText.isNotEmpty &&
        modelUsed &&
        finalTextContractAllows &&
        !looksStatic;

    final route =
        response.metadata['route']?.toString().trim().isNotEmpty == true
        ? response.metadata['route'].toString().trim()
        : brainRoute;

    print(
      'NOVA_SINGLE_BRAIN_DECISION source=${input.source} '
      'allowed=$allowedToSpeak modelUsed=$modelUsed isError=${response.isError} '
      'route=$route textChars=${finalText.length} staticLike=$looksStatic '
      'contract=$finalTextContractAllows',
    );

    if (!allowedToSpeak) {
      return _blockedEnvelope(
        source: input.source,
        message: response.isError
            ? 'AI_REQUIRED_BLOCK: ${response.errorMessage ?? response.displayText}'
            : 'AI_REQUIRED_BLOCK: API/native BrainDecision kanıtı veya final text contract geçerli değil; static/fallback cevap engellendi.',
        metadata: <String, dynamic>{...response.metadata, ...input.metadata},
      );
    }

    final provenResponse = response.withAuthoritativeBrainProofText(
      finalText,
      quickReplyOverride: response.quickReply,
      extraMetadata: <String, dynamic>{
        ...input.metadata,
        'route': route == brainRoute ? brainRoute : '${brainRoute}_$route',
        'singleBrainAuthority': true,
        'singleBrainAllowed': true,
        'modelUsed': modelUsed,
        'coreProfileHash': _coreProfileHash,
        'speakerPriority': speakerPriority,
        'cancelPrevious': input.primaryTurn,
        'ownerPrimaryTurn': input.primaryTurn,
        'singleBrainCallerInstructionApplied': callerInstruction.isNotEmpty,
        ..._actionDecisionMetadata(actionDecision),
      },
    );
    final freshResponse = NovaFreshnessController.instance
        .stampAuthoritativeResponse(
          response: provenResponse,
          source: input.source,
          text: finalText,
        );

    return NovaBrainDecisionEnvelope(
      response: freshResponse,
      finalText: finalText,
      modelUsed: modelUsed,
      allowedToSpeak: true,
      ttsSource: brainTtsSource,
      route: route,
      metadata: <String, dynamic>{
        ...freshResponse.metadata,
        ...input.metadata,
        'singleBrainCallerInstructionApplied': callerInstruction.isNotEmpty,
        ..._actionDecisionMetadata(actionDecision),
      },
    );
  }

  Future<NovaBrainDecisionEnvelope> acceptLocalModelResponse({
    required NovaBrainInput input,
    required AiResponse response,
    String route = brainRoute,
  }) async {
    registerSource(input.source);
    registerSource(input.requiresLocalModel ? 'local_model' : 'api_brain');
    _ensureCoreProfile();

    final responseText = response.displayText.trim();
    final actionDecision = _deriveActionDecision(responseText);
    final modelUsed = !response.isError && response.hasAuthoritativeBrainProof;
    final finalText = _cleanFinalText(responseText);
    final looksStatic = _looksLikeStaticOrFallbackForSource(
      input.source,
      finalText,
    );
    final finalTextContractAllows =
        NovaFinalTextContract.maySpeakMetadata(response.metadata) &&
        AiResponse.authorityTextMatches(finalText, response);
    final allowedToSpeak =
        !response.isError &&
        finalText.isNotEmpty &&
        modelUsed &&
        finalTextContractAllows &&
        !looksStatic;

    print(
      'NOVA_SINGLE_BRAIN_ACCEPT_LOCAL_MODEL source=${input.source} '
      'allowed=$allowedToSpeak modelUsed=$modelUsed isError=${response.isError} '
      'route=$route textChars=${finalText.length} staticLike=$looksStatic '
      'contract=$finalTextContractAllows',
    );

    if (!allowedToSpeak) {
      return _blockedEnvelope(
        source: input.source,
        message: response.isError
            ? 'AI_REQUIRED_BLOCK: ${response.errorMessage ?? response.displayText}'
            : 'AI_REQUIRED_BLOCK: API/native beyin cevabı BrainDecision konuşma şartlarını karşılamadı.',
        metadata: <String, dynamic>{...response.metadata, ...input.metadata},
      );
    }

    final provenResponse = response.withAuthoritativeBrainProofText(
      finalText,
      quickReplyOverride: response.quickReply,
      extraMetadata: <String, dynamic>{
        ...input.metadata,
        'route': route == brainRoute ? brainRoute : '${brainRoute}_$route',
        'singleBrainAuthority': true,
        'singleBrainAllowed': true,
        'modelUsed': modelUsed,
        'coreProfileHash': _coreProfileHash,
        'speakerPriority': _speakerPriority(input),
        'cancelPrevious': input.primaryTurn,
        'ownerPrimaryTurn': input.primaryTurn,
        'acceptedBy': 'single_brain_authoritative_response_acceptor',
        ..._actionDecisionMetadata(actionDecision),
      },
    );
    final freshResponse = NovaFreshnessController.instance
        .stampAuthoritativeResponse(
          response: provenResponse,
          source: input.source,
          text: finalText,
        );

    return NovaBrainDecisionEnvelope(
      response: freshResponse,
      finalText: finalText,
      modelUsed: modelUsed,
      allowedToSpeak: true,
      ttsSource: brainTtsSource,
      route: route,
      metadata: <String, dynamic>{
        ...freshResponse.metadata,
        ...input.metadata,
        ..._actionDecisionMetadata(actionDecision),
      },
    );
  }

  bool authorizeSpeech({
    required String source,
    required String text,
    AiResponse? response,
    bool allowOperational = false,
    bool allowSecurity = false,
  }) {
    registerSource('tts_gate');
    final normalizedSource = source.trim().toLowerCase();
    final normalizedText = _normalize(text);
    if (normalizedText.isEmpty) return false;
    if (_isSecurityOrPermissionSource(normalizedSource)) {
      return allowSecurity &&
          !_looksLikeStaticOrFallbackForSource(source, normalizedText);
    }
    final meta = response?.metadata ?? const <String, dynamic>{};
    final responseTextMatches = AiResponse.authorityTextMatches(
      normalizedText,
      response,
    );
    final freshnessOk = NovaFreshnessController.instance.isCurrent(response);
    final responseHasSingleBrainProof =
        response != null &&
        !response.isError &&
        freshnessOk &&
        NovaFinalTextContract.maySpeakMetadata(meta) &&
        meta['singleBrainAllowed'] == true &&
        meta['singleBrainAuthority'] == true &&
        meta['tts_source'] == brainTtsSource &&
        meta['modelUsed'] == true &&
        response.hasAuthoritativeBrainProof &&
        responseTextMatches;
    final operationalAllowed =
        allowOperational &&
        _isOperationalSource(normalizedSource) &&
        responseHasSingleBrainProof &&
        !_looksLikeStaticOrFallbackForSource(source, normalizedText);
    final allowed =
        (operationalAllowed || responseHasSingleBrainProof) &&
        !_looksLikeStaticOrFallbackForSource(source, normalizedText);
    if (!allowed) {
      final tag = '$normalizedSource:${normalizedText.hashCode}';
      if (!_blockedSpeechSources.contains(tag)) {
        _blockedSpeechSources.add(tag);
        if (_blockedSpeechSources.length > 60)
          _blockedSpeechSources.removeAt(0);
      }
      print(
        'NOVA_SINGLE_BRAIN_SPEECH_BLOCKED source=$source '
        'hasResponse=${response != null} isError=${response?.isError ?? false} '
        'tts_source=${meta['tts_source'] ?? ''} freshnessOk=$freshnessOk allowOperational=$allowOperational allowSecurity=$allowSecurity textBound=$responseTextMatches chars=${normalizedText.length}',
      );
      return false;
    }
    return true;
  }

  void _ensureCoreProfile() {
    if (_coreProfile.isNotEmpty) return;
    _coreProfile = <String>[
      'Nova tek kişilik tek beyin, tek omurga ve tek ASR/TTS karar zinciriyle konuşur.',
      'İç kimlik katmanları prompt listesi değildir; kişilik, refleks, niyet, duygu, ilişki ve Türkçe konuşma alışkanlığı olarak davranışa yansır.',
      'Hızlı cevapta yalnız kısa aktif bağlam, ilgili hafıza ve konuşan kişi önceliği kullanılır.',
      'Cihaz sahibi birinci, yetkili kullanıcı ikinci, tanışılmış ama yetkisiz kişi sohbet düzeyi, yabancı kişi komut dışıdır.',
      'API veya native brain authority proof yoksa normal konuşma yok; fallback/static kabuk normal cevap olamaz.',
      'Türkçe ses karakteri canlı, kısa nefesli, doğal vurgu ve duygu taşımalıdır.',
    ].join('\n');
    _coreProfileHash = _coreProfile.hashCode.toString();
    _coreProfileBuiltAt = DateTime.now();
    print('NOVA_SINGLE_BRAIN_CORE_PROFILE_READY hash=$_coreProfileHash');
  }

  AiRequest _copyOrCreateRequest({
    required AiRequest? baseRequest,
    required String prompt,
    required AiMode mode,
    required NovaBrainInput input,
    required String speakerPriority,
  }) {
    final metadata = <String, dynamic>{
      if (baseRequest != null) ...baseRequest.metadata,
      ...input.metadata,
      'singleBrainAuthority': true,
      'singleBrainRequired': true,
      'aiChainRequired': true,
      'sourceSystem': 'single_brain_authority',
      'inputSource': input.source,
      'runtimeMode': input.mode,
      'speakerName': input.speakerName,
      'speakerVoiceId': input.speakerVoiceId,
      'relationshipLabel': input.relationshipLabel,
      'ownerConfidence': input.ownerConfidence,
      'speakerPriority': speakerPriority,
      'coreProfileHash': _coreProfileHash,
      'tts_source': brainTtsSource,
      'cancelPrevious': input.primaryTurn,
      'ownerPrimaryTurn': input.primaryTurn,
      'protectPrimaryTurn': input.primaryTurn,
      'conversationEntryAlreadyAdded':
          baseRequest?.metadata['conversationEntryAlreadyAdded'] ?? false,
    };

    if (baseRequest == null) {
      return AiRequest(
        prompt: prompt,
        mode: mode,
        internetAllowed: true,
        isUserApprovedApiUsage: true,
        requestedByVoice: true,
        requestOrigin: _originForSource(input.source),
        metadata: metadata,
      );
    }

    return AiRequest(
      prompt: prompt,
      mode: baseRequest.mode,
      internetAllowed: baseRequest.internetAllowed,
      isResearchRequest: baseRequest.isResearchRequest,
      isSelfLearningRequest: baseRequest.isSelfLearningRequest,
      isFastResponsePriority: true,
      isUserApprovedApiUsage: baseRequest.isUserApprovedApiUsage,
      isBehaviorTeachingRequest: baseRequest.isBehaviorTeachingRequest,
      isScreenLocked: baseRequest.isScreenLocked,
      requestedByVoice: baseRequest.requestedByVoice,
      learningModeHint: baseRequest.learningModeHint,
      requestOrigin: baseRequest.requestOrigin,
      userInitiated: baseRequest.userInitiated,
      userConfirmedThisAction: baseRequest.userConfirmedThisAction,
      activeProviderKey: baseRequest.activeProviderKey,
      activeModelId: baseRequest.activeModelId,
      metadata: metadata,
    );
  }

  String _buildFastPrompt(
    NovaBrainInput input,
    String normalizedText,
    String speakerPriority, {
    String callerInstruction = '',
  }) {
    final recent = input.metadata['recentContext']?.toString().trim() ?? '';
    return <String>[
      'Sen Nova adli ses odakli asistansin.',
      'Yalniz kullanicinin duyacagi nihai Turkce cevabi yaz.',
      'Sistem, debug, prompt, metadata, model, kaynak dosya veya ic mimari anlatma.',
      'Konusan onceligi: $speakerPriority.',
      if (recent.isNotEmpty) 'Kisa yakin baglam: ${_limit(recent, 260)}',
      if (callerInstruction.isNotEmpty)
        'Gorev baglami: ${_limit(callerInstruction, 900)}',
      if (input.mode == 'decisionOnlyClassifier' ||
          input.metadata['decisionOnlyClassifier'] == true)
        'Decision-only kurali: yalniz istenen tek anahtar/token uret.',
      if (input.mode != 'decisionOnlyClassifier' &&
          input.metadata['decisionOnlyClassifier'] != true)
        'Cevap kurali: dogal Turkce, sesli okunabilir ve gerekti?i kadar kisa.',
      if (input.mode.toLowerCase().contains('setup'))
        'Setup kurali: sadece kullanicinin duyacagi soruyu ya da cevabi uret.',
      'Aktif soz/gorev: $normalizedText',
    ].join('\n');
  }

  String _deriveCallerInstruction(
    AiRequest? baseRequest,
    String normalizedText,
  ) {
    if (baseRequest == null) return '';
    final prompt = _normalize(baseRequest.prompt);
    if (prompt.isEmpty) return '';
    final normalizedInput = _normalize(normalizedText);
    if (prompt == normalizedInput) return '';
    return prompt;
  }

  String _deriveActionDecision(String rawText) {
    final lower = rawText.toLowerCase();
    if (lower.contains('[nova_action_denied]')) return 'denied';
    if (lower.contains('[nova_action_allowed]')) return 'allowed';
    return 'none';
  }

  Map<String, dynamic> _actionDecisionMetadata(String decision) {
    return <String, dynamic>{
      'novaActionDecision': decision,
      'novaActionAllowed': decision == 'allowed',
      'novaActionDenied': decision == 'denied',
    };
  }

  String _speakerPriority(NovaBrainInput input) {
    final relation = input.relationshipLabel.toLowerCase();
    final name = input.speakerName.toLowerCase();
    final conf = input.ownerConfidence;
    if (conf >= 0.86 ||
        relation.contains('owner') ||
        relation.contains('sahip') ||
        name.contains('ibrahim') ||
        name.contains('patron')) {
      return 'device_owner';
    }
    if (relation.contains('authorized') || relation.contains('yetkili')) {
      return 'authorized_user';
    }
    if (input.speakerVoiceId.trim().isNotEmpty ||
        input.speakerName.trim().isNotEmpty) {
      return 'known_person_chat_only';
    }
    return 'unknown_person_no_command';
  }

  NovaBrainDecisionEnvelope _blockedEnvelope({
    required String source,
    required String message,
    required Map<String, dynamic> metadata,
  }) {
    final clean = _normalize(message);
    print('NOVA_SINGLE_BRAIN_BLOCK source=$source reason=${_safeLog(clean)}');
    return NovaBrainDecisionEnvelope(
      response: AiResponse.error(
        message: clean,
        quickReply: '',
        metadata: <String, dynamic>{
          ...metadata,
          'route': 'single_brain_blocked',
          'tts_source': 'blocked_non_ai_speech',
          'singleBrainAllowed': false,
          'modelOutputRejected': true,
        },
      ),
      finalText: '',
      modelUsed: false,
      allowedToSpeak: false,
      ttsSource: 'blocked_non_ai_speech',
      route: 'single_brain_blocked',
      metadata: metadata,
    );
  }

  // NOVA_SINGLE_BRAIN_OPERATIONAL_FALLBACK_SUCCESS_REMOVED_V1
  // No operational fallback is allowed to become a successful spoken answer.
  String _originForSource(String source) {
    if (source.startsWith('setup')) return 'setup_voice';
    if (source.startsWith('dashboard')) return 'dashboard_voice';
    if (source.contains('background')) return 'background_authorized_voice';
    if (source.contains('native')) return 'native_main_activity';
    return 'user_voice';
  }

  String _cleanFinalText(String input) {
    return _normalize(input)
        .replaceAll(
          RegExp(r'\[NOVA_ACTION_ALLOWED\]', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\[NOVA_ACTION_DENIED\]', caseSensitive: false), '')
        .trim();
  }

  bool _looksLikeStaticOrFallbackForSource(String source, String text) {
    final lower = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalizedSource = source.toLowerCase().trim();
    if (normalizedSource.startsWith('setup') && _isValidSetupQuestion(lower)) {
      return false;
    }
    return _looksLikeStaticOrFallback(text);
  }

  bool _isValidSetupQuestion(String lower) {
    if (lower.isEmpty) return false;
    final asksName =
        lower.contains('hitap') ||
        lower.contains('seslen') ||
        lower.contains('isim');
    final asksPreference =
        lower.contains('istersin') ||
        lower.contains('istersiniz') ||
        lower.contains('istediğin') ||
        lower.contains('istediğiniz') ||
        lower.contains('nasıl çağır');
    final notGenericAssistant =
        !lower.contains('nasıl yardımcı olabilirim') &&
        !lower.contains('ne yapmamı istersin') &&
        !lower.contains('hazırım');
    return asksName && asksPreference && notGenericAssistant;
  }

  bool _looksLikeStaticOrFallback(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return true;
    const markers = <String>[
      'yerel model hazır değil',
      'komut algılanamadı',
      'güvenli fallback',
      'ai_required_block',
      'system prompt',
      'debug',
      'hotpath üst yürütücü',
      'nova human runtime capsule',
      'single brain executive',
      'single_brain_fast_decision',
      'coreprofilehash',
      'novacoreprofile',
      'runtime katmanı',
      'kullanıcı bağlamı',
      'speaker_priority',
      'mode=',
      'source=',
      'input=',
      'kullanıcı girdisi:',
      'görev:',
      'çıkış:',
      'tts_source',
      'brain_decision',
      'setup_speech_rewrite',
      'native_model_timeout',
      'merhaba! ilk kurulum tamamlandı',
      'nasıl yardımcı olabilirim',
      'ne yapmamı istersin',
      'bana nasıl hitap etmemi istediğinizi',
      'türkçe, tek bir cümleyle söyleyin',
      'ok_real_local_model',
      'sistem niyetim',
      'sistem niyeti',
      'sistemin niyetini',
      'aktif kurulum sorusu',
      'önceliklerini sürdür',
      'onceliklerini surdur',
      'tek beyin sözleşmesi',
      'tek beyin sozlesmesi',
      'sistem hedefi',
      'katman bağı',
      'katman bagi',
      '145 katman',
      '110+ katman',
      'streaming asr',
      'native inference',
      'promptchars',
      'systemchars',
    ];
    if (markers.any(lower.contains)) return true;
    if (lower.length < 4) return true;
    return false;
  }

  bool _isSingleBrainOutputSource(String source) {
    return source == brainTtsSource ||
        source.contains('single_brain_output') ||
        source.contains('single_brain_authority_output') ||
        source.contains('call_companion_ai_authority_output') ||
        source.contains('setup_ai_rewrite_output');
  }

  // Deterministic setup voice plans are no longer authorized as spoken output.

  bool _isSecurityOrPermissionSource(String source) {
    return source.contains('security') ||
        source.contains('quarantine') ||
        source.contains('containment') ||
        source.contains('permission') ||
        source.contains('izin');
  }

  bool _isOperationalSource(String source) {
    return source.contains('progress') ||
        source.contains('loading') ||
        source.contains('boot') ||
        source.contains('status') ||
        source.contains('reminder') ||
        source.contains('self_repair') ||
        source.contains('clarification') ||
        source.contains('runtime_orchestrator') ||
        source.contains('speech_runtime');
  }

  String _normalize(String input) =>
      input.replaceAll(RegExp(r'\s+'), ' ').trim();

  String _limit(String input, int max) {
    final clean = _normalize(input);
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max).trimRight()}…';
  }

  String _safeLog(String input) => _limit(input.replaceAll('\n', ' '), 180);
}
