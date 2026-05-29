// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaLearningPolicy {
  final bool allowUserTaughtSkillExpansion;
  final bool allowBehaviorEvolution;
  final bool allowOpenEndedConversationGrowth;

  /// İnternet sadece kullanıcı izniyle ve ChatGPT için.
  final bool externalLearningLimitedToChatGpt;
  final bool requireExplicitUserApprovalForExternalLearning;

  /// Hafıza şişmesin.
  final int maxBehaviorOverrideCount;
  final int maxLearnedCallResponseCount;
  final int maxTaughtWorkflowCount;

  const NovaLearningPolicy({
    this.allowUserTaughtSkillExpansion = true,
    this.allowBehaviorEvolution = true,
    this.allowOpenEndedConversationGrowth = true,
    this.externalLearningLimitedToChatGpt = true,
    this.requireExplicitUserApprovalForExternalLearning = true,
    this.maxBehaviorOverrideCount = 100,
    this.maxLearnedCallResponseCount = 150,
    this.maxTaughtWorkflowCount = 150,
  });

  bool canUseExternalLearning({
    required bool userApproved,
    required bool isChatGptOnly,
  }) {
    if (!externalLearningLimitedToChatGpt && userApproved) {
      return true;
    }

    if (!isChatGptOnly) return false;
    if (requireExplicitUserApprovalForExternalLearning && !userApproved) {
      return false;
    }

    return true;
  }

  String buildLearningBoundaryText() {
    return 'Asistan kullanıcıdan yeni beceri öğrenebilir, davranışını geliştirebilir ve sohbet tarzını evirebilir. '
        'Ancak dış kaynaklı öğrenme yalnızca kullanıcı onayıyla ve yalnızca ChatGPT üzerinden yapılır. '
        'Kalıcı öğrenme kontrollü tutulur, gereksiz veri biriktirilmez.';
  }
}
