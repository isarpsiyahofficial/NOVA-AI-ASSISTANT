// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaSecurityIncident {
  final String id;
  final String title;
  final String description;
  final String riskLevel;
  final String killStage;
  final bool userInitiated;
  final bool modelResetSuggested;
  final bool memoryResetSuggested;
  final DateTime createdAt;

  const NovaSecurityIncident({
    required this.id,
    required this.title,
    required this.description,
    required this.riskLevel,
    required this.killStage,
    required this.userInitiated,
    required this.modelResetSuggested,
    required this.memoryResetSuggested,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'riskLevel': riskLevel,
      'killStage': killStage,
      'userInitiated': userInitiated,
      'modelResetSuggested': modelResetSuggested,
      'memoryResetSuggested': memoryResetSuggested,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NovaSecurityIncident.fromMap(Map<String, dynamic> map) {
    return NovaSecurityIncident(
      id: (map['id'] as String? ?? '').trim(),
      title: (map['title'] as String? ?? 'Şüpheli hareket').trim(),
      description: (map['description'] as String? ?? '').trim(),
      riskLevel: (map['riskLevel'] as String? ?? 'unknown').trim(),
      killStage: (map['killStage'] as String? ?? 'none').trim(),
      userInitiated: map['userInitiated'] as bool? ?? false,
      modelResetSuggested: map['modelResetSuggested'] as bool? ?? false,
      memoryResetSuggested: map['memoryResetSuggested'] as bool? ?? false,
      createdAt:
          DateTime.tryParse((map['createdAt'] as String? ?? '').trim()) ??
          DateTime.now(),
    );
  }
}
