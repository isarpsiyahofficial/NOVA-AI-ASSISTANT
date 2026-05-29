// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_self_repair_issue.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import '../runtime/nova_runtime_signal_service.dart';
import '../security/nova_security_incident_service.dart';

class NovaSelfRepairService {
  const NovaSelfRepairService();

  Future<List<NovaSelfRepairIssue>> collectIssues({
    required NovaRuntimeSignalService runtimeSignalService,
    required NovaSecurityIncidentService securityIncidentService,
  }) async {
    final signals = await runtimeSignalService.getAll();
    final protectedReports = await securityIncidentService.getAllReports();
    final issues = <NovaSelfRepairIssue>[];

    for (final signal in signals.take(40)) {
      final bool ownerPatchRequired =
          (!signal.diagnosticCandidate &&
              signal.level == NovaRuntimeSignalLevel.error) ||
          signal.level == NovaRuntimeSignalLevel.critical;

      issues.add(
        NovaSelfRepairIssue(
          id: signal.id,
          title: signal.code.isEmpty ? 'Runtime sinyali' : signal.code,
          humanDescription: signal.message.isEmpty
              ? 'Sorun algılandı.'
              : signal.message,
          technicalDescription: signal.technicalDetails.isEmpty
              ? signal.kind.name
              : signal.technicalDetails,
          sourceCode: signal.code,
          selfHealCandidate: signal.diagnosticCandidate,
          ownerPatchRequired: ownerPatchRequired,
          detectedAt: signal.createdAt,
        ),
      );
    }

    if (protectedReports.isNotEmpty) {
      final latest = protectedReports.first;
      issues.add(
        NovaSelfRepairIssue(
          id: 'protected_area_guarded',
          title: 'Korunan alan müdahalesi gerekiyor',
          humanDescription:
              'Sistemin korunan bir alanında sahibin dikkat etmesi gereken durum algılandı.',
          technicalDescription:
              'protected_area_attention_required:${latest.createdAt.toIso8601String()}',
          sourceCode: 'protected_area_attention_required',
          selfHealCandidate: false,
          ownerPatchRequired: true,
          detectedAt: latest.createdAt,
        ),
      );
    }

    issues.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return issues;
  }
}
