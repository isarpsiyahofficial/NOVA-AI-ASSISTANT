// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

import '../ai/ai_mode.dart';
import '../../services/runtime/nova_identity_runtime_service.dart';

class AppConstants {
  const AppConstants._();

  static const String methodChannelName = 'nova.ai';

  static String get appName =>
      const NovaIdentityRuntimeService().currentDisplayName;
  static String get defaultWakeReply =>
      const NovaIdentityRuntimeService().defaultWakeReply();
  static String get defaultListeningReply =>
      const NovaIdentityRuntimeService().defaultListeningReply();
  static const String apiBalanceErrorText =
      'Efendim API hizmeti için cüzdan durumu uygun değil.';
  static const String phoneControlReminderText =
      'Efendim telefon yönetimini açık unuttunuz. Kapatmak ister misiniz?';
  static const String urgentWakeSpeechText = 'Uyanmanız gerekiyor efendim.';

  static const Duration preferredResponseTarget = Duration(seconds: 1);
  static const Duration maximumResponseTarget = Duration(seconds: 2);
  static const Duration inactivityShutdownDuration = Duration(minutes: 5);
  static const Duration phoneControlOpenLimit = Duration(hours: 1);
  static const Duration reminderCleanupInterval = Duration(days: 5);
  static const Duration reminderRecentKeepDuration = Duration(hours: 24);
  static const Duration defaultUrgentWakeMaxDuration = Duration(minutes: 10);

  static const AiMode defaultAiMode = AiMode.apiOnly;

  static const String modelAssetFileName = 'gemma-4-E2B-it.litertlm';
  static const List<String> modelAssetFileNameCandidates = <String>[
    'gemma-4-E2B-it.litertlm',
    'gemma-3n-E2B-it-int4.litertlm',
    'gemma-3n-E2B-it.litertlm',
  ];
  static const String voiceProfilesFolder = 'assets/voice_profiles/';
}
