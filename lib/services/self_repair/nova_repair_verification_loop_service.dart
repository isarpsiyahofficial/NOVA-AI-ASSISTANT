// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_const_literals_to_create_immutables
// GEMMA95952_SELF_REPAIR_SAFE_KERNEL_V4
import '../../core/self_repair/nova_repair_manifest.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import 'nova_repair_audit_ledger_service.dart';
import 'nova_repair_policy_store_service.dart';
import 'nova_runtime_signal_service.dart';

enum NovaRepairVerificationStatus { passed, pending, failed }

class NovaRepairVerificationResult {
  final bool success;
  final bool shouldRollback;
  final NovaRepairVerificationStatus status;
  final String message;

  const NovaRepairVerificationResult({
    required this.success,
    required this.shouldRollback,
    required this.status,
    required this.message,
  });
}

class NovaRepairVerificationLoopService {
  final NovaRuntimeSignalService? _runtimeSignalService;
  final NovaRepairAuditLedgerService auditLedgerService;
  final NovaRepairPolicyStoreService policyStoreService;

  const NovaRepairVerificationLoopService({
    NovaRuntimeSignalService? runtimeSignalService,
    this.auditLedgerService = const NovaRepairAuditLedgerService(),
    this.policyStoreService = const NovaRepairPolicyStoreService(),
  }) : _runtimeSignalService = runtimeSignalService;

  NovaRuntimeSignalService get runtimeSignalService =>
      _runtimeSignalService ?? NovaRuntimeSignalService.instance;

  Future<NovaRepairVerificationResult> verify(
    NovaRepairManifest manifest,
  ) async {
    final signals = await runtimeSignalService.getAll();
    final snapshot = await policyStoreService.getPolicy(manifest.targetPolicy);
    final expected = manifest.expectedSignal.trim().toLowerCase();
    final policyApplied =
        snapshot != null &&
        snapshot.manifestId == manifest.id &&
        snapshot.activeValue.trim().isNotEmpty &&
        snapshot.activeValue !=
            NovaRepairPolicyStoreService.rejectedSecurityValue;

    if (!policyApplied) {
      final result = const NovaRepairVerificationResult(
        success: false,
        shouldRollback: true,
        status: NovaRepairVerificationStatus.failed,
        message:
            'Repair policy store uygulanmadı veya güvenlik nedeniyle reddedildi.',
      );
      await _record(manifest, result);
      return result;
    }

    final runtimeSignals = signals
        .where((signal) => !_isSelfGeneratedRepairSignal(signal, manifest))
        .where(
          (signal) => !signal.createdAt.isBefore(
            manifest.createdAt.subtract(const Duration(seconds: 2)),
          ),
        )
        .toList(growable: false);

    final expectedSignalSeen =
        expected.isNotEmpty &&
        runtimeSignals.take(80).any((signal) {
          final text =
              '${signal.code} ${signal.message} ${signal.technicalDetails}'
                  .toLowerCase();
          return text.contains(expected);
        });

    final negativeSignalSeen = runtimeSignals.take(80).any((signal) {
      if (signal.level != NovaRuntimeSignalLevel.error &&
          signal.level != NovaRuntimeSignalLevel.critical) {
        return false;
      }
      final text = '${signal.code} ${signal.message} ${signal.technicalDetails}'
          .toLowerCase();
      return text.contains(manifest.targetPolicy.key.toLowerCase()) ||
          text.contains(manifest.faultType.key.toLowerCase()) ||
          text.contains('repair_regression') ||
          text.contains('rollback_required');
    });

    final NovaRepairVerificationResult result;
    if (expectedSignalSeen) {
      result = const NovaRepairVerificationResult(
        success: true,
        shouldRollback: false,
        status: NovaRepairVerificationStatus.passed,
        message: 'Repair sonrası bağımsız runtime sinyali doğrulandı.',
      );
    } else if (negativeSignalSeen) {
      result = const NovaRepairVerificationResult(
        success: false,
        shouldRollback: true,
        status: NovaRepairVerificationStatus.failed,
        message:
            'Repair sonrası negatif runtime sinyali görüldü; rollback gerekir.',
      );
    } else {
      result = const NovaRepairVerificationResult(
        success: false,
        shouldRollback: false,
        status: NovaRepairVerificationStatus.pending,
        message:
            'Repair policy uygulandı; bağımsız runtime doğrulaması bekleniyor. Sahte başarı sayılmadı.',
      );
    }

    await _record(manifest, result);
    return result;
  }

  bool _isSelfGeneratedRepairSignal(
    NovaRuntimeSignal signal,
    NovaRepairManifest manifest,
  ) {
    if (signal.code.toLowerCase().startsWith('repair_policy_')) return true;
    if ((signal.metadata['repairManifestId']?.toString() ?? '') == manifest.id)
      return true;
    final source = signal.metadata['source']?.toString().toLowerCase() ?? '';
    return source.contains('repair_executor') ||
        source.contains('repair_gateway');
  }

  Future<void> _record(
    NovaRepairManifest manifest,
    NovaRepairVerificationResult result,
  ) async {
    await auditLedgerService.record(
      category: result.status == NovaRepairVerificationStatus.passed
          ? 'repair_validation_success'
          : (result.status == NovaRepairVerificationStatus.failed
                ? 'repair_validation_failed'
                : 'repair_validation_pending'),
      title: result.status == NovaRepairVerificationStatus.passed
          ? 'Repair doğrulandı'
          : (result.status == NovaRepairVerificationStatus.failed
                ? 'Repair doğrulaması başarısız'
                : 'Repair bağımsız doğrulama bekliyor'),
      detail: result.message,
      manifest: manifest,
      securityDecision: 'post_apply_verification',
      validationResult: result.status.name,
      aiAuthored: false,
      userApproved: manifest.ownerApproved,
    );
  }
}
