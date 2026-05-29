// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// GEMMA95952_SAFE_SELF_REPAIR_KERNEL
import '../../core/self_repair/nova_repair_manifest.dart';
import 'nova_repair_audit_ledger_service.dart';
import 'nova_repair_escalation_bridge_service.dart';

class NovaRepairGatewayDecision {
  final bool allowed;
  final bool needsOwnerApproval;
  final bool hardDenied;
  final String reason;

  const NovaRepairGatewayDecision({
    required this.allowed,
    required this.needsOwnerApproval,
    required this.hardDenied,
    required this.reason,
  });

  const NovaRepairGatewayDecision.allow(String reason)
    : allowed = true,
      needsOwnerApproval = false,
      hardDenied = false,
      reason = reason;

  const NovaRepairGatewayDecision.ownerApproval(String reason)
    : allowed = false,
      needsOwnerApproval = true,
      hardDenied = false,
      reason = reason;

  const NovaRepairGatewayDecision.deny(String reason)
    : allowed = false,
      needsOwnerApproval = false,
      hardDenied = false,
      reason = reason;

  const NovaRepairGatewayDecision.hardDeny(String reason)
    : allowed = false,
      needsOwnerApproval = false,
      hardDenied = true,
      reason = reason;
}

class NovaRepairGatewayService {
  final NovaRepairAuditLedgerService auditLedgerService;
  final NovaRepairEscalationBridgeService escalationBridgeService;

  const NovaRepairGatewayService({
    this.auditLedgerService = const NovaRepairAuditLedgerService(),
    this.escalationBridgeService = const NovaRepairEscalationBridgeService(),
  });

  Future<NovaRepairGatewayDecision> evaluate(
    NovaRepairManifest manifest,
  ) async {
    final decision = _evaluateSync(manifest);
    await auditLedgerService.record(
      category: decision.allowed
          ? 'repair_gateway_allowed'
          : 'repair_gateway_rejected',
      title: decision.allowed
          ? 'Repair Gateway izin verdi'
          : 'Repair Gateway reddetti',
      detail: decision.reason,
      manifest: manifest,
      securityDecision: decision.allowed
          ? 'allowed'
          : (decision.hardDenied ? 'hard_denied' : 'denied'),
      validationResult: 'gateway_checked',
      aiAuthored: false,
      userApproved: manifest.ownerApproved,
    );
    if (!decision.allowed) {
      await escalationBridgeService.notifyDenied(
        manifest: manifest,
        reason: decision.reason,
        hardSecurityRisk: decision.hardDenied,
      );
    } else {
      await escalationBridgeService.notifyAllowedLowRisk(manifest: manifest);
    }
    return decision;
  }

  NovaRepairGatewayDecision _evaluateSync(NovaRepairManifest manifest) {
    final combined = <String>[
      manifest.repairType,
      manifest.targetPolicy.key,
      manifest.oldValue,
      manifest.newValue,
      manifest.reason,
      manifest.rollbackKey,
      manifest.expectedSignal,
      manifest.proposedBy,
    ].join(' ').toLowerCase();

    const hardForbidden = <String>[
      'android/',
      'android\\',
      'androidmanifest',
      'manifest.xml',
      'kotlin',
      '.kt',
      '.java',
      'native',
      'methodchannel',
      'permission',
      'assets/',
      'assets\\',
      'model_loader',
      'model loader',
      'bootdoctor',
      'boot_doctor',
      'repairgateway',
      'repair_gateway',
      'auditledger',
      'audit_ledger',
      'rollbackmanager',
      'rollback_manager',
      'lib/security',
      'security shield',
      'security_shield',
      'security root',
      'security_root',
      'disable_security',
      'owner root',
      'owner_root',
      'kill-switch',
      'killswitch',
      'full shutdown',
      'quarantine root',
      'new file',
      'create file',
      'delete file',
      'rewrite file',
      'full rewrite',
      'script',
      'process.run',
      'process.start',
      'shell',
      'bash',
      'python',
      'dart:io',
      'file(',
      'directory(',
      'writeas',
      'chmod',
      'exec',
      'download code',
      'external code',
      'permission escalate',
      'escalate permission',
    ];

    for (final token in hardForbidden) {
      if (combined.contains(token)) {
        return NovaRepairGatewayDecision.hardDeny(
          'Hard deny: self-repair isteği kapalı kırmızı bölge veya icra kapısı içeriyor: $token',
        );
      }
    }

    if (manifest.id.trim().isEmpty || manifest.repairType.trim().isEmpty) {
      return const NovaRepairGatewayDecision.deny(
        'Repair manifest eksik: id/repairType boş.',
      );
    }

    if (manifest.targetPolicy == NovaRepairTargetPolicy.none) {
      return const NovaRepairGatewayDecision.hardDeny(
        'Repair hedefi izinli lib runtime policy allowlist içinde değil.',
      );
    }

    if (manifest.rollbackKey.trim().isEmpty) {
      return const NovaRepairGatewayDecision.deny(
        'Rollback anahtarı olmadan repair uygulanamaz.',
      );
    }

    if (manifest.repeatCount < _minimumRepeatFor(manifest)) {
      return NovaRepairGatewayDecision.deny(
        'Tek log/tek başarısızlık repair için yeterli değil. repeat=${manifest.repeatCount}',
      );
    }

    if (manifest.riskLevel == NovaRepairRiskLevel.red) {
      return const NovaRepairGatewayDecision.hardDeny(
        'Kırmızı bölge repair uygulanamaz; sadece raporlanır.',
      );
    }

    if (manifest.riskLevel == NovaRepairRiskLevel.yellow &&
        !manifest.ownerApproved) {
      return const NovaRepairGatewayDecision.ownerApproval(
        'Sarı bölge repair için owner onayı gerekir.',
      );
    }

    if (manifest.riskLevel == NovaRepairRiskLevel.green &&
        !manifest.targetPolicy.isGreen) {
      return const NovaRepairGatewayDecision.deny(
        'Yeşil risk beyanı target policy ile uyumlu değil.',
      );
    }

    if (manifest.riskLevel == NovaRepairRiskLevel.yellow &&
        !manifest.targetPolicy.isYellow) {
      return const NovaRepairGatewayDecision.deny(
        'Sarı risk beyanı target policy ile uyumlu değil.',
      );
    }

    return const NovaRepairGatewayDecision.allow(
      'Repair manifest izinli lib runtime policy sınırları içinde.',
    );
  }

  int _minimumRepeatFor(NovaRepairManifest manifest) {
    switch (manifest.faultType) {
      case NovaRepairFaultType.modelNotReady:
        return 2;
      case NovaRepairFaultType.ttsWrongSource:
      case NovaRepairFaultType.ttsNotSpeaking:
      case NovaRepairFaultType.transcriptNotRouted:
      case NovaRepairFaultType.asrNoTranscript:
        return 3;
      case NovaRepairFaultType.queueStaleTurn:
      case NovaRepairFaultType.fallbackContamination:
      case NovaRepairFaultType.securityFalsePositive:
        return 2;
      case NovaRepairFaultType.nativeChannelFail:
      case NovaRepairFaultType.realSecurityRisk:
      case NovaRepairFaultType.unknown:
        return 999;
    }
  }
}
