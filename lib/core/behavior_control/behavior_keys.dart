// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class BehaviorKeys {
  const BehaviorKeys._();

  static const String callOpeningGeneral = 'call_opening_general';
  static const String callOpeningSleep = 'call_opening_sleep';
  static const String callOpeningDriving = 'call_opening_driving';
  static const String callOpeningBusy = 'call_opening_busy';
  static const String callOpeningShowering = 'call_opening_showering';

  static const String humorStyle = 'humor_style';
  static const String speechTone = 'speech_tone';
  static const String urgentWakeStyle = 'urgent_wake_style';
  static const String ownerAddressingStyle = 'owner_addressing_style';
  static const String noteAskingStyle = 'note_asking_style';
  static const String callTakeOverStyle = 'call_take_over_style';
  static const String callHandBackStyle = 'call_hand_back_style';

  static const String socialChatStyle = 'social_chat_style';
  static const String comfortTalkStyle = 'comfort_talk_style';
  static const String adviceStyle = 'advice_style';
  static const String learningConfirmationStyle = 'learning_confirmation_style';
  static const String wakeAlarmLoopStyle = 'wake_alarm_loop_style';
  static const String wakeAlarmStopConfirmStyle =
      'wake_alarm_stop_confirm_style';
  static const String unknownTaskAskChatGptPermissionStyle =
      'unknown_task_ask_chatgpt_permission_style';

  static const Set<String> all = <String>{
    callOpeningGeneral,
    callOpeningSleep,
    callOpeningDriving,
    callOpeningBusy,
    callOpeningShowering,
    humorStyle,
    speechTone,
    urgentWakeStyle,
    ownerAddressingStyle,
    noteAskingStyle,
    callTakeOverStyle,
    callHandBackStyle,
    socialChatStyle,
    comfortTalkStyle,
    adviceStyle,
    learningConfirmationStyle,
    wakeAlarmLoopStyle,
    wakeAlarmStopConfirmStyle,
    unknownTaskAskChatGptPermissionStyle,
  };

  static bool isValid(String key) => all.contains(key);
}
