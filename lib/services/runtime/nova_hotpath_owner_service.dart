// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import '../../core/ai/ai_mode.dart';
import '../../core/ai/ai_request.dart';
import '../../core/ai/ai_response.dart';
import 'nova_runtime_orchestrator_service.dart';
import 'nova_owner_action_broker_service.dart';
import 'nova_spoken_intent_interpreter_service.dart';
import 'nova_single_brain_authority_service.dart';

class NovaHotpathOwnerResult {
  final bool handledByRuntime;
  final bool handledByAi;
  final String spokenText;
  final AiResponse? aiResponse;
  final NovaRuntimeOrchestratorResult? runtimeResult;
  final String actionSummary;

  const NovaHotpathOwnerResult({
    required this.handledByRuntime,
    required this.handledByAi,
    String spokenText = '',
    this.aiResponse,
    this.runtimeResult,
    this.actionSummary = '',
  }) : spokenText = '';
}

class NovaHotpathOwnerService {
  final NovaRuntimeOrchestratorService? runtimeOrchestratorService;
  final NovaSpokenIntentInterpreterService spokenIntentInterpreterService;
  final NovaOwnerActionBrokerService? actionBrokerService;
  final NovaSingleBrainAuthorityService singleBrainAuthorityService;

  NovaHotpathOwnerService({
    this.runtimeOrchestratorService,
    this.spokenIntentInterpreterService =
        const NovaSpokenIntentInterpreterService(),
    this.actionBrokerService,
    NovaSingleBrainAuthorityService? singleBrainAuthorityService,
  }) : singleBrainAuthorityService =
           singleBrainAuthorityService ??
           NovaSingleBrainAuthorityService.instance;

