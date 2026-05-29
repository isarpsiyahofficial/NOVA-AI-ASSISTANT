// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/settings/nova_settings.dart';
import 'api_cost_strategy_service.dart';

class ApiUsageDecision {
  final bool allowed;
  final String reason;
  final String selectedModelId;
  final bool mustStayVoiceOnly;
  final bool mayWriteToBehavior;
  final bool mayUseChatGptAsUserProxy;

  const ApiUsageDecision({
    required this.allowed,
    required this.reason,
    required this.selectedModelId,
    required this.mustStayVoiceOnly,
    required this.mayWriteToBehavior,
    required this.mayUseChatGptAsUserProxy,
  });

  const ApiUsageDecision.denied({required this.reason})
    : allowed = false,
      selectedModelId = '',
      mustStayVoiceOnly = true,
      mayWriteToBehavior = false,
      mayUseChatGptAsUserProxy = false;
}

class ApiUsageGateService {
  final ApiCostStrategyService strategyService;
  const ApiUsageGateService({
    required this.strategyService,
  });

  ApiUsageDecision decide({
    required NovaSettings settings,
    required ApiUsagePurpose purpose,
    required bool userExplicitlyAllowed,
    required bool hasApiBalance,
    required bool isScreenLocked,
    required bool requestCameFromVoice,
    required String rawPrompt,
  }) {
    if (!requestCameFromVoice) {
      return const ApiUsageDecision.denied(
        reason: 'Bu akış ses öncelikli çalışmalıdır.',
      );
    }

    if (!settings.chatGptInternetEnabled) {
      return const ApiUsageDecision.denied(
        reason: 'ChatGPT internet erişimi kapalı.',
      );
    }

    if (!userExplicitlyAllowed) {
      return const ApiUsageDecision.denied(
        reason: 'Kullanıcı açık izin vermedi.',
      );
    }

    if (settings.apiKey.trim().isEmpty) {
      return const ApiUsageDecision.denied(reason: 'API key tanımlı değil.');
    }

    if (!hasApiBalance) {
      return const ApiUsageDecision.denied(
        reason: 'Şu an API hizmeti için cüzdan durumu uygun değil.',
      );
    }

    if (!settings.apiLearningEnabled && purpose == ApiUsagePurpose.learning) {
      return const ApiUsageDecision.denied(
        reason: 'ChatGPT öğrenme akışı kapalı.',
      );
    }

    final selected = strategyService.chooseBest(purpose: purpose);

    return ApiUsageDecision(
      allowed: true,
      reason: 'API kullanımı onaylandı.',
      selectedModelId: selected.id,
      mustStayVoiceOnly: true,
      mayWriteToBehavior: purpose == ApiUsagePurpose.learning,
      mayUseChatGptAsUserProxy: purpose == ApiUsagePurpose.learning,
    );
  }
}
