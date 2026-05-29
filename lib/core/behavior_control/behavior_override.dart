// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class BehaviorOverride {
  final String key;
  final String instruction;
  final bool isEnabled;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BehaviorOverride({
    required this.key,
    required this.instruction,
    this.isEnabled = true,
    this.source = 'user',
    required this.createdAt,
    required this.updatedAt,
  });

  BehaviorOverride copyWith({
    String? key,
    String? instruction,
    bool? isEnabled,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BehaviorOverride(
      key: key ?? this.key,
      instruction: instruction ?? this.instruction,
      isEnabled: isEnabled ?? this.isEnabled,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasUsableInstruction => instruction.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'key': key,
      'instruction': instruction,
      'isEnabled': isEnabled,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BehaviorOverride.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return BehaviorOverride(
      key: (map['key'] as String? ?? '').trim(),
      instruction: (map['instruction'] as String? ?? '').trim(),
      isEnabled: map['isEnabled'] as bool? ?? true,
      source: (map['source'] as String? ?? 'user').trim(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? now,
    );
  }
}
