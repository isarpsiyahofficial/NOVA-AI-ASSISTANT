// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaPostTaskReflection {
  final String taskKey;
  final String summary;
  final List<String> shouldKeep;
  final List<String> shouldAvoid;
  final bool shouldPromoteSkill;
  final double improvementPotential;
  final double confidence;

  const NovaPostTaskReflection({
    required this.taskKey,
    required this.summary,
    required this.shouldKeep,
    required this.shouldAvoid,
    required this.shouldPromoteSkill,
    required this.improvementPotential,
    required this.confidence,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'taskKey': taskKey,
    'summary': summary,
    'shouldKeep': shouldKeep,
    'shouldAvoid': shouldAvoid,
    'shouldPromoteSkill': shouldPromoteSkill,
    'improvementPotential': improvementPotential,
    'confidence': confidence,
  };
}
