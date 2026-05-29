// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaIdentityRolloutProgress {
  final int percent;
  final String title;
  final String detail;
  final bool success;

  const NovaIdentityRolloutProgress({
    required this.percent,
    required this.title,
    required this.detail,
    this.success = true,
  });
}

class NovaCapabilityAuditReport {
  final Map<String, bool> capabilities;
  final Map<String, List<String>> layerGroups;
  final List<String> adaptedFiles;
  final Map<String, List<String>> bindingGroups;
  final int repositoryDartFileCount;

  const NovaCapabilityAuditReport({
    required this.capabilities,
    this.layerGroups = const <String, List<String>>{},
    this.adaptedFiles = const <String>[],
    this.bindingGroups = const <String, List<String>>{},
    this.repositoryDartFileCount = 0,
  });

  List<String> get enabledCapabilities => capabilities.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList(growable: false);

  List<String> get missingCapabilities => capabilities.entries
      .where((entry) => !entry.value)
      .map((entry) => entry.key)
      .toList(growable: false);

  int get totalAuditedFiles => adaptedFiles.length;
  int get totalBindingFiles =>
      bindingGroups.values.expand((e) => e).toSet().length;
}

class NovaIdentityRolloutReport {
  final String assistantName;
  final bool success;
  final List<NovaIdentityRolloutProgress> progress;
  final NovaCapabilityAuditReport auditReport;
  final List<String> adaptedSystems;
  final String summary;

  const NovaIdentityRolloutReport({
    required this.assistantName,
    required this.success,
    required this.progress,
    required this.auditReport,
    required this.adaptedSystems,
    required this.summary,
  });
}
