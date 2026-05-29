// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum PhoneControlTaskStatus { pending, running, completed, failed, cancelled }

class PhoneControlTask {
  final String id;
  final String title;
  final String description;
  final List<String> steps;
  final PhoneControlTaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PhoneControlTask({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  PhoneControlTask copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? steps,
    PhoneControlTaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PhoneControlTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'steps': steps,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PhoneControlTask.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return PhoneControlTask(
      id: (map['id'] as String? ?? '').trim(),
      title: (map['title'] as String? ?? '').trim(),
      description: (map['description'] as String? ?? '').trim(),
      steps: ((map['steps'] as List?) ?? const <dynamic>[])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      status: PhoneControlTaskStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'pending'),
        orElse: () => PhoneControlTaskStatus.pending,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? now,
    );
  }
}
