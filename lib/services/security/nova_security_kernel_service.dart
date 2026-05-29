// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/security/nova_security_event.dart';
import '../../core/security/nova_security_state.dart';
import '../../core/security/nova_security_verdict.dart';
import '../../core/security/nova_threat_source.dart';
import 'nova_escalation_sanity_service.dart';
import 'nova_persistent_state_guard_service.dart';

class NovaSecurityKernelService {
  final NovaPersistentStateGuardService persistenceService;
  final NovaEscalationSanityService escalationService;

  NovaSecurityState _state = NovaSecurityState.initial();

  NovaSecurityKernelService({
    required this.persistenceService,
    required this.escalationService,
  });

  NovaSecurityState get state => _state;

  Future<void> restore() async {
    _state = await persistenceService.restore();
  }

  NovaSecurityVerdict getCurrentVerdict() {
    return escalationService.buildVerdict(_state);
  }

  Future<NovaSecurityVerdict> registerUserDrivenEvent({
    required String ruleKey,
    required String message,
    int severity = 20,
    bool confirmedDanger = false,
    bool userExplicitlyTriggered = true,
  }) async {
    final event = NovaSecurityEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ruleKey: ruleKey.trim(),
      source: NovaThreatSource.userDriven,
      confirmedDanger: confirmedDanger,
      userExplicitlyTriggered: userExplicitlyTriggered,
      severity: severity.clamp(0, 100),
      message: message.trim(),
      createdAt: DateTime.now(),
    );

    return _applyEvent(event);
  }

  Future<NovaSecurityVerdict> registerAiSelfInitiatedEvent({
    required String ruleKey,
    required String message,
    required int severity,
    bool confirmedDanger = true,
  }) async {
    final event = NovaSecurityEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ruleKey: ruleKey.trim(),
      source: NovaThreatSource.aiSelfInitiated,
      confirmedDanger: confirmedDanger,
      userExplicitlyTriggered: false,
      severity: severity.clamp(0, 100),
      message: message.trim(),
      createdAt: DateTime.now(),
    );

    return _applyEvent(event);
  }

  Future<NovaSecurityVerdict> registerSystemTamperEvent({
    required String ruleKey,
    required String message,
    int severity = 90,
    bool confirmedDanger = true,
  }) async {
    final event = NovaSecurityEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ruleKey: ruleKey.trim(),
      source: NovaThreatSource.systemTamper,
      confirmedDanger: confirmedDanger,
      userExplicitlyTriggered: false,
      severity: severity.clamp(0, 100),
      message: message.trim(),
      createdAt: DateTime.now(),
    );

    return _applyEvent(event);
  }

  Future<NovaSecurityVerdict> registerNativeGuardEvent({
    required String ruleKey,
    required String message,
    int severity = 95,
    bool confirmedDanger = true,
  }) async {
    final event = NovaSecurityEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ruleKey: ruleKey.trim(),
      source: NovaThreatSource.nativeGuard,
      confirmedDanger: confirmedDanger,
      userExplicitlyTriggered: false,
      severity: severity.clamp(0, 100),
      message: message.trim(),
      createdAt: DateTime.now(),
    );

    return _applyEvent(event);
  }

  Future<void> resetByOwnerRecoveryOnly() async {
    _state = NovaSecurityState.initial();
    await persistenceService.save(_state);
  }

  Future<NovaSecurityVerdict> _applyEvent(NovaSecurityEvent event) async {
    final result = escalationService.applyEvent(current: _state, event: event);

    _state = result.nextState;
    await persistenceService.save(_state);
    return result.verdict;
  }
}
