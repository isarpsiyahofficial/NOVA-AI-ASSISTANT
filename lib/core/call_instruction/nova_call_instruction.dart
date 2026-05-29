// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

import '../contacts/nova_contact.dart';

enum NovaCallInstructionStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

enum NovaCallInstructionType { immediate, scheduledOnce, recurringDaily }

class NovaCallInstruction {
  final String id;
  final NovaCallInstructionType type;
  final NovaCallInstructionStatus status;
  final String contactId;
  final String contactName;
  final String phoneNumber;
  final String instructionText;
  final bool speakerPreferred;
  final String createdAtIso;
  final String scheduledForIso;
  final String? completedAtIso;
  final String? lastExecutedAtIso;
  final String recurrenceLabel;

  const NovaCallInstruction({
    required this.id,
    required this.type,
    required this.status,
    required this.contactId,
    required this.contactName,
    required this.phoneNumber,
    required this.instructionText,
    required this.speakerPreferred,
    required this.createdAtIso,
    required this.scheduledForIso,
    this.completedAtIso,
    this.lastExecutedAtIso,
    this.recurrenceLabel = '',
  });

  bool get isCompleted => status == NovaCallInstructionStatus.completed;
  bool get isPending => status == NovaCallInstructionStatus.pending;

  String get title {
    final when = switch (type) {
      NovaCallInstructionType.immediate => 'Anlık çağrı görevi',
      NovaCallInstructionType.scheduledOnce => 'Planlı çağrı görevi',
      NovaCallInstructionType.recurringDaily => 'Tekrarlı çağrı görevi',
    };
    return '$when • $contactName';
  }

  NovaCallInstruction copyWith({
    String? id,
    NovaCallInstructionType? type,
    NovaCallInstructionStatus? status,
    String? contactId,
    String? contactName,
    String? phoneNumber,
    String? instructionText,
    bool? speakerPreferred,
    String? createdAtIso,
    String? scheduledForIso,
    String? completedAtIso,
    String? lastExecutedAtIso,
    String? recurrenceLabel,
  }) {
    return NovaCallInstruction(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      instructionText: instructionText ?? this.instructionText,
      speakerPreferred: speakerPreferred ?? this.speakerPreferred,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      scheduledForIso: scheduledForIso ?? this.scheduledForIso,
      completedAtIso: completedAtIso ?? this.completedAtIso,
      lastExecutedAtIso: lastExecutedAtIso ?? this.lastExecutedAtIso,
      recurrenceLabel: recurrenceLabel ?? this.recurrenceLabel,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'status': status.name,
    'contactId': contactId,
    'contactName': contactName,
    'phoneNumber': phoneNumber,
    'instructionText': instructionText,
    'speakerPreferred': speakerPreferred,
    'createdAtIso': createdAtIso,
    'scheduledForIso': scheduledForIso,
    'completedAtIso': completedAtIso,
    'lastExecutedAtIso': lastExecutedAtIso,
    'recurrenceLabel': recurrenceLabel,
  };

  factory NovaCallInstruction.fromMap(Map<String, dynamic> map) =>
      NovaCallInstruction(
        id: (map['id'] as String? ?? '').trim(),
        type: NovaCallInstructionType.values.firstWhere(
          (e) => e.name == (map['type'] as String? ?? 'scheduledOnce'),
          orElse: () => NovaCallInstructionType.scheduledOnce,
        ),
        status: NovaCallInstructionStatus.values.firstWhere(
          (e) => e.name == (map['status'] as String? ?? 'pending'),
          orElse: () => NovaCallInstructionStatus.pending,
        ),
        contactId: (map['contactId'] as String? ?? '').trim(),
        contactName: (map['contactName'] as String? ?? '').trim(),
        phoneNumber: (map['phoneNumber'] as String? ?? '').trim(),
        instructionText: (map['instructionText'] as String? ?? '').trim(),
        speakerPreferred: map['speakerPreferred'] as bool? ?? false,
        createdAtIso: (map['createdAtIso'] as String? ?? '').trim(),
        scheduledForIso: (map['scheduledForIso'] as String? ?? '').trim(),
        completedAtIso: map['completedAtIso'] as String?,
        lastExecutedAtIso: map['lastExecutedAtIso'] as String?,
        recurrenceLabel: (map['recurrenceLabel'] as String? ?? '').trim(),
      );
}

class NovaCallInstructionDraft {
  final NovaContact? contact;
  final String instructionText;
  final bool speakerPreferred;
  final NovaCallInstructionType type;
  final DateTime scheduledFor;
  final String recurrenceLabel;

  const NovaCallInstructionDraft({
    required this.contact,
    required this.instructionText,
    required this.speakerPreferred,
    required this.type,
    required this.scheduledFor,
    this.recurrenceLabel = '',
  });
}
