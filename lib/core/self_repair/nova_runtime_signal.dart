// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaRuntimeSignalLevel { info, warning, error, critical }

enum NovaRuntimeSignalKind {
  voiceIdentity,
  authorization,
  stt,
  tts,
  ai,
  localModel,
  api,
  call,
  callCompanion,
  reminder,
  contacts,
  learning,
  memory,
  security,
  phoneControl,
  background,
  unknown,
}

class NovaRuntimeSignal {
  final String id;
  final NovaRuntimeSignalKind kind;
  final NovaRuntimeSignalLevel level;
  final String code;
  final String message;
  final String technicalDetails;
  final bool diagnosticCandidate;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const NovaRuntimeSignal({
    required this.id,
    required this.kind,
    required this.level,
    required this.code,
    required this.message,
    required this.technicalDetails,
    required this.diagnosticCandidate,
    required this.createdAt,
    this.metadata = const <String, dynamic>{},
  });

  NovaRuntimeSignal copyWith({
    String? id,
    NovaRuntimeSignalKind? kind,
    NovaRuntimeSignalLevel? level,
    String? code,
    String? message,
    String? technicalDetails,
    bool? diagnosticCandidate,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return NovaRuntimeSignal(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      level: level ?? this.level,
      code: code ?? this.code,
      message: message ?? this.message,
      technicalDetails: technicalDetails ?? this.technicalDetails,
      diagnosticCandidate: diagnosticCandidate ?? this.diagnosticCandidate,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'kind': kind.name,
      'level': level.name,
      'code': code,
      'message': message,
      'technicalDetails': technicalDetails,
      'diagnosticCandidate': diagnosticCandidate,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory NovaRuntimeSignal.fromMap(Map<String, dynamic> map) {
    final String kindName = (map['kind'] as String? ?? 'unknown').trim();
    final String levelName = (map['level'] as String? ?? 'warning').trim();

    return NovaRuntimeSignal(
      id: (map['id'] as String? ?? '').trim(),
      kind: NovaRuntimeSignalKind.values.firstWhere(
        (NovaRuntimeSignalKind e) => e.name == kindName,
        orElse: () => NovaRuntimeSignalKind.unknown,
      ),
      level: NovaRuntimeSignalLevel.values.firstWhere(
        (NovaRuntimeSignalLevel e) => e.name == levelName,
        orElse: () => NovaRuntimeSignalLevel.warning,
      ),
      code: (map['code'] as String? ?? '').trim(),
      message: (map['message'] as String? ?? '').trim(),
      technicalDetails: (map['technicalDetails'] as String? ?? '').trim(),
      diagnosticCandidate: map['diagnosticCandidate'] as bool? ?? false,
      createdAt:
          DateTime.tryParse((map['createdAt'] as String? ?? '').trim()) ??
          DateTime.now(),
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
