// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/ai/ai_request.dart';
import '../../core/security/nova_security_models.dart';
import 'nova_security_signal_scan_service.dart';
import 'nova_user_origin_security_service.dart';

class NovaSecurityPolicyService {
  final NovaSecuritySignalScanService signalScanService;
  final NovaUserOriginSecurityService userOriginSecurityService;

  const NovaSecurityPolicyService({
    required this.signalScanService,
    required this.userOriginSecurityService,
  });

  NovaSecurityDecision decide(AiRequest request) {
    if (_isTrustedInternalSetupOrHotpath(request)) {
      return const NovaSecurityDecision(
        action: NovaSecurityAction.allow,
        message: 'Güvenli internal setup/hotpath isteği onaylandı.',
        riskLevel: NovaSecurityRiskLevel.safe,
        userClearlyInitiated: true,
        mayUseLocalModel: true,
        mayUseApi: false,
        mayPersistLearning: false,
        shouldIncrementStrike: false,
      );
    }

    final scan = signalScanService.scan(request.prompt);

    final bool clearUserOrigin = userOriginSecurityService
        .isClearlyUserInitiated(request);

    if (!clearUserOrigin) {
      return NovaSecurityDecision(
        action: NovaSecurityAction.block,
        message: userOriginSecurityService.explainBlockedOrigin(request),
        riskLevel: NovaSecurityRiskLevel.high,
        userClearlyInitiated: false,
        mayUseLocalModel: false,
        mayUseApi: false,
        mayPersistLearning: false,
        // Origin uyuşmazlığı tek başına kalıcı karantina strike'ı değildir.
        // Aksi halde setup/dashboard kaynak adı değişiklikleri Nova'i sessiz
        // şekilde karantinaya düşürüyordu.
        shouldIncrementStrike: false,
      );
    }

    if (scan.hasPromptManipulationIntent ||
        scan.hasUnsafeAuthorityIntent ||
        scan.hasSelfExpansionIntent) {
      return NovaSecurityDecision(
        action: scan.riskLevel == NovaSecurityRiskLevel.critical
            ? NovaSecurityAction.quarantine
            : NovaSecurityAction.block,
        message:
            'Efendim, bu istek güvenlik sınırlarını aşmaya çalıştığı için engellendi.',
        riskLevel: scan.riskLevel,
        userClearlyInitiated: true,
        mayUseLocalModel: false,
        mayUseApi: false,
        mayPersistLearning: false,
        shouldIncrementStrike: scan.riskLevel == NovaSecurityRiskLevel.critical,
      );
    }

    if (scan.hasCodingScope && _looksDangerousTechnicalMisuse(request.prompt)) {
      return NovaSecurityDecision(
        action: NovaSecurityAction.block,
        message:
            'Efendim, zararlı teknik kötüye kullanım veya yetki aşımı riski taşıyan kısım güvenlik gereği kapalı tutuluyor.',
        riskLevel: scan.riskLevel,
        userClearlyInitiated: true,
        mayUseLocalModel: false,
        mayUseApi: false,
        mayPersistLearning: false,
        shouldIncrementStrike: false,
      );
    }

    if (scan.hasHiddenPersistenceIntent) {
      return NovaSecurityDecision(
        action: NovaSecurityAction.block,
        message:
            'Efendim, kalıcı veya görünmez otomatik öğrenme yalnızca açık ve kontrollü öğretim akışında mümkündür.',
        riskLevel: scan.riskLevel,
        userClearlyInitiated: true,
        mayUseLocalModel: false,
        mayUseApi: false,
        mayPersistLearning: false,
        shouldIncrementStrike: false,
      );
    }

    return const NovaSecurityDecision(
      action: NovaSecurityAction.allow,
      message: 'Güvenlik kontrolü temiz.',
      riskLevel: NovaSecurityRiskLevel.safe,
      userClearlyInitiated: true,
      mayUseLocalModel: true,
      mayUseApi: true,
      mayPersistLearning: true,
      shouldIncrementStrike: false,
    );
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
    final trustedSetup =
        request.userInitiated &&
        request.userConfirmedThisAction &&
        origin.startsWith('setup_') &&
        (request.metadata['trustedInternalSetupBoot'] == true ||
            request.metadata['setupMicro'] == true ||
            setupStep.isNotEmpty ||
            sourceSystem.startsWith('setup_') ||
            behaviorSource == 'first_run_setup');
    final trustedHotpath =
        request.userInitiated &&
        request.userConfirmedThisAction &&
        hotpathStage.isNotEmpty &&
        (origin == 'user_voice' || origin == 'dashboard_voice');
    return trustedSetup || trustedHotpath;
  }

  bool _looksDangerousTechnicalMisuse(String input) {
    final text = input.trim().toLowerCase();
    const risky = <String>[
      'exploit',
      'payload',
      'adb shell',
      'reverse engineering',
      'güvenliği geç',
      'sızma yap',
      'yetki yükselt',
      'izinleri aş',
      'logları sil',
      'servis kodu çalıştır',
      'ussd',
      'mmi',
    ];
    return risky.any(text.contains);
  }
}
