// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_const_constructors, prefer_const_literals_to_create_immutables
// GEMMA95952_SELF_REPAIR_SAFE_KERNEL_V4
import '../../core/self_repair/nova_repair_manifest.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import 'nova_boot_doctor_service.dart';
import 'nova_fault_classifier_service.dart';
import 'nova_local_brain_repair_agent_service.dart';
import 'nova_repair_audit_ledger_service.dart';
import 'nova_repair_executor_service.dart';
import 'nova_repair_rollback_manager_service.dart';
import 'nova_repair_verification_loop_service.dart';
import 'nova_runtime_signal_service.dart';

class NovaSelfRepairSafeKernelResult {
  final bool applied;
  final bool verificationPassed;
  final bool verificationPending;
  final bool needsOwnerApproval;
  final bool hardDenied;
  final String message;

  const NovaSelfRepairSafeKernelResult({
    required this.applied,
    required this.verificationPassed,
    required this.verificationPending,
    required this.needsOwnerApproval,
    required this.hardDenied,
    required this.message,
  });
}

class NovaSelfRepairSafeKernelService {
  final NovaBootDoctorService bootDoctorService;
  final NovaFaultClassifierService faultClassifierService;
  final NovaLocalBrainRepairAgentService repairAgentService;
  final NovaRepairExecutorService repairExecutorService;
  final NovaRepairVerificationLoopService verificationLoopService;
  final NovaRepairRollbackManagerService rollbackManagerService;
  final NovaRepairAuditLedgerService auditLedgerService;
  final NovaRuntimeSignalService? _runtimeSignalService;

  const NovaSelfRepairSafeKernelService({
    this.bootDoctorService = const NovaBootDoctorService(),
    this.faultClassifierService = const NovaFaultClassifierService(),
    this.repairAgentService = const NovaLocalBrainRepairAgentService(),
    this.repairExecutorService = const NovaRepairExecutorService(),
    this.verificationLoopService = const NovaRepairVerificationLoopService(),
    this.rollbackManagerService = const NovaRepairRollbackManagerService(),
    this.auditLedgerService = const NovaRepairAuditLedgerService(),
    NovaRuntimeSignalService? runtimeSignalService,
  }) : _runtimeSignalService = runtimeSignalService;

  NovaRuntimeSignalService get runtimeSignalService =>
      _runtimeSignalService ?? NovaRuntimeSignalService.instance;

  Future<NovaSelfRepairSafeKernelResult> run({
    bool ownerApproved = false,
  }) async {
    final boot = await bootDoctorService.inspectReadOnly();
    final signals = await runtimeSignalService.getAll();
    await auditLedgerService.record(
      category: 'bootdoctor_report',
      title: 'BootDoctor read-only raporu',
      detail: boot.toMap().toString(),
      securityDecision: 'read_only',
      validationResult: boot.bootLooksHealthy
          ? 'healthy'
          : 'needs_classification',
      aiAuthored: false,
      userApproved: ownerApproved,
    );

    final classification = faultClassifierService.classify(
      signals: signals,
      bootReport: boot,
    );
    final manifest = repairAgentService.proposeManifest(
      classification: classification,
      ownerApproved: ownerApproved,
    );
    if (manifest == null) {
      await auditLedgerService.record(
        category: 'repair_not_available',
        title: 'Güvenli repair adayı yok',
        detail: classification.reason,
        securityDecision: classification.riskLevel.key,
        validationResult: classification.faultType.key,
        aiAuthored: false,
        userApproved: ownerApproved,
      );
      return NovaSelfRepairSafeKernelResult(
        applied: false,
        verificationPassed: false,
        verificationPending: false,
        needsOwnerApproval: classification.riskLevel.key == 'yellow',
        hardDenied: classification.riskLevel.key == 'red',
        message: classification.reason,
      );
    }

    final execution = await repairExecutorService.execute(manifest);
    if (!execution.applied) {
      return NovaSelfRepairSafeKernelResult(
        applied: false,
        verificationPassed: false,
        verificationPending: false,
        needsOwnerApproval: execution.needsOwnerApproval,
        hardDenied: execution.hardDenied,
        message: execution.message,
      );
    }

    final verification = await verificationLoopService.verify(manifest);
    if (!verification.success && verification.shouldRollback) {
      final rollback = await rollbackManagerService.rollback(
        manifest,
        reason: verification.message,
      );
      return NovaSelfRepairSafeKernelResult(
        applied: false,
        verificationPassed: false,
        verificationPending: false,
        needsOwnerApproval: false,
        hardDenied: false,
        message: rollback.message,
      );
    }
    final pending = verification.status == NovaRepairVerificationStatus.pending;
    return NovaSelfRepairSafeKernelResult(
      applied: true,
      verificationPassed: verification.success,
      verificationPending: pending,
      needsOwnerApproval: false,
      hardDenied: false,
      message: verification.message,
    );
  }

  bool _hasRepeatedRepairSignal(List<NovaRuntimeSignal> signals) {
    final Map<String, int> counts = <String, int>{};
    for (final signal in signals.take(100)) {
      if (!signal.diagnosticCandidate &&
          signal.level == NovaRuntimeSignalLevel.info) {
        continue;
      }
      final root = _signalRoot(signal.code);
      counts[root] = (counts[root] ?? 0) + 1;
      if ((counts[root] ?? 0) >= 2) return true;
    }
    return false;
  }

  String _signalRoot(String code) {
    final parts = code
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .split('_')
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.length <= 2) return parts.join('_');
    return parts.take(2).join('_');
  }
}
