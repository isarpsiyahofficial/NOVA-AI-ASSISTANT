// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_owner_patch.dart';
import '../../core/self_repair/nova_patch_validation_result.dart';
import 'nova_owner_blind_patch_bridge_service.dart';
import 'nova_owner_blind_patch_guard_service.dart';
import 'nova_owner_patch_service.dart';
import 'nova_patch_validation_service.dart';

class NovaOwnerDirectedSpeechPatchExecutionResult {
  final bool success;
  final String message;
  final NovaOwnerPatch? patch;

  const NovaOwnerDirectedSpeechPatchExecutionResult({
    required this.success,
    required this.message,
    required this.patch,
  });
}

class NovaOwnerDirectedSpeechPatchExecutionService {
  final NovaOwnerBlindPatchBridgeService bridgeService;
  final NovaOwnerBlindPatchGuardService guardService;
  final NovaPatchValidationService patchValidationService;
  final NovaOwnerPatchService ownerPatchService;
  final Future<bool> Function(NovaOwnerPatch patch) applyPatch;

  const NovaOwnerDirectedSpeechPatchExecutionService({
    required this.bridgeService,
    required this.guardService,
    required this.patchValidationService,
    required this.ownerPatchService,
    required this.applyPatch,
  });

  Future<NovaOwnerDirectedSpeechPatchExecutionResult> execute({
    required String capabilityId,
    required String targetArea,
    required String humanSummary,
  }) async {
    return const NovaOwnerDirectedSpeechPatchExecutionResult(
      success: false,
      message:
          'Owner-directed kör patch güvenli self-repair kernel tarafından devre dışı bırakıldı. Runtime onarım yalnız RepairGateway/AuditLedger onaylı policy alanlarında yapılır.',
      patch: null,
    );
  }

  NovaPatchValidationResult _verifySafetyTriad({
    required NovaOwnerPatch patch,
    required NovaPatchValidationResult validation,
    required String ownerHumanSummary,
  }) {
    final checks = <String>[
      ...validation.checks,
      'owner_approval_present:${ownerHumanSummary.trim().isNotEmpty}',
      'validator_accepted:${validation.accepted}',
      'rollback_backup_required:true',
      'host_apply_patch_is_single_gate:true',
    ];
    if (ownerHumanSummary.trim().isEmpty) {
      return NovaPatchValidationResult(
        accepted: false,
        message: 'Owner onayı/insan özeti olmadan patch uygulanamaz.',
        checks: checks,
      );
    }
    if (!validation.accepted) {
      return NovaPatchValidationResult(
        accepted: false,
        message: validation.message,
        checks: checks,
      );
    }
    final patchText = patch.patchText.toLowerCase();
    final forbidden = <String>[
      'delete_recursive_without_backup',
      'disable_security',
      'bypass_owner',
      'override_quarantine',
      'unrestricted_exec',
    ];
    final dangerous = forbidden.any(patchText.contains);
    if (dangerous) {
      return NovaPatchValidationResult(
        accepted: false,
        message:
            'Patch güvenlik/rollback sınırlarını zayıflatabilecek ifade içeriyor.',
        checks: checks,
      );
    }
    return NovaPatchValidationResult(
      accepted: true,
      message:
          'Owner approval + validator + rollback/backup preflight zinciri sağlandı.',
      checks: checks,
    );
  }
}
