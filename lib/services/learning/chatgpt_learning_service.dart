// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/learning/learning_engine.dart';
import '../../core/learning/learned_rule.dart';

class ChatGptLearningService {
  final LearningEngine learningEngine;

  const ChatGptLearningService({required this.learningEngine});

  /// ChatGPT’den öğrenilen bilgiyi rule'a çevirir
  Future<void> learnFromChatGpt({
    required String userInstruction,
    required String chatGptResponse,
  }) async {
    final parsed = _extractRule(userInstruction, chatGptResponse);

    if (parsed == null) return;

    await learningEngine.teach(
      trigger: parsed.trigger,
      action: parsed.action,
      priority: RulePriority.chatgpt,
    );
  }

  /// basit rule çıkarımı (ileride AI ile daha da güçlenir ama geri dönüş yok)
  _ParsedRule? _extractRule(String instruction, String response) {
    final trigger = instruction.trim();
    final action = response.trim();

    if (trigger.isEmpty || action.isEmpty) return null;

    return _ParsedRule(trigger: trigger, action: action);
  }
}

class _ParsedRule {
  final String trigger;
  final String action;

  _ParsedRule({required this.trigger, required this.action});
}
