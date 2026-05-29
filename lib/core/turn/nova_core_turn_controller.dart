import '../ai/ai_mode.dart';
import '../ai/ai_request.dart';
import '../ai/ai_response.dart';
import '../settings/nova_settings.dart';
import '../../services/api/api_service.dart';
import '../../services/runtime/nova_single_brain_authority_service.dart';

// NOVA_CORE_TURN_CONTROLLER_V1
// Single, auditable entry point for normal Nova user turns.
// UI/setup/voice surfaces must not call ApiService directly.

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
  const NovaCoreTurnController();

  Future<NovaCoreTurnResult> processUserTurn(NovaCoreTurnRequest turn) async {
    final input = turn.inputText.trim();
    final turnId = turn.context['turnId']?.toString().trim().isNotEmpty == true
        ? turn.context['turnId'].toString().trim()
        : 'nova_core_${DateTime.now().microsecondsSinceEpoch}';
    final settings = turn.settings;
    final apiConfigured =
        settings.apiBrainEnabled && settings.apiKey.trim().isNotEmpty;
    final apiService = ApiService(
      isApiConfigured: apiConfigured,
      hasAvailableBalance: apiConfigured,
      provider: settings.activeAiProvider,
      apiKey: settings.apiKey.trim(),
      model: settings.activeApiModel.trim(),
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
        'directApiUsed': false,
        'inputSource': turn.source.name,
        'requestedByVoice': turn.requestedByVoice,
      },
    );

    final baseRequest = AiRequest(
      prompt: input,
      mode: AiMode.apiOnly,
      internetAllowed: true,
      isResearchRequest: false,
      isSelfLearningRequest: false,
      isFastResponsePriority: true,
      isUserApprovedApiUsage: true,
      requestedByVoice: turn.requestedByVoice,
      requestOrigin: turn.requestedByVoice
          ? 'dashboard_stt'
          : 'dashboard_manual_voice_entry',
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
      },
    );

    final envelope = await NovaSingleBrainAuthorityService.instance.handleInput(
      input: brainInput,
      baseRequest: baseRequest,
      mode: AiMode.apiOnly,
      runAi: apiService.send,
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
        'directApiUsed': false,
        'selectedRoute': 'nova_core_turn_controller',
        'source': _sourceKey(turn.source),
        'provider': settings.activeAiProvider.key,
        'model': settings.activeApiModel,
      },
    );
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
