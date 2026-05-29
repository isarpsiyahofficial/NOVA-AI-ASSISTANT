// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class CallNote {
  final String id;
  final String callerName;
  final String callerNumber;
  final String content;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isCompleted;

  const CallNote({
    required this.id,
    required this.callerName,
    required this.callerNumber,
    required this.content,
    required this.createdAt,
    required this.expiresAt,
    this.isCompleted = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  CallNote copyWith({
    String? id,
    String? callerName,
    String? callerNumber,
    String? content,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isCompleted,
  }) {
    return CallNote(
      id: id ?? this.id,
      callerName: callerName ?? this.callerName,
      callerNumber: callerNumber ?? this.callerNumber,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'callerName': callerName,
      'callerNumber': callerNumber,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory CallNote.fromMap(Map<String, dynamic> map) {
    return CallNote(
      id: map['id'] as String? ?? '',
      callerName: map['callerName'] as String? ?? '',
      callerNumber: map['callerNumber'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}
