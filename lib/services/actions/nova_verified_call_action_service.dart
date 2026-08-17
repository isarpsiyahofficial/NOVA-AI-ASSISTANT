// NOVA_VERIFIED_CALL_ACTION_ROUTER_V1
// All runtime-originated call controls pass through the same typed policy,
// immutable intent binding, native bridge and postcondition verification chain
// used by provider tool calls.

import '../../core/actions/nova_device_action.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/ai/ai_request.dart';
import '../../core/turn/nova_turn_authority.dart';
import '../../core/turn/nova_turn_lease.dart';
import 'nova_device_action_executor_service.dart';

class NovaVerifiedCallActionService {
  final NovaDeviceActionExecutorService executor;

  const NovaVerifiedCallActionService({
    this.executor = const NovaDeviceActionExecutorService(),
  });

  Future<NovaDeviceActionResult> execute({
    required String action,
    required String immutableTranscript,
    required NovaTurnAuthority authority,
    required NovaTurnLease lease,
    required String requestOrigin,
    bool screenLocked = false,
    String value = '',
    String providerCallId = 'runtime_verified_call_action',
  }) {
    final request = AiRequest(
      prompt: immutableTranscript,
      originalUserText: immutableTranscript,
      mode: AiMode.apiOnly,
      internetAllowed: false,
      isUserApprovedApiUsage: false,
      requestedByVoice: authority.kind == NovaTurnAuthorityKind.ownerVoice,
      requestOrigin: requestOrigin,
      userInitiated: authority.localUserPresence || authority.ownerVoiceVerified,
      userConfirmedThisAction: true,
      isScreenLocked: screenLocked,
      authority: authority,
      lease: lease,
      metadata: <String, dynamic>{
        'source': 'nova_verified_call_action_service',
        'runtimeVerifiedCallAction': true,
        'turnLease': lease.toAuditMap(),
        'typedAuthority': authority.toAuditMap(),
        'disableDeviceTools': true,
      },
    );
    return executor.execute(
      call: NovaDeviceActionCall(
        action: action,
        value: value,
        providerCallId: providerCallId,
      ),
      request: request,
    );
  }

  Future<NovaDeviceActionResult> executeCompanion({
    required String action,
    required String immutableEventText,
    required String evidenceId,
    bool screenLocked = false,
    String value = '',
  }) {
    final lease = NovaTurnLeaseController.instance.begin(
      sessionId: 'call_companion_runtime',
      lifetime: const Duration(seconds: 30),
    );
    final authority = NovaTurnAuthority.companion(
      evidenceId: evidenceId,
      lifetime: const Duration(seconds: 30),
    );
    return execute(
      action: action,
      immutableTranscript: immutableEventText,
      authority: authority,
      lease: lease,
      requestOrigin: 'call_companion_authorized_voice',
      screenLocked: screenLocked,
      value: value,
      providerCallId: 'companion_${lease.sequence}_$action',
    );
  }
}
