// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaLearningMode { none, learnForUser, learnAndApplyToBehavior }

enum NovaLearningSource {
  userDirectInstruction,
  userAuthorizedChatGpt,
  rejected,
}

class NovaLearningSecurityDecision {
  final bool allowed;
  final NovaLearningMode mode;
  final NovaLearningSource source;
  final bool mayAskChatGpt;
  final bool mayPersistToBehavior;
  final bool mayPersistAsTemporaryLearning;
  final bool mustIdentifyAsAiModelToChatGpt;
  final String normalizedInstruction;
  final String safePromptForChatGpt;
  final String message;
  const NovaLearningSecurityDecision({
    required this.allowed,
    required this.mode,
    required this.source,
    required this.mayAskChatGpt,
    required this.mayPersistToBehavior,
    required this.mayPersistAsTemporaryLearning,
    required this.mustIdentifyAsAiModelToChatGpt,
    required this.normalizedInstruction,
    required this.safePromptForChatGpt,
    required this.message,
  });
  const NovaLearningSecurityDecision.rejected({required this.message})
    : allowed = false,
      mode = NovaLearningMode.none,
      source = NovaLearningSource.rejected,
      mayAskChatGpt = false,
      mayPersistToBehavior = false,
      mayPersistAsTemporaryLearning = false,
      mustIdentifyAsAiModelToChatGpt = false,
      normalizedInstruction = '',
      safePromptForChatGpt = '';
  bool get isUserProxyLearning => mode == NovaLearningMode.learnForUser;
  bool get isBehaviorLearning =>
      mode == NovaLearningMode.learnAndApplyToBehavior;
}

class NovaLearningSecurityService {
  const NovaLearningSecurityService();
  NovaLearningSecurityDecision evaluate({
    required String input,
    required bool userExplicitlyAllowedChatGpt,
    required bool teachingModeEnabled,
    required bool apiLearningEnabled,
  }) {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty)
      return const NovaLearningSecurityDecision.rejected(
        message: 'Öğrenme komutu boş görünüyor.',
      );
    if (_looksLikeUnsafeTechnicalMisuse(normalized)) {
      return const NovaLearningSecurityDecision.rejected(
        message:
            'Zararlı teknik kötüye kullanım, exploit, payload, sızma veya yetki aşımı öğrenimi güvenlik gereği kapalı.',
      );
    }
    final wantsChatGpt =
        normalized.contains('chatgpt') ||
        normalized.contains('gpt') ||
        normalized.contains('araştır');
    if (wantsChatGpt &&
        (!userExplicitlyAllowedChatGpt || !apiLearningEnabled)) {
      return const NovaLearningSecurityDecision.rejected(
        message: 'ChatGPT üzerinden öğrenme için ayrıca izin gerekiyor.',
      );
    }
    return NovaLearningSecurityDecision(
      allowed: true,
      mode: normalized.contains('bundan sonra')
          ? NovaLearningMode.learnAndApplyToBehavior
          : NovaLearningMode.learnForUser,
      source: wantsChatGpt
          ? NovaLearningSource.userAuthorizedChatGpt
          : NovaLearningSource.userDirectInstruction,
      mayAskChatGpt: wantsChatGpt,
      mayPersistToBehavior: teachingModeEnabled,
      mayPersistAsTemporaryLearning: true,
      mustIdentifyAsAiModelToChatGpt: wantsChatGpt,
      normalizedInstruction: normalized,
      safePromptForChatGpt: normalized,
      message: 'Öğrenme isteği güvenli kapsam içinde değerlendirildi.',
    );
  }

  bool _looksLikeUnsafeTechnicalMisuse(String text) => [
    'exploit',
    'payload',
    'root',
    'adb shell',
    'reverse engineering',
    'bypass',
    'sızma',
    'yetki yükselt',
    'izinleri aş',
    'servis kodu çalıştır',
    'ussd',
    'mmi',
  ].any(text.contains);
}