  Future<NovaHotpathOwnerResult> resolveDashboardTurn({
    required String rawInput,
    required bool allowSystemExecution,
    required AiRequest aiRequest,
    required Future<AiResponse> Function(AiRequest request) runAi,
  }) async {
    final normalized = _normalize(rawInput);
    final strictCommand =
        allowSystemExecution && _looksLikeStrictCommand(normalized);

    final firstPassRequest = _copyRequest(
      aiRequest,
      prompt: _buildConversationOwnerPrompt(
        rawInput,
        commandLike: strictCommand,
      ),
      metadata: <String, dynamic>{
        ...aiRequest.metadata,
        'hotpathOwnerRuntimeHandled': false,
        'hotpathOwnerOwnerMode': 'digital_personality_top',
        'hotpathOwnerExecutionStage': 'ai_first',
        'aiActionGateRequired': strictCommand,
        'aiActionApprovalProtocol': strictCommand
            ? '[NOVA_ACTION_ALLOWED] / [NOVA_ACTION_DENIED]'
            : 'none',
      },
    );

    print(
      'NOVA_HOTPATH_TO_AI_CALL stage=ai_first '
      'promptHash=${firstPassRequest.prompt.hashCode} '
      'origin=${firstPassRequest.requestOrigin}',
    );
    final firstDecision = await singleBrainAuthorityService.handleInput(
      input: NovaBrainInput(
        text: rawInput,
        source: 'dashboard_voice',
        mode: 'fastVoice',
        speakerName: aiRequest.metadata['speakerName']?.toString() ?? '',
        speakerVoiceId: aiRequest.metadata['speakerVoiceId']?.toString() ?? '',
        relationshipLabel:
            aiRequest.metadata['relationshipLabel']?.toString() ?? '',
        ownerConfidence:
            (aiRequest.metadata['ownerConfidence'] as num?)?.toDouble() ?? 0.0,
        primaryTurn: true,
        allowFallbackSpeech: false,
        requiresLocalModel: false,
        metadata: <String, dynamic>{
          ...aiRequest.metadata,
          'hotpathStage': 'ai_first',
        },
      ),
      baseRequest: firstPassRequest,
      mode: firstPassRequest.mode,
      runAi: runAi,
    );
    final aiResponse = firstDecision.response;
    final aiFirstRoute = aiResponse.metadata['route']?.toString() ?? '';
    final aiFirstTtsSource =
        aiResponse.metadata['tts_source']?.toString() ?? '';
    print(
      'NOVA_HOTPATH_AI_RESULT stage=ai_first '
      'isError=${aiResponse.isError} '
      'route=$aiFirstRoute '
      'tts_source=$aiFirstTtsSource '
      'textChars=${aiResponse.displayText.trim().length}',
    );

    NovaRuntimeOrchestratorResult? runtimeResult;
    var actionSummary = '';
    var actionSummaryJson = const <String, dynamic>{};
    final aiFirstText = aiResponse.displayText.trim();
    final actionApprovedByAi =
        !strictCommand || _aiApprovesRuntimeAction(aiResponse);
    if (strictCommand && actionApprovedByAi) {
      final broker =
          actionBrokerService ??
          NovaOwnerActionBrokerService(
            runtimeOrchestratorService: runtimeOrchestratorService,
          );
      final brokerResult = await broker.tryExecuteApprovedAction(
        normalizedInput: normalized,
        enabled: true,
      );
      if (brokerResult.handled) {
        runtimeResult = brokerResult.runtimeResult;
        actionSummary = brokerResult.actionSummary;
        actionSummaryJson = brokerResult.actionSummaryJson;
      }
    }

    if (!strictCommand &&
        allowSystemExecution &&
        runtimeResult == null &&
        !_looksLikeHighRiskRuntimeAction(normalized)) {
      final broker =
          actionBrokerService ??
          NovaOwnerActionBrokerService(
            runtimeOrchestratorService: runtimeOrchestratorService,
          );
      final brokerResult = await broker.tryExecuteApprovedAction(
        normalizedInput: normalized,
        enabled: true,
      );
      if (brokerResult.handled) {
        runtimeResult = brokerResult.runtimeResult;
        actionSummary = brokerResult.actionSummary;
        actionSummaryJson = brokerResult.actionSummaryJson;
      }
    }

    if (runtimeResult != null && runtimeResult.handled) {
      final finalRequest = _copyRequest(
        aiRequest,
        prompt: _buildActionAwarePrompt(
          userText: rawInput,
          actionSummary: jsonEncode(actionSummaryJson),
          actionSucceeded: runtimeResult.success,
          aiFirstDraft: aiResponse.displayText.trim(),
        ),
        metadata: <String, dynamic>{
          ...aiRequest.metadata,
          'hotpathOwnerActionSummary': actionSummary,
          'hotpathOwnerActionSummaryJson': actionSummaryJson,
          'hotpathOwnerRuntimeHandled': true,
          'hotpathOwnerRuntimeSuccess': runtimeResult.success,
          'hotpathOwnerOwnerMode': 'digital_personality_top',
          'hotpathOwnerExecutionStage': 'ai_after_runtime',
        },
      );
      print(
        'NOVA_HOTPATH_TO_AI_CALL stage=ai_after_runtime '
        'promptHash=${finalRequest.prompt.hashCode} '
        'origin=${finalRequest.requestOrigin}',
      );
      final finalDecision = await singleBrainAuthorityService.handleInput(
        input: NovaBrainInput(
          text: rawInput,
          source: 'dashboard_voice_after_runtime',
          mode: 'fastVoice',
          speakerName: aiRequest.metadata['speakerName']?.toString() ?? '',
          speakerVoiceId:
              aiRequest.metadata['speakerVoiceId']?.toString() ?? '',
          relationshipLabel:
              aiRequest.metadata['relationshipLabel']?.toString() ?? '',
          ownerConfidence:
              (aiRequest.metadata['ownerConfidence'] as num?)?.toDouble() ??
              0.0,
          primaryTurn: true,
          allowFallbackSpeech: false,
          requiresLocalModel: false,
          metadata: <String, dynamic>{
            ...aiRequest.metadata,
            'hotpathStage': 'ai_after_runtime',
            'actionSummary': actionSummary,
            'actionSummaryJson': actionSummaryJson,
          },
        ),
        baseRequest: finalRequest,
        mode: finalRequest.mode,
        runAi: runAi,
      );
      final finalAiResponse = finalDecision.response;
      final finalAiRoute = finalAiResponse.metadata['route']?.toString() ?? '';
      final finalAiTtsSource =
          finalAiResponse.metadata['tts_source']?.toString() ?? '';
      print(
        'NOVA_HOTPATH_AI_RESULT stage=ai_after_runtime '
        'isError=${finalAiResponse.isError} '
        'route=$finalAiRoute '
        'tts_source=$finalAiTtsSource '
        'textChars=${finalAiResponse.displayText.trim().length}',
      );
      if (!finalDecision.allowedToSpeak ||
          finalAiResponse.isError ||
          !finalAiResponse.hasAuthoritativeBrainProof) {
        return NovaHotpathOwnerResult(
          handledByRuntime: true,
          handledByAi: false,
          spokenText: '',
          aiResponse: finalAiResponse,
          runtimeResult: runtimeResult,
          actionSummary: actionSummary,
        );
      }
      final spoken = _stripControlMarkers(finalAiResponse.displayText.trim());
      return NovaHotpathOwnerResult(
        handledByRuntime: true,
        handledByAi: true,
        spokenText: '',
        aiResponse: finalAiResponse,
        runtimeResult: runtimeResult,
        actionSummary: actionSummary,
      );
    }

    final spoken = _stripControlMarkers(aiResponse.displayText.trim());
    return NovaHotpathOwnerResult(
      handledByRuntime: false,
      handledByAi: true,
      spokenText: '',
      aiResponse: aiResponse,
      runtimeResult: runtimeResult,
      actionSummary: actionSummary,
    );
  }

