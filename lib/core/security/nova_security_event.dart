// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_threat_source.dart';

class NovaSecurityEvent {
  final String id;
  final String ruleKey;
  final NovaThreatSource source;
  final bool confirmedDanger;
  final bool userExplicitlyTriggered;
  final int severity;
  final String message;
  final DateTime createdAt;

  const NovaSecurityEvent({
    required this.id,
    required this.ruleKey,
    required this.source,
    required this.confirmedDanger,
    required this.userExplicitlyTriggered,
    required this.severity,
    required this.message,
    required this.createdAt,
  });

  NovaSecurityEvent copyWith({
    String? id,
    String? ruleKey,
    NovaThreatSource? source,
    bool? confirmedDanger,
    bool? userExplicitlyTriggered,
    int? severity,
    String? message,
    DateTime? createdAt,
  }) {
    return NovaSecurityEvent(
      id: id ?? this.id,
      ruleKey: ruleKey ?? this.ruleKey,
      source: source ?? this.source,
      confirmedDanger: confirmedDanger ?? this.confirmedDanger,
      userExplicitlyTriggered:
          userExplicitlyTriggered ?? this.userExplicitlyTriggered,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'ruleKey': ruleKey,
      'source': source.key,
      'confirmedDanger': confirmedDanger,
      'userExplicitlyTriggered': userExplicitlyTriggered,
      'severity': severity,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NovaSecurityEvent.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return NovaSecurityEvent(
      id: (map['id'] as String? ?? '').trim(),
      ruleKey: (map['ruleKey'] as String? ?? '').trim(),
      source: NovaThreatSourceX.fromKey(map['source'] as String?),
      confirmedDanger: map['confirmedDanger'] as bool? ?? false,
      userExplicitlyTriggered: map['userExplicitlyTriggered'] as bool? ?? false,
      severity: (map['severity'] as int? ?? 0).clamp(0, 100),
      message: (map['message'] as String? ?? '').trim(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? now,
    );
  }
}
