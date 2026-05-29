// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaTaskExperience {
  final String id;
  final String taskKey;
  final String speakerKey;
  final String strategySummary;
  final List<String> successfulSteps;
  final List<String> wastedSteps;
  final List<String> errorSignals;
  final double durationSeconds;
  final double firstResponseLatencySeconds;
  final int turnCount;
  final int correctionCount;
  final int unnecessaryQuestionCount;
  final double satisfactionSignal;
  final DateTime createdAt;

  const NovaTaskExperience({
    required this.id,
    required this.taskKey,
    required this.speakerKey,
    required this.strategySummary,
    required this.successfulSteps,
    required this.wastedSteps,
    required this.errorSignals,
    required this.durationSeconds,
    required this.firstResponseLatencySeconds,
    required this.turnCount,
    required this.correctionCount,
    required this.unnecessaryQuestionCount,
    required this.satisfactionSignal,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'taskKey': taskKey,
    'speakerKey': speakerKey,
    'strategySummary': strategySummary,
    'successfulSteps': successfulSteps,
    'wastedSteps': wastedSteps,
    'errorSignals': errorSignals,
    'durationSeconds': durationSeconds,
    'firstResponseLatencySeconds': firstResponseLatencySeconds,
    'turnCount': turnCount,
    'correctionCount': correctionCount,
    'unnecessaryQuestionCount': unnecessaryQuestionCount,
    'satisfactionSignal': satisfactionSignal,
    'createdAt': createdAt.toIso8601String(),
  };

  factory NovaTaskExperience.fromMap(Map<String, dynamic> map) {
    List<String> parseList(String key) =>
        (map[key] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    return NovaTaskExperience(
      id: map['id']?.toString() ?? '',
      taskKey: map['taskKey']?.toString() ?? '',
      speakerKey: map['speakerKey']?.toString() ?? '',
      strategySummary: map['strategySummary']?.toString() ?? '',
      successfulSteps: parseList('successfulSteps'),
      wastedSteps: parseList('wastedSteps'),
      errorSignals: parseList('errorSignals'),
      durationSeconds: (map['durationSeconds'] as num?)?.toDouble() ?? 0.0,
      firstResponseLatencySeconds:
          (map['firstResponseLatencySeconds'] as num?)?.toDouble() ?? 0.0,
      turnCount: (map['turnCount'] as num?)?.toInt() ?? 0,
      correctionCount: (map['correctionCount'] as num?)?.toInt() ?? 0,
      unnecessaryQuestionCount:
          (map['unnecessaryQuestionCount'] as num?)?.toInt() ?? 0,
      satisfactionSignal:
          (map['satisfactionSignal'] as num?)?.toDouble() ?? 0.5,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