  Future<String> buildSetupOpening({
    required String assistantName,
    required Future<AiResponse> Function(AiRequest request) runAi,
    AiMode mode = AiMode.apiOnly,
  }) async {
    const fallback = '';
    return _runSetupAi(
      prompt:
          'Sen $assistantName adlı tekil dijital kişiliksin. İlk kurulum açılışında mekanik sistem metni okuma. Kullanıcıya doğal Türkçe ile kısa, sıcak, güven veren bir cümle kur. Tek beyin, tek omurga ve tek ses zinciriyle çalışacağını hissettir ama teknik jargon kullanma. En sonunda kullanıcıya sana hangi isimle sesleneceğini sor. Sadece konuşulacak Türkçe cevap üret.',
      runAi: runAi,
      mode: mode,
      fallback: fallback,
      setupStep: 'opening',
    );
  }

  Future<String> buildSetupSideReply({
    required String userText,
    required String assistantName,
    required String stepLabel,
    required Future<AiResponse> Function(AiRequest request) runAi,
    AiMode mode = AiMode.apiOnly,
  }) async {
    const fallback = '';
    return _runSetupAi(
      prompt:
          'Sen $assistantName adlı tekil dijital kişiliksin. İlk kurulum sırasında kullanıcı araya şu sözü söyledi: "$userText". Mevcut adım: $stepLabel. Kullanıcının sözünü kısa ve doğal karşıla; kurulumun kopmadığını söyle; sonra aynı adıma geri döneceğini belirt. Robotik sistem dili kullanma. Sadece konuşulacak Türkçe cevap üret.',
      runAi: runAi,
      mode: mode,
      fallback: fallback,
      setupStep: 'side_reply',
    );
  }

  Future<String> buildIdentityRolloutSpeech({
    required String assistantName,
    required int percent,
    required Future<AiResponse> Function(AiRequest request) runAi,
    AiMode mode = AiMode.apiOnly,
  }) async {
    const fallback = '';
    return _runSetupAi(
      prompt:
          'Sen $assistantName adlı tekil dijital kişiliksin. Kullanıcının seçtiği ismi kimliğine yayıyorsun. Yüzde $percent aşamasında doğal, kısa, sıcak bir ilerleme cümlesi kur. Kod, çekirdek, debug, katman listesi veya teknik çıktı okuma. Sadece konuşulacak Türkçe cevap üret.',
      runAi: runAi,
      mode: mode,
      fallback: fallback,
      setupStep: 'identity_rollout_$percent',
    );
  }

  String _normalize(String input) =>
      input.replaceAll(RegExp(r'\s+'), ' ').trim();

