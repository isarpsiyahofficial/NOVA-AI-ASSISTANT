// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class AutomationRecoveryPlan {
  final bool shouldRetryLocally;
  final bool shouldAskForChatGpt;
  final String explanation;

  const AutomationRecoveryPlan({
    required this.shouldRetryLocally,
    required this.shouldAskForChatGpt,
    required this.explanation,
  });
}

class AutomationRecoveryService {
  const AutomationRecoveryService();

  AutomationRecoveryPlan buildPlan({
    required String errorText,
    required bool canUseChatGpt,
    required bool userAlreadySaidNo,
    required int retryCount,
  }) {
    final safeError = errorText.trim().isEmpty
        ? 'Görev sırasında belirsiz bir sorun oluştu.'
        : errorText.trim();

    if (retryCount < 2) {
      return AutomationRecoveryPlan(
        shouldRetryLocally: true,
        shouldAskForChatGpt: false,
        explanation:
            'Efendim şu adımda sorun oluştu: $safeError. Önce güvenli bir alternatif yol deneyeceğim.',
      );
    }

    if (canUseChatGpt && !userAlreadySaidNo) {
      return AutomationRecoveryPlan(
        shouldRetryLocally: false,
        shouldAskForChatGpt: true,
        explanation:
            'Efendim şu adımda takıldım: $safeError. ChatGPT’ye sorayım mı?',
      );
    }

    return AutomationRecoveryPlan(
      shouldRetryLocally: true,
      shouldAskForChatGpt: false,
      explanation:
          'Efendim şu adımda sorun var: $safeError. ChatGPT kullanamıyorum ya da izin yok. Yerelde başka güvenli bir yol daha deneyeceğim.',
    );
  }
}
