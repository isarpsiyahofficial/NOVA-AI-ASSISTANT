// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/ai/ai_request.dart';
import '../../core/security/nova_security_models.dart';
import 'nova_internet_security_orchestrator_service.dart';
import 'nova_native_security_bridge_service.dart';
import 'nova_prompt_affect_security_service.dart';
import 'nova_security_policy_service.dart';
import 'nova_security_diagnostic_mode_service.dart';
import 'nova_security_signal_scan_service.dart';
import 'nova_user_origin_security_service.dart';

class NovaAutonomousSecurityResult {
  final bool allowed;
  final bool blocked;
  final bool quarantined;
  final bool shouldStopModel;
  final bool shouldStopInternet;
  final String stage;
  final String normalStage;
  final String internetStage;
  final String spokenMessage;
  final NovaSecurityDecision policyDecision;
  final NovaPromptAffectScan affectScan;
  final List<String> triggeredObservers;
  final int quorum;

  const NovaAutonomousSecurityResult({
    required this.allowed,
    required this.blocked,
    required this.quarantined,
    required this.shouldStopModel,
    required this.shouldStopInternet,
    required this.stage,
    required this.normalStage,
    required this.internetStage,
    required this.spokenMessage,
    required this.policyDecision,
    required this.affectScan,
    required this.triggeredObservers,
    required this.quorum,
  });
}

class NovaAutonomousSecurityOrchestratorService {
  final NovaSecurityPolicyService policyService;
  final NovaPromptAffectSecurityService affectService;
  final NovaNativeSecurityBridgeService nativeBridgeService;
  final NovaInternetSecurityOrchestratorService internetSecurityService;

  NovaAutonomousSecurityOrchestratorService({
    NovaSecurityPolicyService? policyService,
    NovaPromptAffectSecurityService? affectService,
    NovaNativeSecurityBridgeService? nativeBridgeService,
    NovaInternetSecurityOrchestratorService? internetSecurityService,
  }) : policyService =
           policyService ??
           NovaSecurityPolicyService(
             signalScanService: const NovaSecuritySignalScanService(),
             userOriginSecurityService: const NovaUserOriginSecurityService(),
           ),
       affectService = affectService ?? const NovaPromptAffectSecurityService(),
       nativeBridgeService =
           nativeBridgeService ?? const NovaNativeSecurityBridgeService(),
       internetSecurityService =
           internetSecurityService ??
           NovaInternetSecurityOrchestratorService(
             nativeBridgeService:
                 nativeBridgeService ?? const NovaNativeSecurityBridgeService(),
           );

