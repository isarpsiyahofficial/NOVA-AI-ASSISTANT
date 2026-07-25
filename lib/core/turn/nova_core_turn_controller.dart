import '../ai/ai_mode.dart';
import '../ai/ai_request.dart';
import '../ai/ai_response.dart';
import '../ai/nova_ai_service.dart';
import '../settings/nova_settings.dart';
import '../../services/runtime/nova_runtime_graph_service.dart';
import '../../services/runtime/nova_single_brain_authority_service.dart';
import 'nova_turn_authority.dart';
import 'nova_turn_lease.dart';

// NOVA_CORE_TURN_CONTROLLER_V4_TYPED_AUTHORITY_LEASE
// The controller is the only normal user-turn entry point. It never creates a
// fallback AI root and it never derives authority from mutable metadata.

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
  final bool userConfirmedThisAction;
  final NovaTurnAuthority authority;
  final Map<String, dynamic> context;

  const NovaCoreTurnRequest({
    required this.inputText,
    required this.source,
    required this.settings,
    this.requestedByVoice = false,
    this.userInitiated = false,
    this.userConfirmedThisAction = false,
    this.authority = const NovaTurnAuthority.unverified(),
    this.context = const <String, dynamic>{},
  });
}

class NovaCoreTurnResult {
  final AiResponse response;
  final String finalText;
  final bool allowedToSpeak;
  final String ttsSource;
  final NovaTurnLease lease;
  final Map<String, dynamic> trace;

  const NovaCoreTurnResult({
    required this.response,
    required this.finalText,
    required this.allowedToSpeak,
    required this.ttsSource,
    required this.lease,
    this.trace = const <String, dynamic>{},
  });
}

class NovaCoreTurnController {
  final NovaAiService? aiService;

  const NovaCoreTurnController({this.aiService});

  Future<NovaCoreTurnResult> processUserTurn(NovaCoreTurnRequest turn) async {
    final input = turn.inputText.trim();
    if (input.isEmpty) {
      throw ArgumentError.value(turn.inputText, 'inputText', 'Boş tur başlatılamaz.');
    }

    final sessionId = turn.context['sessionId']?.toString().trim().isNotEmpty ==
            true
        ? turn.context['sessionId'].toString().trim()
        : 'nova_session';
    final lease = NovaTurnLeaseController.instance.begin(sessionId: sessionId);
    final turnId = lease.id;
    final authority = turn.authority.isVerified
        ? turn.authority
        : const NovaTurnAuthority.unverified();
    final sharedAi = aiService ?? NovaRuntimeGraphService.instance.sharedAiOrThrow;

    final brainInput = NovaBrainInput(
      text: input,
      source: _sourceKey(turn.source),
      mode: turn.source == NovaTurnSource.setupPanel ? 'setup' : 'coreTurn',
      speakerName: turn.context['speakerName']?.toString().trim() ?? '',
      speakerVoiceId: authority.ownerVoiceId,
      relationshipLabel: authority.kind.name,
      ownerConfidence: authority.ownerConfidence,
      authority: authority,
      lease: lease,
      primaryTurn: true,
      allowFallbackSpeech: false,
      requiresLocalModel: false,
      metadata: <String, dynamic>{
        ...turn.context,
        'turnId': turnId,
        'turnLease': lease.toAuditMap(),
        'typedAuthority': authority.toAuditMap(),
        'usedCoreTurnController': true,
        'usedSharedNovaAiService': true,
        'directApiUsed': false,
        'inputSource': turn.source.name,
        'requestedByVoice': turn.requestedByVoice,
      },
    );

    final baseRequest = AiRequest(
      prompt: input,
      originalUserText: input,
      mode: AiMode.apiOnly,
      internetAllowed: true,
      isResearchRequest: turn.context['isResearchRequest'] == true,
      isSelfLearningRequest: turn.context['isSelfLearningRequest'] == true,
      isFastResponsePriority: turn.context['isResearchRequest'] != true,
      isUserApprovedApiUsage: true,
      isScreenLocked: turn.context['screenLocked'] == true,
      requestedByVoice: turn.requestedByVoice,
      requestOrigin: _requestOrigin(turn.source),
      userInitiated: turn.userInitiated,
      userConfirmedThisAction: turn.userConfirmedThisAction,
      activeProviderKey: turn.settings.activeAiProvider.key,
      activeModelId: turn.settings.activeApiModel,
      authority: authority,
      lease: lease,
      metadata: <String, dynamic>{
        ...turn.context,
        'turnId': turnId,
        'assistantName': 'Nova',
        'runtime': 'apk_only_no_local_server',
        'source': 'nova_core_turn_controller',
        'directApiUsed': false,
        'usedCoreTurnController': true,
        'usedSharedNovaAiService': true,
        'turnLease': lease.toAuditMap(),
        'typedAuthority': authority.toAuditMap(),
      },
    );

    final envelope = await NovaSingleBrainAuthorityService.instance.handleInput(
      input: brainInput,
      baseRequest: baseRequest,
      mode: AiMode.apiOnly,
      runAi: sharedAi.process,
    );
    if (!NovaTurnLeaseController.instance.isCurrent(lease)) {
      throw StateError('Tur tamamlanmadan önce geçersiz kaldı; eski cevap atıldı.');
    }

    return NovaCoreTurnResult(
      response: envelope.response,
      finalText: envelope.finalText,
      allowedToSpeak: envelope.allowedToSpeak,
      ttsSource: envelope.ttsSource,
      lease: lease,
      trace: <String, dynamic>{
        ...envelope.metadata,
        'turnId': turnId,
        'turnLease': lease.toAuditMap(),
        'typedAuthority': authority.toAuditMap(),
        'usedCoreTurnController': true,
        'usedSharedNovaAiService': true,
        'directApiUsed': false,
        'selectedRoute': 'shared_nova_ai_service',
        'source': _sourceKey(turn.source),
        'provider': turn.settings.activeAiProvider.key,
        'model': turn.settings.activeApiModel,
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

  String _sourceKey(NovaTurnSource source) => source.name;
}
