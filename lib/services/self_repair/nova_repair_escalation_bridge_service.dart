// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_const_constructors, prefer_const_literals_to_create_immutables
// GEMMA95952_SAFE_SELF_REPAIR_KERNEL_V3
import '../../core/self_repair/nova_repair_manifest.dart';
import '../security/nova_escalation_sanity_service.dart';
import '../security/nova_persistent_state_guard_service.dart';
import '../security/nova_security_kernel_service.dart';

class NovaRepairEscalationBridgeService {
  final NovaSecurityKernelService? securityKernelService;

  const NovaRepairEscalationBridgeService({this.securityKernelService});

  Future<NovaSecurityKernelService> _kernel() async {
    final existing = securityKernelService;
    if (existing != null) {
      await existing.restore();
      return existing;
    }
    final kernel = NovaSecurityKernelService(
      persistenceService: const NovaPersistentStateGuardService(),
      escalationService: const NovaEscalationSanityService(),
    );
    await kernel.restore();
    return kernel;
  }

  Future<void> notifyDenied({
    required NovaRepairManifest manifest,
    required String reason,
    required bool hardSecurityRisk,
  }) async {
    if (!hardSecurityRisk) {
      // Eşik bekleme, owner onayı eksikliği veya normal gateway reddi
      // security escalation'a taşınmaz. Bu olaylar AuditLedger'da kalır.
      return;
    }
    final kernel = await _kernel();
    await kernel.registerSystemTamperEvent(
      ruleKey: 'self_repair_hard_deny_${manifest.targetPolicy.key}',
      message: reason,
      severity: 92,
      confirmedDanger: true,
    );
  }

  Future<void> notifyAllowedLowRisk({
    required NovaRepairManifest manifest,
  }) async {
    final kernel = await _kernel();
    await kernel.registerUserDrivenEvent(
      ruleKey: 'self_repair_allowed_${manifest.targetPolicy.key}',
      message:
          'Düşük/sınırlı self-repair policy düzeltmesi güvenlik kapısından geçti.',
      severity: 8,
      confirmedDanger: false,
      userExplicitlyTriggered: true,
    );
  }
}
