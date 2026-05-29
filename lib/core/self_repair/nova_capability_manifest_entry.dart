// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaCapabilityManifestEntry {
  final String capabilityId;
  final String title;
  final String humanSummary;
  final String technicalSummary;
  final bool selfRepairAllowed;
  final bool ownerPatchAllowed;
  final List<String> tags;
  final List<String> signalCodes;
  final List<String> restartTargets;

  const NovaCapabilityManifestEntry({
    required this.capabilityId,
    required this.title,
    required this.humanSummary,
    required this.technicalSummary,
    required this.selfRepairAllowed,
    required this.ownerPatchAllowed,
    this.tags = const <String>[],
    this.signalCodes = const <String>[],
    this.restartTargets = const <String>[],
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'capabilityId': capabilityId,
    'title': title,
    'humanSummary': humanSummary,
    'technicalSummary': technicalSummary,
    'selfRepairAllowed': selfRepairAllowed,
    'ownerPatchAllowed': ownerPatchAllowed,
    'tags': tags,
    'signalCodes': signalCodes,
    'restartTargets': restartTargets,
  };

  factory NovaCapabilityManifestEntry.fromMap(Map<String, dynamic> map) {
    return NovaCapabilityManifestEntry(
      capabilityId: (map['capabilityId'] as String? ?? '').trim(),
      title: (map['title'] as String? ?? '').trim(),
      humanSummary: (map['humanSummary'] as String? ?? '').trim(),
      technicalSummary: (map['technicalSummary'] as String? ?? '').trim(),
      selfRepairAllowed: map['selfRepairAllowed'] as bool? ?? false,
      ownerPatchAllowed: map['ownerPatchAllowed'] as bool? ?? false,
      tags: (map['tags'] as List? ?? const <dynamic>[])
          .map((e) => '$e')
          .toList(growable: false),
      signalCodes: (map['signalCodes'] as List? ?? const <dynamic>[])
          .map((e) => '$e')
          .toList(growable: false),
      restartTargets: (map['restartTargets'] as List? ?? const <dynamic>[])
          .map((e) => '$e')
          .toList(growable: false),
    );
  }
}
