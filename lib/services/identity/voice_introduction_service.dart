// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/identity/known_voice_identity.dart';
import 'voice_identity_registry_service.dart';

class VoiceIntroductionService {
  final VoiceIdentityRegistryService registryService;

  const VoiceIntroductionService({required this.registryService});

  Future<void> introducePerson({
    required String displayName,
    required String relationshipLabel,
    required String voiceId,
    bool grantNovaPermission = false,
    bool allowAutoCallHandling = false,
    bool familiarOnly = false,
  }) async {
    final now = DateTime.now();
    final normalizedVoiceId = voiceId.trim();

    if (normalizedVoiceId.isEmpty) {
      return;
    }

    final existing = await registryService.findByVoiceId(normalizedVoiceId);

    final identity = KnownVoiceIdentity(
      id: existing?.id ?? normalizedVoiceId,
      displayName: displayName.trim(),
      relationshipLabel: relationshipLabel.trim(),
      voiceId: normalizedVoiceId,
      isVoiceKnown: true,
      isAuthorizedToUseNova: familiarOnly ? false : grantNovaPermission,
      canReceiveAutoCallHandling: allowAutoCallHandling,
      introducedByOwner: true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await registryService.addOrUpdate(identity);
  }

  Future<void> updatePermission({
    required String voiceId,
    required bool authorizedToUseNova,
    required bool canReceiveAutoCallHandling,
  }) async {
    final current = await registryService.findByVoiceId(voiceId);
    if (current == null) return;

    await registryService.addOrUpdate(
      current.copyWith(
        isAuthorizedToUseNova: authorizedToUseNova,
        canReceiveAutoCallHandling: canReceiveAutoCallHandling,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> markAsFamiliar({
    required String displayName,
    required String relationshipLabel,
    required String voiceId,
  }) async {
    await introducePerson(
      displayName: displayName,
      relationshipLabel: relationshipLabel,
      voiceId: voiceId,
      grantNovaPermission: false,
      allowAutoCallHandling: false,
      familiarOnly: true,
    );
  }

  Future<void> markAsAuthorized({
    required String displayName,
    required String relationshipLabel,
    required String voiceId,
    bool allowAutoCallHandling = false,
  }) async {
    await introducePerson(
      displayName: displayName,
      relationshipLabel: relationshipLabel,
      voiceId: voiceId,
      grantNovaPermission: true,
      allowAutoCallHandling: allowAutoCallHandling,
      familiarOnly: false,
    );
  }
}
