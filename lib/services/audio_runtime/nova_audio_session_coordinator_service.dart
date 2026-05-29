// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_AUDIO_SESSION_PRIORITY_GUARD_V2
import '../../core/audio_runtime/nova_audio_session_owner.dart';

class NovaAudioSessionCoordinatorService {
  NovaAudioSessionOwner _owner = NovaAudioSessionOwner.idle;

  NovaAudioSessionCoordinatorService();

  NovaAudioSessionOwner get owner => _owner;

  bool tryAcquire(NovaAudioSessionOwner nextOwner) {
    if (_owner == nextOwner) return true;
    if (_owner == NovaAudioSessionOwner.idle) {
      _owner = nextOwner;
      return true;
    }

    // Call and call-companion audio must not be stolen by normal/background ASR.
    if (_owner == NovaAudioSessionOwner.call &&
        nextOwner != NovaAudioSessionOwner.call) {
      return false;
    }
    if (_owner == NovaAudioSessionOwner.callCompanion &&
        nextOwner != NovaAudioSessionOwner.callCompanion &&
        nextOwner != NovaAudioSessionOwner.tts) {
      return false;
    }

    // A real call/companion owner may take over lower priority media/continuous listening.
    if (_priority(nextOwner) >= _priority(_owner)) {
      _owner = nextOwner;
      return true;
    }
    return false;
  }

  void release(NovaAudioSessionOwner owner) {
    if (_owner == owner) {
      _owner = NovaAudioSessionOwner.idle;
    }
  }

  int _priority(NovaAudioSessionOwner owner) {
    switch (owner) {
      case NovaAudioSessionOwner.idle:
        return 0;
      case NovaAudioSessionOwner.media:
        return 10;
      case NovaAudioSessionOwner.continuousListening:
        return 20;
      case NovaAudioSessionOwner.tts:
        return 30;
      case NovaAudioSessionOwner.callCompanion:
        return 50;
      case NovaAudioSessionOwner.call:
        return 60;
    }
  }
}
