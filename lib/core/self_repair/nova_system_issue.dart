// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaSystemIssueStatus { open, selfHealed, needsOwnerAction, ignored }

class NovaSystemIssue {
  final String issueId;
  final String capabilityId;
  final String title;
  final String humanMessage;
  final String technicalMessage;
  final String suggestedAction;
  final bool canSelfHeal;
  final bool canRequestOwnerPatch;
  final NovaSystemIssueStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> relatedSignalIds;

  const NovaSystemIssue({
    required this.issueId,
    required this.capabilityId,
    required this.title,
    required this.humanMessage,
    required this.technicalMessage,
    required this.suggestedAction,
    required this.canSelfHeal,
    required this.canRequestOwnerPatch,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.relatedSignalIds,
  });

  NovaSystemIssue copyWith({
    String? issueId,
    String? capabilityId,
    String? title,
    String? humanMessage,
    String? technicalMessage,
    String? suggestedAction,
    bool? canSelfHeal,
    bool? canRequestOwnerPatch,
    NovaSystemIssueStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? relatedSignalIds,
  }) {
    return NovaSystemIssue(
      issueId: issueId ?? this.issueId,
      capabilityId: capabilityId ?? this.capabilityId,
      title: title ?? this.title,
      humanMessage: humanMessage ?? this.humanMessage,
      technicalMessage: technicalMessage ?? this.technicalMessage,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      canSelfHeal: canSelfHeal ?? this.canSelfHeal,
      canRequestOwnerPatch: canRequestOwnerPatch ?? this.canRequestOwnerPatch,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      relatedSignalIds: relatedSignalIds ?? this.relatedSignalIds,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'issueId': issueId,
      'capabilityId': capabilityId,
      'title': title,
      'humanMessage': humanMessage,
      'technicalMessage': technicalMessage,
      'suggestedAction': suggestedAction,
      'canSelfHeal': canSelfHeal,
      'canRequestOwnerPatch': canRequestOwnerPatch,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'relatedSignalIds': relatedSignalIds,
    };
  }

  factory NovaSystemIssue.fromMap(Map<String, dynamic> map) {
    final String statusName = (map['status'] as String? ?? 'open').trim();

    return NovaSystemIssue(
      issueId: (map['issueId'] as String? ?? '').trim(),
      capabilityId: (map['capabilityId'] as String? ?? '').trim(),
      title: (map['title'] as String? ?? '').trim(),
      humanMessage: (map['humanMessage'] as String? ?? '').trim(),
      technicalMessage: (map['technicalMessage'] as String? ?? '').trim(),
      suggestedAction: (map['suggestedAction'] as String? ?? '').trim(),
      canSelfHeal: map['canSelfHeal'] as bool? ?? false,
      canRequestOwnerPatch: map['canRequestOwnerPatch'] as bool? ?? false,
      status: NovaSystemIssueStatus.values.firstWhere(
        (NovaSystemIssueStatus e) => e.name == statusName,
        orElse: () => NovaSystemIssueStatus.open,
      ),
      createdAt:
          DateTime.tryParse((map['createdAt'] as String? ?? '').trim()) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse((map['updatedAt'] as String? ?? '').trim()) ??
          DateTime.now(),
      relatedSignalIds: (map['relatedSignalIds'] as List? ?? const <dynamic>[])
          .map((dynamic e) => '$e')
          .toList(growable: false),
    );
  }
}
