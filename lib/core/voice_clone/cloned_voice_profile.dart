// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'voice_clone_source_type.dart';

class ClonedVoiceProfile {
  final String id;
  final String name;
  final VoiceCloneSourceType sourceType;
  final String sourceReference;
  final String styleInstruction;
  final bool noiseReduced;
  final bool isFavorite;
  final bool isActiveInUse;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClonedVoiceProfile({
    required this.id,
    required this.name,
    required this.sourceType,
    required this.sourceReference,
    required this.styleInstruction,
    required this.noiseReduced,
    this.isFavorite = false,
    this.isActiveInUse = false,
    required this.createdAt,
    required this.updatedAt,
  });

  ClonedVoiceProfile copyWith({
    String? id,
    String? name,
    VoiceCloneSourceType? sourceType,
    String? sourceReference,
    String? styleInstruction,
    bool? noiseReduced,
    bool? isFavorite,
    bool? isActiveInUse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClonedVoiceProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceType: sourceType ?? this.sourceType,
      sourceReference: sourceReference ?? this.sourceReference,
      styleInstruction: styleInstruction ?? this.styleInstruction,
      noiseReduced: noiseReduced ?? this.noiseReduced,
      isFavorite: isFavorite ?? this.isFavorite,
      isActiveInUse: isActiveInUse ?? this.isActiveInUse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'sourceType': sourceType.name,
      'sourceReference': sourceReference,
      'styleInstruction': styleInstruction,
      'noiseReduced': noiseReduced,
      'isFavorite': isFavorite,
      'isActiveInUse': isActiveInUse,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ClonedVoiceProfile.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return ClonedVoiceProfile(
      id: (map['id'] as String? ?? '').trim(),
      name: (map['name'] as String? ?? '').trim(),
      sourceType: VoiceCloneSourceType.values.firstWhere(
        (e) => e.name == (map['sourceType'] as String? ?? 'file'),
        orElse: () => VoiceCloneSourceType.file,
      ),
      sourceReference: (map['sourceReference'] as String? ?? '').trim(),
      styleInstruction: (map['styleInstruction'] as String? ?? '').trim(),
      noiseReduced: map['noiseReduced'] as bool? ?? false,
      isFavorite: map['isFavorite'] as bool? ?? false,
      isActiveInUse: map['isActiveInUse'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? now,
    );
  }
}
