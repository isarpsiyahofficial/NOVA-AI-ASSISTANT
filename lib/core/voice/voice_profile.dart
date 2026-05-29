// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class VoiceProfile {
  final String id;
  final String name;
  final String filePath;
  final bool isSelected;
  final bool isApproved;
  final String description;
  final String styleHint;
  final bool isReferenceSample;

  const VoiceProfile({
    required this.id,
    this.name = '',
    this.filePath = '',
    this.isSelected = false,
    this.isApproved = false,
    this.description = '',
    this.styleHint = '',
    this.isReferenceSample = false,
  });

  VoiceProfile copyWith({
    String? id,
    String? name,
    String? filePath,
    bool? isSelected,
    bool? isApproved,
    String? description,
    String? styleHint,
    bool? isReferenceSample,
  }) {
    return VoiceProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      isSelected: isSelected ?? this.isSelected,
      isApproved: isApproved ?? this.isApproved,
      description: description ?? this.description,
      styleHint: styleHint ?? this.styleHint,
      isReferenceSample: isReferenceSample ?? this.isReferenceSample,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'filePath': filePath,
      'isSelected': isSelected,
      'isApproved': isApproved,
      'description': description,
      'styleHint': styleHint,
      'isReferenceSample': isReferenceSample,
    };
  }

  factory VoiceProfile.fromMap(Map<String, dynamic> map) {
    return VoiceProfile(
      id: (map['id'] as String? ?? '').trim(),
      name: (map['name'] as String? ?? '').trim(),
      filePath: (map['filePath'] as String? ?? '').trim(),
      isSelected: map['isSelected'] as bool? ?? false,
      isApproved: map['isApproved'] as bool? ?? false,
      description: (map['description'] as String? ?? '').trim(),
      styleHint: (map['styleHint'] as String? ?? '').trim(),
      isReferenceSample: map['isReferenceSample'] as bool? ?? false,
    );
  }
}
