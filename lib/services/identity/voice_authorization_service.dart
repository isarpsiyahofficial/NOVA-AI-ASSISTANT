// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/identity/voice_access_decision.dart';
import 'device_owner_identity_service.dart';
import '../runtime/nova_identity_runtime_service.dart';
import 'voice_identity_registry_service.dart';

class VoiceAuthorizationService {
  final DeviceOwnerIdentityService ownerService;
  final VoiceIdentityRegistryService registryService;
  final NovaIdentityRuntimeService identityRuntimeService;

  const VoiceAuthorizationService({
    required this.ownerService,
    required this.registryService,
    this.identityRuntimeService = const NovaIdentityRuntimeService(),
  });

  static const String _unauthorizedMessage = 'Yetkiniz bulunmamaktadır.';
  static const String _neutralConversationMessage =
      'Sesi tanıdık bir profille eşleştiremedim; nötr sohbete devam edebilirim ama komut çalıştırmam efendim.';

  String _normalizeRelationship(String input) {
    final text = input.trim();
    if (text.isEmpty) return '';
    switch (text.toLowerCase()) {
      case 'anne':
      case 'mother':
        return 'Anne';
      case 'baba':
      case 'father':
        return 'Baba';
      case 'eş':
      case 'es':
      case 'spouse':
        return 'Eş';
      case 'abi':
      case 'brother':
        return 'Abi';
      case 'abla':
      case 'sister':
        return 'Abla';
      case 'kardes':
      case 'kardeş':
      case 'sibling':
        return 'Kardeş';
      default:
        return text;
    }
  }

  Future<VoiceAccessDecision> decide(String recognizedVoiceId) async {
    await identityRuntimeService.ensureLoaded();
    final assistantName = identityRuntimeService.currentDisplayName;
    final voiceId = recognizedVoiceId.trim();
    if (voiceId.isEmpty) {
      return const VoiceAccessDecision(
        level: VoiceAccessLevel.denied,
        message: _neutralConversationMessage,
        suppressStatusBroadcast: true,
      );
    }

    final owner = await ownerService.loadOwner();
    if (owner != null && owner.ownerVoiceId.trim() == voiceId) {
      return VoiceAccessDecision(
        level: VoiceAccessLevel.owner,
        message: '${owner.ownerName} hoş geldiniz efendim. Öncelik sizde.',
        recognizedName: owner.ownerName,
        relationshipLabel: 'Cihaz sahibi',
      );
    }

    final known = await registryService.findByVoiceId(voiceId);
    if (known == null) {
      return const VoiceAccessDecision(
        level: VoiceAccessLevel.denied,
        message: _neutralConversationMessage,
        suppressStatusBroadcast: true,
      );
    }

    final displayName = known.displayName.trim().isNotEmpty
        ? known.displayName.trim()
        : 'Kayıtlı kişi';
    final relationship = _normalizeRelationship(known.relationshipLabel);

    if (known.isAuthorizedToUseNova) {
      return VoiceAccessDecision(
        level: VoiceAccessLevel.authorizedGuest,
        message:
            '$displayName için $assistantName kullanım yetkisi aktif efendim. Cihaz sahibinden sonra öncelik veririm.',
        recognizedName: displayName,
        relationshipLabel: relationship.isEmpty
            ? '$assistantName kullanım yetkisi'
            : relationship,
      );
    }

    if (known.isVoiceKnown || known.introducedByOwner) {
      return VoiceAccessDecision(
        level: VoiceAccessLevel.familiar,
        message:
            '$displayName tanıştırılmış kişi olarak tanınıyor efendim. Sohbet edebilirim ama komut alamam.',
        recognizedName: displayName,
        relationshipLabel: relationship.isEmpty
            ? 'Tanıştırılmış kişi'
            : relationship,
      );
    }

    return VoiceAccessDecision(
      level: VoiceAccessLevel.knownButUnauthorized,
      message:
          '$displayName tanınıyor efendim. Sohbet edebilirim ama işlem ve komut çalıştırmam.',
      recognizedName: displayName,
      relationshipLabel: relationship.isEmpty ? 'Tanınmış kişi' : relationship,
    );
  }

  Future<bool> isOwnerVoice(String recognizedVoiceId) async {
    final decision = await decide(recognizedVoiceId);
    return decision.level == VoiceAccessLevel.owner;
  }

  Future<bool> isAuthorizedVoice(String recognizedVoiceId) async {
    final decision = await decide(recognizedVoiceId);
    return decision.level == VoiceAccessLevel.owner ||
        decision.level == VoiceAccessLevel.authorizedGuest;
  }

  Future<bool> canWakeNova(String recognizedVoiceId) async {
    return isAuthorizedVoice(recognizedVoiceId);
  }

  Future<bool> canControlNova(String recognizedVoiceId) async {
    return isAuthorizedVoice(recognizedVoiceId);
  }
}
