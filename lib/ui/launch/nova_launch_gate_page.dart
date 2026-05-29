// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../core/behavior/nova_persona.dart';
import '../../core/behavior/response_style.dart';
import '../../services/api/api_service.dart';
import '../../services/identity/device_owner_identity_service.dart';
import '../../services/identity/nova_first_run_service.dart';
import '../../services/conversation/nova_conversation_session_service.dart';
import '../../services/identity/nova_voice_identity_bridge_service.dart';
import '../../services/identity/nova_voice_identity_runtime_service.dart';
import '../../services/local_model/local_model_service.dart';
import '../../services/reminder/nova_reminder_command_service.dart';
import '../../services/reminder/nova_reminder_service.dart';
import '../../services/settings/nova_settings_service.dart';
import '../../services/permissions/nova_android_permission_bridge_service.dart';
import '../../services/stt/nova_speech_to_text_service.dart';
import '../../services/tts/nova_tts_service.dart';
import '../../services/voice_clone/voice_clone_runtime_control_service.dart';
import '../../services/voice_clone/voice_clone_service.dart';
import '../nova/nova_dashboard_page.dart';
import '../onboarding/nova_first_run_setup_page.dart';

class NovaLaunchGatePage extends StatefulWidget {
  final NovaPersona persona;
  final ResponseStyle responseStyle;
  final LocalModelService localModelService;
  final ApiService apiService;
  final VoiceCloneService cloneService;
  final VoiceCloneRuntimeControlService runtimeControl;
  final NovaSpeechToTextService sttService;
  final NovaTtsService ttsService;
  final NovaReminderService reminderService;
  final NovaReminderCommandService reminderCommandService;
  final NovaConversationSessionService conversationSessionService;
  final NovaVoiceIdentityBridgeService voiceIdentityBridgeService;

  const NovaLaunchGatePage({
    super.key,
    required this.persona,
    required this.responseStyle,
    required this.localModelService,
    required this.apiService,
    required this.cloneService,
    required this.runtimeControl,
    required this.sttService,
    required this.ttsService,
    required this.reminderService,
    required this.reminderCommandService,
    required this.conversationSessionService,
    required this.voiceIdentityBridgeService,
  });

  @override
  State<NovaLaunchGatePage> createState() => _NovaLaunchGatePageState();
}

class _NovaLaunchGatePageState extends State<NovaLaunchGatePage> {
  final DeviceOwnerIdentityService _ownerService =
      const DeviceOwnerIdentityService();
  final NovaSettingsService _settingsService = const NovaSettingsService();
  final NovaAndroidPermissionBridgeService _permissionBridgeService =
      const NovaAndroidPermissionBridgeService();

  bool _loading = true;
  bool _showSetup = false;
  bool _justCompletedSetup = false;

  late final NovaFirstRunService _firstRunService = NovaFirstRunService(
    ownerService: _ownerService,
  );
  late final NovaVoiceIdentityRuntimeService _voiceIdentityRuntimeService =
      NovaVoiceIdentityRuntimeService(
        bridgeService: widget.voiceIdentityBridgeService,
      );

  @override
  void initState() {
    super.initState();
    _resolveEntry();
  }

  Future<void> _resolveEntry() async {
    final shouldOpenSetup = await _firstRunService.shouldOpenFirstRunSetup();
    final settings = await _settingsService.load();
    final owner = await _ownerService.loadOwner();
    final ownerMissing =
        owner == null ||
        owner.ownerName.trim().isEmpty ||
        owner.ownerVoiceId.trim().isEmpty;
    final shouldForceSetupForVoice = settings.activeVoiceProfileId
        .trim()
        .isEmpty;
    final shouldShowSetup =
        shouldOpenSetup || ownerMissing || shouldForceSetupForVoice;
    if (!mounted) return;
    setState(() {
      _showSetup = shouldShowSetup;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (shouldShowSetup) {
        await _permissionBridgeService.getPermissionSnapshot();
        await _warmRequestPermissions(
          includeCallPermissions: false,
          forceSetupEssentialPermissions: true,
        );
        return;
      }
      await _warmRequestPermissions(includeCallPermissions: true);
    });
  }

  Future<void> _completeSetup() async {
    _justCompletedSetup = true;
    await _resolveEntry();
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 900), () async {
      if (!mounted) return;
      await _permissionBridgeService.getPermissionSnapshot();
    });
  }

  Future<void> _warmRequestPermissions({
    required bool includeCallPermissions,
    bool forceSetupEssentialPermissions = false,
  }) async {
    try {
      await _permissionBridgeService.getPermissionSnapshot();
      final hasMic = await _permissionBridgeService.hasRecordAudioPermission();
      if (!hasMic && (!_showSetup || forceSetupEssentialPermissions)) {
        await _permissionBridgeService.requestRecordAudioPermission();
      }
      final hasNotifications = await _permissionBridgeService
          .canPostNotifications();
      if (!hasNotifications &&
          (!_showSetup || forceSetupEssentialPermissions)) {
        await _permissionBridgeService.requestPostNotificationsPermission();
      }
      if (includeCallPermissions) {
        // Stabilizasyon turunda çağrı zincirini zorla açmak yerine yalnız mevcut durumu okuyoruz.
      }
    } catch (_) {}
  }

  Widget _buildDashboard({bool setupRequired = false}) {
    return NovaDashboardPage(
      persona: widget.persona,
      responseStyle: widget.responseStyle,
      localModelService: widget.localModelService,
      apiService: widget.apiService,
      cloneService: widget.cloneService,
      runtimeControl: widget.runtimeControl,
      sttService: widget.sttService,
      ttsService: widget.ttsService,
      reminderService: widget.reminderService,
      reminderCommandService: widget.reminderCommandService,
      conversationSessionService: widget.conversationSessionService,
      voiceIdentityBridgeService: widget.voiceIdentityBridgeService,
      deferHeavyBootstrap: _justCompletedSetup,
      setupRequired: setupRequired,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF130405),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showSetup) {
      return _buildDashboard(setupRequired: true);
    }

    return _buildDashboard();
  }
}
