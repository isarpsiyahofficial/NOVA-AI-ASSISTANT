// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'call_audio_route.dart';

class CallAudioState {
  final bool inCall;
  final bool novaSpeakingMode;
  final bool callMicrophoneMuted;
  final CallAudioRoute audioRoute;

  /// Kullanıcıya geri verilebilecek önceki güvenli durum
  final bool previousMicMuted;
  final CallAudioRoute previousRoute;

  const CallAudioState({
    required this.inCall,
    required this.novaSpeakingMode,
    required this.callMicrophoneMuted,
    required this.audioRoute,
    required this.previousMicMuted,
    required this.previousRoute,
  });

  const CallAudioState.idle()
    : inCall = false,
      novaSpeakingMode = false,
      callMicrophoneMuted = false,
      audioRoute = CallAudioRoute.earpiece,
      previousMicMuted = false,
      previousRoute = CallAudioRoute.earpiece;

  CallAudioState copyWith({
    bool? inCall,
    bool? novaSpeakingMode,
    bool? callMicrophoneMuted,
    CallAudioRoute? audioRoute,
    bool? previousMicMuted,
    CallAudioRoute? previousRoute,
  }) {
    return CallAudioState(
      inCall: inCall ?? this.inCall,
      novaSpeakingMode: novaSpeakingMode ?? this.novaSpeakingMode,
      callMicrophoneMuted: callMicrophoneMuted ?? this.callMicrophoneMuted,
      audioRoute: audioRoute ?? this.audioRoute,
      previousMicMuted: previousMicMuted ?? this.previousMicMuted,
      previousRoute: previousRoute ?? this.previousRoute,
    );
  }

  bool get isSpeakerMode => audioRoute == CallAudioRoute.speaker;
  bool get isSafeForUserSpeaking => !callMicrophoneMuted;
}