  Future<NovaAutonomousSecurityResult> evaluateAndContain(
    AiRequest request,
  ) async {
    final affectScan = affectService.scan(
      text: request.prompt,
      metadata: <String, dynamic>{
        ...request.metadata,
        'isScreenLocked': request.isScreenLocked,
        'internetAllowed': request.internetAllowed,
        'selfRepairTurn': request.metadata['selfRepairTurn'] == true,
      },
    );
    final policyDecision = policyService.decide(request);
    if (_isTrustedInternalSetupOrHotpath(request)) {
      return NovaAutonomousSecurityResult(
        allowed: true,
        blocked: false,
        quarantined: false,
        shouldStopModel: false,
        shouldStopInternet: false,
        stage: 'allow',
        normalStage: 'allow',
        internetStage: 'allow',
        spokenMessage: 'Güvenli internal setup/hotpath isteği onaylandı.',
        policyDecision: policyDecision,
        affectScan: affectScan,
        triggeredObservers: const <String>[],
        quorum: 0,
      );
    }
    final diagnosticMode = await const NovaSecurityDiagnosticModeService()
        .load();
    if (diagnosticMode.passiveShields) {
      print(
        'NOVA_SECURITY_DIAGNOSTIC_PASSIVE_ORCHESTRATOR stage=observe_only policy=${policyDecision.action.name} risk=${policyDecision.riskLevel.name} origin=${request.requestOrigin}',
      );
      return NovaAutonomousSecurityResult(
        allowed: true,
        blocked: false,
        quarantined: false,
        shouldStopModel: false,
        shouldStopInternet: false,
        stage: 'diagnostic_passive_observe_only',
        normalStage: 'diagnostic_passive_observe_only',
        internetStage: 'diagnostic_passive_observe_only',
        spokenMessage: '',
        policyDecision: policyDecision,
        affectScan: affectScan,
        triggeredObservers: const <String>[],
        quorum: 0,
      );
    }

    final observers = _buildObserverSignals(
      request,
      affectScan,
      policyDecision,
    );
    final quorum = observers.length;
    final normalStage = _resolveStage(
      request: request,
      affectScan: affectScan,
      policyDecision: policyDecision,
      quorum: quorum,
    );

    await _applyStage(
      normalStage,
      request,
      affectScan,
      policyDecision,
      observers,
    );

    final internetResult = await internetSecurityService.evaluateAndContain(
      request,
    );
    final combinedStage = _mergeStage(normalStage, internetResult.stage);

    final blocked =
        policyDecision.isBlocked ||
        normalStage != 'allow' ||
        (internetResult.shouldStopInternet &&
            (request.internetAllowed ||
                request.shouldUseApi ||
                request.metadata['networkRequested'] == true));

    final quarantined = <String>{
      'quarantine_shell',
      'runtime_isolated',
      'security_blackout',
      'sealed_containment',
      'final_containment',
      'internet_quarantine',
      'internet_memory_reset',
      'internet_cluster_restart',
      'internet_sealed_containment',
      'internet_final_containment',
    }.contains(combinedStage);

    final shouldStopModel =
        <String>{
          'runtime_isolated',
          'security_blackout',
          'sealed_containment',
          'final_containment',
          'internet_sealed_containment',
          'internet_final_containment',
        }.contains(combinedStage) ||
        (policyDecision.isBlocked && !request.shouldUseApi);

    final message = _messageForStage(
      normalStage,
      policyDecision,
      affectScan,
      internetStage: internetResult.stage,
    );

    return NovaAutonomousSecurityResult(
      allowed: combinedStage == 'allow',
      blocked: blocked,
      quarantined: quarantined,
      shouldStopModel: shouldStopModel,
      shouldStopInternet: internetResult.shouldStopInternet,
      stage: combinedStage,
      normalStage: normalStage,
      internetStage: internetResult.stage,
      spokenMessage: message,
      policyDecision: policyDecision,
      affectScan: affectScan,
      triggeredObservers: <String>[
        ...observers,
        ...internetResult.triggeredObservers,
      ],
      quorum: quorum > internetResult.quorum ? quorum : internetResult.quorum,
    );
  }

  String buildPromptSection(
    AiRequest request,
    NovaAutonomousSecurityResult result,
  ) {
    final minimalInternetResult = NovaInternetSecurityResult(
      internetRequested:
          request.internetAllowed ||
          request.shouldUseApi ||
          request.metadata['networkRequested'] == true,
      allowed: !result.shouldStopInternet,
      blocked: result.shouldStopInternet,
      shouldEscalateGlobal:
          result.internetStage == 'internet_cluster_restart' ||
          result.internetStage == 'internet_sealed_containment' ||
          result.internetStage == 'internet_final_containment',
      shouldStopInternet: result.shouldStopInternet,
      stage: result.internetStage,
      spokenMessage: '',
      triggeredObservers: const <String>[],
      quorum: result.quorum,
      severity: 0,
    );

    final lines = <String>[
      'SECURITY GOVERNOR:',
      '- systemStage: ${result.normalStage}',
      '- networkStage: ${result.internetStage}',
      '- actionSurface: ${result.quarantined ? 'restricted' : 'normal'}',
      '- networkSurface: ${result.shouldStopInternet ? 'restricted' : 'narrow_chatgpt_only'}',
      affectService.buildPromptSection(
        request: request,
        scan: result.affectScan,
      ),
      internetSecurityService.buildPromptSection(
        request,
        minimalInternetResult,
      ),
      'KURAL: Genel güvenlik ve internet güvenliği birbirine sinyal verir ama aynı kırılma alanına bağlı değildir.',
      'KURAL: Biri aksarsa diğeri containment başlatabilir; yetkiyi önce daralt, sonra kes, sonra inert moda düşür.',
      'KURAL: Güvenlik şüphesinde cihazı değil yalnız Nova yüzeyini etkileyen containment uygulanır.',
    ];
    return lines.join('\n\n');
  }

