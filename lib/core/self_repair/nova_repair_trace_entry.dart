// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaRepairTraceEntry {
  final String id;
  final String issueCode;
  final String solutionSummary;
  final String decisionLevel;
  final DateTime createdAt;

  const NovaRepairTraceEntry({
    required this.id,
    required this.issueCode,
    required this.solutionSummary,
    required this.decisionLevel,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'issueCode': issueCode,
    'solutionSummary': solutionSummary,
    'decisionLevel': decisionLevel,
    'createdAt': createdAt.toIso8601String(),
  };

  factory NovaRepairTraceEntry.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return NovaRepairTraceEntry(
      id: (map['id'] as String? ?? '').trim(),
      issueCode: (map['issueCode'] as String? ?? '').trim(),
      solutionSummary: (map['solutionSummary'] as String? ?? '').trim(),
      decisionLevel: (map['decisionLevel'] as String? ?? '').trim(),
      createdAt:
          DateTime.tryParse((map['createdAt'] as String? ?? '').trim()) ?? now,
    );
  }
}
