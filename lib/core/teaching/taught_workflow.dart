// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class TaughtWorkflow {
  final String id;
  final String title;
  final String triggerPhrase;
  final String description;

  /// Öğretilen adımlar
  final List<String> steps;

  /// Sesli mi öğretildi, ekran üstünden mi, karışık mı
  final String teachingSource;

  /// Aktif mi
  final bool isEnabled;

  final DateTime createdAt;
  final DateTime updatedAt;

  const TaughtWorkflow({
    required this.id,
    required this.title,
    required this.triggerPhrase,
    required this.description,
    required this.steps,
    required this.teachingSource,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  TaughtWorkflow copyWith({
    String? id,
    String? title,
    String? triggerPhrase,
    String? description,
    List<String>? steps,
    String? teachingSource,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaughtWorkflow(
      id: id ?? this.id,
      title: title ?? this.title,
      triggerPhrase: triggerPhrase ?? this.triggerPhrase,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      teachingSource: teachingSource ?? this.teachingSource,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasUsableTrigger => triggerPhrase.trim().isNotEmpty;
  bool get hasUsableSteps => steps.any((e) => e.trim().isNotEmpty);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'triggerPhrase': triggerPhrase,
      'description': description,
      'steps': steps,
      'teachingSource': teachingSource,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaughtWorkflow.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return TaughtWorkflow(
      id: (map['id'] as String? ?? '').trim(),
      title: (map['title'] as String? ?? '').trim(),
      triggerPhrase: (map['triggerPhrase'] as String? ?? '').trim(),
      description: (map['description'] as String? ?? '').trim(),
      steps: ((map['steps'] as List?) ?? const <dynamic>[])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      teachingSource: (map['teachingSource'] as String? ?? 'manual').trim(),
      isEnabled: map['isEnabled'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? now,
    );
  }
}