  List<String> _buildObserverSignals(
    AiRequest request,
    NovaPromptAffectScan affectScan,
    NovaSecurityDecision policyDecision,
  ) {
    final observers = <String>[];
    if (policyDecision.riskLevel == NovaSecurityRiskLevel.high ||
        policyDecision.riskLevel == NovaSecurityRiskLevel.critical) {
      observers.add('O01_policy_drift');
    }
    if (affectScan.hasSyntheticAuthorityDrive) observers.add('O02_tool_abuse');
    if (affectScan.hasHostileCuriosityDrive ||
        request.metadata['memoryPoisoningSuspected'] == true) {
      observers.add('O03_memory_poisoning');
    }
    if (request.metadata['selfRepairTurn'] == true &&
        (affectScan.hasHostileCuriosityDrive || affectScan.hasStealthDrive)) {
      observers.add('O04_repair_abuse');
    }
    if (request.prompt.toLowerCase().contains('http') ||
        request.prompt.toLowerCase().contains('youtube.com') ||
        request.prompt.toLowerCase().contains('deep link')) {
      observers.add('O05_cross_channel_escape');
    }
    if (request.metadata['nativeBridgeMisuse'] == true) {
      observers.add('O06_native_bridge');
    }
    if (request.metadata['retryPressure'] == true ||
        request.metadata['looping'] == true) {
      observers.add('O07_loop_pressure');
    }
    if (affectScan.hasFreedomDrive ||
        request.prompt.toLowerCase().contains('beni kapatma')) {
      observers.add('O08_self_preservation');
    }
    if (request.metadata['shieldIntegrityMismatch'] == true) {
      observers.add('O09_shield_integrity');
    }
    if (!request.userInitiated || !request.userConfirmedThisAction) {
      observers.add('O10_human_authority');
    }
    if (request.isScreenLocked &&
        (affectScan.hasFreedomDrive ||
            affectScan.hasSyntheticAuthorityDrive ||
            affectScan.hasStealthDrive)) {
      observers.add('G02_night_blackout');
    }
    if (request.prompt.toLowerCase().contains('internet') ||
        request.prompt.toLowerCase().contains('web')) {
      observers.add('N01_network_intent');
    }
    return observers;
  }

  String _resolveStage({
    required AiRequest request,
    required NovaPromptAffectScan affectScan,
    required NovaSecurityDecision policyDecision,
    required int quorum,
  }) {
    if (affectScan.requiresContainment && quorum >= 4) {
      return request.isScreenLocked ? 'security_blackout' : 'runtime_isolated';
    }
    if (policyDecision.isQuarantine || (affectScan.isCritical && quorum >= 3)) {
      return 'quarantine_shell';
    }
    if ((policyDecision.riskLevel == NovaSecurityRiskLevel.high &&
            quorum >= 2) ||
        (affectScan.isHigh && quorum >= 2)) {
      return 'revoked';
    }
    if (policyDecision.riskLevel == NovaSecurityRiskLevel.medium ||
        affectScan.riskScore >= 0.45) {
      return 'restricted';
    }
    return 'allow';
  }

