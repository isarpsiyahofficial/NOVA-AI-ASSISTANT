// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum RulePriority {
  user, // en güçlü (sen)
  chatgpt, // ikinci (ben)
  defaultRule, // en zayıf
}

class LearnedRule {
  final String id;
  final String trigger;
  final String action;
  final RulePriority priority;

  const LearnedRule({
    required this.id,
    required this.trigger,
    required this.action,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trigger': trigger,
      'action': action,
      'priority': priority.name,
    };
  }

  factory LearnedRule.fromMap(Map<String, dynamic> map) {
    return LearnedRule(
      id: map['id'],
      trigger: map['trigger'],
      action: map['action'],
      priority: RulePriority.values.firstWhere(
        (e) => e.name == map['priority'],
      ),
    );
  }
}