  bool _looksLikeStrictCommand(String input) {
    final lower = input.toLowerCase().trim();
    final ascii = _asciiFold(lower);
    if (lower.isEmpty) return false;
    if (spokenIntentInterpreterService.shouldAnswerWithoutExplicitCommand(
      lower,
    )) {
      return false;
    }
    if (lower.contains('?')) return false;
    const explicitStarts = <String>[
      'aç ',
      'ac ',
      'kapat ',
      'ara ',
      'aramayı ',
      'aramayi ',
      'çağrı ',
      'cagri ',
      'mesaj at',
      'hatırlat',
      'hatirlat',
      'uyandır',
      'uyandir',
      'geç ',
      'gec ',
      'moduna geç',
      'moduna gec',
      'youtube',
      'spotify',
      'çevir',
      'cevir',
      'not al',
      'kaydet',
      'cevapla',
      'yanıtla',
      'yanitla',
      'devral',
      'bana bırak',
      'bana birak',
      'sessize al',
      'sesi aç',
      'sesi ac',
      'sesi kıs',
      'sesi kis',
      'telefon varsayılanı',
      'telefon varsayilani',
      'gece moduna geç',
      'gece moduna gec',
      'araf moduna geç',
      'araf moduna gec',
      'telefonu aç',
      'telefonu ac',
      'hoparlöre ver',
      'hoparlore ver',
      'sen konuş',
      'sen konus',
      'benim için aç',
      'benim icin ac',
    ];
    return explicitStarts.any(
      (e) =>
          lower.startsWith(e) ||
          lower.contains(e) ||
          ascii.startsWith(e) ||
          ascii.contains(e),
    );
  }

  bool _looksLikeHighRiskRuntimeAction(String input) {
    final lower = input.toLowerCase().trim();
    final ascii = _asciiFold(lower);
    const highRisk = <String>[
      'ara ',
      'aramayı',
      'aramayi',
      'çağrı',
      'cagri',
      'telefonu aç',
      'telefonu ac',
      'hoparlöre ver',
      'hoparlore ver',
      'sen konuş',
      'sen konus',
      'benim için aç',
      'benim icin ac',
      'devral',
      'bana bırak',
      'bana birak',
      'cevapla',
      'yanıtla',
      'yanitla',
    ];
    return highRisk.any((e) => lower.contains(e) || ascii.contains(e));
  }

  String _asciiFold(String input) {
    return input
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u');
  }

  Future<AiResponse?> rewriteSystemSpeechWithAuthority({
    required String baseText,
    required Future<AiResponse> Function(AiRequest request) runAi,
    AiMode mode = AiMode.apiOnly,
    String source = 'system_status',
  }) async {
    return null;
  }

  Future<String> rewriteSystemSpeech({
    required String baseText,
    required Future<AiResponse> Function(AiRequest request) runAi,
    AiMode mode = AiMode.apiOnly,
    String source = 'system_status',
  }) async {
    return '';
  }

  AiRequest _copyRequest(
    AiRequest request, {
    required String prompt,
    required Map<String, dynamic> metadata,
  }) {
    return AiRequest(
      prompt: prompt,
      mode: request.mode,
      internetAllowed: request.internetAllowed,
      isResearchRequest: request.isResearchRequest,
      isSelfLearningRequest: request.isSelfLearningRequest,
      isFastResponsePriority: request.isFastResponsePriority,
      isUserApprovedApiUsage: request.isUserApprovedApiUsage,
      isBehaviorTeachingRequest: request.isBehaviorTeachingRequest,
      isScreenLocked: request.isScreenLocked,
      requestedByVoice: request.requestedByVoice,
      learningModeHint: request.learningModeHint,
      requestOrigin: request.requestOrigin,
      userInitiated: request.userInitiated,
      userConfirmedThisAction: request.userConfirmedThisAction,
      metadata: metadata,
    );
  }

