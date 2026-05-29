// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'memory_types.dart';

class MemoryItem {
  final String id;
  final MemoryType type;
  final MemorySource source;
  final String content;
  final double trustScore;
  final Map<String, dynamic> metadata;

  final DateTime createdAt;
  final DateTime? expiresAt;

  const MemoryItem({
    required this.id,
    required this.type,
    this.source = MemorySource.pollutedLegacyResponse,
    required this.content,
    this.trustScore = 0.0,
    this.metadata = const <String, dynamic>{},
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'source': source.name,
      'content': content,
      'trustScore': trustScore,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory MemoryItem.fromMap(Map<String, dynamic> map) {
    return MemoryItem(
      id: map['id'],
      type: MemoryType.values.firstWhere((e) => e.name == map['type']),
      source: MemorySource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => MemorySource.pollutedLegacyResponse,
      ),
      content: map['content'],
      trustScore:
          (map['trustScore'] as num?)?.toDouble() ??
          (map['source'] == null ? 0.0 : 1.0),
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map? ?? const <String, dynamic>{},
      ),
      createdAt: DateTime.parse(map['createdAt']),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'])
          : null,
    );
  }

  MemoryItem get memory => this;
}
