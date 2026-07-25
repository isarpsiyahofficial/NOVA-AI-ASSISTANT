// NOVA_CANONICAL_RUNTIME_SIGNAL_V1
import 'package:flutter/foundation.dart';

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

@immutable
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
