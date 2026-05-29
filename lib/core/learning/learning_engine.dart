// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../services/learning/learning_service.dart';
import 'learned_rule.dart';

class LearningEngine {
  final LearningService _service;

  LearningEngine(this._service);

  Future<String?> process(String input) async {
    final rule = await _service.findBestMatch(input);

    if (rule == null) return null;

    return rule.action;
  }

  Future<void> teach({
    required String trigger,
    required String action,
    required RulePriority priority,
  }) async {
    final rule = LearnedRule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      trigger: trigger,
      action: action,
      priority: priority,
    );

    await _service.addRule(rule);
  }
}
