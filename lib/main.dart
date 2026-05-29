// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/ai/ai_mode.dart';
import 'core/ai/ai_request.dart';
import 'core/ai/ai_response.dart';
import 'core/ai/nova_ai_service.dart';
import 'core/behavior/nova_persona.dart';
import 'core/behavior/response_style.dart';
import 'core/config/app_constants.dart';
import 'core/voice/voice_profile_service.dart';
import 'services/api/api_service.dart';
import 'services/audio_runtime/nova_native_audio_bridge_service.dart';
import 'services/behavior_control/behavior_override_service.dart';
import 'services/conversation/nova_conversation_cleanup_runtime_service.dart';
import 'services/conversation/nova_conversation_session_service.dart';
import 'services/call_instruction/nova_call_instruction_runtime_service.dart';
import 'services/call_instruction/nova_call_instruction_service.dart';
import 'services/phone_control/phone_control_native_bridge_service.dart';
import 'services/phone_control/phone_control_service.dart';
import 'services/identity/nova_voice_identity_bridge_service.dart';
import 'services/local_model/local_model_service.dart';
import 'services/reminder/nova_reminder_command_service.dart';
import 'services/reminder/nova_reminder_runtime_service.dart';
import 'services/reminder/nova_reminder_service.dart';
import 'services/settings/nova_settings_service.dart';
import 'services/speech/tts_service.dart';
import 'services/stt/nova_speech_to_text_service.dart';
import 'services/system/nova_overlay_bridge_service.dart';
import 'services/tts/nova_tts_service.dart';
import 'services/runtime/nova_identity_runtime_service.dart';
import 'services/runtime/nova_runtime_graph_service.dart';
import 'services/runtime/nova_decision_wrapper_contract_service.dart';
import 'services/runtime/nova_single_brain_authority_service.dart';
import 'services/voice_clone/cloned_voice_library_service.dart';
import 'services/voice_clone/local_voice_clone_engine.dart';
import 'services/voice_clone/voice_clone_runtime_control_service.dart';
import 'services/voice_clone/voice_clone_service.dart';
import 'ui/launch/nova_launch_gate_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  final nativeBridge = NovaNativeAudioBridgeService();
  final overlayBridge = NovaOverlayBridgeService();

  final runtimeControl = VoiceCloneRuntimeControlService(
    nativeAudioBridgeService: nativeBridge,
    overlayBridgeService: overlayBridge,
  );

  final cloneEngine = LocalVoiceCloneEngine(nativeBridge: nativeBridge);

  final libraryService = ClonedVoiceLibraryService();

  final cloneService = VoiceCloneService(
    engine: cloneEngine,
    runtimeControl: runtimeControl,
    libraryService: libraryService,
  );

  final sttService = NovaSpeechToTextService(nativeBridge: nativeBridge);

  const settingsService = NovaSettingsService();
  final settings = await settingsService.load();
  final voiceProfileService = const VoiceProfileService();

  final apiConfigured =
      settings.apiBrainEnabled && settings.apiKey.trim().isNotEmpty;
  final apiService = ApiService(
    isApiConfigured: apiConfigured,
    hasAvailableBalance: apiConfigured,
    provider: settings.activeAiProvider,
    apiKey: settings.apiKey,
    model: settings.activeApiModel,
  );
  final mainAiService = NovaRuntimeGraphService.instance.registerSharedAi(
    owner: 'main_app_root',
    service: NovaRuntimeGraphService.buildAiService(
      localModelService: const LocalModelService(),
      apiService: apiService,
      persona: const NovaPersona(),
      responseStyle: const ResponseStyle(),
    ),
  );
  NovaRuntimeGraphService.instance.registerDelegate(
    'main_core_turn_controller',
    'single_ai_final_response_path',
  );
  NovaDecisionWrapperContractService.registerAll();

  final ttsRuntimeService = NovaTtsService(
    ttsService: TtsService(
      voiceProfileService: voiceProfileService,
      nativeBridge: nativeBridge,
    ),
    settingsService: settingsService,
  );

  final reminderService = NovaReminderService();
  final reminderCommandService = NovaReminderCommandService();

  final reminderRuntimeService = NovaReminderRuntimeService(
    reminderService: reminderService,
    behaviorOverrideService: const BehaviorOverrideService(),
  )..start();

  const conversationSessionService = NovaConversationSessionService();
  final conversationCleanupRuntimeService =
      NovaConversationCleanupRuntimeService(
        sessionService: conversationSessionService,
      )..start();

  final callInstructionPhoneControlService = PhoneControlService();
  await callInstructionPhoneControlService.restore();
  final callInstructionRuntimeService = NovaCallInstructionRuntimeService(
    instructionService: const NovaCallInstructionService(),
    phoneControlService: callInstructionPhoneControlService,
    phoneBridgeService: const NovaPhoneControlNativeBridgeService(),
  )..start();

  const voiceIdentityBridgeService = NovaVoiceIdentityBridgeService();

  runApp(
    NovaApp(
      cloneService: cloneService,
      runtimeControl: runtimeControl,
      sttService: sttService,
      ttsService: ttsRuntimeService,
      reminderService: reminderService,
      reminderCommandService: reminderCommandService,
      reminderRuntimeService: reminderRuntimeService,
      conversationSessionService: conversationSessionService,
      conversationCleanupRuntimeService: conversationCleanupRuntimeService,
      voiceIdentityBridgeService: voiceIdentityBridgeService,
      apiService: apiService,
    ),
  );
}

class NovaApp extends StatelessWidget {
  final VoiceCloneService cloneService;
  final VoiceCloneRuntimeControlService runtimeControl;
  final NovaSpeechToTextService sttService;
  final NovaTtsService ttsService;
  final NovaReminderService reminderService;
  final NovaReminderCommandService reminderCommandService;
  final NovaReminderRuntimeService reminderRuntimeService;
  final NovaConversationSessionService conversationSessionService;
  final NovaConversationCleanupRuntimeService conversationCleanupRuntimeService;
  final NovaVoiceIdentityBridgeService voiceIdentityBridgeService;
  final ApiService apiService;

  const NovaApp({
    super.key,
    required this.cloneService,
    required this.runtimeControl,
    required this.sttService,
    required this.ttsService,
    required this.reminderService,
    required this.reminderCommandService,
    required this.reminderRuntimeService,
    required this.conversationSessionService,
    required this.conversationCleanupRuntimeService,
    required this.voiceIdentityBridgeService,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0E7490),
          brightness: Brightness.light,
        ).copyWith(surface: const Color(0xFFFFFFFF)),
        useMaterial3: true,
      ),
      home: NovaLaunchGatePage(
        persona: const NovaPersona(),
        responseStyle: const ResponseStyle(),
        localModelService: const LocalModelService(),
        apiService: apiService,
        cloneService: cloneService,
        runtimeControl: runtimeControl,
        sttService: sttService,
        ttsService: ttsService,
        reminderService: reminderService,
        reminderCommandService: reminderCommandService,
        conversationSessionService: conversationSessionService,
        voiceIdentityBridgeService: voiceIdentityBridgeService,
      ),
    );
  }
}
