// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'automation_command.dart';

class AutomationWorkflow {
  final String id;
  final String title;
  final String triggerPhrase;
  final String description;
  final List<AutomationCommand> commands;

  /// Görsel / sözlü / yazılı / karışık
  final String learnedFrom;

  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AutomationWorkflow({
    required this.id,
    required this.title,
    required this.triggerPhrase,
    required this.description,
    required this.commands,
    required this.learnedFrom,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });

  AutomationWorkflow copyWith({
    String? id,
    String? title,
    String? triggerPhrase,
    String? description,
    List<AutomationCommand>? commands,
    String? learnedFrom,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AutomationWorkflow(
      id: id ?? this.id,
      title: title ?? this.title,
      triggerPhrase: triggerPhrase ?? this.triggerPhrase,
      description: description ?? this.description,
      commands: commands ?? this.commands,
      learnedFrom: learnedFrom ?? this.learnedFrom,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasUsableTrigger => triggerPhrase.trim().isNotEmpty;
  bool get hasCommands => commands.isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'triggerPhrase': triggerPhrase,
      'description': description,
      'commands': commands.map((e) => e.toMap()).toList(growable: false),
      'learnedFrom': learnedFrom,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AutomationWorkflow.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return AutomationWorkflow(
      id: (map['id'] as String? ?? '').trim(),
      title: (map['title'] as String? ?? '').trim(),
      triggerPhrase: (map['triggerPhrase'] as String? ?? '').trim(),
      description: (map['description'] as String? ?? '').trim(),
      commands: ((map['commands'] as List?) ?? const <dynamic>[])
          .map(
            (e) =>
                AutomationCommand.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .where((e) => e.id.isNotEmpty)
          .toList(growable: false),
      learnedFrom: (map['learnedFrom'] as String? ?? 'manual').trim(),
      enabled: map['enabled'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? now,
    );
  }
}
