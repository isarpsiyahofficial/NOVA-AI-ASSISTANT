// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_const_constructors, prefer_const_literals_to_create_immutables
// GEMMA95952_SELF_REPAIR_SAFE_KERNEL_V4
import '../../core/self_repair/nova_repair_manifest.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import '../runtime/nova_ai_turn_queue_service.dart';
import 'nova_repair_audit_ledger_service.dart';
import 'nova_repair_gateway_service.dart';
import 'nova_repair_policy_store_service.dart';
import 'nova_repair_runtime_policy_enforcer_service.dart';
import 'nova_runtime_signal_service.dart';

class NovaRepairExecutionResult {
  final bool applied;
  final bool needsOwnerApproval;
  final bool hardDenied;
  final bool runtimeEffectApplied;
  final String message;

  const NovaRepairExecutionResult({
    required this.applied,
    required this.needsOwnerApproval,
    required this.hardDenied,
    required this.runtimeEffectApplied,
    required this.message,
  });
}

class NovaRepairExecutorService {
  final NovaRepairGatewayService gatewayService;
  final NovaRepairAuditLedgerService auditLedgerService;
  final NovaRuntimeSignalService? _runtimeSignalService;
  final NovaRepairPolicyStoreService policyStoreService;
  final NovaAiTurnQueueService? _aiTurnQueueService;
  final NovaRepairRuntimePolicyEnforcerService runtimePolicyEnforcerService;

  const NovaRepairExecutorService({
    this.gatewayService = const NovaRepairGatewayService(),
    this.auditLedgerService = const NovaRepairAuditLedgerService(),
    this.policyStoreService = const NovaRepairPolicyStoreService(),
    this.runtimePolicyEnforcerService =
        const NovaRepairRuntimePolicyEnforcerService(),
    NovaAiTurnQueueService? aiTurnQueueService,
    NovaRuntimeSignalService? runtimeSignalService,
  }) : _aiTurnQueueService = aiTurnQueueService,
       _runtimeSignalService = runtimeSignalService;

  NovaRuntimeSignalService get runtimeSignalService =>
      _runtimeSignalService ?? NovaRuntimeSignalService.instance;

  NovaAiTurnQueueService get aiTurnQueueService =>
      _aiTurnQueueService ?? NovaAiTurnQueueService.instance;

  Future<NovaRepairExecutionResult> execute(NovaRepairManifest manifest) async {
    final gateway = await gatewayService.evaluate(manifest);
    if (!gateway.allowed) {
      await auditLedgerService.record(
        category: gateway.hardDenied
            ? 'repair_hard_denied'
            : 'repair_not_applied',
        title: gateway.hardDenied ? 'Repair hard deny' : 'Repair uygulanmadı',
        detail: gateway.reason,
        manifest: manifest,
        securityDecision: gateway.hardDenied ? 'hard_denied' : 'not_allowed',
        validationResult: gateway.needsOwnerApproval
            ? 'owner_approval_required'
            : 'blocked',
        aiAuthored: false,
        userApproved: manifest.ownerApproved,
      );
      return NovaRepairExecutionResult(
        applied: false,
        needsOwnerApproval: gateway.needsOwnerApproval,
        hardDenied: gateway.hardDenied,
        runtimeEffectApplied: false,
        message: gateway.reason,
      );
    }

    final safe = await _applyPolicy(manifest);
    final runtimeEffect = safe ? await _applyRuntimeEffect(manifest) : false;
    await auditLedgerService.record(
      category: safe ? 'repair_applied' : 'repair_rejected_by_executor',
      title: safe ? 'Repair policy uygulandı' : 'Executor repair reddetti',
      detail: safe
          ? 'İzinli lib runtime policy store güncellendi. Runtime etkisi: ${runtimeEffect ? 'uygulandı' : 'policy-consumer bekliyor'}.'
          : 'Gateway izin verse bile executor allowlist/sanitize kontrolünde reddetti.',
      manifest: manifest,
      securityDecision: safe ? 'executor_allowed' : 'executor_denied',
      validationResult: safe
          ? 'awaiting_independent_runtime_verification'
          : 'failed_before_apply',
      aiAuthored: false,
      userApproved: manifest.ownerApproved,
    );

    return NovaRepairExecutionResult(
      applied: safe,
      needsOwnerApproval: false,
      hardDenied: !safe,
      runtimeEffectApplied: runtimeEffect,
      message: safe
          ? 'Güvenli runtime policy repair uygulandı; bağımsız runtime doğrulama bekleniyor.'
          : 'Executor güvenlik sınırı nedeniyle repair uygulamadı.',
    );
  }

