// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaCapabilityDescriptor {
  final String capabilityId;
  final String title;
  final String humanSummary;
  final String technicalSummary;
  final bool selfRepairAllowed;
  final bool ownerPatchAllowed;
  final List<String> signalCodes;
  final DateTime discoveredAt;
  final bool inferredFromSignals;

  const NovaCapabilityDescriptor({
    required this.capabilityId,
    required this.title,
    required this.humanSummary,
    required this.technicalSummary,
    required this.selfRepairAllowed,
    required this.ownerPatchAllowed,
    required this.signalCodes,
    required this.discoveredAt,
    this.inferredFromSignals = false,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'capabilityId': capabilityId,
    'title': title,
    'humanSummary': humanSummary,
    'technicalSummary': technicalSummary,
    'selfRepairAllowed': selfRepairAllowed,
    'ownerPatchAllowed': ownerPatchAllowed,
    'signalCodes': signalCodes,
    'discoveredAt': discoveredAt.toIso8601String(),
    'inferredFromSignals': inferredFromSignals,
  };

  factory NovaCapabilityDescriptor.fromMap(Map<String, dynamic> map) {
    return NovaCapabilityDescriptor(
      capabilityId: (map['capabilityId'] as String? ?? '').trim(),
      title: (map['title'] as String? ?? '').trim(),
      humanSummary: (map['humanSummary'] as String? ?? '').trim(),
      technicalSummary: (map['technicalSummary'] as String? ?? '').trim(),
      selfRepairAllowed: map['selfRepairAllowed'] as bool? ?? false,
      ownerPatchAllowed: map['ownerPatchAllowed'] as bool? ?? false,
      signalCodes: (map['signalCodes'] as List? ?? const <dynamic>[])
          .map((dynamic e) => '$e')
          .toList(growable: false),
      discoveredAt:
          DateTime.tryParse((map['discoveredAt'] as String? ?? '').trim()) ??
          DateTime.now(),
      inferredFromSignals: map['inferredFromSignals'] as bool? ?? false,
    );
  }
}
