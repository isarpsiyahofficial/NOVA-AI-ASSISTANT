// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/call/call_handoff_command.dart';

enum LiveCallMode { userSpeaking, novaSpeaking }

class CallHandoffService {
  LiveCallMode _mode = LiveCallMode.userSpeaking;

  LiveCallMode get mode => _mode;
  bool get isNovaHandling => _mode == LiveCallMode.novaSpeaking;
  bool get isUserHandling => _mode == LiveCallMode.userSpeaking;

  CallHandoffCommand detectCommand(String input) {
    final text = input.toLowerCase().trim();

    if (text.contains('nova devral') ||
        text.contains('cevapla nova') ||
        text.contains('sen konuş')) {
      return CallHandoffCommand.novaTakeOver;
    }

    if (text.contains('çağrıyı bana bırak') ||
        text.contains('bana bırak') ||
        text.contains('ben konuşacağım')) {
      return CallHandoffCommand.userTakeOver;
    }

    return CallHandoffCommand.none;
  }

  LiveCallMode processCommand(String input) {
    final command = detectCommand(input);

    switch (command) {
      case CallHandoffCommand.novaTakeOver:
        _mode = LiveCallMode.novaSpeaking;
        return _mode;
      case CallHandoffCommand.userTakeOver:
        _mode = LiveCallMode.userSpeaking;
        return _mode;
      case CallHandoffCommand.none:
        return _mode;
    }
  }

  void resetToUser() {
    _mode = LiveCallMode.userSpeaking;
  }
}
