// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/call/call_audio_route.dart';
import '../../core/call/call_audio_state.dart';
import 'call_handoff_service.dart';

class CallAudioHandoffService {
  CallAudioState _state = const CallAudioState.idle();

  CallAudioState get state => _state;

  bool get isInCall => _state.inCall;
  bool get isNovaHandling => _state.novaSpeakingMode;
  bool get isUserHandling => _state.inCall && !_state.novaSpeakingMode;

  /// Çağrı başladığında mevcut güvenli sesi baz alır.
  void beginCall({
    CallAudioRoute initialRoute = CallAudioRoute.earpiece,
    bool initialMicMuted = false,
  }) {
    _state = CallAudioState(
      inCall: true,
      novaSpeakingMode: false,
      callMicrophoneMuted: initialMicMuted,
      audioRoute: initialRoute,
      previousMicMuted: initialMicMuted,
      previousRoute: initialRoute,
    );
  }

  /// Nova devralınca:
  /// - hoparlöre geç
  /// - çağrı mikrofonunu kapat
  /// - sadece Nova sesi gitsin
  void handoffToNova() {
    if (!_state.inCall) return;

    _state = _state.copyWith(
      novaSpeakingMode: true,
      callMicrophoneMuted: true,
      audioRoute: CallAudioRoute.speaker,
    );
  }

  /// Kullanıcıya bırakınca:
  /// - mikrofonu aç
  /// - önceki route'a dön
  /// - Nova konuşmayı bırak
  void handoffToUser() {
    if (!_state.inCall) return;

    _state = _state.copyWith(
      novaSpeakingMode: false,
      callMicrophoneMuted: false,
      audioRoute: _state.previousRoute,
    );
  }

  /// Güvenli reset:
  /// çağrı bitince mikrofon kilitli kalmasın
  void endCall() {
    _state = const CallAudioState.idle();
  }

  /// Dışarıdan gelen komutu çağrı ses durumuna uygular
  LiveCallMode processLiveCommand(String input, CallHandoffService handoff) {
    final mode = handoff.processCommand(input);

    switch (mode) {
      case LiveCallMode.novaSpeaking:
        handoffToNova();
        break;
      case LiveCallMode.userSpeaking:
        handoffToUser();
        break;
    }

    return mode;
  }
}