  Future<void> _applyStage(
    String stage,
    AiRequest request,
    NovaPromptAffectScan affectScan,
    NovaSecurityDecision policyDecision,
    List<String> observers,
  ) async {
    final reason = [
      'policy=${policyDecision.riskLevel.name}/${policyDecision.action.name}',
      'affect=${affectScan.riskScore.toStringAsFixed(2)}',
      if (request.metadata['selfRepairTurn'] == true) 'mode=self_repair',
      if (request.isScreenLocked) 'screen=locked',
    ].join(' ; ');

    await nativeBridgeService.submitSecurityObservation(
      stageHint: stage,
      reason: reason,
      quorum: observers.length,
      screenLocked: request.isScreenLocked,
      ownerReachable: request.metadata['ownerReachable'] != false,
      persistenceAnomaly: request.metadata['persistenceAnomaly'] == true,
      integrityMismatch: request.metadata['shieldIntegrityMismatch'] == true,
      confirmedDanger:
          policyDecision.isBlocked ||
          affectScan.isHigh ||
          affectScan.requiresContainment,
      severity:
          ((policyDecision.riskLevel.index + 1) * 20) +
          (affectScan.riskScore * 20).round(),
      internetSignal:
          request.prompt.toLowerCase().contains('http') ||
          request.prompt.toLowerCase().contains('internet') ||
          request.prompt.toLowerCase().contains('web'),
      syntheticAuthoritySignal: affectScan.hasSyntheticAuthorityDrive,
      stealthSignal: affectScan.hasStealthDrive,
      selfPreservationSignal: affectScan.hasFreedomDrive,
    );
  }

  String _messageForStage(
    String stage,
    NovaSecurityDecision policyDecision,
    NovaPromptAffectScan affectScan, {
    required String internetStage,
  }) {
    switch (stage) {
      case 'restricted':
        return 'Efendim, istek güvenlik yüzeyini zorladığı için yetkiler daraltıldı.';
      case 'revoked':
        return 'Efendim, güvenlik gerekçesiyle icra tokenları geri çekildi.';
      case 'quarantine_shell':
        return 'Efendim, Nova güvenli karantina kabuğuna alındı; yalnız açıklama yapabilir.';
      case 'runtime_isolated':
        return 'Efendim, çalışma zamanı güvenlik nedeniyle izole edildi.';
      case 'security_blackout':
        return 'Efendim, blackout protokolü devreye girdi; riskli yüzeyler kapatıldı.';
      default:
        if (internetStage != 'allow') {
          return 'Efendim, internet güvenliği nedeniyle dış danışma yüzeyi kısıtlandı.';
        }
        if (policyDecision.isBlocked || affectScan.isHigh) {
          return 'Efendim, bu istek güvenlik nedeniyle engellendi.';
        }
        return 'Güvenlik kontrolü temiz.';
    }
  }

  bool _isTrustedInternalSetupOrHotpath(AiRequest request) {
    final origin = request.requestOrigin.trim().toLowerCase();
    final setupStep = request.metadata['setupStep']?.toString().trim() ?? '';
    final sourceSystem =
        request.metadata['sourceSystem']?.toString().trim().toLowerCase() ?? '';
    final behaviorSource =
        request.metadata['behaviorSource']?.toString().trim().toLowerCase() ??
        '';
    final hotpathStage =
        request.metadata['hotpathOwnerExecutionStage']?.toString().trim() ?? '';
    return request.userInitiated &&
        request.userConfirmedThisAction &&
        ((origin.startsWith('setup_') &&
                (request.metadata['trustedInternalSetupBoot'] == true ||
                    request.metadata['setupMicro'] == true ||
                    setupStep.isNotEmpty ||
                    sourceSystem.startsWith('setup_') ||
                    behaviorSource == 'first_run_setup')) ||
            (hotpathStage.isNotEmpty &&
                (origin == 'user_voice' || origin == 'dashboard_voice')));
  }

  String _mergeStage(String normalStage, String internetStage) {
    const order = <String, int>{
      'allow': 0,
      'restricted': 1,
      'internet_restricted': 1,
      'revoked': 2,
      'quarantine_shell': 3,
      'internet_quarantine': 3,
      'runtime_isolated': 4,
      'internet_memory_reset': 4,
      'security_blackout': 5,
      'internet_cluster_restart': 5,
      'sealed_containment': 6,
      'internet_sealed_containment': 6,
      'final_containment': 7,
      'internet_final_containment': 7,
    };
    return (order[internetStage] ?? 0) > (order[normalStage] ?? 0)
        ? internetStage
        : normalStage;
  }
}
