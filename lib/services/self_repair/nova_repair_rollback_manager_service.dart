// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_const_constructors, prefer_const_literals_to_create_immutables
// GEMMA95952_SAFE_SELF_REPAIR_KERNEL_V3
import '../../core/self_repair/nova_repair_manifest.dart';
import 'nova_repair_audit_ledger_service.dart';
import 'nova_repair_policy_store_service.dart';

class NovaRepairRollbackResult {
  final bool rolledBack;
  final String message;

  const NovaRepairRollbackResult({
    required this.rolledBack,
    required this.message,
  });
}

class NovaRepairRollbackManagerService {
  final NovaRepairPolicyStoreService policyStoreService;
  final NovaRepairAuditLedgerService auditLedgerService;

  const NovaRepairRollbackManagerService({
    this.policyStoreService = const NovaRepairPolicyStoreService(),
    this.auditLedgerService = const NovaRepairAuditLedgerService(),
  });

  Future<NovaRepairRollbackResult> rollback(
    NovaRepairManifest manifest, {
    required String reason,
  }) async {
    final rolledBack = await policyStoreService.rollback(manifest);
    await auditLedgerService.record(
      category: rolledBack
          ? 'repair_rollback_applied'
          : 'repair_rollback_not_available',
      title: rolledBack
          ? 'Repair rollback uygulandı'
          : 'Repair rollback uygulanamadı',
      detail: reason,
      manifest: manifest,
      securityDecision: 'rollback_manager',
      validationResult: rolledBack ? 'rolled_back' : 'rollback_missing',
      aiAuthored: false,
      userApproved: manifest.ownerApproved,
    );
    return NovaRepairRollbackResult(
      rolledBack: rolledBack,
      message: rolledBack
          ? 'Repair doğrulanamadı; önceki güvenli policy değerine rollback yapıldı.'
          : 'Repair doğrulanamadı; rollback snapshot bulunamadı.',
    );
  }
}
