// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_system_issue.dart';
import 'nova_self_diagnostic_service.dart';

class NovaRepairValidationResult {
  final bool success;
  final String message;
  final List<NovaSystemIssue> remainingIssues;

  const NovaRepairValidationResult({
    required this.success,
    required this.message,
    required this.remainingIssues,
  });
}

class NovaRepairValidationService {
  final NovaSelfDiagnosticService diagnosticService;

  const NovaRepairValidationService({required this.diagnosticService});

  Future<NovaRepairValidationResult> validate(NovaSystemIssue issue) async {
    final issues = await diagnosticService.diagnose();
    final stillOpen = issues.any(
      (e) =>
          e.issueId == issue.issueId ||
          (e.capabilityId == issue.capabilityId &&
              e.technicalMessage == issue.technicalMessage),
    );

    return NovaRepairValidationResult(
      success: !stillOpen,
      message: stillOpen
          ? 'Doğrulama sonrası sorun hâlâ görünüyor.'
          : 'Doğrulama başarılı. Sorun görünmüyor.',
      remainingIssues: issues,
    );
  }
}
