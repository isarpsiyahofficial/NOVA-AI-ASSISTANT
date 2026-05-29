// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaOwnerPatchStatus { pending, validated, rejected, applied }

class NovaOwnerPatch {
  final String id;
  final String targetArea;
  final String humanNote;
  final String patchText;
  final NovaOwnerPatchStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String validationMessage;

  const NovaOwnerPatch({
    required this.id,
    required this.targetArea,
    required this.humanNote,
    required this.patchText,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.validationMessage = '',
  });

  NovaOwnerPatch copyWith({
    String? targetArea,
    String? humanNote,
    String? patchText,
    NovaOwnerPatchStatus? status,
    DateTime? updatedAt,
    String? validationMessage,
  }) {
    return NovaOwnerPatch(
      id: id,
      targetArea: targetArea ?? this.targetArea,
      humanNote: humanNote ?? this.humanNote,
      patchText: patchText ?? this.patchText,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      validationMessage: validationMessage ?? this.validationMessage,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'targetArea': targetArea,
    'humanNote': humanNote,
    'patchText': patchText,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'validationMessage': validationMessage,
  };

  factory NovaOwnerPatch.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return NovaOwnerPatch(
      id: (map['id'] as String? ?? '').trim(),
      targetArea: (map['targetArea'] as String? ?? '').trim(),
      humanNote: (map['humanNote'] as String? ?? '').trim(),
      patchText: (map['patchText'] as String? ?? '').trim(),
      status: NovaOwnerPatchStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'pending'),
        orElse: () => NovaOwnerPatchStatus.pending,
      ),
      createdAt:
          DateTime.tryParse((map['createdAt'] as String? ?? '').trim()) ?? now,
      updatedAt:
          DateTime.tryParse((map['updatedAt'] as String? ?? '').trim()) ?? now,
      validationMessage: (map['validationMessage'] as String? ?? '').trim(),
    );
  }
}
