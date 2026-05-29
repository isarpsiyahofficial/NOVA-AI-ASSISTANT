// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// GEMMA95952_SAFE_SELF_REPAIR_KERNEL

class NovaRepairAuditEntry {
  final String id;
  final String category;
  final String title;
  final String detail;
  final String manifestId;
  final String targetPolicy;
  final String riskLevel;
  final String oldValue;
  final String newValue;
  final String securityDecision;
  final String validationResult;
  final String rollbackKey;
  final bool aiAuthored;
  final bool userApproved;
  final DateTime createdAt;

  const NovaRepairAuditEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.detail,
    required this.manifestId,
    required this.targetPolicy,
    required this.riskLevel,
    required this.oldValue,
    required this.newValue,
    required this.securityDecision,
    required this.validationResult,
    required this.rollbackKey,
    required this.aiAuthored,
    required this.userApproved,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'category': category,
    'title': title,
    'detail': detail,
    'manifestId': manifestId,
    'targetPolicy': targetPolicy,
    'riskLevel': riskLevel,
    'oldValue': oldValue,
    'newValue': newValue,
    'securityDecision': securityDecision,
    'validationResult': validationResult,
    'rollbackKey': rollbackKey,
    'aiAuthored': aiAuthored,
    'userApproved': userApproved,
    'createdAt': createdAt.toIso8601String(),
  };

  factory NovaRepairAuditEntry.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return NovaRepairAuditEntry(
      id: (map['id'] as String? ?? '').trim(),
      category: (map['category'] as String? ?? '').trim(),
      title: (map['title'] as String? ?? '').trim(),
      detail: (map['detail'] as String? ?? '').trim(),
      manifestId: (map['manifestId'] as String? ?? '').trim(),
      targetPolicy: (map['targetPolicy'] as String? ?? '').trim(),
      riskLevel: (map['riskLevel'] as String? ?? '').trim(),
      oldValue: (map['oldValue'] as String? ?? '').trim(),
      newValue: (map['newValue'] as String? ?? '').trim(),
      securityDecision: (map['securityDecision'] as String? ?? '').trim(),
      validationResult: (map['validationResult'] as String? ?? '').trim(),
      rollbackKey: (map['rollbackKey'] as String? ?? '').trim(),
      aiAuthored: map['aiAuthored'] as bool? ?? false,
      userApproved: map['userApproved'] as bool? ?? false,
      createdAt:
          DateTime.tryParse((map['createdAt'] as String? ?? '').trim()) ?? now,
    );
  }
}