  Future<bool> _applyPolicy(NovaRepairManifest manifest) async {
    if (manifest.targetPolicy == NovaRepairTargetPolicy.none) return false;
    if (manifest.riskLevel == NovaRepairRiskLevel.red) return false;
    if (manifest.riskLevel == NovaRepairRiskLevel.yellow &&
        !manifest.ownerApproved)
      return false;

    final allowed =
        manifest.targetPolicy.isGreen ||
        (manifest.targetPolicy.isYellow && manifest.ownerApproved);
    if (!allowed) return false;

    final NovaRepairPolicySnapshot snapshot;
    try {
      snapshot = await policyStoreService.applyManifest(manifest);
      await runtimePolicyEnforcerService.refresh();
    } catch (_) {
      return false;
    }
    if (snapshot.activeValue ==
        NovaRepairPolicyStoreService.rejectedSecurityValue) {
      await policyStoreService.rollback(manifest);
      return false;
    }

    runtimeSignalService.record(
      kind: _kindFor(manifest.targetPolicy),
      level: NovaRuntimeSignalLevel.info,
      code: 'repair_policy_${manifest.targetPolicy.key}_applied',
      message: 'Güvenli self-repair policy store güncellendi.',
      technicalDetails:
          'manifest=${manifest.id} active=${snapshot.activeValue}',
      diagnosticCandidate: false,
      metadata: <String, dynamic>{
        'repairManifestId': manifest.id,
        'repairType': manifest.repairType,
        'targetPolicy': manifest.targetPolicy.key,
        'rollbackKey': manifest.rollbackKey,
        'activeValue': snapshot.activeValue,
        'source': 'repair_executor',
      },
    );
    return true;
  }

  Future<bool> _applyRuntimeEffect(NovaRepairManifest manifest) async {
    switch (manifest.targetPolicy) {
      case NovaRepairTargetPolicy.queueStalePolicy:
        final cleared = aiTurnQueueService.clearWaitingStale(
          reason: manifest.id,
        );
        await runtimeSignalService.record(
          kind: NovaRuntimeSignalKind.ai,
          level: NovaRuntimeSignalLevel.info,
          code: 'STALE_TURN_DROPPED',
          message: 'Stale AI turn kuyruğu güvenli şekilde temizlendi.',
          technicalDetails:
              'cleared=$cleared epoch=${aiTurnQueueService.repairEpoch}',
          diagnosticCandidate: false,
          metadata: <String, dynamic>{
            'source': 'queue_runtime_policy_enforcer',
            'targetPolicy': manifest.targetPolicy.key,
          },
        );
        return true;
      case NovaRepairTargetPolicy.ttsSourcePolicy:
      case NovaRepairTargetPolicy.fallbackSpeechPolicy:
      case NovaRepairTargetPolicy.asrSingleBrainRoutePolicy:
      case NovaRepairTargetPolicy.modelRetryPolicy:
      case NovaRepairTargetPolicy.memoryRetrievalPolicy:
      case NovaRepairTargetPolicy.modeTransitionPolicy:
      case NovaRepairTargetPolicy.setupRuntimeBoundaryPolicy:
      case NovaRepairTargetPolicy.toolRoutingPolicy:
      case NovaRepairTargetPolicy.callBehaviorPolicy:
      case NovaRepairTargetPolicy.personaDigestPolicy:
      case NovaRepairTargetPolicy.responseLengthPolicy:
      case NovaRepairTargetPolicy.contextCompactPolicy:
        // Bu policy'ler gerçek runtime consumer tarafından uygulanır. Executor burada
        // başarı sinyali üretmez; VerificationLoop yalnız bağımsız consumer sinyalini
        // başarı sayar. Böylece sahte doğrulama oluşmaz.
        await runtimePolicyEnforcerService.refresh();
        return false;
      case NovaRepairTargetPolicy.none:
        return false;
    }
  }

  NovaRuntimeSignalKind _kindFor(NovaRepairTargetPolicy target) {
    switch (target) {
      case NovaRepairTargetPolicy.ttsSourcePolicy:
      case NovaRepairTargetPolicy.fallbackSpeechPolicy:
        return NovaRuntimeSignalKind.tts;
      case NovaRepairTargetPolicy.asrSingleBrainRoutePolicy:
        return NovaRuntimeSignalKind.stt;
      case NovaRepairTargetPolicy.modelRetryPolicy:
        return NovaRuntimeSignalKind.localModel;
      case NovaRepairTargetPolicy.memoryRetrievalPolicy:
        return NovaRuntimeSignalKind.memory;
      case NovaRepairTargetPolicy.callBehaviorPolicy:
        return NovaRuntimeSignalKind.call;
      default:
        return NovaRuntimeSignalKind.ai;
    }
  }
}
