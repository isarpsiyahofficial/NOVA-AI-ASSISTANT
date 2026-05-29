// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_owner_blind_patch_receipt.dart';

class NovaOwnerBlindPatchGuardService {
  const NovaOwnerBlindPatchGuardService();

  bool canExposeFragment({
    required String capabilityId,
    required String targetArea,
  }) {
    final normalizedCapability = capabilityId.trim().toLowerCase();
    final normalizedArea = targetArea.trim().toLowerCase();
    const allowedCapabilities = <String>{
      'speech_understanding',
      'speech_response',
      'speech_and_understanding',
    };
    const allowedAreas = <String>{
      'speech_understanding',
      'speech_response',
      'speech_and_understanding',
      'voice_understanding',
      'voice_response',
    };
    return allowedCapabilities.contains(normalizedCapability) &&
        allowedAreas.contains(normalizedArea);
  }

  NovaOwnerBlindPatchReceipt sanitizeReceipt(
    NovaOwnerBlindPatchReceipt receipt,
  ) {
    return NovaOwnerBlindPatchReceipt(
      available: receipt.available,
      sessionId: receipt.sessionId.trim(),
      targetArea: receipt.targetArea.trim(),
      fragmentText: receipt.fragmentText.trim(),
    );
  }
}
