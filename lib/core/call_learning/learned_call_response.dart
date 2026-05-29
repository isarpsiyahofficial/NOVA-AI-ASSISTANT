// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class LearnedCallResponse {
  final String id;
  final String trigger;
  final String responseText;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearnedCallResponse({
    required this.id,
    required this.trigger,
    required this.responseText,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  LearnedCallResponse copyWith({
    String? id,
    String? trigger,
    String? responseText,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearnedCallResponse(
      id: id ?? this.id,
      trigger: trigger ?? this.trigger,
      responseText: responseText ?? this.responseText,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'trigger': trigger,
      'responseText': responseText,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LearnedCallResponse.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return LearnedCallResponse(
      id: (map['id'] as String? ?? '').trim(),
      trigger: (map['trigger'] as String? ?? '').trim(),
      responseText: (map['responseText'] as String? ?? '').trim(),
      category: (map['category'] as String? ?? '').trim().toLowerCase(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? now,
    );
  }
}
