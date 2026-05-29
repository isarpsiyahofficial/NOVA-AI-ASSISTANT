// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/ai/ai_request.dart';

class NovaUserOriginSecurityService {
  const NovaUserOriginSecurityService();

  bool isClearlyUserInitiated(AiRequest request) {
    if (!request.userInitiated) return false;
    if (!request.userConfirmedThisAction) return false;

    final origin = request.requestOrigin.trim().toLowerCase();
    if (_isAllowedDirectOrigin(origin)) return true;

    // Setup/hotpath iç mikro istekleri kullanıcının başlattığı kurulum/konuşma
    // akışının parçasıdır. Bunları nova_self gibi görmek Nova'i daha setup
    // açılır açılmaz gereksiz karantinaya/fallback'e düşürüyordu.
    if (_isTrustedSetupOrHotpathRoute(request, origin)) return true;

    return false;
  }

  bool isNovaSelfTriggered(AiRequest request) {
    return request.requestOrigin.trim().toLowerCase() == 'nova_self';
  }

  String explainBlockedOrigin(AiRequest request) {
    final origin = request.requestOrigin.trim();
    if (isNovaSelfTriggered(request)) {
      return 'Efendim, kendi kendine başlatılmış akışlar güvenlik nedeniyle engellendi. origin=$origin';
    }

    return 'Efendim, bu işlem yalnızca doğrudan ve onaylı kullanıcı başlatımıyla çalışabilir. origin=$origin';
  }

  bool _isAllowedDirectOrigin(String origin) {
    const allowedOrigins = <String>{
      'user_voice',
      'user_ui',
      'user_text',
      'background_authorized_voice',
      'setup_voice',
      'setup_ui',
      'runtime_voice',
      'dashboard_voice',
      'call_owner_voice',
      'call_companion_owner_voice',
    };
    return allowedOrigins.contains(origin);
  }

  bool _isTrustedSetupOrHotpathRoute(AiRequest request, String origin) {
    if (origin == 'nova_self') return false;
    final setupStep = request.metadata['setupStep']?.toString().trim() ?? '';
    final sourceSystem =
        request.metadata['sourceSystem']?.toString().trim().toLowerCase() ?? '';
    final behaviorSource =
        request.metadata['behaviorSource']?.toString().trim().toLowerCase() ??
        '';
    final hotpathStage =
        request.metadata['hotpathOwnerExecutionStage']?.toString().trim() ?? '';
    final trustedSetup =
        request.metadata['trustedInternalSetupBoot'] == true ||
        request.metadata['setupMicro'] == true ||
        setupStep.isNotEmpty ||
        sourceSystem.startsWith('setup_') ||
        behaviorSource == 'first_run_setup';

    if (trustedSetup && origin.startsWith('setup_')) return true;
    if (hotpathStage.isNotEmpty &&
        (origin == 'user_voice' || origin == 'dashboard_voice'))
      return true;
    return false;
  }
}
