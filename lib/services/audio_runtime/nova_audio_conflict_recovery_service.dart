// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/audio_runtime/nova_audio_session_owner.dart';
import 'nova_audio_session_coordinator_service.dart';

class NovaAudioConflictRecoveryService {
  final NovaAudioSessionCoordinatorService coordinatorService;

  const NovaAudioConflictRecoveryService({required this.coordinatorService});

  String recoverFor(NovaAudioSessionOwner requestedOwner) {
    final acquired = coordinatorService.tryAcquire(requestedOwner);
    if (acquired) {
      return 'Ses oturumu ${requestedOwner.name} için hazır.';
    }
    return 'Ses oturumu çakıştı. Önce ${coordinatorService.owner.name} bırakılmalı.';
  }
}