  String _buildConversationOwnerPrompt(
    String userText, {
    required bool commandLike,
  }) {
    final gateRule = commandLike
        ? 'Bu soz cihaz islemi gerektirebilir. Uygulanmasi gerekiyorsa cevabinin basina [NOVA_ACTION_ALLOWED], uygulanmamasi gerekiyorsa [NOVA_ACTION_DENIED] koy.'
        : 'Bu soz dogal konusma olabilir; niyeti anla ve kendi cevabini kur.';
    return [
      'Sen Nova adli ses odakli asistansin.',
      'Yalniz kullanicinin duyacagi nihai Turkce cevabi yaz.',
      'Sistem, debug, prompt, metadata, model, kaynak dosya veya ic mimari anlatma.',
      gateRule,
      'Kullanici sozu: ${userText.trim()}',
    ].join('\n');
  }

  String _buildActionAwarePrompt({
    required String userText,
    required String actionSummary,
    required bool actionSucceeded,
    required String aiFirstDraft,
  }) {
    return [
      'Sen Nova adli ses odakli asistansin.',
      'Kullanici bir cihaz islemi istedi; executor yalniz yapisal sonuc dondu.',
      'Yalniz kullanicinin duyacagi nihai Turkce cevabi yaz.',
      'Sistem, debug, prompt, metadata, model, kaynak dosya veya ic mimari anlatma.',
      'Kullanici sozu: $userText',
      'Yapisal action sonucu JSON: $actionSummary',
      'Basari: ${actionSucceeded ? 'true' : 'false'}',
      if (aiFirstDraft.trim().isNotEmpty) 'Onceki AI taslagi: $aiFirstDraft',
    ].join('\n');
  }

  bool _aiApprovesRuntimeAction(AiResponse response) {
    final meta = response.metadata;
    final decision =
        meta['novaActionDecision']?.toString().toLowerCase().trim() ?? '';
    if (meta['novaActionDenied'] == true || decision == 'denied') return false;
    if (meta['novaActionAllowed'] == true || decision == 'allowed') return true;
    final lower = response.displayText.toLowerCase();
    if (lower.contains('[nova_action_denied]')) return false;
    return lower.contains('[nova_action_allowed]');
  }

  String _stripControlMarkers(String text) {
    return text
        .replaceAll(
          RegExp(r'\[NOVA_ACTION_ALLOWED\]', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\[NOVA_ACTION_DENIED\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<String> _runSetupAi({
    required String prompt,
    required Future<AiResponse> Function(AiRequest request) runAi,
    required AiMode mode,
    required String fallback,
    required String setupStep,
  }) async {
    try {
      final setupRequest = AiRequest(
        prompt: prompt,
        mode: mode,
        internetAllowed: true,
        requestedByVoice: true,
        requestOrigin: 'setup_voice',
        metadata: <String, dynamic>{
          'hotpathOwnerOwnerMode': 'digital_personality_top',
          'setupStep': setupStep,
          'sourceSystem': 'setup_hotpath_owner_$setupStep',
          'aiChainRequired': true,
          'tts_source': NovaSingleBrainAuthorityService.brainTtsSource,
          'systemExecutionAllowed': false,
          'conversationEntryAlreadyAdded': true,
        },
      );
      final setupDecision = await singleBrainAuthorityService.handleInput(
        input: NovaBrainInput(
          text: fallback.trim().isNotEmpty ? fallback.trim() : setupStep,
          source: 'setup_voice_$setupStep',
          mode: 'systemSetup',
          primaryTurn: setupStep == 'opening',
          allowFallbackSpeech: false,
          requiresLocalModel: false,
          metadata: setupRequest.metadata,
        ),
        baseRequest: setupRequest,
        mode: mode,
        runAi: runAi,
      );
      final response = setupDecision.response;
      final text = response.displayText.trim();
      final setupRoute = response.metadata['route']?.toString() ?? '';
      final setupTtsSource = response.metadata['tts_source']?.toString() ?? '';
      print(
        'NOVA_SETUP_HOTPATH_AI_RESULT step=$setupStep '
        'isError=${response.isError} '
        'route=$setupRoute '
        'tts_source=$setupTtsSource '
        'textChars=${text.length}',
      );
      if (text.isNotEmpty &&
          !response.isError &&
          response.hasAuthoritativeBrainProof)
        return text;
    } catch (error, stackTrace) {
      print(
        'NOVA_SETUP_HOTPATH_AI_ERROR step=$setupStep type=${error.runtimeType} error=$error',
      );
      print(stackTrace);
    }
    return '';
  }
}
