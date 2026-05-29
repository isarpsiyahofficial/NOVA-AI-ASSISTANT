// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_owner_patch.dart';
import '../../core/self_repair/nova_patch_validation_result.dart';

class NovaPatchValidationService {
  const NovaPatchValidationService();

  NovaPatchValidationResult validate(NovaOwnerPatch patch) {
    final checks = <String>[];
    final area = patch.targetArea.trim().toLowerCase();
    final text = patch.patchText.trim();
    final lowered = text.toLowerCase();

    const allowedAreas = <String>{
      'speech_understanding',
      'speech_response',
      'speech_and_understanding',
      'voice_understanding',
      'voice_response',
    };

    if (allowedAreas.contains(area)) {
      checks.add('Hedef alan izinli konuşma/anlama kapsamı içinde.');
    }

    if (text.length >= 8 && text.length <= 6000) {
      checks.add('Patch içeriği boyut sınırları içinde.');
    }

    final containsUnsafe =
        lowered.contains('delete from') ||
        lowered.contains('rm -rf') ||
        lowered.contains('drop table') ||
        lowered.contains('androidmanifest') ||
        lowered.contains('build.gradle') ||
        lowered.contains('methodchannel') ||
        lowered.contains('security_') ||
        lowered.contains('killstage') ||
        lowered.contains('owner_blind_patch') ||
        lowered.contains('recoverytoken') ||
        lowered.contains('quarantine') ||
        lowered.contains('internet permission') ||
        lowered.contains('uses-permission') ||
        lowered.contains('http://') ||
        lowered.contains('https://') ||
        lowered.contains('socket') ||
        lowered.contains('dart:io') ||
        lowered.contains('file(');

    if (!containsUnsafe) {
      checks.add(
        'Güvenlik/kök sistemleri ve internet açan yasaklı ifade görünmüyor.',
      );
    }

    final accepted =
        allowedAreas.contains(area) &&
        text.length >= 8 &&
        text.length <= 6000 &&
        !containsUnsafe;

    return NovaPatchValidationResult(
      accepted: accepted,
      message: accepted
          ? 'Patch doğrulama ön kontrolünden geçti.'
          : 'Patch yalnız konuşma/anlama kapsamındaki owner-directed kör akışta kabul edilir.',
      checks: checks,
    );
  }
}
