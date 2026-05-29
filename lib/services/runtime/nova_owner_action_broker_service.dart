// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/security/nova_native_security_snapshot.dart';
import 'nova_runtime_orchestrator_service.dart';
import '../security/nova_native_security_bridge_service.dart';

class NovaOwnerActionBrokerResult {
  final bool handled;
  final bool success;
  final String spokenText;
  final String actionSummary;
  final Map<String, dynamic> actionSummaryJson;
  final NovaRuntimeOrchestratorResult? runtimeResult;

  NovaOwnerActionBrokerResult({
    required this.handled,
    required this.success,
    String spokenText = '',
    String actionSummary = '',
    Map<String, dynamic>? actionSummaryJson,
    this.runtimeResult,
  }) : spokenText = '',
       actionSummary = '',
       actionSummaryJson = Map<String, dynamic>.unmodifiable(
         actionSummaryJson ??
             <String, dynamic>{
               'handled': handled,
               'success': success,
               'safeToSummarizeToUser': true,
             },
       );

  const NovaOwnerActionBrokerResult.unhandled()
    : handled = false,
      success = false,
      spokenText = '',
      actionSummary = '',
      actionSummaryJson = const <String, dynamic>{},
      runtimeResult = null;
}

class NovaOwnerActionBrokerService {
  final NovaRuntimeOrchestratorService? runtimeOrchestratorService;
  final NovaNativeSecurityBridgeService nativeSecurityBridgeService;

  const NovaOwnerActionBrokerService({
    required this.runtimeOrchestratorService,
    this.nativeSecurityBridgeService = const NovaNativeSecurityBridgeService(),
  });

  Future<NovaOwnerActionBrokerResult> tryExecuteApprovedAction({
    required String normalizedInput,
    required bool enabled,
  }) async {
    if (!enabled) return const NovaOwnerActionBrokerResult.unhandled();
    final runtimeService = runtimeOrchestratorService;
    if (runtimeService == null) {
      return const NovaOwnerActionBrokerResult.unhandled();
    }

    final securitySnapshot = await nativeSecurityBridgeService.getSnapshot();
    if (_runtimeBlocked(securitySnapshot)) {
      final message = securitySnapshot.message.trim().isEmpty
          ? 'Native security gate action surface is closed.'
          : securitySnapshot.message.trim();
      return NovaOwnerActionBrokerResult(
        handled: true,
        success: false,
        actionSummaryJson: <String, dynamic>{
          'handled': true,
          'success': false,
          'actionType': 'native_security_gate',
          'errorDetail': message,
          'safeToSummarizeToUser': true,
        },
      );
    }

    final runtimeResult = await runtimeService.tryHandle(normalizedInput);
    if (!runtimeResult.handled) {
      return const NovaOwnerActionBrokerResult.unhandled();
    }

    return NovaOwnerActionBrokerResult(
      handled: true,
      success: runtimeResult.success,
      actionSummaryJson: runtimeResult.actionSummaryJson,
      runtimeResult: runtimeResult,
    );
  }

  bool _runtimeBlocked(NovaNativeSecuritySnapshot snapshot) {
    return !snapshot.runtimeAllowed ||
        !snapshot.actionSurfaceAllowed ||
        !snapshot.nativeBridgeAllowed ||
        snapshot.blackoutActive ||
        snapshot.safeDecommissioned ||
        snapshot.finalDestroyed;
  }
}
