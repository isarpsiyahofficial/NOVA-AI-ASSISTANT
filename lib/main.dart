// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_BOOT_FIRST_VISIBLE_ROOT_V1
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/behavior/nova_persona.dart';
import 'core/behavior/response_style.dart';
import 'core/config/app_constants.dart';
import 'core/settings/nova_settings.dart';
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
import 'services/runtime/nova_runtime_graph_service.dart';
import 'services/runtime/nova_decision_wrapper_contract_service.dart';
import 'services/voice_clone/cloned_voice_library_service.dart';
import 'services/voice_clone/local_voice_clone_engine.dart';
import 'services/voice_clone/voice_clone_runtime_control_service.dart';
import 'services/voice_clone/voice_clone_service.dart';
import 'ui/launch/nova_launch_gate_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation is cosmetic. It must never be allowed to hold the first frame.
  unawaited(
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]).catchError((_) {}),
  );

  // The first Flutter frame is now unconditional. Runtime/bootstrap work happens
  // behind a visible shell so a failed subsystem can no longer look like an app
  // that simply refuses to open.
  runApp(const NovaBootstrapRoot());
}

class _NovaBootstrapBundle {
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

  const _NovaBootstrapBundle({
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
}

Future<_NovaBootstrapBundle> _bootstrapNova() async {
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
  NovaSettings settings;
  try {
    settings = await settingsService.load().timeout(
      const Duration(seconds: 8),
      onTimeout: () => const NovaSettings(),
    );
  } catch (_) {
    settings = const NovaSettings();
  }

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

  final runtimeGraph = NovaRuntimeGraphService.instance;
  try {
    if (!runtimeGraph.hasSharedAi) {
      runtimeGraph.registerSharedAi(
        owner: 'main_app_root',
        service: NovaRuntimeGraphService.buildAiService(
          localModelService: const LocalModelService(),
          apiService: apiService,
          persona: const NovaPersona(),
          responseStyle: const ResponseStyle(),
        ),
      );
    }
    runtimeGraph.registerDelegate(
      'main_core_turn_controller',
      'single_ai_final_response_path',
    );
    NovaDecisionWrapperContractService.registerAll();
  } catch (_) {
    // If an optional duplicate-registration audit fails during recovery, keep
    // the UI alive. Individual action paths remain fail-closed downstream.
    if (!runtimeGraph.hasSharedAi) rethrow;
  }

  final ttsRuntimeService = NovaTtsService(
    ttsService: TtsService(
      voiceProfileService: voiceProfileService,
      nativeBridge: nativeBridge,
    ),
    settingsService: settingsService,
  );

  unawaited(() async {
    try {
      await Future.wait<bool>(<Future<bool>>[
        ttsRuntimeService.ttsService.prewarmPreferredTurkishVoice(),
        nativeBridge.warmupSherpaTts(
          preferredModelKey: 'sherpa_piper_tr_offline',
        ),
      ]);
    } catch (_) {}
  }());

  final reminderService = NovaReminderService();
  final reminderCommandService = NovaReminderCommandService();
  final reminderRuntimeService = NovaReminderRuntimeService(
    reminderService: reminderService,
    behaviorOverrideService: const BehaviorOverrideService(),
  );
  try {
    reminderRuntimeService.start();
  } catch (_) {}

  const conversationSessionService = NovaConversationSessionService();
  final conversationCleanupRuntimeService =
      NovaConversationCleanupRuntimeService(
        sessionService: conversationSessionService,
      );
  try {
    conversationCleanupRuntimeService.start();
  } catch (_) {}

  final callInstructionPhoneControlService = PhoneControlService();
  try {
    await callInstructionPhoneControlService.restore().timeout(
      const Duration(seconds: 5),
    );
  } catch (_) {}

  final callInstructionRuntimeService = NovaCallInstructionRuntimeService(
    instructionService: const NovaCallInstructionService(),
    phoneControlService: callInstructionPhoneControlService,
    phoneBridgeService: const NovaPhoneControlNativeBridgeService(),
  );
  try {
    callInstructionRuntimeService.start();
  } catch (_) {}

  const voiceIdentityBridgeService = NovaVoiceIdentityBridgeService();

  return _NovaBootstrapBundle(
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
  );
}

class NovaBootstrapRoot extends StatefulWidget {
  const NovaBootstrapRoot({super.key});

  @override
  State<NovaBootstrapRoot> createState() => _NovaBootstrapRootState();
}

class _NovaBootstrapRootState extends State<NovaBootstrapRoot> {
  late Future<_NovaBootstrapBundle> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrapNova();
  }

  void _retry() {
    setState(() {
      _bootstrapFuture = _bootstrapNova();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_NovaBootstrapBundle>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        final bundle = snapshot.data;
        if (bundle != null) {
          return NovaApp(
            cloneService: bundle.cloneService,
            runtimeControl: bundle.runtimeControl,
            sttService: bundle.sttService,
            ttsService: bundle.ttsService,
            reminderService: bundle.reminderService,
            reminderCommandService: bundle.reminderCommandService,
            reminderRuntimeService: bundle.reminderRuntimeService,
            conversationSessionService: bundle.conversationSessionService,
            conversationCleanupRuntimeService:
                bundle.conversationCleanupRuntimeService,
            voiceIdentityBridgeService: bundle.voiceIdentityBridgeService,
            apiService: bundle.apiService,
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFF130405),
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'NOVA başlatma katmanında bir sorun oluştu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          snapshot.error.toString(),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _retry,
                          child: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Color(0xFF130405),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'NOVA başlatılıyor…',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
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
