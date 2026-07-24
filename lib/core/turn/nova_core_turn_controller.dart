import '../ai/ai_mode.dart';
import '../ai/ai_request.dart';
import '../ai/ai_response.dart';
import '../ai/nova_ai_service.dart';
import '../behavior/nova_persona.dart';
import '../behavior/response_style.dart';
import '../settings/nova_settings.dart';
import '../../services/api/api_service.dart';
import '../../services/local_model/local_model_service.dart';
import '../../services/runtime/nova_runtime_graph_service.dart';
import '../../services/runtime/nova_single_brain_authority_service.dart';

// NOVA_CORE_TURN_CONTROLLER_V2
// Single, auditable entry point for normal Nova user turns.
// UI/setup/voice surfaces must never create a second decision root or call
// ApiService.send directly. Every turn is processed by the shared NovaAiService
// so memory, emotion, relationship and human-behaviour layers stay active.

enum NovaTurnSource {
  dashboardText,
  dashboardVoice,
  setupPanel,
  continuousListening,
  reminderEvent,
  callEvent,
}

class NovaCoreTurnRequest {
  final String inputText;
  final NovaTurnSource source;
  final NovaSettings settings;
  final bool requestedByVoice;
  final bool userInitiated;
  final Map<String, dynamic> context;

  const NovaCoreTurnRequest({
    required this.inputText,
    required this.source,
    required this.settings,
    this.requestedByVoice = false,
    this.userInitiated = true,
    this.context = const <String, dynamic>{},
  });
}

class NovaCoreTurnResult {
  final AiResponse response;
  final String finalText;
  final bool allowedToSpeak;
  final String ttsSource;
  final Map<String, dynamic> trace;

  const NovaCoreTurnResult({
    required this.response,
    required this.finalText,
    required this.allowedToSpeak,
    required this.ttsSource,
    this.trace = const <String, dynamic>{},
  });
}

class NovaCoreTurnController {
  final NovaAiService? aiService;

  const NovaCoreTurnController({this.aiService});

  Future<NovaCoreTurnResult> processUserTurn(NovaCoreTurnRequest turn) async {
    final input = turn.inputText.trim();
    final turnId = turn.context['turnId']?.toString().trim().isNotEmpty == true
        ? turn.context['turnId'].toString().trim()
        : 'nova_core_${DateTime.now().microsecondsSinceEpoch}';
    final settings = turn.settings;
    final apiConfigured =
        settings.apiBrainEnabled && settings.apiKey.trim().isNotEmpty;

    // The factory is used only when an embedding/test surface invokes the
    // controller before main.dart has registered the root service. In the real
    // app this always resolves the exact same NovaAiService instance.
    final sharedAi = aiService ??
        NovaRuntimeGraphService.instance.resolveSharedAi(
          requester: 'nova_core_turn_controller',
          factory: () => NovaRuntimeGraphService.buildAiService(
            localModelService: const LocalModelService(),
            apiService: ApiService(
              isApiConfigured: apiConfigured,
              hasAvailableBalance: apiConfigured,
              provider: settings.activeAiProvider,
              apiKey: settings.apiKey.trim(),
              model: settings.activeApiModel.trim(),
            ),
            persona: const NovaPersona(),
            responseStyle: const ResponseStyle(),
          ),
        );

    final brainInput = NovaBrainInput(
      text: input,
      source: _sourceKey(turn.source),
      mode: turn.source == NovaTurnSource.setupPanel ? 'setup' : 'coreTurn',
      primaryTurn: true,
      allowFallbackSpeech: false,
      requiresLocalModel: false,
      metadata: <String, dynamic>{
        ...turn.context,
        'turnId': turnId,
        'usedCoreTurnController': true,
        'usedSharedNovaAiService': true,
        'directApiUsed': false,
        'inputSource': turn.source.name,
        'requestedByVoice': turn.requestedByVoice,
      },
    );

    final baseRequest = AiRequest(
      prompt: input,
      mode: AiMode.apiOnly,
      internetAllowed: true,
      isResearchRequest: turn.context['isResearchRequest'] == true,
      isSelfLearningRequest: turn.context['isSelfLearningRequest'] == true,
      isFastResponsePriority: turn.context['isResearchRequest'] != true,
      isUserApprovedApiUsage: true,
      requestedByVoice: turn.requestedByVoice,
      requestOrigin: _requestOrigin(turn.source),
      userInitiated: turn.userInitiated,
      userConfirmedThisAction: true,
      activeProviderKey: settings.activeAiProvider.key,
      activeModelId: settings.activeApiModel,
      metadata: <String, dynamic>{
        ...turn.context,
        'turnId': turnId,
        'assistantName': 'Nova',
        'runtime': 'apk_only_no_local_server',
        'source': 'nova_core_turn_controller',
        'directApiUsed': false,
        'usedCoreTurnController': true,
        'usedSharedNovaAiService': true,
      },
    );

    final envelope = await NovaSingleBrainAuthorityService.instance.handleInput(
      input: brainInput,
      baseRequest: baseRequest,
      mode: AiMode.apiOnly,
      runAi: sharedAi.process,
    );

    return NovaCoreTurnResult(
      response: envelope.response,
      finalText: envelope.finalText,
      allowedToSpeak: envelope.allowedToSpeak,
      ttsSource: envelope.ttsSource,
      trace: <String, dynamic>{
        ...envelope.metadata,
        'turnId': turnId,
        'usedCoreTurnController': true,
        'usedSharedNovaAiService': true,
        'directApiUsed': false,
        'selectedRoute': 'shared_nova_ai_service',
        'source': _sourceKey(turn.source),
        'provider': settings.activeAiProvider.key,
        'model': settings.activeApiModel,
      },
    );
  }

  String _requestOrigin(NovaTurnSource source) {
    switch (source) {
      case NovaTurnSource.dashboardVoice:
        return 'dashboard_stt';
      case NovaTurnSource.continuousListening:
        return 'background_authorized_voice';
      case NovaTurnSource.callEvent:
        return 'call_companion_authorized_voice';
      case NovaTurnSource.reminderEvent:
        return 'reminder_runtime_event';
      case NovaTurnSource.setupPanel:
        return 'setup_panel';
      case NovaTurnSource.dashboardText:
        return 'dashboard_text';
    }
  }

  String _sourceKey(NovaTurnSource source) {
    switch (source) {
      case NovaTurnSource.dashboardText:
        return 'dashboard_text';
      case NovaTurnSource.dashboardVoice:
        return 'dashboard_voice';
      case NovaTurnSource.setupPanel:
        return 'setup_panel';
      case NovaTurnSource.continuousListening:
        return 'continuous_listening';
      case NovaTurnSource.reminderEvent:
        return 'reminder_event';
      case NovaTurnSource.callEvent:
        return 'call_event';
    }
  }
}
