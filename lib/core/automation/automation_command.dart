// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum AutomationCommandType {
  tap,
  longPress,
  typeText,
  scroll,
  wait,
  back,
  openApp,
  closeApp,
  readScreen,
  custom,
}

class AutomationCommand {
  final String id;
  final AutomationCommandType type;
  final String description;

  /// Hedef metin, paket adı, yazılacak içerik vb.
  final String target;

  /// Opsiyonel sayısal değerler (bekleme süresi, x/y, scroll miktarı vb.)
  final Map<String, double> numericArgs;

  const AutomationCommand({
    required this.id,
    required this.type,
    required this.description,
    this.target = '',
    this.numericArgs = const <String, double>{},
  });

  AutomationCommand copyWith({
    String? id,
    AutomationCommandType? type,
    String? description,
    String? target,
    Map<String, double>? numericArgs,
  }) {
    return AutomationCommand(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      target: target ?? this.target,
      numericArgs: numericArgs ?? this.numericArgs,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'description': description,
      'target': target,
      'numericArgs': numericArgs,
    };
  }

  factory AutomationCommand.fromMap(Map<String, dynamic> map) {
    return AutomationCommand(
      id: (map['id'] as String? ?? '').trim(),
      type: AutomationCommandType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'custom'),
        orElse: () => AutomationCommandType.custom,
      ),
      description: (map['description'] as String? ?? '').trim(),
      target: (map['target'] as String? ?? '').trim(),
      numericArgs: ((map['numericArgs'] as Map?) ?? const <String, dynamic>{})
          .map(
            (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
          ),
    );
  }
}
