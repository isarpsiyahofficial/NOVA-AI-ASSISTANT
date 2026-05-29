// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaReminderStatus { pending, completed, cancelled }

enum NovaReminderKind { reminder, wakeAlarm }

class NovaReminder {
  final String id;
  final String text;
  final String dueAtIso;
  final NovaReminderStatus status;
  final String createdAtIso;
  final String? completedAtIso;
  final NovaReminderKind kind;

  /// Yeni alanlar
  final bool repeatUntilAcknowledged;
  final int maxActiveMinutes;
  final String wakeStyleKey;
  final String? activeUntilIso;
  final String? lastTriggeredAtIso;
  final String? acknowledgedAtIso;
  final int triggerCount;

  const NovaReminder({
    required this.id,
    required this.text,
    required this.dueAtIso,
    required this.status,
    required this.createdAtIso,
    this.completedAtIso,
    this.kind = NovaReminderKind.reminder,
    this.repeatUntilAcknowledged = false,
    this.maxActiveMinutes = 10,
    this.wakeStyleKey = 'wake_alarm_loop_style',
    this.activeUntilIso,
    this.lastTriggeredAtIso,
    this.acknowledgedAtIso,
    this.triggerCount = 0,
  });

  NovaReminder copyWith({
    String? id,
    String? text,
    String? dueAtIso,
    NovaReminderStatus? status,
    String? createdAtIso,
    String? completedAtIso,
    NovaReminderKind? kind,
    bool? repeatUntilAcknowledged,
    int? maxActiveMinutes,
    String? wakeStyleKey,
    String? activeUntilIso,
    String? lastTriggeredAtIso,
    String? acknowledgedAtIso,
    int? triggerCount,
  }) {
    return NovaReminder(
      id: id ?? this.id,
      text: text ?? this.text,
      dueAtIso: dueAtIso ?? this.dueAtIso,
      status: status ?? this.status,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      completedAtIso: completedAtIso ?? this.completedAtIso,
      kind: kind ?? this.kind,
      repeatUntilAcknowledged:
          repeatUntilAcknowledged ?? this.repeatUntilAcknowledged,
      maxActiveMinutes: maxActiveMinutes ?? this.maxActiveMinutes,
      wakeStyleKey: wakeStyleKey ?? this.wakeStyleKey,
      activeUntilIso: activeUntilIso ?? this.activeUntilIso,
      lastTriggeredAtIso: lastTriggeredAtIso ?? this.lastTriggeredAtIso,
      acknowledgedAtIso: acknowledgedAtIso ?? this.acknowledgedAtIso,
      triggerCount: triggerCount ?? this.triggerCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'dueAtIso': dueAtIso,
      'status': status.name,
      'createdAtIso': createdAtIso,
      'completedAtIso': completedAtIso,
      'kind': kind.name,
      'repeatUntilAcknowledged': repeatUntilAcknowledged,
      'maxActiveMinutes': maxActiveMinutes,
      'wakeStyleKey': wakeStyleKey,
      'activeUntilIso': activeUntilIso,
      'lastTriggeredAtIso': lastTriggeredAtIso,
      'acknowledgedAtIso': acknowledgedAtIso,
      'triggerCount': triggerCount,
    };
  }

  factory NovaReminder.fromMap(Map<String, dynamic> map) {
    return NovaReminder(
      id: (map['id'] as String? ?? '').trim(),
      text: (map['text'] as String? ?? '').trim(),
      dueAtIso: (map['dueAtIso'] as String? ?? '').trim(),
      status: NovaReminderStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'pending'),
        orElse: () => NovaReminderStatus.pending,
      ),
      createdAtIso: (map['createdAtIso'] as String? ?? '').trim(),
      completedAtIso: map['completedAtIso'] as String?,
      kind: NovaReminderKind.values.firstWhere(
        (e) => e.name == (map['kind'] as String? ?? 'reminder'),
        orElse: () => NovaReminderKind.reminder,
      ),
      repeatUntilAcknowledged: map['repeatUntilAcknowledged'] as bool? ?? false,
      maxActiveMinutes: map['maxActiveMinutes'] as int? ?? 10,
      wakeStyleKey: (map['wakeStyleKey'] as String? ?? 'wake_alarm_loop_style')
          .trim(),
      activeUntilIso: map['activeUntilIso'] as String?,
      lastTriggeredAtIso: map['lastTriggeredAtIso'] as String?,
      acknowledgedAtIso: map['acknowledgedAtIso'] as String?,
      triggerCount: map['triggerCount'] as int? ?? 0,
    );
  }
}
