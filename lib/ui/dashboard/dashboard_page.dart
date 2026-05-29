// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ai/ai_mode.dart';
import '../../core/ai/ai_request.dart';
import '../../core/ai/ai_response.dart';
import '../../core/api/nova_ai_provider_type.dart';
import '../../core/api/nova_api_model_catalog.dart';
import '../../core/api/nova_secure_token_store.dart';
import '../../core/behavior/nova_persona.dart';
import '../../core/behavior_control/behavior_keys.dart';
import '../../core/behavior/response_style.dart';
import '../../core/config/app_constants.dart';
import '../../core/config/feature_flags.dart';
import '../../core/contacts/nova_contact.dart';
import '../../core/identity/voice_access_decision.dart';
import '../../core/system/nova_power_mode.dart';
import '../../core/memory/memory_types.dart';
import '../../core/security/nova_security_incident.dart';
import '../../core/security/nova_native_security_snapshot.dart';
import '../../core/settings/nova_settings.dart';
import '../../core/speech/nova_final_text_contract.dart';
import '../../services/api/api_service.dart';
import '../../services/asr/nova_streaming_asr_bridge_service.dart';
import '../../services/behavior_control/behavior_override_service.dart';
import '../../services/call_companion/nova_call_companion_runtime_service.dart';
import '../../services/call_companion/nova_call_companion_service.dart';
import '../../services/call/nova_call_control_bridge_service.dart';
import '../../services/call/urgent_call_memory_service.dart';
import '../../services/call/nova_call_state_service.dart';
import '../../services/call_learning/learned_call_response_service.dart';
import '../../services/call_learning/nova_call_style_learning_service.dart';
import '../../services/call_notes/call_note_service.dart';
import '../../services/call_instruction/nova_call_instruction_command_service.dart';
import '../../services/call_instruction/nova_call_instruction_service.dart';
import '../../core/call_instruction/nova_call_instruction.dart';
import '../../services/conversation/nova_conversation_session_service.dart';
import '../../services/conversation/nova_conversation_focus_service.dart';
import '../../services/contacts/nova_contact_service.dart';
import '../../services/contacts/nova_device_contacts_bridge_service.dart';
import '../../services/identity/device_owner_identity_service.dart';
import '../../services/identity/nova_daily_voice_session_service.dart';
import '../../services/identity/nova_voice_identity_bridge_service.dart';
import '../../services/identity/nova_voice_identity_runtime_service.dart';
import '../../services/identity/voice_authorization_runtime_service.dart';
import '../../services/identity/voice_authorization_service.dart';
import '../../services/identity/voice_identity_registry_service.dart';
import '../../services/identity/voice_introduction_service.dart';
import '../../services/learning/nova_learning_registry_service.dart';
import '../../services/local_model/local_model_service.dart';
import '../../services/self_repair/nova_owner_patch_service.dart';
import '../../services/self_repair/nova_patch_validation_service.dart';
import '../../services/self_repair/nova_repair_trace_service.dart';
import '../../services/self_repair/nova_controlled_restart_service.dart';
import '../../services/self_repair/nova_capability_catalog_service.dart';
import '../../services/self_repair/nova_capability_manifest_service.dart';
import '../../services/self_repair/nova_capability_probe_service.dart';
import '../../services/self_repair/nova_capability_runtime_registry_service.dart';
import '../../services/self_repair/nova_repair_resolution_memory_service.dart';
import '../../services/self_repair/nova_repair_validation_service.dart';
import '../../services/self_repair/nova_repair_voice_narration_service.dart';
import '../../services/self_repair/nova_runtime_signal_service.dart' as self_repair_signal;
import '../../services/self_repair/nova_self_diagnostic_service.dart';
import '../../services/self_repair/nova_self_recognition_service.dart';
import '../../services/self_repair/nova_self_repair_command_service.dart';
import '../../services/self_repair/nova_self_repair_coordinator_service.dart';
import '../../services/self_repair/nova_self_repair_orchestrator_service.dart';
import '../../services/self_repair/nova_self_repair_report_service.dart';
import '../../services/self_repair/nova_self_repair_security_service.dart';
import '../../services/self_repair/nova_self_repair_settings_service.dart';
import '../../services/memory/memory_service.dart';
import '../../services/permissions/nova_android_permission_bridge_service.dart';
import '../../services/phone_control/phone_control_execution_service.dart';
import '../../services/phone_control/nova_media_control_service.dart';
import '../../services/phone_control/phone_control_native_bridge_service.dart';
import '../../services/ui/nova_dashboard_performance_guard_service.dart';
import '../../services/phone_control/phone_control_guard_service.dart';
import '../../services/phone_control/phone_control_service.dart';
import '../../services/phone_control/phone_control_task_service.dart';
import '../../services/presence/nova_presence_service.dart';
import '../../services/reminder/nova_reminder_command_service.dart';
import '../../services/reminder/nova_reminder_service.dart';
import '../../services/screen_control/screen_observation_permission_service.dart';
import '../../services/security/nova_native_security_bridge_service.dart';
import '../../services/security/nova_security_incident_service.dart';
import '../../services/security/nova_restricted_capability_guard_service.dart';
import '../../services/security/nova_security_quarantine_service.dart';
import '../../services/security/nova_security_diagnostic_mode_service.dart';
import '../../services/settings/nova_settings_service.dart';
import '../../services/storage/nova_storage_cleanup_service.dart';
import '../../services/stt/nova_speech_to_text_service.dart';
import '../../services/system/nova_background_bridge_service.dart';
import '../../services/system/nova_continuous_listening_runtime_service.dart';
import '../../services/system/nova_lifecycle_service.dart';
import '../../services/system/nova_power_service.dart';
import '../../services/runtime/nova_runtime_intent_router_service.dart';
import '../../services/runtime/nova_runtime_orchestrator_service.dart';
import '../../services/runtime/nova_hotpath_owner_service.dart';
import '../../services/runtime/nova_single_brain_authority_service.dart';
import '../../services/runtime/nova_runtime_graph_service.dart';
import '../../services/runtime/nova_system_adaptation_contract_service.dart';
import '../../services/runtime/nova_identity_runtime_service.dart';
import '../../services/runtime/nova_spoken_intent_interpreter_service.dart';
import '../../services/runtime/nova_adaptive_instruction_service.dart';
import '../../services/runtime/nova_language_pack_service.dart';
import '../../services/runtime/nova_translator_mode_service.dart';
import '../../services/personality/nova_personality_command_service.dart';
import '../../services/personality/personality_settings_service.dart';
import '../../services/system/nova_power_schedule_service.dart';
import '../../services/self_repair/nova_debug_mode_service.dart';
import '../../services/tts/nova_tts_service.dart';
import '../../services/voice_clone/cloned_voice_library_service.dart';
import '../../services/voice_clone/turkish_expressive_voice_service.dart';
import '../../services/voice_clone/voice_clone_cleanup_command_service.dart';
import '../../services/voice_clone/voice_clone_cleanup_service.dart';
import '../../services/voice_clone/voice_clone_runtime_control_service.dart';
import '../../services/voice_clone/voice_clone_service.dart';
import '../../services/voice_clone/voice_clone_settings_service.dart';
import '../call/call_contact_control_page.dart';
import '../identity/voice_identity_control_page.dart';
import '../learning/nova_learning_items_page.dart';
import '../phone_control/phone_control_page.dart';
import '../reminder/reminder_control_page.dart';
import '../settings/voice_personality_settings_page.dart';
import '../../presentation/self_repair/self_repair_control_page.dart';
import '../system/phone_and_screen_control_page.dart';
import '../system/nova_power_and_presence_page.dart';
import '../voice_clone/voice_clone_control_page.dart';
import '../../core/ai/nova_ai_service.dart';

class DashboardPage extends StatefulWidget {
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
  final bool deferHeavyBootstrap;

  const DashboardPage({
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
    this.deferHeavyBootstrap = false,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _lastUiRefreshAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _lastOperationalListeningAttemptAt;
  bool _operationalListeningStartInFlight = false;
  final NovaDashboardPerformanceGuardService _dashboardPerformanceGuard =
      NovaDashboardPerformanceGuardService();
  void _safeSetState(
    VoidCallback fn, {
    bool force = false,
    String bucket = 'dashboard',
    String signature = '',
  }) {
    if (!mounted) return;
    final decision = _dashboardPerformanceGuard.shouldAllow(
      bucket: bucket,
      signature: signature,
      force: force,
      baseIntervalMs: 80,
    );
    if (!decision.allow) return;
    _lastUiRefreshAt = DateTime.now();
    setState(fn);
  }

  static const Duration _dashboardRefreshDebounce = Duration(milliseconds: 250);
  static const String _familiarConversationMarker =
      NovaContinuousListeningRuntimeService.familiarConversationMarker;
  late final NovaAiService _novaAiService;

  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiModelController = TextEditingController();

  final NovaSettingsService _novaSettingsService = const NovaSettingsService();
  final NovaSecurityDiagnosticModeService _securityDiagnosticModeService =
      const NovaSecurityDiagnosticModeService();
  final NovaPowerService _powerService = NovaPowerService();
  final NovaPresenceService _presenceService = NovaPresenceService();
  final NovaContactService _contactService = const NovaContactService();
  final NovaDeviceContactsBridgeService _deviceContactsBridgeService =
      const NovaDeviceContactsBridgeService();
  final NovaLifecycleService _lifecycleService = NovaLifecycleService();

  final MemoryService _memoryService = MemoryService();
  final NovaConversationFocusService _conversationFocusService =
      const NovaConversationFocusService();
  final NovaCallStyleLearningService _callStyleLearningService =
      const NovaCallStyleLearningService();
  final NovaLanguagePackService _languagePackService =
      const NovaLanguagePackService();
  late final NovaTranslatorModeService _translatorModeService =
      NovaTranslatorModeService(languagePackService: _languagePackService);
  NovaTranslatorModeState _translatorModeState =
      const NovaTranslatorModeState.disabled();
  late final NovaPersonalityCommandService _personalityCommandService =
      NovaPersonalityCommandService(
        settingsService: const PersonalitySettingsService(),
      );
  final NovaPhoneControlNativeBridgeService _phoneControlNativeBridgeService =
      const NovaPhoneControlNativeBridgeService();
  late final NovaMediaControlService _mediaControlService =
      NovaMediaControlService(bridgeService: _phoneControlNativeBridgeService);

  bool _awaitingMediaForegroundChoice = false;
  String _pendingMediaQuery = '';
  String _pendingMediaPackage = '';
  final CallNoteService _callNoteService = const CallNoteService();
  final UrgentCallMemoryService _urgentCallMemoryService =
      const UrgentCallMemoryService();
  final NovaCallInstructionService _callInstructionService =
      const NovaCallInstructionService();
  final NovaCallInstructionCommandService _callInstructionCommandService =
      const NovaCallInstructionCommandService();

  final DeviceOwnerIdentityService _ownerIdentityService =
      const DeviceOwnerIdentityService();
  final NovaRepairTraceService _repairTraceService =
      const NovaRepairTraceService();
  final NovaOwnerPatchService _ownerPatchService =
      const NovaOwnerPatchService();
  final NovaPatchValidationService _patchValidationService =
      const NovaPatchValidationService();
  final VoiceIdentityRegistryService _voiceIdentityRegistryService =
      const VoiceIdentityRegistryService();

  final NovaNativeSecurityBridgeService _nativeSecurityBridgeService =
      const NovaNativeSecurityBridgeService();
  final NovaDailyVoiceSessionService _dailyVoiceSessionService =
      const NovaDailyVoiceSessionService();
  final NovaAndroidPermissionBridgeService _permissionBridgeService =
      const NovaAndroidPermissionBridgeService();
  final NovaStreamingAsrBridgeService _streamingAsrBridgeService =
      const NovaStreamingAsrBridgeService();

  late final NovaSecurityIncidentService _securityIncidentService;
  late final NovaRestrictedCapabilityGuardService
  _restrictedCapabilityGuardService;
  late final NovaStorageCleanupService _storageCleanupService;
  late final NovaVoiceIdentityRuntimeService _voiceIdentityRuntimeService;
  late final VoiceAuthorizationRuntimeService _voiceAuthorizationRuntimeService;
  late final NovaBackgroundBridgeService _backgroundBridgeService;
  late final NovaCallCompanionService _callCompanionService;
  late final NovaCallCompanionRuntimeService _callCompanionRuntimeService;
  late final NovaCallStateService _callStateService;
  late final NovaCallControlBridgeService _callControlService;
  late final NovaContinuousListeningRuntimeService
  _continuousListeningRuntimeService;
  late final NovaRuntimeOrchestratorService _runtimeOrchestratorService;
  late final NovaHotpathOwnerService _hotpathOwnerService;
  final NovaRuntimeIntentRouterService _runtimeIntentRouterService =
      const NovaRuntimeIntentRouterService();

  late final PhoneControlService _phoneControlService;
  late final PhoneControlGuardService _phoneControlGuardService;
  late final PhoneControlTaskService _phoneControlTaskService;
  late final PhoneControlExecutionService _phoneControlExecutionService;
  late final ScreenObservationPermissionService _screenPermissionService;

  final NovaPowerScheduleService _powerScheduleService =
      const NovaPowerScheduleService();
  NovaPowerSchedule _powerSchedule = const NovaPowerSchedule();
  bool _debugRunning = false;
  Timer? _powerScheduleTimer;
  DateTime? _lastSecurityRefreshAt;

  FeatureFlags _featureFlags = const FeatureFlags();
  AiMode _selectedMode = AppConstants.defaultAiMode;

  bool _internetAllowedForThisRequest = true;
  bool _userApprovedApiUsageForThisRequest = true;
  bool _isResearchRequest = false;
  bool _isSelfLearningRequest = false;

  bool _isLoading = false;
  bool _settingsLoading = true;
  bool _settingsSaving = false;
  bool _cleanupRunning = false;
  bool _voiceFlowRunning = false;
  bool _securityLoading = true;
  bool _securityActionRunning = false;
  bool _securityVibrationStopped = false;
  bool _permissionsRefreshing = false;
  bool _securityDiagnosticPassive = true;
  bool _securityDiagnosticSaving = false;

  String _quickReply = AppConstants.defaultWakeReply;
  String _lastResponse = 'Nova runtime durumu bekleniyor.';
  String _securityStatusText = 'Güvenlik sistemi hazırlanıyor...';
  String _securityRiskLevel = 'Yok';
  String _nativeSecurityMessage = '';
  String _nativeKillStage = 'none';
  String _lastHeardText = '';
  String _preferredMediaPackage = 'com.spotify.music';
  String _streamingAsrStatus = 'Streaming ASR hazırlanıyor.';
  String _callRoleStatus = 'Çağrı rolü hazırlanıyor.';
  DateTime? _startupSpeechSuppressUntil;

  NovaSettings _novaSettings = const NovaSettings();
  List<NovaContact> _managedContacts = const <NovaContact>[];
  List<NovaSecurityIncident> _securityIncidents =
      const <NovaSecurityIncident>[];
  List<dynamic> _callNotes = const <dynamic>[];
  List<dynamic> _reminders = const <dynamic>[];
  List<NovaCallInstruction> _callInstructions = const <NovaCallInstruction>[];

  int _reminderPendingCount = 0;
  int _reminderCompletedCount = 0;
  int _voiceCloneCount = 0;
  int _favoriteVoiceCloneCount = 0;
  int _activeVoiceCloneCount = 0;
  int _memoryPermanentCount = 0;
  int _memoryTemporaryCount = 0;
  int _memoryContextualCount = 0;
  int _callNotesCount = 0;
  int _securityIncidentCount = 0;
  int _knownVoiceCount = 0;
  int _authorizedVoiceCount = 0;
  int _familiarVoiceCount = 0;
  int _callInstructionPendingCount = 0;
  int _callInstructionCompletedCount = 0;

  bool _hasCriticalSecurityIncident = false;
  bool _hasHighSecurityIncident = false;
  bool _hasMediumSecurityIncident = false;

  bool _overlayGranted = false;
  bool _accessibilityGranted = false;
  bool _notificationGranted = false;
  bool _microphoneGranted = false;
  bool _defaultDialerGranted = false;
  bool _readPhoneStateGranted = false;
  bool _readPhoneNumbersGranted = false;
  bool _readCallLogGranted = false;
  bool _answerPhoneCallsGranted = false;
  bool _callPhoneGranted = false;
  bool _streamingAsrReady = false;
  bool _streamingAsrSingleAuthorityConfirmed = true;

  bool _awaitingMemoryTypeChoice = false;
  String _pendingMemoryContent = '';
  String _lastSpokenStatusMessage = '';
  DateTime? _lastSpokenStatusAt;
  DateTime? _lastDashboardRefreshAt;
  DateTime? _overlayWarningSnoozeUntil;
  final NovaSpokenIntentInterpreterService _spokenIntentInterpreter =
      const NovaSpokenIntentInterpreterService();
  final NovaAdaptiveInstructionService _adaptiveInstructionService =
      const NovaAdaptiveInstructionService();
  final BehaviorOverrideService _behaviorOverrideService =
      const BehaviorOverrideService();
  final LearnedCallResponseService _learnedCallResponseService =
      const LearnedCallResponseService();

  late final VoiceCloneSettingsService _voiceCloneSettingsService;
  late final ClonedVoiceLibraryService _clonedVoiceLibraryService;
  late final TurkishExpressiveVoiceService _expressiveVoiceService;
  late final VoiceCloneCleanupService _voiceCloneCleanupService;

  @override
  void initState() {
    super.initState();

    _novaAiService = NovaRuntimeGraphService.instance.resolveSharedAi(
      requester: 'dashboard_voice',
      factory: () => NovaRuntimeGraphService.buildAiService(
        localModelService: widget.localModelService,
        apiService: widget.apiService,
        persona: widget.persona,
        responseStyle: widget.responseStyle,
      ),
    );
    NovaRuntimeGraphService.instance.registerDelegate(
      'dashboard_voice',
      'dashboard_page_wrapper',
    );

    _securityIncidentService = NovaSecurityIncidentService(
      nativeBridgeService: _nativeSecurityBridgeService,
    );
    _restrictedCapabilityGuardService = NovaRestrictedCapabilityGuardService(
      quarantineService: const NovaSecurityQuarantineService(),
    );

    _voiceCloneSettingsService = VoiceCloneSettingsService();
    _clonedVoiceLibraryService = ClonedVoiceLibraryService();
    _expressiveVoiceService = const TurkishExpressiveVoiceService();
    _voiceCloneCleanupService = VoiceCloneCleanupService(
      libraryService: _clonedVoiceLibraryService,
      commandService: const VoiceCloneCleanupCommandService(),
    );

    _storageCleanupService = NovaStorageCleanupService(
      callNoteService: _callNoteService,
      memoryService: _memoryService,
      conversationSessionService: widget.conversationSessionService,
    );

    _voiceIdentityRuntimeService = NovaVoiceIdentityRuntimeService(
      bridgeService: widget.voiceIdentityBridgeService,
    );

    _voiceAuthorizationRuntimeService = VoiceAuthorizationRuntimeService(
      voiceIdentityRuntimeService: _voiceIdentityRuntimeService,
      authorizationService: VoiceAuthorizationService(
        ownerService: _ownerIdentityService,
        registryService: _voiceIdentityRegistryService,
      ),
    );

    _backgroundBridgeService = const NovaBackgroundBridgeService();
    _callStateService = const NovaCallStateService();
    _callControlService = const NovaCallControlBridgeService();
    _callCompanionService = NovaCallCompanionService(
      aiService: _novaAiService,
      contactService: _contactService,
      reminderService: widget.reminderService,
      urgentCallMemoryService: _urgentCallMemoryService,
      callNoteService: _callNoteService,
      learnedCallResponseService: _learnedCallResponseService,
      callStyleLearningService: _callStyleLearningService,
    );
    _callCompanionRuntimeService = NovaCallCompanionRuntimeService(
      companionService: _callCompanionService,
      callStateService: _callStateService,
      callControlService: _callControlService,
      contactService: _contactService,
      sttService: widget.sttService,
      ttsService: widget.ttsService,
      authorizationRuntimeService: _voiceAuthorizationRuntimeService,
      callStyleLearningService: _callStyleLearningService,
      powerService: _powerService,
    );

    _phoneControlService = PhoneControlService();
    _phoneControlGuardService = const PhoneControlGuardService();
    _phoneControlTaskService = const PhoneControlTaskService();
    _phoneControlExecutionService = PhoneControlExecutionService(
      phoneControlService: _phoneControlService,
      taskService: _phoneControlTaskService,
    );
    _screenPermissionService = ScreenObservationPermissionService();

    _continuousListeningRuntimeService = NovaContinuousListeningRuntimeService(
      sttService: widget.sttService,
      powerService: _powerService,
      lifecycleService: _lifecycleService,
      presenceService: _presenceService,
      backgroundBridgeService: _backgroundBridgeService,
      authorizationRuntimeService: _voiceAuthorizationRuntimeService,
      callStateService: _callStateService,
      callControlService: _callControlService,
      companionRuntime: _callCompanionRuntimeService,
      contactService: _contactService,
      isWakeWordEnabled: () => _novaSettings.wakeWordEnabled,
      isCallHandlingEnabled: () => _novaSettings.callHandlingEnabled,
      dailyVoiceSessionService: _dailyVoiceSessionService,
    );

    _runtimeOrchestratorService = NovaRuntimeOrchestratorService(
      intentRouterService: _runtimeIntentRouterService,
      powerService: _powerService,
      backgroundBridgeService: _backgroundBridgeService,
      continuousListeningRuntimeService: _continuousListeningRuntimeService,
      callControlService: _callControlService,
      callStateService: _callStateService,
      reminderService: widget.reminderService,
      selfRepairCommandService: const NovaSelfRepairCommandService(),
      phoneControlService: _phoneControlService,
      ensureListeningAction: () => _ensureOperationalListening(),
    );
    _hotpathOwnerService = NovaHotpathOwnerService(
      runtimeOrchestratorService: _runtimeOrchestratorService,
    );

    _startupSpeechSuppressUntil = DateTime.now().add(
      const Duration(seconds: 18),
    );
    if (widget.deferHeavyBootstrap) {
      Future<void>.delayed(
        const Duration(milliseconds: 1200),
        _bootstrapDashboard,
      );
    } else {
      _bootstrapDashboard();
    }
  }

  Future<void> _bootstrapDashboard() async {
    await _restoreSystemControls();
    if (!mounted) return;

    _startPowerScheduleMonitor();

    Future<void>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      await _restoreSecurityState();
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 450));

      await _warmupVoiceIdentity();
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 350));

      final localModelState = await widget.localModelService.getState();
      if (mounted &&
          !localModelState.ready &&
          localModelState.message.trim().isNotEmpty) {
        _safeSetState(() {
          _lastResponse = localModelState.message.trim();
        });
      }
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));

      await _ensureOperationalListening();
      if (!mounted) return;
      await _refreshStreamingAsrState();
    });
  }

  @override
  void dispose() {
    _powerScheduleTimer?.cancel();
    _continuousListeningRuntimeService.stop();
    _promptController.dispose();
    _apiKeyController.dispose();
    _apiModelController.dispose();
    _presenceService.dispose();
    super.dispose();
  }

  Future<void> _restoreSystemControls() async {
    await _powerService.restore();
    await _presenceService.restore();
    await _phoneControlService.restore();
    await _screenPermissionService.restore();

    if (_powerService.isPassiveSleep || _powerService.isLimbo) {
      _lifecycleService.sleep();
      _presenceService.setStateSafe(NovaPresenceState.sleeping);
    } else if (_powerService.isFullyShutdown) {
      _presenceService.setStateSafe(NovaPresenceState.fullyOff);
    } else {
      _lifecycleService.wake();
      _presenceService.setStateSafe(NovaPresenceState.idle);
    }

    final settings = await _novaSettingsService.load();
    final contacts = await _contactService.loadContacts();
    final schedule = await _powerScheduleService.load();
    final translatorModeState = await _translatorModeService.load();
    final securityDiagnosticMode = await _securityDiagnosticModeService.load();

    if (schedule.enabled &&
        _powerScheduleService.shouldSleepNow(schedule, DateTime.now()) &&
        !_powerService.isFullyShutdown) {
      await _powerService.setPassiveSleep(userInitiated: false);
      _lifecycleService.sleep();
      _presenceService.setStateSafe(NovaPresenceState.sleeping);
    }

    if (!mounted) return;

    _safeSetState(() {
      _novaSettings = settings;
      _managedContacts = contacts;
      _apiKeyController.text = settings.apiKey;
      _apiModelController.text = settings.activeApiModel;
      _settingsLoading = false;
      _knownVoiceCount = 0;
      _authorizedVoiceCount = 0;
      _familiarVoiceCount = 0;
      _powerSchedule = schedule;
      _translatorModeState = translatorModeState;
      _securityDiagnosticPassive = securityDiagnosticMode.passiveShields;
    });

    await _refreshPermissionState();
    await _refreshStreamingAsrState();
    await _refreshDashboardSummaries();
    if (!widget.deferHeavyBootstrap) {
      await _maybePromptMissingPermissions();
    }
  }

  void _startPowerScheduleMonitor() {
    _powerScheduleTimer?.cancel();
    _powerScheduleTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _enforceScheduledPowerMode();
    });
  }

  Future<void> _enforceScheduledPowerMode() async {
    final schedule = await _powerScheduleService.load();
    _powerSchedule = schedule;
    if (!_powerSchedule.enabled || _powerService.isFullyShutdown) return;
    final shouldSleep = _powerScheduleService.shouldSleepNow(
      schedule,
      DateTime.now(),
    );
    if (shouldSleep && !_powerService.isPassiveSleep) {
      if (_powerService.shouldKeepScheduledNightHold(DateTime.now())) {
        return;
      }
      await _setPowerPassiveSleep(announce: false, scheduled: true);
      return;
    }
    if (!shouldSleep && _powerService.isPassiveSleep) {
      await _setPowerLimbo(announce: false, scheduled: true);
      if (mounted) {
        _safeSetState(() {
          _lastResponse =
              'Otomatik gece penceresi sona erdi efendim. Nova araf moduna döndü.';
        });
      }
    }
  }

  Future<void> _ensureOperationalListening({bool userRequested = false}) async {
    if (_operationalListeningStartInFlight) {
      return;
    }
    final now = DateTime.now();
    if (_lastOperationalListeningAttemptAt != null &&
        now.difference(_lastOperationalListeningAttemptAt!) <
            const Duration(milliseconds: 1200)) {
      return;
    }
    _lastOperationalListeningAttemptAt = now;
    _operationalListeningStartInFlight = true;
    try {
      if (_powerService.isFullyShutdown &&
          !_novaSettings.wakeWordEnabled &&
          !userRequested) {
        if (_continuousListeningRuntimeService.isRunning) {
          await _continuousListeningRuntimeService.stop();
        }
        return;
      }
      if (userRequested && _powerService.isFullyShutdown) {
        _lifecycleService.wake();
      }

      if (!_microphoneGranted) {
        await _refreshPermissionState();
      }

      final bool shouldRunForWake =
          _novaSettings.wakeWordEnabled && _microphoneGranted;
      final bool shouldRunForCalls =
          _novaSettings.callHandlingEnabled && _autoHandleContactCount > 0;
      final bool shouldRunForManualDashboard =
          userRequested && _microphoneGranted;
      if (!shouldRunForWake &&
          !shouldRunForCalls &&
          !shouldRunForManualDashboard) {
        return;
      }

      final background = await _backgroundBridgeService.startBackground();
      if (!background.success && mounted && background.hasUsableMessage) {
        _safeSetState(() {
          _lastResponse = background.message;
        });
      }

      await _backgroundBridgeService.showOverlayIdle();
      if (_continuousListeningRuntimeService.isRunning) {
        return;
      }
      await _continuousListeningRuntimeService.start(
        onAuthorizedPrompt: _handleBackgroundAuthorizedPrompt,
        onUnauthorizedOrStatus: _handleBackgroundUnauthorizedOrStatus,
      );
      if (userRequested) {
        await _backgroundBridgeService.showOverlayListening();
      } else {
        await _backgroundBridgeService.showOverlayIdle();
      }
    } catch (e) {
      if (!mounted) return;
      _safeSetState(() {
        _lastResponse = 'Arka plan dinleme güvenli modda beklemeye alındı: $e';
      });
    } finally {
      _operationalListeningStartInFlight = false;
    }
  }

  Future<void> _restoreSecurityState() async {
    final state = await _securityIncidentService.refreshState(
      vibrateIfHighRisk: !_securityVibrationStopped,
    );

    if (!mounted) return;

    _safeSetState(() {
      _securityIncidents = state.incidents;
      _securityIncidentCount = state.incidents.length;
      _hasHighSecurityIncident = state.hasHighRisk;
      _hasCriticalSecurityIncident = state.hasCriticalRisk;
      _hasMediumSecurityIncident = state.hasMediumRisk;
      _securityRiskLevel = state.riskLevel;
      _nativeKillStage = state.nativeKillStage;
      _nativeSecurityMessage = state.nativeMessage;
      _securityStatusText = state.statusText;
      _securityLoading = false;
    });
  }

  Future<void> _refreshSecurityState({bool vibrateIfHighRisk = false}) async {
    final now = DateTime.now();
    if (_lastSecurityRefreshAt != null &&
        now.difference(_lastSecurityRefreshAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastSecurityRefreshAt = now;
    final oldCount = _securityIncidentCount;
    final oldHigh = _hasHighSecurityIncident;
    final oldCritical = _hasCriticalSecurityIncident;

    final state = await _securityIncidentService.refreshState(
      vibrateIfHighRisk: false,
    );

    if (!mounted) return;

    _safeSetState(() {
      _securityIncidents = state.incidents;
      _securityIncidentCount = state.incidents.length;
      _hasHighSecurityIncident = state.hasHighRisk;
      _hasCriticalSecurityIncident = state.hasCriticalRisk;
      _hasMediumSecurityIncident = state.hasMediumRisk;
      _securityRiskLevel = state.riskLevel;
      _nativeKillStage = state.nativeKillStage;
      _nativeSecurityMessage = state.nativeMessage;
      _securityStatusText = state.statusText;
    });

    final escalated =
        (_hasCriticalSecurityIncident && !oldCritical) ||
        (_hasHighSecurityIncident && !oldHigh) ||
        (_securityIncidentCount > oldCount);

    if (vibrateIfHighRisk &&
        !_securityVibrationStopped &&
        escalated &&
        (_hasCriticalSecurityIncident || _hasHighSecurityIncident)) {
      await _nativeSecurityBridgeService.vibrateIfNeeded();
    }
  }

  Future<void> _warmupVoiceIdentity() async {
    final warmup = await widget.voiceIdentityBridgeService.warmup();

    if (!mounted) return;

    _safeSetState(() {
      if (!warmup.success) {
        _lastResponse = warmup.message;
      }
    });
  }

  Future<void> _refreshPermissionState() async {
    if (mounted) {
      _safeSetState(() {
        _permissionsRefreshing = true;
      });
    }

    var snapshot = await _permissionBridgeService.getPermissionSnapshot();
    if (!snapshot.recordAudioGranted) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final secondSnapshot = await _permissionBridgeService
          .getPermissionSnapshot();
      if (secondSnapshot.recordAudioGranted) snapshot = secondSnapshot;
    }

    if (!mounted) return;

    final essentialCallReady =
        snapshot.readPhoneStateGranted &&
        snapshot.readPhoneNumbersGranted &&
        snapshot.answerPhoneCallsGranted &&
        snapshot.callPhoneGranted;
    final fullManagedCallReady =
        essentialCallReady &&
        snapshot.readCallLogGranted &&
        snapshot.defaultDialerGranted;

    _safeSetState(() {
      _overlayGranted = snapshot.canDrawOverlays;
      _accessibilityGranted = snapshot.accessibilityEnabled;
      _notificationGranted = snapshot.notificationsGranted;
      _microphoneGranted = snapshot.recordAudioGranted;
      _defaultDialerGranted = snapshot.defaultDialerGranted;
      _readPhoneStateGranted = snapshot.readPhoneStateGranted;
      _readPhoneNumbersGranted = snapshot.readPhoneNumbersGranted;
      _readCallLogGranted = snapshot.readCallLogGranted;
      _answerPhoneCallsGranted = snapshot.answerPhoneCallsGranted;
      _callPhoneGranted = snapshot.callPhoneGranted;
      _callRoleStatus = fullManagedCallReady
          ? 'Kayıtlı kişiler için çağrı zinciri hazır. Normal telefon deneyimi korunur.'
          : snapshot.managedCallSupportReady
          ? 'Temel çağrı desteği hazır. Tam otomasyon için varsayılan telefon rolü veya ek çağrı izinleri eksik.'
          : 'Çağrı desteği kısmen hazır. İzinler ve rol durumu henüz tamamlanmadı.';
      _permissionsRefreshing = false;
    });
  }

  Future<void> _maybePromptMissingPermissions() async {
    if (!mounted) return;
    final missing = <String>[];
    if (!_overlayGranted) missing.add('Overlay');
    if (!_accessibilityGranted) missing.add('Erişilebilirlik');
    if (!_notificationGranted) missing.add('Bildirim');
    if (!_microphoneGranted) missing.add('Mikrofon');
    if (!_defaultDialerGranted) missing.add('Varsayılan Telefon rolü');
    if (!_readPhoneStateGranted) missing.add('Telefon durumu');
    if (!_readPhoneNumbersGranted) missing.add('Telefon numaraları');
    if (!_readCallLogGranted) missing.add('Çağrı günlüğü');
    if (!_answerPhoneCallsGranted) missing.add('Çağrı cevaplama');
    if (!_callPhoneGranted) missing.add('Doğrudan arama');
    if (missing.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eksik izinler var'),
          content: Text(
            'Nova bazı izinleri hâlâ bekliyor: ${missing.join(', ')}. Kayıtlı kişiler için çağrı desteğinin normal telefon ekranını bozmadan tam çalışması adına bu zincir tamamlanmalı efendim.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Sonra'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _permissionBridgeService
                    .requestEssentialCallPermissions();
                await _permissionBridgeService.openAppSettings();
              },
              child: const Text('İzinleri Aç'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _refreshStreamingAsrState() async {
    try {
      await _streamingAsrBridgeService.initialize();
      final state = await _streamingAsrBridgeService.getState();
      if (!mounted) return;
      final message = state.message.trim();
      final status = state.running
          ? 'Streaming ASR çalışıyor • embedded yerel model aktif'
          : state.modelReady
          ? (state.initialized
                ? 'Streaming ASR hazır • dinleme zinciri beklemede'
                : 'Streaming ASR hazır • başlatma bekliyor')
          : (message.isNotEmpty ? message : 'Streaming ASR hazır değil');
      _safeSetState(() {
        _streamingAsrReady = state.embeddedSherpaReady;
        _streamingAsrSingleAuthorityConfirmed = state.singleAuthorityConfirmed;
        _streamingAsrStatus = status;
      });
    } catch (_) {
      if (!mounted) return;
      _safeSetState(() {
        _streamingAsrReady = false;
        _streamingAsrSingleAuthorityConfirmed = false;
        _streamingAsrStatus = 'Streaming ASR durumu okunamadı.';
      });
    }
  }

  Future<void> _refreshDashboardSummaries() async {
    final now = DateTime.now();
    if (_lastDashboardRefreshAt != null &&
        now.difference(_lastDashboardRefreshAt!) < _dashboardRefreshDebounce) {
      return;
    }
    _lastDashboardRefreshAt = now;

    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      widget.reminderService.getAll(),
      _clonedVoiceLibraryService.getAll(),
      _memoryService.getAll(),
      _callNoteService.getAll(),
      _contactService.loadContacts(),
      _voiceIdentityRegistryService.getAll(),
      _callInstructionService.getAll(),
      _mediaControlService.getPreferredPackage(),
    ]);

    final reminders = results[0] as List<dynamic>;
    final clones = results[1] as List<dynamic>;
    final memories = results[2] as List<dynamic>;
    final callNotes = results[3] as List<dynamic>;
    final contacts = results[4] as List<NovaContact>;
    final knownVoices = results[5] as List<dynamic>;
    final callInstructions = results[6] as List<NovaCallInstruction>;
    final preferredMediaPackage = results[7] as String;

    final sortedNotes = <dynamic>[...callNotes]
      ..sort((a, b) {
        final left = _toDateTime(a.createdAt);
        final right = _toDateTime(b.createdAt);
        return right.compareTo(left);
      });

    final sortedReminders = <dynamic>[...reminders]
      ..sort((a, b) {
        final left = '${a.dueAtIso ?? ''}';
        final right = '${b.dueAtIso ?? ''}';
        return left.compareTo(right);
      });

    if (!mounted) return;

    _safeSetState(() {
      _managedContacts = contacts;
      _knownVoiceCount = knownVoices.length;
      _authorizedVoiceCount = knownVoices
          .where((e) => e.isAuthorizedToUseNova)
          .length;
      _familiarVoiceCount = knownVoices
          .where((e) => !e.isAuthorizedToUseNova)
          .length;
      _reminders = sortedReminders;
      _callNotes = sortedNotes;
      _reminderPendingCount = reminders
          .where((e) => e.status.name == 'pending')
          .length;
      _reminderCompletedCount = reminders
          .where((e) => e.status.name == 'completed')
          .length;
      _voiceCloneCount = clones.length;
      _favoriteVoiceCloneCount = clones.where((e) => e.isFavorite).length;
      _activeVoiceCloneCount = clones.where((e) => e.isActiveInUse).length;
      _memoryPermanentCount = memories
          .where((e) => e.type == MemoryType.permanent)
          .length;
      _memoryTemporaryCount = memories
          .where((e) => e.type == MemoryType.temporary)
          .length;
      _memoryContextualCount = memories
          .where((e) => e.type == MemoryType.contextual)
          .length;
      _callNotesCount = callNotes.length;
      _callInstructions = callInstructions;
      _callInstructionPendingCount = callInstructions
          .where((e) => e.status == NovaCallInstructionStatus.pending)
          .length;
      _callInstructionCompletedCount = callInstructions
          .where((e) => e.status == NovaCallInstructionStatus.completed)
          .length;
      _preferredMediaPackage = preferredMediaPackage;
    });

    await _refreshStreamingAsrState();
    await _refreshSecurityState(vibrateIfHighRisk: true);
  }

  Future<void> _refreshContacts() async {
    final contacts = await _contactService.loadContacts();

    if (!mounted) return;

    _safeSetState(() {
      _managedContacts = contacts;
    });
  }

  Future<void> _saveSettings(
    NovaSettings nextSettings, {
    String? successMessage,
  }) async {
    _safeSetState(() {
      _settingsSaving = true;
      _novaSettings = nextSettings;
    });

    await _novaSettingsService.save(nextSettings);

    if (!mounted) return;

    _safeSetState(() {
      _settingsSaving = false;
      if (successMessage != null && successMessage.trim().isNotEmpty) {
        _lastResponse = successMessage;
      }
    });

    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _saveSecurityDiagnosticPassive(bool value) async {
    _safeSetState(() {
      _securityDiagnosticSaving = true;
      _securityDiagnosticPassive = value;
      _lastResponse = value
          ? 'Güvenlik kalkanları pasif gözlem moduna alındı. Nova bu ayarı görmez ve değiştiremez.'
          : 'Güvenlik kalkanları aktif engelleme moduna alındı.';
    });
    await _securityDiagnosticModeService.setPassive(
      passive: value,
      updatedBy: 'dashboard_ui',
    );
    await const NovaSecurityQuarantineService().reset();
    if (!mounted) return;
    _safeSetState(() {
      _securityDiagnosticSaving = false;
    });
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    final model = _apiModelController.text.trim().isEmpty
        ? NovaApiModelCatalog.defaultModelFor(_novaSettings.activeAiProvider)
        : _apiModelController.text.trim();

    await _saveSettings(
      _novaSettings.copyWith(
        apiKey: key,
        activeApiModel: model,
        apiBrainEnabled: key.isNotEmpty,
        chatGptInternetEnabled: key.isNotEmpty,
        apiLearningEnabled: key.isNotEmpty,
      ),
      successMessage: key.isEmpty
          ? 'API anahtarı temizlendi efendim.'
          : '${_novaSettings.activeAiProvider.label} API anahtarı ve model ayarı kaydedildi efendim.',
    );
  }

  Future<void> _saveActiveAiProvider(NovaAiProviderType provider) async {
    final fallbackModel = NovaApiModelCatalog.defaultModelFor(provider);
    final providerKey = await const NovaSecureTokenStore().read(provider);
    _apiModelController.text = fallbackModel;
    _apiKeyController.text = providerKey;
    await _saveSettings(
      _novaSettings.copyWith(
        activeAiProvider: provider,
        activeApiModel: fallbackModel,
        apiKey: providerKey,
        apiBrainEnabled: providerKey.trim().isNotEmpty,
        chatGptInternetEnabled: providerKey.trim().isNotEmpty,
        apiLearningEnabled: providerKey.trim().isNotEmpty,
      ),
      successMessage:
          '${provider.label} aktif beyin sağlayıcısı seçildi efendim.',
    );
  }

  Future<void> _setPowerFullyOn({
    bool announce = true,
    bool scheduled = false,
  }) async {
    if (scheduled) {
      await _powerService.setFullyOn(userInitiated: false);
    } else {
      await _applyUserSelectedPowerMode(NovaPowerMode.fullyOn);
    }
    _lifecycleService.wake();
    _presenceService.setStateSafe(NovaPresenceState.idle);
    await _backgroundBridgeService.setBackgroundRunning();
    await _backgroundBridgeService.showOverlayIdle();
    await _ensureOperationalListening();

    if (!mounted) return;

    _safeSetState(() {
      _lastResponse = scheduled
          ? 'Otomatik uyku sona erdi efendim. Nova yeniden tam güç modunda.'
          : 'Nova tam aktif moda alındı efendim.';
    });

    await _refreshDashboardSummaries();
    if (announce) {
      await _speakDashboardMessage(_lastResponse);
    }
  }

  Future<void> _setPowerBatterySaver({bool announce = true}) async {
    await _applyUserSelectedPowerMode(NovaPowerMode.batterySaver);
    _lifecycleService.wake();
    _presenceService.setStateSafe(NovaPresenceState.idle);
    await _backgroundBridgeService.setBackgroundRunning();
    await _backgroundBridgeService.showOverlayIdle();
    await _ensureOperationalListening();

    if (!mounted) return;
    _safeSetState(() {
      _lastResponse =
          'Nova pil tasarrufu moduna alındı efendim. Sürekli dinleme açık kalır, yalnız enerji kullanımı dengelenir.';
    });
    await _refreshDashboardSummaries();
    if (announce) {
      await _speakDashboardMessage(_lastResponse);
    }
  }

  Future<void> _setPowerLimbo({
    bool announce = true,
    bool scheduled = false,
  }) async {
    if (scheduled) {
      await _powerService.setLimbo(userInitiated: false);
    } else {
      await _applyUserSelectedPowerMode(NovaPowerMode.limbo);
    }
    await _ensureOperationalListening();
    _lifecycleService.sleep();
    _presenceService.setStateSafe(NovaPresenceState.sleeping);
    await _backgroundBridgeService.setBackgroundSleeping();
    await _backgroundBridgeService.showOverlaySleeping();

    if (!mounted) return;
    _safeSetState(() {
      _lastResponse = scheduled
          ? 'Otomatik gece penceresi bitti efendim. Nova araf moduna döndü.'
          : 'Nova araf moduna geçti efendim. Sürekli dinleme kapalı; yalnız kayıtlı kişi çağrıları, hatırlatıcılar ve wake komutu korunuyor.';
    });
    await _refreshDashboardSummaries();
    if (announce) {
      await _speakDashboardMessage(_lastResponse);
    }
  }

  Future<void> _applyUserSelectedPowerMode(NovaPowerMode mode) async {
    final schedule = await _powerScheduleService.load();
    final now = DateTime.now();
    final window = _powerScheduleService.resolveWindow(schedule, now);
    final holdUntil = window.active
        ? _powerService.buildScheduledNightHoldEnd(
            now: now,
            windowEnd: window.end,
          )
        : null;

    switch (mode) {
      case NovaPowerMode.batterySaver:
        await _powerService.setBatterySaver(
          userInitiated: true,
          scheduledNightHoldUntil: holdUntil,
        );
        break;
      case NovaPowerMode.limbo:
        await _powerService.setLimbo(
          userInitiated: true,
          scheduledNightHoldUntil: holdUntil,
        );
        break;
      case NovaPowerMode.fullyOn:
        await _powerService.setFullyOn(
          userInitiated: true,
          scheduledNightHoldUntil: holdUntil,
        );
        break;
      case NovaPowerMode.passiveSleep:
        await _powerService.setPassiveSleep(userInitiated: true);
        break;
      case NovaPowerMode.fullyShutdown:
        await _powerService.setFullyShutdown(userInitiated: true);
        break;
    }
  }

  Future<void> _configureSleepWindow() async {
    final start = await showTimePicker(
      context: context,
      initialTime: _parseTimeOfDay(_powerSchedule.sleepStart),
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: _parseTimeOfDay(_powerSchedule.sleepEnd),
    );
    if (end == null || !mounted) return;
    final next = _powerSchedule.copyWith(
      enabled: true,
      sleepStart: _formatTimeOfDay(start),
      sleepEnd: _formatTimeOfDay(end),
    );
    await _powerScheduleService.save(next);
    _safeSetState(() {
      _powerSchedule = next;
      _lastResponse = 'Otomatik gece modu saatleri kaydedildi efendim.';
    });
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _toggleAutoSleep(bool value) async {
    final next = _powerSchedule.copyWith(enabled: value);
    await _powerScheduleService.save(next);
    if (!mounted) return;
    _safeSetState(() {
      _powerSchedule = next;
      _lastResponse = value
          ? 'Otomatik uyku planı açıldı efendim. Belirlenen saatlerde gece moduna geçer; pencere bitince, siz elle başka moda geçmediyseniz, araf moduna döner.'
          : 'Otomatik uyku planı kapatıldı efendim.';
    });
    await _speakDashboardMessage(_lastResponse);
  }

  TimeOfDay _parseTimeOfDay(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  String _formatTimeOfDay(TimeOfDay value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _runDebugMode() async {
    if (_debugRunning) return;
    _safeSetState(() {
      _debugRunning = true;
      _lastResponse = 'Hata ayıklama modu başlatılıyor efendim.';
    });
    await _speakDashboardMessage(_lastResponse);

    final debugService = NovaDebugModeService(
      diagnosticService: NovaSelfDiagnosticService(
        signalService: self_repair_signal.NovaRuntimeSignalService.instance,
        recognitionService: NovaSelfRecognitionService(
          signalService: self_repair_signal.NovaRuntimeSignalService.instance,
          manifestService: NovaCapabilityManifestService(
            runtimeRegistryService:
                const NovaCapabilityRuntimeRegistryService(),
          ),
        ),
      ),
      capabilityCatalogService: NovaCapabilityCatalogService(
        recognitionService: NovaSelfRecognitionService(
          signalService: self_repair_signal.NovaRuntimeSignalService.instance,
          manifestService: NovaCapabilityManifestService(
            runtimeRegistryService:
                const NovaCapabilityRuntimeRegistryService(),
          ),
        ),
        probeService: NovaCapabilityProbeService(
          runtimeSignalService: self_repair_signal.NovaRuntimeSignalService.instance,
        ),
      ),
    );
    final result = await debugService.runDeepDebug();
    if (!mounted) return;
    _safeSetState(() {
      _debugRunning = false;
      _lastResponse = result.message;
    });
    await _refreshDashboardSummaries();
    await _speakDashboardMessage(_lastResponse);
  }

  Future<bool> _handleDashboardSystemCommand(String raw) async {
    final lower = raw.toLowerCase().trim();
    bool hasAny(List<String> patterns) => patterns.any(lower.contains);

    if (hasAny([
      'pil tasarrufu',
      'güç tasarrufu',
      'ekonomi modu',
      'tasarruf moduna geç',
      'tasarrufa geç',
    ])) {
      await _setPowerBatterySaver();
      return true;
    }
    if (hasAny([
      'uyku moduna geç',
      'pasif uykuya geç',
      'uykuya al',
      'gece modu',
      'gece moduna geç',
    ])) {
      await _setPowerPassiveSleep();
      return true;
    }
    if (hasAny(['araf modu', 'arafa geç', 'arafa al', 'sessiz bekle'])) {
      await _setPowerLimbo();
      return true;
    }
    if (hasAny([
      'tam güç',
      'tam performans',
      'aktif moda geç',
      'uyan nova',
      'uyan ve hazır ol',
    ])) {
      await _setPowerFullyOn();
      return true;
    }
    if (hasAny(['güç durumun ne', 'hangi güç modundasın', 'mevcut güç modu'])) {
      _safeSetState(() {
        _lastResponse = 'Mevcut güç modu: ${_powerLabel()} efendim.';
      });
      await _speakDashboardMessage(_lastResponse);
      return true;
    }
    if (hasAny([
      'hata ayıkla',
      'debug modu',
      'detaylı tara',
      'sistemi tara',
      'arıza tara',
      'tanı koy',
      'derin analiz yap',
    ])) {
      await _runDebugMode();
      return true;
    }
    if (hasAny([
      'kendini tanı',
      'kendini tani',
      'neler yapabiliyorsun',
      'sistemlerini anlat',
    ])) {
      await _runSelfRecognitionSummary();
      return true;
    }
    if (hasAny([
      'kendini onar',
      'onarım başlat',
      'onarim baslat',
      'sorunu onar',
      'tamir et',
      'onar',
    ])) {
      await _runQuickSelfRepair(raw);
      return true;
    }
    return false;
  }

  Future<void> _setPowerPassiveSleep({
    bool announce = true,
    bool scheduled = false,
  }) async {
    await _powerService.setPassiveSleep(userInitiated: !scheduled);
    await _ensureOperationalListening();
    _lifecycleService.sleep();
    _presenceService.setStateSafe(NovaPresenceState.sleeping);
    await _backgroundBridgeService.setBackgroundSleeping();
    await _backgroundBridgeService.showOverlaySleeping();

    if (!mounted) return;

    _safeSetState(() {
      _lastResponse = scheduled
          ? 'Otomatik uyku modu başladı efendim. Çağrı, alarm ve hatırlatıcı zinciri açık; sürekli dinleme kapatıldı.'
          : 'Nova pasif uyku moduna alındı efendim. Sürekli dinleme kapatıldı.';
    });

    await _refreshDashboardSummaries();
    if (announce) {
      await _speakDashboardMessage(_lastResponse);
    }
  }

  Future<void> _setPowerFullyShutdown() async {
    await _continuousListeningRuntimeService.fullyShutdown();
    await _powerService.setFullyShutdown(userInitiated: true);
    _presenceService.setStateSafe(NovaPresenceState.fullyOff);

    if (!mounted) return;

    _safeSetState(() {
      _lastResponse = 'Nova tamamen kapatıldı efendim.';
    });

    await _refreshDashboardSummaries();
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _runManualStorageCleanup() async {
    _safeSetState(() {
      _cleanupRunning = true;
    });

    final result = await _storageCleanupService.runManualCleanup();
    await _refreshDashboardSummaries();

    if (!mounted) return;

    _safeSetState(() {
      _cleanupRunning = false;
      _lastResponse = result.message;
    });

    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _runReminderCleanup() async {
    _safeSetState(() {
      _cleanupRunning = true;
    });

    final removed = await widget.reminderService.cleanupCompletedManually();
    await _refreshDashboardSummaries();

    if (!mounted) return;

    _safeSetState(() {
      _cleanupRunning = false;
      _lastResponse =
          '$removed adet tamamlanmış hatırlatıcı temizlendi efendim.';
    });

    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _runSecurityCleanup() async {
    _safeSetState(() {
      _securityActionRunning = true;
    });

    await _securityIncidentService.cleanupExpiredReports();
    await _refreshSecurityState();

    if (!mounted) return;

    _safeSetState(() {
      _securityActionRunning = false;
      _lastResponse =
          '48 saatten eski şüpheli hareket raporları temizlendi efendim.';
    });

    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _clearAllSecurityReports() async {
    _safeSetState(() {
      _securityActionRunning = true;
    });

    await _securityIncidentService.clearAllReports();
    await _refreshSecurityState();

    if (!mounted) return;

    _safeSetState(() {
      _securityActionRunning = false;
      _lastResponse = 'Tüm güvenlik raporları temizlendi efendim.';
    });

    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _stopSecurityVibration() async {
    if (!mounted) return;

    _safeSetState(() {
      _securityVibrationStopped = true;
      _lastResponse = 'Güvenlik titreşimi durduruldu efendim.';
    });

    await HapticFeedback.selectionClick();
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _resumeSecurityVibration() async {
    if (!mounted) return;

    _safeSetState(() {
      _securityVibrationStopped = false;
      _lastResponse = 'Güvenlik titreşimi yeniden açıldı efendim.';
    });

    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _applyRiskAction() async {
    _safeSetState(() {
      _securityActionRunning = true;
    });

    bool success = false;
    String message = 'Güvenlik aksiyonu uygulanamadı efendim.';

    if (_hasCriticalSecurityIncident) {
      success = await _nativeSecurityBridgeService.applyFinalContainment(
        reason: 'Gösterge paneli kritik risk containment aksiyonu',
      );
      message = success
          ? 'Kritik risk için containment uygulandı efendim.'
          : message;
    } else if (_hasHighSecurityIncident) {
      success = await _nativeSecurityBridgeService.applyQuarantineShell(
        reason: 'Gösterge paneli yüksek risk çalışma zamanı karantina aksiyonu',
      );
      message = success
          ? 'Yüksek risk için quarantine shell uygulandı efendim.'
          : message;
    } else if (_hasMediumSecurityIncident) {
      success = await _nativeSecurityBridgeService.applyRestrictMode(
        reason: 'Gösterge paneli orta risk daraltma aksiyonu',
      );
      message = success
          ? 'Orta risk için restrict mode uygulandı efendim.'
          : message;
    }

    await _refreshSecurityState();

    if (!mounted) return;

    _safeSetState(() {
      _securityActionRunning = false;
      _lastResponse = message;
    });

    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _openPersonalityPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VoicePersonalitySettingsPage()),
    );

    if (!mounted) return;

    _safeSetState(() {
      _lastResponse = 'Kişilik ayarlarından dönüldü efendim.';
    });

    await _speakDashboardMessage(_lastResponse);
  }

  String _powerLabel() {
    if (_powerService.isFullyShutdown) return 'Tamamen kapalı';
    if (_powerService.isLimbo) return 'Araf modu';
    if (_powerService.isPassiveSleep) return 'Gece modu';
    if (_powerService.isBatterySaver) return 'Tasarruf modu';
    return 'Tam güç';
  }

  int get _autoHandleContactCount =>
      _managedContacts.where((e) => e.canReceiveAutoCallHandling).length;

  int get _authorizedNovaUseCount =>
      _managedContacts.where((e) => e.isAuthorizedToUseNova).length;

  String _callHandlingSummary() {
    if (!_novaSettings.callHandlingEnabled) {
      return 'Çağrı yönetimi kapalı. Nova hiçbir çağrıyı devralmaz.';
    }

    if (_managedContacts.isEmpty) {
      return 'Kayıtlı kişi yok. Bilinmeyen numaralarda Nova yalnızca sizi bilgilendirir.';
    }

    if (_autoHandleContactCount == 0) {
      return 'Kişiler kayıtlı ancak çağrı yönetimi yetkisi verilen kişi yok.';
    }

    return 'Yalnızca izin verilen kişilerde çağrı devralma çalışır. Bilinmeyen veya yetkisiz kişilerde önce size sorulur.';
  }

  String _apiStatusText() {
    if (!_featureFlags.apiEnabled || !_novaSettings.apiBrainEnabled) {
      return 'Kapalı';
    }
    final provider = _novaSettings.activeAiProvider;
    final model = _novaSettings.activeApiModel.trim();
    if (_novaSettings.apiKey.trim().isEmpty) {
      return '${provider.label} anahtarı girilmemiş';
    }
    return model.isEmpty
        ? '${provider.label} hazır'
        : '${provider.label} hazır • $model';
  }

  String _voiceCloneSummary() {
    if (_voiceCloneCount == 0) {
      return 'Henüz kayıtlı klon ses yok.';
    }

    return 'Toplam $_voiceCloneCount klon ses var. Favori: $_favoriteVoiceCloneCount, aktif kullanımda: $_activeVoiceCloneCount.';
  }

  String _reminderSummary() {
    return 'Bekleyen $_reminderPendingCount, tamamlanmış $_reminderCompletedCount hatırlatıcı var.';
  }

  String _memorySummary() {
    return 'Kalıcı $_memoryPermanentCount, geçici $_memoryTemporaryCount, bağlamsal $_memoryContextualCount kayıt var. Çağrı notu: $_callNotesCount.';
  }

  String _callInstructionSummary() {
    return 'Bekleyen $_callInstructionPendingCount, tamamlanan $_callInstructionCompletedCount talimatlı çağrı görevi var.';
  }

  String _translatorModeSummary() {
    final state = _translatorModeState;
    if (!state.enabled) {
      return 'Çevirmen modu kapalı. Dil paketleri rehber düzeyinde hazır.';
    }
    return 'Çevirmen modu açık: ${state.sourceLanguageCode.toUpperCase()} → ${state.targetLanguageCode.toUpperCase()}';
  }

  Future<void> _enrollOwnerVoiceprint() async {
    _safeSetState(() {
      _voiceFlowRunning = true;
      _lastResponse =
          'Efendim, sahibin ses izi kaydı başlatılıyor. Lütfen birkaç saniye net konuşun.';
    });

    await _speakDashboardMessage(_lastResponse);

    final owner = await _ownerIdentityService.loadOwner();

    if (owner == null ||
        owner.ownerName.trim().isEmpty ||
        owner.ownerVoiceId.trim().isEmpty) {
      if (!mounted) return;

      _safeSetState(() {
        _voiceFlowRunning = false;
        _lastResponse =
            'Önce cihaz sahibi bilgisi tanımlanmalı efendim. Sahip profili eksik görünüyor.';
      });
      await _speakDashboardMessage(_lastResponse);
      return;
    }

    final enroll = await _voiceIdentityRuntimeService
        .enrollFromFreshExternalSample(
          voiceId: owner.ownerVoiceId,
          displayName: owner.ownerName,
          maxDurationSeconds: 6,
          outputName: 'nova_owner_enroll',
        );

    if (!mounted) return;

    _safeSetState(() {
      _voiceFlowRunning = false;
      _lastResponse = enroll.success
          ? '${owner.ownerName} için ses izi kaydı tamamlandı efendim.'
          : enroll.message;
    });

    if (enroll.success) {
      await _refreshDashboardSummaries();
    }

    await _speakDashboardMessage(_lastResponse);
  }

  Future<bool> _authorizeCurrentSpeakerBeforeCommand() async {
    final trustedDaily = await _dailyVoiceSessionService
        .loadActiveTrustedSession();
    if (trustedDaily != null && trustedDaily.isTrusted) {
      return true;
    }

    final inspection = await _voiceAuthorizationRuntimeService
        .inspectPreferContinuityThenFresh(
          maxDurationSeconds: 4,
          outputName: 'nova_runtime_auth',
          minSimilarity: 0.62,
          allowContinuityReuse: true,
          preferredVoiceId:
              _continuousListeningRuntimeService
                  .currentPromptMetadata['speakerVoiceId']
                  ?.toString() ??
              '',
        );

    if (!mounted) return false;

    final decision = inspection.decision;
    final allowed =
        decision.level == VoiceAccessLevel.owner ||
        decision.level == VoiceAccessLevel.authorizedGuest;

    if (!allowed) {
      _safeSetState(() {
        _lastResponse = decision.message.trim().isEmpty
            ? 'Yetkiniz bulunmamaktadır.'
            : decision.message.trim();
      });

      await _refreshDashboardSummaries();
      await _speakDashboardMessage(_lastResponse);
      return false;
    }

    if (inspection.recognizedVoiceId.trim().isNotEmpty) {
      await _dailyVoiceSessionService.rememberTrustedSpeaker(
        voiceId: inspection.recognizedVoiceId.trim(),
        level: decision.level,
        recognizedName: inspection.recognizedDisplayName.trim(),
      );
    }

    return true;
  }

  Future<void> _processPrompt({
    required String prompt,
    required bool fromVoice,
    bool allowSystemExecution = true,
    Map<String, dynamic> promptMetadata = const <String, dynamic>{},
    String requestOrigin = 'user_voice',
  }) async {
    final raw = prompt.trim();
    if (raw.isEmpty) return;

    try {
      final speakerName = promptMetadata['speakerName']?.toString() ?? '';
      final speakerVoiceId = promptMetadata['speakerVoiceId']?.toString() ?? '';
      final relationshipLabel =
          promptMetadata['relationshipLabel']?.toString() ?? '';
      if (fromVoice) {
        await widget.conversationSessionService.addUserVoice(
          raw,
          speakerName: speakerName,
          speakerVoiceId: speakerVoiceId,
          relationshipLabel: relationshipLabel,
        );
      } else {
        await widget.conversationSessionService.addUserText(
          raw,
          speakerName: speakerName,
          speakerVoiceId: speakerVoiceId,
          relationshipLabel: relationshipLabel,
        );
      }
    } catch (_) {}

    final wakeAlarmStopped = allowSystemExecution
        ? await widget.reminderService.tryAcknowledgeWakeAlarmFromInput(raw)
        : false;

    if (wakeAlarmStopped) {
      const text = 'Tamam efendim. Uyandırma akışı durduruldu.';
      await _refreshDashboardSummaries();

      if (!mounted) return;
      _safeSetState(() {
        _lastResponse = text;
      });

      await _speakDashboardMessage(text);
      return;
    }

    if (_powerService.isFullyShutdown) {
      const text = 'Nova tamamen kapalı durumda efendim.';

      if (!mounted) return;
      _safeSetState(() {
        _lastResponse = text;
      });
      await _speakDashboardMessage(text);
      return;
    }

    final lifecycleDecision = allowSystemExecution
        ? _lifecycleService.evaluateInput(raw)
        : const NovaLifecycleDecision(
            shouldWake: false,
            shouldSleepAfterResponse: false,
            shouldIgnoreInput: false,
          );

    if (lifecycleDecision.shouldWake) {
      _lifecycleService.wake();
      await _powerService.setFullyOn(userInitiated: true);
      _presenceService.setStateSafe(NovaPresenceState.idle);
    }

    if (lifecycleDecision.shouldIgnoreInput) {
      const text =
          'Nova pasif beklemede efendim. Nova burda mısın gibi bir komutla yeniden aktif edebilirsiniz.';
      await _refreshDashboardSummaries();

      if (!mounted) return;
      _safeSetState(() {
        _lastResponse = text;
      });
      await _speakDashboardMessage(text);
      return;
    }

    if (_isLoading) {
      await widget.localModelService.purgeRuntimeState(
        reason: 'dashboard_replace_prompt',
      );
      _safeSetState(() {
        _isLoading = false;
      });
    }

    _safeSetState(() {
      _isLoading = true;
      _quickReply = widget.persona.primaryWakePhrase;
      _lastResponse = 'API beyin cevabı hazırlanıyor.';
      if (fromVoice) {
        _lastHeardText = raw;
      }
    });

    _presenceService.setStateSafe(NovaPresenceState.listening);
    await _backgroundBridgeService.showOverlayListening();

    final restrictedCapability = allowSystemExecution
        ? await _restrictedCapabilityGuardService.evaluatePhoneControlRequest(
            raw,
          )
        : const NovaRestrictedCapabilityGuardResult.allow();
    if (restrictedCapability.blocked) {
      if (!mounted) return;
      _safeSetState(() {
        _quickReply = widget.persona.primaryWakePhrase;
        _lastResponse = restrictedCapability.spokenText;
        _isLoading = false;
      });
      await _refreshDashboardSummaries();
      await _backgroundBridgeService.showOverlayIdle();
      _presenceService.setStateSafe(
        _lifecycleService.isSleeping
            ? NovaPresenceState.sleeping
            : NovaPresenceState.idle,
      );
      await _speakDashboardMessage(restrictedCapability.spokenText);
      return;
    }

    if (_spokenIntentInterpreter.isDeferral(raw) &&
        _lastResponse.toLowerCase().contains('overlay izni kapalı')) {
      _overlayWarningSnoozeUntil = DateTime.now().add(
        const Duration(minutes: 10),
      );
      const text =
          'Tamam efendim. Overlay izni için bir süre bekleyeceğim ve aynı uyarıyı tekrarlamayacağım.';
      if (!mounted) return;
      _safeSetState(() {
        _quickReply = widget.persona.primaryWakePhrase;
        _lastResponse = text;
        _isLoading = false;
      });
      await _backgroundBridgeService.showOverlayIdle();
      _presenceService.setStateSafe(
        _lifecycleService.isSleeping
            ? NovaPresenceState.sleeping
            : NovaPresenceState.idle,
      );
      await _speakDashboardMessage(text);
      return;
    }

    await const NovaIdentityRuntimeService().ensureLoaded();
    final adaptiveMetadata = await const NovaSystemAdaptationContractService()
        .buildMetadata(
          prompt: raw,
          sourceSystem: fromVoice
              ? 'dashboard_stt'
              : 'dashboard_manual_voice_entry',
          requestOrigin: requestOrigin,
          baseMetadata: <String, dynamic>{
            'source': fromVoice
                ? 'dashboard_stt'
                : 'dashboard_manual_voice_entry',
            'systemExecutionAllowed': allowSystemExecution,
            'teachingModeEnabled': _novaSettings.teachingModeEnabled,
            'apiLearningEnabled': _novaSettings.apiLearningEnabled,
            'apiProvider': _novaSettings.activeAiProvider.key,
            'apiModel': _novaSettings.activeApiModel,
            'conversationEntryAlreadyAdded': true,
            ...promptMetadata,
          },
          speakerName: promptMetadata['speakerName']?.toString() ?? '',
          relationshipLabel:
              promptMetadata['relationshipLabel']?.toString() ?? '',
          speakerVoiceId: promptMetadata['speakerVoiceId']?.toString() ?? '',
          ownerConfidence: (promptMetadata['ownerConfidence'] as num?)
              ?.toDouble(),
          mediaMode: _isLikelyMediaRequest(raw),
        );

    final AiRequest request = AiRequest(
      prompt: allowSystemExecution
          ? raw
          : 'Bu kişi komut çalıştıramaz; sadece doğal sohbete cevap ver. Komut veya cihaz kontrolü istemi varsa nazikçe reddet. Kullanıcı sözü: $raw',
      mode: _novaSettings.apiBrainEnabled ? AiMode.apiOnly : _selectedMode,
      internetAllowed:
          _novaSettings.apiBrainEnabled && _internetAllowedForThisRequest,
      isResearchRequest: allowSystemExecution ? _isResearchRequest : false,
      isSelfLearningRequest: allowSystemExecution
          ? _isSelfLearningRequest
          : false,
      isFastResponsePriority: true,
      isUserApprovedApiUsage:
          _novaSettings.apiBrainEnabled && _userApprovedApiUsageForThisRequest,
      activeProviderKey: _novaSettings.activeAiProvider.key,
      activeModelId: _novaSettings.activeApiModel,
      requestedByVoice: true,
      requestOrigin: requestOrigin,
      metadata: adaptiveMetadata,
    );

    final dashboardPromptSource = adaptiveMetadata['source']?.toString() ?? '';
    debugPrint(
      'NOVA_DASHBOARD_PROMPT_TO_AI promptHash=${raw.hashCode} '
      'fromVoice=$fromVoice origin=$requestOrigin source=$dashboardPromptSource '
      'prompt="${_safeLogPreview(raw)}"',
    );

    final hotpathResult = await _hotpathOwnerService.resolveDashboardTurn(
      rawInput: raw,
      allowSystemExecution: allowSystemExecution,
      aiRequest: request,
      runAi: _novaAiService.process,
    );

    final dashboardAiRoute =
        hotpathResult.aiResponse?.metadata['route']?.toString() ?? '';
    final dashboardAiTtsSource =
        hotpathResult.aiResponse?.metadata['tts_source']?.toString() ?? '';
    debugPrint(
      'NOVA_DASHBOARD_AI_RESULT handledByAi=${hotpathResult.handledByAi} '
      'handledByRuntime=${hotpathResult.handledByRuntime} '
      'isError=${hotpathResult.aiResponse?.isError ?? false} '
      'route=$dashboardAiRoute '
      'tts_source=$dashboardAiTtsSource '
      'textChars=${hotpathResult.spokenText.trim().length}',
    );

    final specializedHandled = await _tryHandleOwnerDelegatedCapabilityBroker(
      raw: raw,
      allowSystemExecution: allowSystemExecution,
      hotpathHandledRuntime: hotpathResult.handledByRuntime,
    );
    if (specializedHandled) {
      return;
    }

    final response = hotpathResult.aiResponse;
    if (response == null ||
        response.isError ||
        !response.hasAuthoritativeBrainProof) {
      final blockedText = response?.displayText.trim().isNotEmpty == true
          ? response!.displayText.trim()
          : 'API/AI otorite kanıtı yok; dashboard konuşması engellendi.';
      if (!mounted) return;
      _safeSetState(() {
        _lastResponse = blockedText;
        _isLoading = false;
      });
      debugPrint(
        'NOVA_DASHBOARD_FINAL_BLOCKED_MISSING_AUTHORITY_PROOF '
        'hasResponse=${response != null} isError=${response?.isError ?? false} '
        'textChars=${blockedText.length}',
      );
      return;
    }

    final finalText = hotpathResult.spokenText.trim().isEmpty
        ? response.displayText.trim()
        : hotpathResult.spokenText.trim();

    try {
      await _conversationFocusService.rememberExchange(
        userText: raw,
        novaReply: finalText,
        learningRelevant: _adaptiveInstructionService
            .looksLikePersistentTeaching(raw),
        explicitlyPersistent: _looksLikeMemorySaveRequest(raw),
      );
    } catch (_) {}

    if (!mounted) return;

    _safeSetState(() {
      _quickReply = response.quickReply.isEmpty
          ? widget.persona.primaryWakePhrase
          : response.quickReply;
      _lastResponse = finalText;
      _isLoading = false;
    });

    await _refreshDashboardSummaries();

    try {
      _presenceService.setStateSafe(NovaPresenceState.speaking);
      await _backgroundBridgeService.showOverlaySpeaking();
      final responseTtsSource =
          response.metadata['tts_source']?.toString() ??
          'brain_decision_ai_output';
      final responseRoute = response.metadata['route']?.toString() ?? '';
      final speechAllowed = NovaSingleBrainAuthorityService.instance
          .authorizeSpeech(
            source: 'dashboard_final',
            text: finalText,
            response: response,
          );
      debugPrint(
        'NOVA_DASHBOARD_TTS_SPEAK_START '
        'tts_source=$responseTtsSource '
        'route=$responseRoute '
        'isError=${response.isError} allowedBySingleBrain=$speechAllowed '
        'textChars=${finalText.length}',
      );
      final trace = NovaRouteTrace(
        turnId: response.metadata['turnId']?.toString() ?? '',
        inputSource: 'dashboard_voice',
        acceptedTranscript: raw,
        selectedRoute: responseRoute,
        dashboardPath: true,
        setupPath: false,
        hotpathOwner: true,
        runtimeOrchestrator: hotpathResult.handledByRuntime,
        directAi: !hotpathResult.handledByRuntime,
        systemSpeechRewrite: false,
        ttsSource: responseTtsSource,
        finalTextOwner: NovaFinalTextContract.ownerFromMetadata(
          response.metadata,
        ),
        apiRawResponseHash:
            response.metadata['rawModelTextHash']?.toString() ?? '',
        cleanResponseHash:
            response.metadata['cleanModelTextHash']?.toString() ?? '',
        finalSpokenHash: NovaFinalTextContract.hashText(finalText),
        actionExecuted: hotpathResult.handledByRuntime,
        memoryWritten: true,
        staticSpokenAttemptBlocked: false,
        finalTextSourceFile:
            response.metadata['sourceFile']?.toString() ?? 'ai_provider',
      );
      debugPrint('NOVA_ROUTE_TRACE ${trace.toMap()}');
      if (!speechAllowed) {
        return;
      }
      await widget.ttsService.speak(
        finalText,
        mode: _preferredConversationTtsMode(),
        authoritySource: 'dashboard_final',
        authorityResponse: response,
      );
    } catch (_) {
      // Türkçe dijital insan ses zincirini sistem fallback sesiyle bozma.
    } finally {
      await _backgroundBridgeService.showOverlayIdle();
      if (lifecycleDecision.shouldSleepAfterResponse) {
        _lifecycleService.sleep();
        await _powerService.setPassiveSleep(userInitiated: true);
        await _ensureOperationalListening();
        _presenceService.setStateSafe(NovaPresenceState.sleeping);
        await _backgroundBridgeService.showOverlaySleeping();
      } else {
        _presenceService.setStateSafe(
          _lifecycleService.isSleeping
              ? NovaPresenceState.sleeping
              : NovaPresenceState.idle,
        );
      }
    }
  }

  bool _looksLikeMemorySaveRequest(String input) {
    final lower = input.toLowerCase();
    return lower.contains('hafızana kaydet') ||
        lower.contains('hafızaya kaydet') ||
        lower.contains('bunu kaydet') ||
        lower.contains('bunu unutma') ||
        lower.contains('şunu unutma');
  }

  bool _isTemporaryMemoryChoice(String input) {
    final lower = input.toLowerCase();
    return lower.contains('geçici') || lower.contains('48 saat');
  }

  bool _isPermanentMemoryChoice(String input) {
    final lower = input.toLowerCase();
    return lower.contains('kalıcı');
  }

  String _extractMemoryContent(String input) {
    var value = input.trim();
    for (final pattern in <String>[
      'geçici hafızana kaydet',
      'kalıcı hafızana kaydet',
      'geçici hafızaya kaydet',
      'kalıcı hafızaya kaydet',
      'hafızana kaydet',
      'hafızaya kaydet',
      'bunu kaydet',
      'bunu unutma',
      'şunu unutma',
    ]) {
      final index = value.toLowerCase().indexOf(pattern);
      if (index >= 0) {
        value = value.substring(index + pattern.length).trim();
        break;
      }
    }
    return value
        .replaceFirst(RegExp(r'^(olarak|diye)\s+', caseSensitive: false), '')
        .trim();
  }

  Future<bool> _tryHandleOwnerDelegatedCapabilityBroker({
    required String raw,
    required bool allowSystemExecution,
    required bool hotpathHandledRuntime,
  }) async {
    if (!allowSystemExecution || hotpathHandledRuntime) {
      return false;
    }

    final snapshot = await _nativeSecurityBridgeService.getSnapshot();
    if (!_snapshotAllows(snapshot, requireActionSurface: true)) {
      await _announceCapabilityBlocked(snapshot);
      return true;
    }

    final aiSelectedCapability = await _resolveAiDelegatedCapability(raw);
    if (aiSelectedCapability.isEmpty || aiSelectedCapability == 'none') {
      return false;
    }

    final delegatedHandlers =
        <({String key, Future<bool> Function() run, bool refreshSummaries})>[
          (
            key: 'memory',
            run: () => _runDelegatedMemoryCapability(raw),
            refreshSummaries: true,
          ),
          (
            key: 'translator',
            run: () => _runDelegatedTranslatorCapability(raw),
            refreshSummaries: false,
          ),
          (
            key: 'language_pack',
            run: () => _runDelegatedLanguagePackCapability(raw),
            refreshSummaries: false,
          ),
          (
            key: 'call_instruction',
            run: () => _runDelegatedCallInstructionCapability(raw),
            refreshSummaries: true,
          ),
          (
            key: 'personality',
            run: () => _runDelegatedPersonalityCapability(raw),
            refreshSummaries: false,
          ),
          (
            key: 'media',
            run: () => _runDelegatedMediaCapability(raw),
            refreshSummaries: false,
          ),
          (
            key: 'adaptive_teaching',
            run: () => _runDelegatedAdaptiveTeachingCapability(raw),
            refreshSummaries: true,
          ),
        ];

    for (final handler in delegatedHandlers.where(
      (handler) => handler.key == aiSelectedCapability,
    )) {
      final handled = await handler.run();
      if (handled) {
        await _finishHandledTurn(refreshSummaries: handler.refreshSummaries);
        return true;
      }
    }

    return false;
  }

  Future<void> _finishHandledTurn({bool refreshSummaries = false}) async {
    if (!mounted) return;
    _safeSetState(() {
      _quickReply = widget.persona.primaryWakePhrase;
      _isLoading = false;
    });
    if (refreshSummaries) {
      await _refreshDashboardSummaries();
    }
    await _backgroundBridgeService.showOverlayIdle();
    _presenceService.setStateSafe(
      _lifecycleService.isSleeping
          ? NovaPresenceState.sleeping
          : NovaPresenceState.idle,
    );
  }

  bool _snapshotAllows(
    NovaNativeSecuritySnapshot snapshot, {
    bool requireActionSurface = false,
    bool requireCallFlow = false,
    bool requireMediaFlow = false,
    bool requireNetwork = false,
    bool requireSelfRepair = false,
  }) {
    if (!snapshot.runtimeAllowed ||
        !snapshot.nativeBridgeAllowed ||
        snapshot.blackoutActive) {
      return false;
    }
    if (requireActionSurface && !snapshot.actionSurfaceAllowed) return false;
    if (requireCallFlow && !snapshot.callFlowAllowed) return false;
    if (requireMediaFlow && !snapshot.mediaFlowAllowed) return false;
    if (requireNetwork && !snapshot.networkIntentsAllowed) return false;
    if (requireSelfRepair && !snapshot.selfRepairAllowed) return false;
    return true;
  }

  Future<void> _announceCapabilityBlocked(
    NovaNativeSecuritySnapshot snapshot,
  ) async {
    final text = snapshot.message.trim().isEmpty
        ? 'Güvenlik containment nedeniyle bu yüzey şu anda kapalı efendim.'
        : snapshot.message.trim();
    if (mounted) {
      _safeSetState(() => _lastResponse = text);
    }
    await _speakDashboardMessage(text);
  }

  Future<String> _resolveAiDelegatedCapability(String raw) async {
    final normalized = raw.trim();
    if (normalized.isEmpty) return 'none';
    try {
      final capabilityRequest = AiRequest(
        prompt:
            'Kullanıcı sözü için hangi yerel davranış modülü çalışmalı? Yalnız şu anahtarlardan birini üret: memory, translator, language_pack, call_instruction, personality, media, adaptive_teaching, none. Açıklama yazma. Kullanıcı sözü: "$normalized"',
        mode: AiMode.apiOnly,
        internetAllowed: true,
        requestedByVoice: true,
        isFastResponsePriority: true,
        requestOrigin: 'user_voice',
        userInitiated: true,
        userConfirmedThisAction: true,
        metadata: <String, dynamic>{
          'source': 'dashboard_delegated_capability_gate',
          'systemExecutionAllowed': false,
          'aiChainAuthorityGate': true,
          'allowedCapabilities':
              'memory|translator|language_pack|call_instruction|personality|media|adaptive_teaching|none',
          'decisionOnlyClassifier': true,
        },
      );
      final capabilityDecision = await NovaSingleBrainAuthorityService.instance
          .handleInput(
            input: NovaBrainInput(
              text: normalized,
              source: 'dashboard_delegated_capability_gate',
              mode: 'decisionOnlyClassifier',
              primaryTurn: false,
              allowFallbackSpeech: false,
              requiresLocalModel: false,
              metadata: capabilityRequest.metadata,
            ),
            baseRequest: capabilityRequest,
            mode: AiMode.apiOnly,
            runAi: _novaAiService.process,
          );
      final response = capabilityDecision.response;
      final token = response.displayText
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z_]+'), ' ')
          .trim();
      for (final key in <String>[
        'adaptive_teaching',
        'call_instruction',
        'language_pack',
        'personality',
        'translator',
        'memory',
        'media',
        'none',
      ]) {
        if (token.split(RegExp(r'\s+')).contains(key)) {
          return key;
        }
      }
    } catch (_) {}
    return 'none';
  }

  Future<bool> _runDelegatedMemoryCapability(String raw) async {
    final normalized = raw.trim();
    if (normalized.isEmpty) return false;

    if (_awaitingMemoryTypeChoice && _pendingMemoryContent.isNotEmpty) {
      if (_isTemporaryMemoryChoice(normalized)) {
        await _memoryService.addTemporary48Hours(_pendingMemoryContent);
        _awaitingMemoryTypeChoice = false;
        _pendingMemoryContent = '';
        final text =
            'Tamam efendim. Bunu geçici hafızaya 48 saatlik olarak kaydettim.';
        if (mounted) _safeSetState(() => _lastResponse = text);
        await _speakDashboardMessage(text);
        return true;
      }
      if (_isPermanentMemoryChoice(normalized)) {
        await _memoryService.add(
          type: MemoryType.permanent,
          content: _pendingMemoryContent,
        );
        _awaitingMemoryTypeChoice = false;
        _pendingMemoryContent = '';
        final text = 'Tamam efendim. Bunu kalıcı hafızaya kaydettim.';
        if (mounted) _safeSetState(() => _lastResponse = text);
        await _speakDashboardMessage(text);
        return true;
      }
      final ask =
          'Bunu geçici hafızaya mı, kalıcı hafızaya mı kaydedeyim efendim? Geçici hafıza 48 saat sürer.';
      if (mounted) _safeSetState(() => _lastResponse = ask);
      await _speakDashboardMessage(ask);
      return true;
    }

    if (!_looksLikeMemorySaveRequest(normalized)) {
      return false;
    }

    final content = _extractMemoryContent(normalized);
    if (content.isEmpty) {
      final text =
          'Kaydetmemi istediğiniz bilgiyi kısa ve net söyleyin efendim.';
      if (mounted) _safeSetState(() => _lastResponse = text);
      await _speakDashboardMessage(text);
      return true;
    }

    if (_isTemporaryMemoryChoice(normalized)) {
      await _memoryService.addTemporary48Hours(content);
      final text =
          'Tamam efendim. Bunu geçici hafızaya 48 saatlik olarak kaydettim.';
      if (mounted) _safeSetState(() => _lastResponse = text);
      await _speakDashboardMessage(text);
      return true;
    }

    if (_isPermanentMemoryChoice(normalized)) {
      await _memoryService.add(type: MemoryType.permanent, content: content);
      final text = 'Tamam efendim. Bunu kalıcı hafızaya kaydettim.';
      if (mounted) _safeSetState(() => _lastResponse = text);
      await _speakDashboardMessage(text);
      return true;
    }

    _awaitingMemoryTypeChoice = true;
    _pendingMemoryContent = content;
    final ask =
        'Bunu geçici hafızaya mı, kalıcı hafızaya mı kaydedeyim efendim? Geçici hafıza 48 saat sürer.';
    if (mounted) _safeSetState(() => _lastResponse = ask);
    await _speakDashboardMessage(ask);
    return true;
  }

  Future<bool> _runDelegatedTranslatorCapability(String raw) async {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final wantsTranslator =
        normalized.contains('cevirmen modu') ||
        normalized.contains('çevirmen modu') ||
        normalized.contains('ceviri modu') ||
        normalized.contains('çeviri modu') ||
        normalized.contains('translator mode');

    if (!wantsTranslator) {
      return false;
    }

    if (normalized.contains('kapat')) {
      _translatorModeState = await _translatorModeService.disable();
      const text = 'Çevirmen modu kapatıldı efendim.';
      if (mounted) _safeSetState(() => _lastResponse = text);
      await _refreshDashboardSummaries();
      await _speakDashboardMessage(text);
      return true;
    }

    final source =
        _extractLanguageCode(normalized) ??
        _translatorModeState.sourceLanguageCode;
    var target = _translatorModeState.targetLanguageCode;
    if (source == target) {
      target = source == 'tr' ? 'en' : 'tr';
    }
    if (normalized.contains('ingilizceye') ||
        normalized.contains('ingilizceye cevir') ||
        normalized.contains('ingilizce çevir')) {
      target = 'en';
    } else if (normalized.contains('turkceye') ||
        normalized.contains('türkçeye') ||
        normalized.contains('turkce cevir') ||
        normalized.contains('türkçe çevir')) {
      target = 'tr';
    }

    _translatorModeState = await _translatorModeService.enable(
      source: source,
      target: target,
    );
    final hasPacks = await _translatorModeService.hasRequiredPacks(
      _translatorModeState,
    );
    final text = hasPacks
        ? 'Çevirmen modu açıldı efendim. ${source.toUpperCase()} → ${target.toUpperCase()} zinciri hazır.'
        : 'Çevirmen modu açıldı efendim ancak bazı dil paketleri eksik olabilir.';
    if (mounted) _safeSetState(() => _lastResponse = text);
    await _refreshDashboardSummaries();
    await _speakDashboardMessage(text);
    return true;
  }

  Future<bool> _runDelegatedAdaptiveTeachingCapability(String raw) async {
    final snapshot = await _nativeSecurityBridgeService.getSnapshot();
    if (!_snapshotAllows(
      snapshot,
      requireActionSurface: true,
      requireSelfRepair: true,
    )) {
      await _announceCapabilityBlocked(snapshot);
      return true;
    }
    if (_adaptiveInstructionService.looksLikeTeachingReset(raw)) {
      await _adaptiveInstructionService.clearAll();
      await _behaviorOverrideService.resetAllToDefault();
      await _learnedCallResponseService.clearAll();
      const text =
          'Öğretilmiş davranışlar ve anlık öğretimler temizlendi efendim. Varsayılan davranışa döndüm.';
      if (mounted) _safeSetState(() => _lastResponse = text);
      await _speakDashboardMessage(text);
      return true;
    }

    if (_adaptiveInstructionService.looksLikePersistentTeaching(raw)) {
      final instruction = _adaptiveInstructionService.extractInstructionBody(
        raw,
      );
      if (instruction.isEmpty) return false;
      await _adaptiveInstructionService.setPersistentInstruction(instruction);
      final normalized = instruction.toLowerCase();
      if (normalized.contains('çağrı') || normalized.contains('cagri')) {
        await _behaviorOverrideService.setOverride(
          key: BehaviorKeys.callOpeningGeneral,
          instruction: instruction,
          source: 'user_teaching',
        );
      }
      if (normalized.contains('konuşma') || normalized.contains('ton')) {
        await _behaviorOverrideService.setOverride(
          key: BehaviorKeys.speechTone,
          instruction: instruction,
          source: 'user_teaching',
        );
      }
      final text =
          'Öğrettim efendim. Bundan sonraki uygun durumlarda bu davranışı referans alacağım: $instruction';
      if (mounted) _safeSetState(() => _lastResponse = text);
      await _speakDashboardMessage(text);
      return true;
    }

    if (_adaptiveInstructionService.looksLikeSessionTeaching(raw)) {
      final instruction = _adaptiveInstructionService.extractInstructionBody(
        raw,
      );
      if (instruction.isEmpty) return false;
      await _adaptiveInstructionService.setSessionInstruction(instruction);
      final text =
          'Anlaşıldı efendim. Bu seferlik şu çalışma tarzını uygulayacağım: $instruction';
      if (mounted) _safeSetState(() => _lastResponse = text);
      await _speakDashboardMessage(text);
      return true;
    }

    return false;
  }

  Future<bool> _runDelegatedCallInstructionCapability(String raw) async {
    final snapshot = await _nativeSecurityBridgeService.getSnapshot();
    if (!_snapshotAllows(
      snapshot,
      requireActionSurface: true,
      requireCallFlow: true,
    )) {
      await _announceCapabilityBlocked(snapshot);
      return true;
    }
    final result = _callInstructionCommandService.parse(
      raw: raw,
      contacts: _managedContacts,
    );
    if (!result.handled) return false;
    if (!result.success || result.draft == null) {
      if (mounted) _safeSetState(() => _lastResponse = result.spokenText);
      await _speakDashboardMessage(result.spokenText);
      return true;
    }

    await _callInstructionService.addFromDraft(result.draft!);
    await _refreshDashboardSummaries();
    if (mounted) _safeSetState(() => _lastResponse = result.spokenText);
    await _speakDashboardMessage(result.spokenText);
    return true;
  }

  Future<bool> _runDelegatedLanguagePackCapability(String raw) async {
    final snapshot = await _nativeSecurityBridgeService.getSnapshot();
    if (!_snapshotAllows(
      snapshot,
      requireActionSurface: true,
      requireNetwork: true,
    )) {
      await _announceCapabilityBlocked(snapshot);
      return true;
    }
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    if (normalized.contains('dil ekle') ||
        normalized.contains('dil öğren') ||
        normalized.contains('dili öğren')) {
      final target = _extractLanguageCode(normalized);
      if (target == null) {
        const text =
            'Tabii efendim. Şimdilik Türkçe çekirdeği ve İngilizce paketini yönetebiliyorum. Öğrenmek istediğiniz dili ayarlardan ekleyebilirsiniz.';
        if (mounted) _safeSetState(() => _lastResponse = text);
        await _speakDashboardMessage(text);
        return true;
      }
      await _languagePackService.installByCode(target);
      final spoken = target == 'en'
          ? 'Tamam efendim. İngilizce dil paketi etkinleştirildi. Çeviri ve açıklama desteği hazır.'
          : 'İstenen dil paketi eklendi efendim.';
      if (mounted) _safeSetState(() => _lastResponse = spoken);
      await _speakDashboardMessage(spoken);
      return true;
    }

    if (normalized.contains('dili kaldır') ||
        normalized.contains('dil kaldır')) {
      final target = _extractLanguageCode(normalized);
      if (target == null) {
        const text =
            'Hangi dili kaldırmamı istediğinizi netleştirir misiniz efendim?';
        if (mounted) _safeSetState(() => _lastResponse = text);
        await _speakDashboardMessage(text);
        return true;
      }
      if (target == 'tr') {
        const text =
            'Türkçe çekirdek dildir efendim. Güvenlik ve ana iletişim için kaldırılamaz.';
        if (mounted) _safeSetState(() => _lastResponse = text);
        await _speakDashboardMessage(text);
        return true;
      }
      await _languagePackService.removeByCode(target);
      final spoken = target == 'en'
          ? 'Tamam efendim. İngilizce dil paketi kaldırıldı.'
          : 'İstenen dil paketi kaldırıldı efendim.';
      if (mounted) _safeSetState(() => _lastResponse = spoken);
      await _speakDashboardMessage(spoken);
      return true;
    }
    return false;
  }

  String? _extractLanguageCode(String input) {
    final normalized = input
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u');
    if (normalized.contains('ingilizce') || normalized.contains('english'))
      return 'en';
    if (normalized.contains('türkçe') || normalized.contains('turkce'))
      return 'tr';
    if (normalized.contains('arapça') ||
        normalized.contains('arapca') ||
        normalized.contains('arabic'))
      return 'ar';
    if (normalized.contains('fransızca') ||
        normalized.contains('fransizca') ||
        normalized.contains('french'))
      return 'fr';
    if (normalized.contains('rusça') ||
        normalized.contains('rusca') ||
        normalized.contains('russian'))
      return 'ru';
    if (normalized.contains('italyanca') || normalized.contains('italian'))
      return 'it';
    return null;
  }

  Future<bool> _runDelegatedPersonalityCapability(String raw) async {
    final snapshot = await _nativeSecurityBridgeService.getSnapshot();
    if (!_snapshotAllows(snapshot, requireActionSurface: true)) {
      await _announceCapabilityBlocked(snapshot);
      return true;
    }
    final result = await _personalityCommandService.tryHandle(raw);
    if (!result.handled) return false;
    if (mounted) _safeSetState(() => _lastResponse = result.spokenText);
    await _speakDashboardMessage(result.spokenText);
    return true;
  }

  Future<bool> _runDelegatedMediaCapability(String raw) async {
    final snapshot = await _nativeSecurityBridgeService.getSnapshot();
    if (!_snapshotAllows(
      snapshot,
      requireActionSurface: true,
      requireMediaFlow: true,
    )) {
      await _announceCapabilityBlocked(snapshot);
      return true;
    }
    final normalized = raw.trim();
    if (normalized.isEmpty) return false;

    if (_awaitingMediaForegroundChoice && _pendingMediaQuery.isNotEmpty) {
      final followUp = _mediaControlService.interpret(normalized);
      if (followUp.isAffirmativeChoice) {
        final status = await _phoneControlNativeBridgeService.getStatus();
        if (status.screenLocked) {
          final text =
              'Ekran kilitli efendim. Bu aramayı açmam için ekranı açmanız gerekiyor.';
          if (mounted) _safeSetState(() => _lastResponse = text);
          await _speakDashboardMessage(text);
          return true;
        }
        final result = await _mediaControlService.openSearchInForeground(
          query: _pendingMediaQuery,
          packageName: _pendingMediaPackage.isEmpty
              ? null
              : _pendingMediaPackage,
        );
        if (_pendingMediaPackage.isNotEmpty) {
          await _phoneControlService.setPreferredMediaPackage(
            _pendingMediaPackage,
          );
        }
        _awaitingMediaForegroundChoice = false;
        _pendingMediaQuery = '';
        _pendingMediaPackage = '';
        final text = result.spokenText.trim().isEmpty
            ? 'Medya aramasını açıyorum efendim.'
            : result.spokenText.trim();
        if (mounted) _safeSetState(() => _lastResponse = text);
        await _speakDashboardMessage(text);
        return true;
      }
      if (followUp.isNegativeChoice) {
        _awaitingMediaForegroundChoice = false;
        _pendingMediaQuery = '';
        _pendingMediaPackage = '';
        const text =
            'Tamam efendim. Arama için uygulamayı ekranda açmayacağım. Arka planda yalnız temel medya kontrol komutlarını kullanabilirim.';
        if (mounted) _safeSetState(() => _lastResponse = text);
        await _speakDashboardMessage(text);
        return true;
      }
    }

    final intent = _mediaControlService.interpret(normalized);
    if (!intent.handled) return false;

    final selection = await _mediaControlService.applySelection(intent);
    if (selection.handled) {
      if (intent.suggestedAppPackage.trim().isNotEmpty) {
        await _phoneControlService.setPreferredMediaPackage(
          intent.suggestedAppPackage,
        );
      }
      if (mounted) _safeSetState(() => _lastResponse = selection.spokenText);
      await _speakDashboardMessage(selection.spokenText);
      return true;
    }

    if (intent.requiresForegroundChoice) {
      _awaitingMediaForegroundChoice = true;
      _pendingMediaQuery = intent.suggestedQuery.trim();
      _pendingMediaPackage = intent.suggestedAppPackage.trim();
      final text = intent.spokenPrompt.trim().isEmpty
          ? 'Bu işlem için ilgili medya uygulamasını ekranda açmam gerekiyor efendim. Açmamı ister misiniz?'
          : intent.spokenPrompt.trim();
      if (mounted) _safeSetState(() => _lastResponse = text);
      await _speakDashboardMessage(text);
      return true;
    }

    if (intent.canRunInBackground) {
      final result = await _mediaControlService.executeBackground(intent);
      final text = result.spokenText.trim().isEmpty
          ? 'Medya komutu işlendi efendim.'
          : result.spokenText.trim();
      if (mounted) _safeSetState(() => _lastResponse = text);
      await _speakDashboardMessage(text);
      return true;
    }

    return false;
  }

  Future<void> _sendPrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _safeSetState(() {
        _lastResponse =
            'Buyurun efendim. Bu panelde öncelikli kullanım sesli komuttur.';
      });
      await _speakDashboardMessage(_lastResponse);
      return;
    }

    _safeSetState(() {
      _lastResponse =
          'Bu panel voice-first çalışır efendim. Yazılı giriş AI çalıştırmaz. Lütfen sesli komut kullanın.';
    });
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _runVoiceFlow() async {
    if (_voiceFlowRunning || _isLoading) return;

    if (_powerService.isFullyShutdown) {
      _safeSetState(() {
        _lastResponse = 'Nova tamamen kapalı durumda efendim.';
      });
      await _speakDashboardMessage(_lastResponse);
      return;
    }

    _safeSetState(() {
      _voiceFlowRunning = true;
      _isLoading = true;
      _quickReply = widget.persona.primaryWakePhrase;
      _lastResponse = AppConstants.defaultListeningReply;
    });

    _presenceService.setStateSafe(NovaPresenceState.listening);
    await _backgroundBridgeService.showOverlayListening();

    final authorized = await _authorizeCurrentSpeakerBeforeCommand();

    if (!mounted) return;

    if (!authorized) {
      _safeSetState(() {
        _voiceFlowRunning = false;
        _isLoading = false;
      });

      _presenceService.setStateSafe(
        _lifecycleService.isSleeping
            ? NovaPresenceState.sleeping
            : NovaPresenceState.idle,
      );
      await _backgroundBridgeService.showOverlayIdle();
      return;
    }

    await widget.ttsService.stop();
    final recognizedPrompt =
        (await _listenVoiceFlowFromStreaming())?.trim() ?? '';

    if (!mounted) return;

    if (recognizedPrompt.isEmpty) {
      _safeSetState(() {
        _voiceFlowRunning = false;
        _isLoading = false;
        _lastResponse = 'Aktif ses akışından net bir ifade alamadım efendim.';
      });

      _presenceService.setStateSafe(
        _lifecycleService.isSleeping
            ? NovaPresenceState.sleeping
            : NovaPresenceState.idle,
      );
      await _backgroundBridgeService.showOverlayIdle();
      await _speakDashboardMessage(_lastResponse);
      return;
    }

    _safeSetState(() {
      _voiceFlowRunning = false;
      _isLoading = false;
      _lastHeardText = recognizedPrompt;
    });

    await _processPrompt(
      prompt: recognizedPrompt,
      fromVoice: true,
      requestOrigin: 'user_voice',
    );
  }

  Future<void> _runTtsTest() async {
    try {
      await _speakDashboardMessage(
        'Buyurun efendim. Sistemler hazır.',
        source: 'dashboard_tts_test',
      );
      if (!mounted) return;
      _safeSetState(() {
        _lastResponse = 'TTS test sesi oynatıldı efendim.';
      });
    } catch (_) {
      if (!mounted) return;
      _safeSetState(() {
        _lastResponse = 'TTS testinde doğal ses başlatılamadı efendim.';
      });
    } finally {
      await _backgroundBridgeService.showOverlayIdle();
      _presenceService.setStateSafe(
        _lifecycleService.isSleeping
            ? NovaPresenceState.sleeping
            : NovaPresenceState.idle,
      );
    }
  }

  NovaTtsMode _preferredConversationTtsMode() {
    if (_novaSettings.voiceCloneListeningEnabled) {
      return NovaTtsMode.cloned;
    }
    return NovaTtsMode.neuralLocal;
  }

  Future<void> _handleBackgroundAuthorizedPrompt(
    String recognizedPrompt,
  ) async {
    if (!mounted) return;
    try {
      await widget.ttsService.stop();
    } catch (_) {}
    final familiarConversation = recognizedPrompt.startsWith(
      _familiarConversationMarker,
    );
    final normalizedPrompt = familiarConversation
        ? recognizedPrompt.substring(_familiarConversationMarker.length).trim()
        : recognizedPrompt;
    final promptMetadata = Map<String, dynamic>.from(
      _continuousListeningRuntimeService.currentPromptMetadata,
    );
    await _processPrompt(
      prompt: normalizedPrompt,
      fromVoice: true,
      allowSystemExecution: !familiarConversation,
      promptMetadata: promptMetadata,
      requestOrigin: 'background_authorized_voice',
    );
  }

  bool _shouldSuppressStartupSpeech(String text) {
    final until = _startupSpeechSuppressUntil;
    if (until == null || DateTime.now().isAfter(until)) {
      return false;
    }
    final lower = text.toLowerCase();
    const technicalMarkers = <String>[
      'streaming asr',
      'çağrı desteği',
      'çağrı zinciri',
      'overlay',
      'izin',
      'rol',
      'hazır değil',
      'başlatılmadı',
      'durumu okunamadı',
      'arka plan',
      'çekirdek',
      'katman',
      'runtime',
      'repo',
      'binding',
      'audit',
      'dosya',
    ];
    for (final marker in technicalMarkers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }

  Future<void> _handleBackgroundUnauthorizedOrStatus(
    String statusMessage,
  ) async {
    if (!mounted) return;
    final normalized = statusMessage.trim();
    final isOverlayStatus = normalized.toLowerCase().contains(
      'overlay izni kapalı',
    );
    if (isOverlayStatus &&
        _overlayWarningSnoozeUntil != null &&
        DateTime.now().isBefore(_overlayWarningSnoozeUntil!)) {
      return;
    }
    _safeSetState(() {
      _lastResponse = normalized.isEmpty
          ? 'Yetkiniz bulunmamaktadır.'
          : normalized;
    });
    if (_shouldSuppressStartupSpeech(_lastResponse)) {
      return;
    }
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _startContinuousListening() async {
    await _refreshPermissionState();
    if (!_microphoneGranted) {
      if (!mounted) return;
      _safeSetState(
        () => _lastResponse =
            'Mikrofon izni sistem tarafından açık görünmüyor. Android izin snapshotı yeniden kontrol edilecek.',
      );
      return;
    }
    if (_continuousListeningRuntimeService.isRunning) {
      await _backgroundBridgeService.startBackground();
      await _backgroundBridgeService.showOverlayIdle();
      if (!mounted) return;
      _safeSetState(
        () => _lastResponse = 'Sürekli dinleme zaten aktif efendim.',
      );
      await _speakDashboardMessage(_lastResponse);
      return;
    }
    await _ensureOperationalListening(userRequested: true);
    if (!mounted) return;
    _safeSetState(() {
      _lastResponse = _continuousListeningRuntimeService.isRunning
          ? 'Sürekli arka plan dinleme başlatıldı efendim.'
          : 'Sürekli dinleme başlatılamadı; runtime hâlâ kapalı görünüyor.';
    });
    await _refreshDashboardSummaries();
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _stopContinuousListening() async {
    await _continuousListeningRuntimeService.stop();

    if (!mounted) return;

    _safeSetState(() {
      _lastResponse = 'Sürekli arka plan dinleme durduruldu efendim.';
    });

    await _refreshDashboardSummaries();
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _startExternalCloneFromDashboard() async {
    final result = await widget.cloneService.startExternalCloneCapture(
      suggestedName: 'Dış Ses Klonu',
    );
    await _refreshDashboardSummaries();
    if (!mounted) return;
    _safeSetState(() {
      _lastResponse = result;
    });
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _startInternalCloneFromDashboard() async {
    final result = await widget.cloneService.startInternalCloneCapture(
      suggestedName: 'Telefon İçi Ses Klonu',
    );
    await _refreshDashboardSummaries();
    if (!mounted) return;
    _safeSetState(() {
      _lastResponse = result;
    });
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _openVoiceClonePage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceCloneControlPage(
          settingsService: _voiceCloneSettingsService,
          libraryService: _clonedVoiceLibraryService,
          expressiveVoiceService: _expressiveVoiceService,
          cleanupService: _voiceCloneCleanupService,
          runtimeControlService: widget.runtimeControl,
          cloneService: widget.cloneService,
        ),
      ),
    );

    await _refreshDashboardSummaries();
  }

  Future<void> _openReminderPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReminderControlPage(
          reminderService: widget.reminderService,
          reminderCommandService: widget.reminderCommandService,
        ),
      ),
    );

    await _refreshDashboardSummaries();
  }

  Future<void> _openCallContactsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallContactControlPage(
          contactService: _contactService,
          deviceContactsBridgeService: _deviceContactsBridgeService,
        ),
      ),
    );

    await _refreshContacts();

    if (!mounted) return;

    _safeSetState(() {
      _lastResponse = 'Çağrı kişi ve yetki listesi güncellendi efendim.';
    });

    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _openVoiceIdentityPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceIdentityControlPage(
          ownerService: _ownerIdentityService,
          registryService: _voiceIdentityRegistryService,
          introductionService: VoiceIntroductionService(
            registryService: _voiceIdentityRegistryService,
          ),
          runtimeService: _voiceIdentityRuntimeService,
        ),
      ),
    );

    await _refreshContacts();
    if (!mounted) return;
    _safeSetState(() {
      _lastResponse = 'Ses kimliği ve yetki listesi güncellendi efendim.';
    });
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _openLearnedItemsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NovaLearnedItemsPage(
          registryService: NovaLearningRegistryService(
            behaviorOverrideService: const BehaviorOverrideService(),
            learnedCallResponseService: const LearnedCallResponseService(),
          ),
        ),
      ),
    );

    if (!mounted) return;

    _safeSetState(() {
      _lastResponse = 'Öğrenilenler ekranından dönüldü efendim.';
    });

    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _openPhoneControlPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneControlPage(
          phoneControlService: _phoneControlService,
          taskService: _phoneControlTaskService,
          executionService: _phoneControlExecutionService,
          guardService: _phoneControlGuardService,
        ),
      ),
    );

    await _refreshDashboardSummaries();
  }

  Future<void> _openPhoneAndScreenControlPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneAndScreenControlPage(
          phoneControlService: _phoneControlService,
          phoneControlGuardService: _phoneControlGuardService,
          screenPermissionService: _screenPermissionService,
          permissionBridgeService: _permissionBridgeService,
        ),
      ),
    );

    await _refreshDashboardSummaries();
    await _refreshPermissionState();
  }

  Future<void> _openPowerAndPresencePage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NovaPowerAndPresencePage(
          powerService: _powerService,
          presenceService: _presenceService,
        ),
      ),
    );

    await _refreshDashboardSummaries();
  }

  Future<void> _openOverlaySettings() async {
    final opened = await _permissionBridgeService.openOverlaySettings();
    if (!opened || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await _refreshPermissionState();
    _safeSetState(() {
      _lastResponse = _overlayGranted
          ? 'Overlay izni hazır görünüyor efendim.'
          : 'Overlay ayarları açıldı efendim.';
    });
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _openAccessibilitySettings() async {
    final ok = await _permissionBridgeService.openAccessibilitySettings();

    _safeSetState(() {
      _lastResponse = ok
          ? 'Erişilebilirlik ayarları açıldı efendim.'
          : 'Erişilebilirlik ayarları açılamadı efendim.';
    });

    await _refreshPermissionState();
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _openDefaultDialerSettings() async {
    await _permissionBridgeService.requestDefaultDialerRole();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _refreshPermissionState();
    if (!mounted) return;
    _safeSetState(() {
      _lastResponse = _defaultDialerGranted
          ? 'Nova varsayılan telefon rolünü aldı efendim. Normal telefon çağrı ekranı korunacak; Nova yalnız kayıtlı kişilerde destek katmanı olarak çalışacak.'
          : 'Varsayılan telefon rolü hâlâ verilmedi efendim. Kayıtlı kişiler için tam çağrı cevaplama, companion devralma ve sıkı sistem senkronu için bu rol gerekli.';
    });
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _openAppSettings() async {
    final ok = await _permissionBridgeService.openAppSettings();

    _safeSetState(() {
      _lastResponse = ok
          ? 'Uygulama ayarları açıldı efendim.'
          : 'Uygulama ayarları açılamadı efendim.';
    });

    await _refreshPermissionState();
    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _startBackgroundPreview() async {
    final result = await _backgroundBridgeService.startBackground();
    if (result.success) {
      await _backgroundBridgeService.setBackgroundRunning();
    }

    _safeSetState(() {
      _lastResponse = result.message.trim().isEmpty
          ? 'Arka plan servisi kontrol edildi efendim.'
          : result.message.trim();
    });

    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _deleteCallNote(String noteId) async {
    await _callNoteService.remove(noteId);
    await _refreshDashboardSummaries();

    if (!mounted) return;

    _safeSetState(() {
      _lastResponse = 'Çağrı notu silindi efendim.';
    });

    await _speakDashboardMessage(_lastResponse);
  }

  Future<void> _speakLatestNotes() async {
    if (_callNotes.isEmpty) {
      await _speakDashboardMessage('Çağrı notu bulunmuyor efendim.');
      return;
    }

    final recent = _callNotes.take(3).toList(growable: false);
    final buffer = StringBuffer('Son çağrı notları efendim. ');

    for (final item in recent) {
      final caller = '${item.callerName ?? 'Bilinmeyen kişi'}'.trim();
      final content = '${item.content ?? ''}'.trim();
      if (content.isEmpty) continue;
      buffer.write('$caller: $content. ');
    }

    await _speakDashboardMessage(buffer.toString().trim());
  }

  Future<void> _toggleWakeWord() async {
    await _saveSettings(
      _novaSettings.copyWith(wakeWordEnabled: !_novaSettings.wakeWordEnabled),
      successMessage: !_novaSettings.wakeWordEnabled
          ? 'Wake word açıldı efendim.'
          : 'Wake word kapatıldı efendim.',
    );
  }

  Future<void> _toggleCallHandling() async {
    await _saveSettings(
      _novaSettings.copyWith(
        callHandlingEnabled: !_novaSettings.callHandlingEnabled,
      ),
      successMessage: !_novaSettings.callHandlingEnabled
          ? 'Çağrı yönetimi açıldı efendim.'
          : 'Çağrı yönetimi kapatıldı efendim.',
    );
  }

  Future<void> _togglePhoneManagement() async {
    await _saveSettings(
      _novaSettings.copyWith(
        phoneManagementEnabled: !_novaSettings.phoneManagementEnabled,
      ),
      successMessage: !_novaSettings.phoneManagementEnabled
          ? 'Telefon yönetimi açıldı efendim.'
          : 'Telefon yönetimi kapatıldı efendim.',
    );
  }

  String _safeLogPreview(String input, {int maxChars = 180}) {
    final compact = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxChars) return compact;
    return '${compact.substring(0, maxChars)}…';
  }

  Future<String?> _listenVoiceFlowFromStreaming() async {
    try {
      // Dashboard mikrofon sahibi değildir; yalnız mevcut Continuous Listening
      // oturumunu gözlemler. Böylece ASR geldikten sonra oluşan start/stop
      // çakışması ve mikrofon kapan-aç döngüsü engellenir.
      await _ensureOperationalListening(userRequested: true);
      await widget.sttService.nativeBridge.ensureStreamingAsrReady();
    } catch (_) {}

    final startedAt = DateTime.now();
    final stablePartialWindow = const Duration(milliseconds: 1200);
    final maxWait = const Duration(seconds: 7);
    String lastPartial = '';
    DateTime? lastPartialChangedAt;

    while (DateTime.now().difference(startedAt) <= maxWait) {
      final snapshot = _continuousListeningRuntimeService.runtimeSnapshot();
      final finalText = (snapshot['recentStreamingFinalText'] as String? ?? '')
          .trim();
      final partialText =
          (snapshot['recentStreamingPartialText'] as String? ?? '').trim();
      final finalAtRaw = snapshot['recentStreamingFinalAt'] as String? ?? '';
      final partialAtRaw =
          snapshot['recentStreamingPartialAt'] as String? ?? '';
      final finalAt = DateTime.tryParse(finalAtRaw);
      final partialAt = DateTime.tryParse(partialAtRaw);

      if (finalText.isNotEmpty &&
          finalAt != null &&
          finalAt.isAfter(startedAt)) {
        debugPrint(
          'NOVA_DASHBOARD_ASR_TRANSCRIPT_RECEIVED kind=final chars=${finalText.length} '
          'asr_transcript_received="${_safeLogPreview(finalText)}"',
        );
        return finalText;
      }

      if (partialText != lastPartial) {
        lastPartial = partialText;
        lastPartialChangedAt = DateTime.now();
      }
      if (partialText.length >= 12 &&
          partialAt != null &&
          partialAt.isAfter(startedAt) &&
          lastPartialChangedAt != null &&
          DateTime.now().difference(lastPartialChangedAt!) >=
              stablePartialWindow) {
        debugPrint(
          'NOVA_DASHBOARD_ASR_TRANSCRIPT_RECEIVED kind=partial chars=${partialText.length} '
          'asr_transcript_received="${_safeLogPreview(partialText)}"',
        );
        return partialText;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return null;
  }

  Future<void> _speakDashboardMessage(
    String text, {
    bool throughOwner = true,
    String source = 'dashboard_system',
  }) async {
    debugPrint(
      'NOVA_DASHBOARD_STATUS_TTS_BLOCKED_UI_ONLY source=$source '
      'textChars=${text.trim().length}',
    );
    // Dashboard/status/debug strings are UI-only. They must never be rescued
    // through SingleBrain rewrite or spoken as Nova final speech.
    return;
  }

  bool _shouldRewriteDashboardSpeech(
    String text, {
    String source = 'dashboard_system',
  }) {
    final lower = text.toLowerCase().trim();
    final normalizedSource = source.toLowerCase().trim();
    if (lower.isEmpty) return false;
    if (lower.length > 520) return false;
    if (normalizedSource.contains('security') ||
        normalizedSource.contains('quarantine') ||
        normalizedSource.contains('containment')) {
      return false;
    }
    return true;
  }

  DateTime _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse('${value ?? ''}') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(dynamic value) {
    final date = _toDateTime(value).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  Widget _buildPowerModeButton({
    required String label,
    required bool active,
    required VoidCallback onPressed,
  }) {
    final style = active
        ? FilledButton.styleFrom(
            backgroundColor: const Color(0xFFED2C2E),
            foregroundColor: const Color(0xFF2A0709),
            elevation: 6,
            shadowColor: const Color(0x88ED2C2E),
          )
        : FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFFCF7),
            foregroundColor: const Color(0xFF8A1116),
          );
    return FilledButton(onPressed: onPressed, style: style, child: Text(label));
  }

  Future<void> _setPreferredMediaApp(String packageName, String label) async {
    await _mediaControlService.setPreferredPackage(packageName);
    if (!mounted) return;
    _safeSetState(() {
      _preferredMediaPackage = packageName;
      _lastResponse =
          '$label varsayılan medya uygulaması olarak seçildi efendim.';
    });
    await _speakDashboardMessage(_lastResponse);
  }

  String _mediaLabelForPackage(String packageName) {
    for (final app in NovaMediaControlService.supportedApps) {
      if (app.packageName == packageName) return app.label;
    }
    return 'Spotify';
  }

  Color _riskColor() {
    switch (_securityRiskLevel.toLowerCase()) {
      case 'kritik':
        return const Color(0xFFFF3B3F);
      case 'yüksek':
        return const Color(0xFFED2C2E);
      case 'orta':
        return const Color(0xFFB7302F);
      default:
        return const Color(0xFFC81018);
    }
  }

  Color _panelSeed(int index) {
    const palette = <Color>[
      Color(0xFFED2C2E),
      Color(0xFFC81018),
      Color(0xFFB7302F),
      Color(0xFFF0D7D1),
      Color(0xFFF7DED6),
      Color(0xFFFFF8F1),
    ];
    return palette[index % palette.length];
  }

  BoxDecoration _glassCardDecoration({Color? accent}) {
    final seed = accent ?? const Color(0xFFC81018);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: <Color>[
          Color(0xFFFFFCF7),
          Color(0xFFFBF3E6),
          Color(0xFFF3E6D1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: seed.withOpacity(0.16)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: seed.withOpacity(0.06),
          blurRadius: 2,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    required Color seed,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: _glassCardDecoration(accent: seed),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: seed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: seed),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF2A0709),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8A3B3B), fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2A0709),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF6A3E3A),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF4A1417),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? accent,
  }) {
    final seed = accent ?? const Color(0xFFC81018);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: seed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: seed.withOpacity(0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: seed.withOpacity(0.12),
              ),
              child: Icon(icon, color: seed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF2A0709),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6A3E3A),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A3B3B)),
          ],
        ),
      ),
    );
  }

  Widget _permissionRow(String label, bool ok, Future<void> Function() action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3EA),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7CFC4)),
          ),
          child: Row(
            children: [
              Icon(
                ok ? Icons.verified_rounded : Icons.warning_rounded,
                color: ok ? const Color(0xFFC81018) : const Color(0xFFB7302F),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF4A1417),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                ok ? 'Hazır' : 'Kontrol Et',
                style: TextStyle(
                  color: ok ? const Color(0xFFC81018) : const Color(0xFFB7302F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runSelfRecognitionSummary() async {
    final runtimeSignalService = self_repair_signal.NovaRuntimeSignalService.instance;
    final recognitionService = NovaSelfRecognitionService(
      signalService: runtimeSignalService,
      manifestService: NovaCapabilityManifestService(
        runtimeRegistryService: const NovaCapabilityRuntimeRegistryService(),
      ),
    );
    final capabilities = await recognitionService.discoverCapabilities();
    final names = capabilities.take(6).map((e) => e.title).join(', ');
    final text = capabilities.isEmpty
        ? 'Kendimi tanıma zincirinde doğrulanmış yetenek listesi bulunamadı efendim.'
        : 'Kendimi tanıma raporu hazır efendim. Aktif doğrulanan başlıklar: $names.';
    if (!mounted) return;
    _safeSetState(() => _lastResponse = text);
    await _speakDashboardMessage(text);
  }

  Future<void> _runQuickSelfRepair([
    String commandText = 'kendini onar',
  ]) async {
    final runtimeSignalService = self_repair_signal.NovaRuntimeSignalService.instance;
    final recognitionService = NovaSelfRecognitionService(
      signalService: runtimeSignalService,
      manifestService: NovaCapabilityManifestService(
        runtimeRegistryService: const NovaCapabilityRuntimeRegistryService(),
      ),
    );
    final diagnosticService = NovaSelfDiagnosticService(
      signalService: runtimeSignalService,
      recognitionService: recognitionService,
    );
    final coordinator = NovaSelfRepairCoordinatorService(
      diagnosticService: diagnosticService,
      orchestratorService: NovaSelfRepairOrchestratorService(
        ttsService: widget.ttsService,
        backgroundBridgeService: _backgroundBridgeService,
        reportService: const NovaSelfRepairReportService(),
        securityService: const NovaSelfRepairSecurityService(),
        controlledRestartService: NovaControlledRestartService(
          continuousListeningRuntimeService: _continuousListeningRuntimeService,
          backgroundBridgeService: _backgroundBridgeService,
          ttsService: widget.ttsService,
        ),
        narrationService: const NovaRepairVoiceNarrationService(),
          endListeningSessionAction: _stopContinuousListening,
        ensureListeningAction: () =>
            _ensureOperationalListening(userRequested: true),
      ),
      reportService: const NovaSelfRepairReportService(),
      settingsService: const NovaSelfRepairSettingsService(),
      commandService: const NovaSelfRepairCommandService(),
      capabilityCatalogService: NovaCapabilityCatalogService(
        recognitionService: recognitionService,
        probeService: NovaCapabilityProbeService(
          runtimeSignalService: runtimeSignalService,
        ),
      ),
      repairTraceService: _repairTraceService,
      repairValidationService: NovaRepairValidationService(
        diagnosticService: diagnosticService,
      ),
      resolutionMemoryService: const NovaRepairResolutionMemoryService(),
    );
    final result = await coordinator.runFromCommand(
      commandText.trim().isEmpty ? 'kendini onar' : commandText,
    );
    if (!mounted) return;
    _safeSetState(() => _lastResponse = result.message);
    await _speakDashboardMessage(result.message);
  }

  Future<void> _openSelfRepairPage() async {
    final runtimeSignalService = self_repair_signal.NovaRuntimeSignalService.instance;
    final runtimeRegistryService = const NovaCapabilityRuntimeRegistryService();
    final manifestService = NovaCapabilityManifestService(
      runtimeRegistryService: runtimeRegistryService,
    );
    final recognitionService = NovaSelfRecognitionService(
      manifestService: manifestService,
      signalService: runtimeSignalService,
    );
    final diagnosticService = NovaSelfDiagnosticService(
      signalService: runtimeSignalService,
      recognitionService: recognitionService,
    );
    final reportService = const NovaSelfRepairReportService();
    final settingsService = const NovaSelfRepairSettingsService();
    final repairValidationService = NovaRepairValidationService(
      diagnosticService: diagnosticService,
    );
    final repairResolutionMemoryService =
        const NovaRepairResolutionMemoryService();
    final capabilityProbeService = NovaCapabilityProbeService(
      runtimeSignalService: runtimeSignalService,
    );
    final capabilityCatalogService = NovaCapabilityCatalogService(
      recognitionService: recognitionService,
      probeService: capabilityProbeService,
    );
    final orchestratorService = NovaSelfRepairOrchestratorService(
      ttsService: widget.ttsService,
      backgroundBridgeService: _backgroundBridgeService,
      reportService: reportService,
      securityService: const NovaSelfRepairSecurityService(),
      controlledRestartService: NovaControlledRestartService(
        continuousListeningRuntimeService: _continuousListeningRuntimeService,
        backgroundBridgeService: _backgroundBridgeService,
        ttsService: widget.ttsService,
      ),
      ensureListeningAction: () =>
          _ensureOperationalListening(userRequested: true),
      narrationService: const NovaRepairVoiceNarrationService(),
      endListeningSessionAction: _stopContinuousListening,
    );
    final coordinatorService = NovaSelfRepairCoordinatorService(
      diagnosticService: diagnosticService,
      orchestratorService: orchestratorService,
      reportService: reportService,
      settingsService: settingsService,
      commandService: const NovaSelfRepairCommandService(),
      capabilityCatalogService: capabilityCatalogService,
      repairTraceService: _repairTraceService,
      repairValidationService: repairValidationService,
      resolutionMemoryService: repairResolutionMemoryService,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelfRepairControlPage(
          coordinatorService: coordinatorService,
          settingsService: settingsService,
          repairTraceService: _repairTraceService,
        ),
      ),
    );

    await _refreshDashboardSummaries();

    if (!mounted) return;
    _safeSetState(() {
      _lastResponse = 'Onarım panelinden dönüldü efendim.';
    });
    await _speakDashboardMessage(_lastResponse);
  }

  Widget _buildCallNotesSection() {
    final items = _callNotes.take(5).toList(growable: false);

    return _buildCard(
      title: 'Çağrı Notları',
      icon: Icons.sticky_note_2_rounded,
      seed: _panelSeed(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard içinden görünür ve silinebilir son çağrı notları.',
            style: TextStyle(color: Color(0xFF6A3E3A)),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Kayıtlı çağrı notu bulunmuyor.',
              style: TextStyle(color: Color(0xFF8A3B3B)),
            ),
          ...items.map((dynamic item) {
            final String id = '${item.id ?? ''}';
            final String caller = '${item.callerName ?? 'Bilinmeyen kişi'}';
            final String content = '${item.content ?? ''}'.trim();
            final String number = '${item.callerNumber ?? ''}'.trim();
            final String created = _formatDate(item.createdAt);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7CFC4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          caller,
                          style: const TextStyle(
                            color: Color(0xFF2A0709),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sil',
                        onPressed: id.isEmpty
                            ? null
                            : () => _deleteCallNote(id),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFB7302F),
                        ),
                      ),
                    ],
                  ),
                  if (number.isNotEmpty)
                    Text(
                      number,
                      style: const TextStyle(
                        color: Color(0xFF8A3B3B),
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    content.isEmpty ? 'Not içeriği boş.' : content,
                    style: const TextStyle(
                      color: Color(0xFFF7DED6),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    created,
                    style: const TextStyle(
                      color: Color(0xFF8A3B3B),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          FilledButton.tonalIcon(
            onPressed: _speakLatestNotes,
            icon: const Icon(Icons.record_voice_over_rounded),
            label: const Text('Son Notları Sesli Oku'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection() {
    final items = _reminders.take(5).toList(growable: false);

    return _buildCard(
      title: 'Hatırlatıcılar',
      icon: Icons.alarm_rounded,
      seed: _panelSeed(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son kayıtlar, tarih ve tür bilgisiyle listelenir.',
            style: TextStyle(color: Color(0xFF6A3E3A)),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Kayıtlı hatırlatma bulunmuyor.',
              style: TextStyle(color: Color(0xFF8A3B3B)),
            ),
          ...items.map((dynamic item) {
            final String text = '${item.text ?? ''}'.trim();
            final String due = '${item.dueAtIso ?? ''}'.trim();
            final String kind = '${item.kind ?? ''}'.trim();
            final bool completed = item.isCompleted == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7CFC4)),
              ),
              child: Row(
                children: [
                  Icon(
                    completed ? Icons.task_alt_rounded : Icons.alarm_rounded,
                    color: completed
                        ? const Color(0xFFC81018)
                        : const Color(0xFF8A3B3B),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.isEmpty ? 'İsimsiz hatırlatma' : text,
                          style: const TextStyle(
                            color: Color(0xFF2A0709),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${kind.isEmpty ? 'standard' : kind} • ${due.isEmpty ? '-' : due}',
                          style: const TextStyle(
                            color: Color(0xFF8A3B3B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),
      appBar: AppBar(
        title: const Text(
          'Nova',
          style: TextStyle(
            color: Color(0xFF2A0709),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Onarım Paneli',
            onPressed: () => _openSelfRepairPage(),
            icon: const Icon(Icons.healing_rounded),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _permissionsRefreshing
                ? null
                : () async {
                    await _refreshDashboardSummaries();
                    await _refreshPermissionState();
                    if (!mounted) return;
                    _safeSetState(() {
                      _lastResponse = 'Gösterge paneli yenilendi efendim.';
                    });
                    await _speakDashboardMessage(_lastResponse);
                  },
            icon: _permissionsRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -30,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFED2C2E).withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            top: 180,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF0D7D1).withOpacity(0.12),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard(
                title: 'NOVA CORE',
                icon: Icons.memory_rounded,
                seed: _panelSeed(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lastResponse,
                      style: const TextStyle(
                        color: Color(0xFF4A1417),
                        height: 1.4,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_lastHeardText.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Son algılanan: $_lastHeardText',
                        style: const TextStyle(
                          color: Color(0xFF6A3E3A),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildChip('Güç', _powerLabel(), _panelSeed(0)),
                        _buildChip(
                          'Karantina',
                          _nativeKillStage,
                          _panelSeed(1),
                        ),
                        _buildChip('Risk', _securityRiskLevel, riskColor),
                        _buildChip(
                          'Dinleme',
                          _continuousListeningRuntimeService.isRunning
                              ? 'Açık'
                              : 'Kapalı',
                          _panelSeed(3),
                        ),
                        _buildChip(
                          'Ses Kimliği',
                          '$_knownVoiceCount',
                          _panelSeed(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildCard(
                title: 'Sesli Komut Merkezi',
                icon: Icons.multitrack_audio_rounded,
                seed: _panelSeed(2),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _presenceService,
                      builder: (context, _) {
                        final state = _presenceService.state;
                        final active =
                            state == NovaPresenceState.listening ||
                            state == NovaPresenceState.speaking;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          width: active ? 132 : 114,
                          height: active ? 132 : 114,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFFFFF8F1),
                                Color(0xFFED2C2E),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFED2C2E,
                                ).withOpacity(active ? 0.34 : 0.14),
                                blurRadius: active ? 30 : 16,
                                spreadRadius: active ? 4 : 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              active
                                  ? Icons.graphic_eq_rounded
                                  : Icons.mic_none_rounded,
                              color: const Color(0xFF2A0709),
                              size: active ? 42 : 34,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _voiceFlowRunning
                          ? 'Nova sizi dinliyor efendim…'
                          : _lifecycleService.isSleeping
                          ? 'Nova pasif beklemede.'
                          : _continuousListeningRuntimeService.isRunning
                          ? 'Sürekli arka plan dinleme aktif.'
                          : 'Nova sesli komut için hazır.',
                      style: const TextStyle(color: Color(0xFF6A3E3A)),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: _voiceFlowRunning ? null : _runVoiceFlow,
                          child: Text(
                            _voiceFlowRunning
                                ? 'Dinleniyor...'
                                : 'Sesli Komut Başlat',
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed:
                              _continuousListeningRuntimeService.isRunning
                              ? _stopContinuousListening
                              : _startContinuousListening,
                          child: Text(
                            _continuousListeningRuntimeService.isRunning
                                ? 'Sürekli Dinlemeyi Durdur'
                                : 'Sürekli Dinlemeyi Başlat',
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: _voiceFlowRunning
                              ? null
                              : _enrollOwnerVoiceprint,
                          child: const Text('Sahip Ses İzini Kaydet'),
                        ),
                        FilledButton.tonal(
                          onPressed: _runTtsTest,
                          child: const Text('TTS Testi Yap'),
                        ),
                        FilledButton.tonal(
                          onPressed: _startBackgroundPreview,
                          child: const Text('Arka Plan / Overlay Testi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildCard(
                title: 'Durum ve Ayarlar',
                icon: Icons.tune_rounded,
                seed: _panelSeed(1),
                child: Column(
                  children: [
                    _buildInfoRow('Asistan', widget.persona.assistantName),
                    _buildInfoRow('Mod', _selectedMode.label),
                    _buildInfoRow(
                      'Yerel Model',
                      _featureFlags.localModelEnabled
                          ? 'Açık'
                          : 'API-first sürümde kapalı',
                    ),
                    _buildInfoRow(
                      'API',
                      _featureFlags.apiEnabled ? 'Açık' : 'Kapalı',
                    ),
                    _buildInfoRow('API Durumu', _apiStatusText()),
                    _buildInfoRow('Güç', _powerLabel()),
                    _buildInfoRow(
                      'Çağrı Sistemi',
                      _featureFlags.callHandlingEnabled ? 'Açık' : 'Kapalı',
                    ),
                    _buildInfoRow(
                      'Telefon Yönetimi',
                      _featureFlags.phoneControlEnabled ? 'Açık' : 'Kapalı',
                    ),
                    const SizedBox(height: 10),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Güvenlik kalkanları sökülmüş/pasif',
                        style: TextStyle(color: Color(0xFF2A0709)),
                      ),
                      subtitle: Text(
                        'Bu sürüm API-first çalışır; eski boot/runtime güvenlik kalkanları konuşma ve setup akışını bloke etmez.',
                        style: TextStyle(color: Color(0xFF6A3E3A)),
                      ),
                    ),
                    if (_featureFlags.apiEnabled)
                      SwitchListTile(
                        value: _novaSettings.chatGptInternetEnabled,
                        onChanged: _settingsSaving
                            ? null
                            : (value) => _saveSettings(
                                _novaSettings.copyWith(
                                  chatGptInternetEnabled: value,
                                ),
                                successMessage: value
                                    ? 'Kalıcı internet kullanımı izni açıldı efendim.'
                                    : 'Kalıcı internet kullanımı izni kapatıldı efendim.',
                              ),
                        title: const Text(
                          'API beyin kullanımı açık',
                          style: TextStyle(color: Color(0xFF2A0709)),
                        ),
                        subtitle: const Text(
                          'Gemini/OpenAI sağlayıcısı üzerinden tek aktif beyin hattı için',
                          style: TextStyle(color: Color(0xFF6A3E3A)),
                        ),
                      ),
                    SwitchListTile(
                      value: _novaSettings.callHandlingEnabled,
                      onChanged: _settingsSaving
                          ? null
                          : (_) => _toggleCallHandling(),
                      title: const Text(
                        'Çağrı kontrolü açık',
                        style: TextStyle(color: Color(0xFF2A0709)),
                      ),
                    ),
                    SwitchListTile(
                      value: _novaSettings.phoneManagementEnabled,
                      onChanged: _settingsSaving
                          ? null
                          : (_) => _togglePhoneManagement(),
                      title: const Text(
                        'Telefon yönetimi açık',
                        style: TextStyle(color: Color(0xFF2A0709)),
                      ),
                    ),
                    SwitchListTile(
                      value: _novaSettings.teachingModeEnabled,
                      onChanged: _settingsSaving
                          ? null
                          : (value) => _saveSettings(
                              _novaSettings.copyWith(
                                teachingModeEnabled: value,
                              ),
                              successMessage: value
                                  ? 'Öğretim modu açıldı efendim.'
                                  : 'Öğretim modu kapatıldı efendim.',
                            ),
                      title: const Text(
                        'Öğretim modu açık',
                        style: TextStyle(color: Color(0xFF2A0709)),
                      ),
                    ),
                    SwitchListTile(
                      value: _novaSettings.speakerCallModeEnabled,
                      onChanged: _settingsSaving
                          ? null
                          : (value) => _saveSettings(
                              _novaSettings.copyWith(
                                speakerCallModeEnabled: value,
                              ),
                              successMessage: value
                                  ? 'Hoparlörlü çağrı modu açıldı efendim.'
                                  : 'Hoparlörlü çağrı modu kapatıldı efendim.',
                            ),
                      title: const Text(
                        'Hoparlörlü çağrı modu açık',
                        style: TextStyle(color: Color(0xFF2A0709)),
                      ),
                    ),
                    SwitchListTile(
                      value: _novaSettings.wakeWordEnabled,
                      onChanged: _settingsSaving
                          ? null
                          : (_) => _toggleWakeWord(),
                      title: const Text(
                        'Uyandırma komutu açık',
                        style: TextStyle(color: Color(0xFF2A0709)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<NovaAiProviderType>(
                      value: _novaSettings.activeAiProvider,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Aktif AI Sağlayıcısı',
                        helperText:
                            'Aynı anda yalnızca bir sağlayıcı aktif çalışır.',
                      ),
                      dropdownColor: const Color(0xFFF7F0EC),
                      style: const TextStyle(color: Color(0xFF4A1417)),
                      items: NovaAiProviderType.values
                          .map(
                            (provider) => DropdownMenuItem<NovaAiProviderType>(
                              value: provider,
                              child: Text(provider.label),
                            ),
                          )
                          .toList(),
                      onChanged: _settingsSaving || _securityDiagnosticSaving
                          ? null
                          : (provider) {
                              if (provider != null) {
                                _saveActiveAiProvider(provider);
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _apiModelController,
                      style: const TextStyle(color: Color(0xFF4A1417)),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            'Örn. gemini-3.1-flash-lite, gpt-5.4-mini, qwen-flash veya qwen-plus',
                        labelText: 'Model',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          NovaApiModelCatalog.presetsFor(
                                _novaSettings.activeAiProvider,
                              )
                              .map(
                                (model) => OutlinedButton(
                                  onPressed: _settingsSaving
                                      ? null
                                      : () {
                                          _apiModelController.text = model;
                                          _safeSetState(() {
                                            _lastResponse =
                                                '${NovaApiModelCatalog.labelFor(model)} modeli seçildi. API anahtarını kaydettiğinizde aktifleşir.';
                                          });
                                        },
                                  child: Text(
                                    NovaApiModelCatalog.labelFor(model),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      style: const TextStyle(color: Color(0xFF4A1417)),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText:
                            '${_novaSettings.activeAiProvider.label} API anahtarını buraya girin',
                        labelText: 'API Anahtarı',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: _settingsSaving ? null : _saveApiKey,
                          child: const Text('API Anahtarını Kaydet'),
                        ),
                        _buildPowerModeButton(
                          label: 'Tam Güç',
                          active:
                              !_powerService.isBatterySaver &&
                              !_powerService.isPassiveSleep &&
                              !_powerService.isLimbo &&
                              !_powerService.isFullyShutdown,
                          onPressed: _setPowerFullyOn,
                        ),
                        _buildPowerModeButton(
                          label: 'Pil Tasarrufu',
                          active: _powerService.isBatterySaver,
                          onPressed: _setPowerBatterySaver,
                        ),
                        _buildPowerModeButton(
                          label: 'Gece Modu',
                          active: _powerService.isPassiveSleep,
                          onPressed: _setPowerPassiveSleep,
                        ),
                        _buildPowerModeButton(
                          label: 'Araf Modu',
                          active: _powerService.isLimbo,
                          onPressed: _setPowerLimbo,
                        ),
                        _buildPowerModeButton(
                          label: 'Tamamen Kapat',
                          active: _powerService.isFullyShutdown,
                          onPressed: _setPowerFullyShutdown,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              _buildCard(
                title: 'Güç Modları',
                icon: Icons.battery_charging_full_rounded,
                seed: _panelSeed(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Aktif güç modu', _powerLabel()),
                    _buildInfoRow(
                      'Otomatik uyku',
                      _powerSchedule.enabled ? 'Açık' : 'Kapalı',
                    ),
                    _buildInfoRow(
                      'Gece aralığı',
                      '${_powerSchedule.sleepStart} - ${_powerSchedule.sleepEnd}',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPowerModeButton(
                          label: 'Tam Güç',
                          active:
                              !_powerService.isBatterySaver &&
                              !_powerService.isPassiveSleep &&
                              !_powerService.isLimbo &&
                              !_powerService.isFullyShutdown,
                          onPressed: _setPowerFullyOn,
                        ),
                        _buildPowerModeButton(
                          label: 'Pil Tasarrufu',
                          active: _powerService.isBatterySaver,
                          onPressed: _setPowerBatterySaver,
                        ),
                        _buildPowerModeButton(
                          label: 'Gece Modu',
                          active: _powerService.isPassiveSleep,
                          onPressed: _setPowerPassiveSleep,
                        ),
                        _buildPowerModeButton(
                          label: 'Araf Modu',
                          active: _powerService.isLimbo,
                          onPressed: _setPowerLimbo,
                        ),
                        OutlinedButton(
                          onPressed: _configureSleepWindow,
                          child: const Text('Gece Saatlerini Ayarla'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _powerSchedule.enabled,
                      onChanged: _toggleAutoSleep,
                      title: const Text(
                        'Otomatik uyku planı',
                        style: TextStyle(color: Color(0xFF2A0709)),
                      ),
                      subtitle: const Text(
                        'Gece seçili saatlerde düşük enerji ama çağrı / alarm aktif',
                        style: TextStyle(color: Color(0xFF6A3E3A)),
                      ),
                    ),
                  ],
                ),
              ),
              _buildCard(
                title: 'Onarım ve Hata Ayıklama',
                icon: Icons.bug_report_rounded,
                seed: _panelSeed(7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kendini onarma ve hata ayıklama zinciri sesli olarak anlatılır. Sahibe özel kör yama kanalı gizli tutulur.',
                      style: TextStyle(color: Color(0xFF6A3E3A)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: _openSelfRepairPage,
                          child: const Text('Onarım Panelini Aç'),
                        ),
                        FilledButton.tonal(
                          onPressed: _runSelfRecognitionSummary,
                          child: const Text('Kendini Tanı'),
                        ),
                        FilledButton(
                          onPressed: _debugRunning ? null : _runDebugMode,
                          child: Text(
                            _debugRunning
                                ? 'Taranıyor...'
                                : 'Hata Ayıklama Modu',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildCard(
                title: 'Çağrı / Kişiler / Kişilik',
                icon: Icons.call_rounded,
                seed: _panelSeed(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Kayıtlı kişi', '${_managedContacts.length}'),
                    _buildInfoRow(
                      'Çağrı yönetimi yetkili kişi',
                      '$_autoHandleContactCount',
                    ),
                    _buildInfoRow(
                      'Ses tanımada komut yetkili kişi',
                      '$_authorizedVoiceCount',
                    ),
                    _buildInfoRow('Tanıdık ses sayısı', '$_familiarVoiceCount'),
                    _buildInfoRow(
                      'Duygu seviyesi',
                      _novaSettings.emotionLevel.toStringAsFixed(2),
                    ),
                    _buildInfoRow(
                      'Mizah seviyesi',
                      _novaSettings.humorLevel.toString(),
                    ),
                    _buildInfoRow(
                      'Resmiyet seviyesi',
                      _novaSettings.formalityLevel.toStringAsFixed(2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _callHandlingSummary(),
                      style: const TextStyle(color: Color(0xFF6A3E3A)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: _openCallContactsPage,
                          child: const Text('Çağrı Kişilerini Yönet'),
                        ),
                        FilledButton.tonal(
                          onPressed: _openPersonalityPage,
                          child: const Text('Kişilik Ayarlarını Aç'),
                        ),
                        FilledButton.tonal(
                          onPressed: _openVoiceClonePage,
                          child: const Text('Ses Klonlama Ayarlarını Aç'),
                        ),
                        FilledButton.tonal(
                          onPressed: _startExternalCloneFromDashboard,
                          child: const Text('Dış Sesten Klon Başlat'),
                        ),
                        FilledButton.tonal(
                          onPressed: _startInternalCloneFromDashboard,
                          child: const Text('Telefon Sesinden Klon Başlat'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildCard(
                title: 'Hatırlatıcı / Bellek / Öğrenme',
                icon: Icons.auto_awesome_rounded,
                seed: _panelSeed(3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _reminderSummary(),
                      style: const TextStyle(color: Color(0xFF4A1417)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _memorySummary(),
                      style: const TextStyle(color: Color(0xFF4A1417)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: _openReminderPage,
                          child: const Text('Hatırlatıcıları Aç'),
                        ),
                        OutlinedButton(
                          onPressed: _cleanupRunning
                              ? null
                              : _runReminderCleanup,
                          child: const Text('Tamamlananları Temizle'),
                        ),
                        FilledButton.tonal(
                          onPressed: _cleanupRunning
                              ? null
                              : _runManualStorageCleanup,
                          child: Text(
                            _cleanupRunning
                                ? 'Temizleniyor...'
                                : 'Genel Temizlik',
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: _openLearnedItemsPage,
                          child: const Text('Öğrenilenleri Aç'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              _buildCard(
                title: 'Bilgi Çekirdeği ve Rehberler',
                icon: Icons.menu_book_rounded,
                seed: _panelSeed(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Yerel rehber kaynakları, bilgi çekirdeği ve dil paketleri hazır tutulur; cevap üretirken bu kaynaklar önceliklenir.',
                      style: TextStyle(color: Color(0xFF4A1417)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Nova cevap üretirken çevrimdışı bilgi kütüphanesini, rehber kaynakları ve yüklü dil paketlerini kullanır.',
                      style: TextStyle(color: Color(0xFFFFF8F1)),
                    ),
                  ],
                ),
              ),
              _buildCard(
                title: 'Çevirmen Modu',
                icon: Icons.translate_rounded,
                seed: _panelSeed(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translatorModeSummary(),
                      style: const TextStyle(color: Color(0xFF4A1417)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: () async {
                            _translatorModeState = await _translatorModeService
                                .enable(source: 'tr', target: 'en');
                            if (!mounted) return;
                            _safeSetState(
                              () => _lastResponse =
                                  'Çevirmen modu açıldı efendim.',
                            );
                            await _refreshDashboardSummaries();
                            await _speakDashboardMessage(_lastResponse);
                          },
                          child: const Text('TR → EN Aç'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            _translatorModeState = await _translatorModeService
                                .disable();
                            if (!mounted) return;
                            _safeSetState(
                              () => _lastResponse =
                                  'Çevirmen modu kapatıldı efendim.',
                            );
                            await _refreshDashboardSummaries();
                            await _speakDashboardMessage(_lastResponse);
                          },
                          child: const Text('Kapat'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildCard(
                title: 'Talimatlı Çağrılar',
                icon: Icons.add_ic_call_rounded,
                seed: _panelSeed(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _callInstructionSummary(),
                      style: const TextStyle(color: Color(0xFF4A1417)),
                    ),
                    const SizedBox(height: 8),
                    if (_callInstructions.isEmpty)
                      const Text(
                        'Kayıtlı talimatlı çağrı görevi yok.',
                        style: TextStyle(color: Color(0xFF6A3E3A)),
                      )
                    else
                      ..._callInstructions
                          .take(4)
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3EA),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE7CFC4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.title,
                                      style: const TextStyle(
                                        color: Color(0xFF2A0709),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      e.instructionText,
                                      style: const TextStyle(
                                        color: Color(0xFF6A3E3A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Durum: ${e.status.name} • ${_formatDate(e.scheduledForIso)}',
                                      style: const TextStyle(
                                        color: Color(0xFF8A3B3B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final removed = await _callInstructionService
                            .cleanupCompletedOlderThan48Hours();
                        if (!mounted) return;
                        _safeSetState(
                          () => _lastResponse = removed > 0
                              ? 'Tamamlanan talimatlı çağrılar temizlendi efendim.'
                              : 'Silinecek eski tamamlanmış talimatlı çağrı bulunamadı efendim.',
                        );
                        await _refreshDashboardSummaries();
                        await _speakDashboardMessage(_lastResponse);
                      },
                      child: const Text('48 Saatlik Temizlik'),
                    ),
                  ],
                ),
              ),

              _buildCard(
                title: 'Ses Yetki Ayrımı',
                icon: Icons.manage_accounts_rounded,
                seed: _panelSeed(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Cihaz sahibi', 'Tam yetki'),
                    _buildInfoRow('Yetkili kişi', 'Komut verebilir'),
                    _buildInfoRow(
                      'Tanıdık kişi',
                      'Sohbet edebilir, komut veremez',
                    ),
                    _buildInfoRow(
                      'Çağrı yetkisi',
                      'Telefon rehberindeki ayrı izin',
                    ),
                  ],
                ),
              ),

              _buildCard(
                title: 'Modüller',
                icon: Icons.dashboard_customize_rounded,
                seed: _panelSeed(0),
                child: Column(
                  children: [
                    _buildActionTile(
                      icon: Icons.contacts_rounded,
                      title: 'Çağrı Kişi ve Yetki Yönetimi',
                      subtitle: 'Telefon rehberi ve çağrı yetki alanı.',
                      onTap: _openCallContactsPage,
                    ),
                    const SizedBox(height: 10),
                    _buildActionTile(
                      icon: Icons.record_voice_over_rounded,
                      title: 'Ses Kimliği / Tanıdık / Yetkili',
                      subtitle: 'Cihaz sahibi, yetkili ve tanıdık ses havuzu.',
                      onTap: _openVoiceIdentityPage,
                    ),
                    const SizedBox(height: 10),
                    _buildActionTile(
                      icon: Icons.psychology_alt_rounded,
                      title: 'Kişilik ve Şaka Ayarları',
                      subtitle: 'Konuşma tarzı, mizah ve duygusal denge.',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const VoicePersonalitySettingsPage(),
                          ),
                        );
                        await _refreshDashboardSummaries();
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildActionTile(
                      icon: Icons.settings_phone_rounded,
                      title: 'Telefon Yönetimi',
                      subtitle: 'Görev yürütme ve güvenlik koruması zinciri.',
                      onTap: _openPhoneControlPage,
                    ),
                    const SizedBox(height: 10),
                    _buildActionTile(
                      icon: Icons.phone_android_rounded,
                      title: 'Telefon + Ekran Kontrolü',
                      subtitle: 'Telefon kontrolü ve ekran izleme alanı.',
                      onTap: _openPhoneAndScreenControlPage,
                    ),
                    const SizedBox(height: 10),
                    _buildActionTile(
                      icon: Icons.nightlight_round_rounded,
                      title: 'Gece / Araf / Varlık Durumu',
                      subtitle:
                          'Pasif uyku, tamamen kapatma ve karşılama ayarı.',
                      onTap: _openPowerAndPresencePage,
                    ),
                  ],
                ),
              ),

              _buildCard(
                title: 'Medya Kontrolü',
                icon: Icons.library_music_rounded,
                seed: _panelSeed(3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Varsayılan medya',
                      _mediaLabelForPackage(_preferredMediaPackage),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: NovaMediaControlService.supportedApps
                          .map((app) {
                            final active =
                                _preferredMediaPackage == app.packageName;
                            return _buildPowerModeButton(
                              label: app.label,
                              active: active,
                              onPressed: () => _setPreferredMediaApp(
                                app.packageName,
                                app.label,
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Arka planda ileri, geri, durdur, devam, ses aç, ses kıs ve sessize al komutları çalışır. Uygulama içinde arama gereken komutlarda seçili medya uygulaması kullanılır.',
                      style: TextStyle(color: Color(0xFF6A3E3A)),
                    ),
                  ],
                ),
              ),

              _buildCard(
                title: 'İzin ve Ulaşım Durumu',
                icon: Icons.verified_user_rounded,
                seed: _panelSeed(2),
                child: Column(
                  children: [
                    _permissionRow(
                      'Overlay izni',
                      _overlayGranted,
                      _openOverlaySettings,
                    ),
                    _permissionRow(
                      'Accessibility',
                      _accessibilityGranted,
                      _openAccessibilitySettings,
                    ),
                    _permissionRow(
                      'Bildirim izni',
                      _notificationGranted,
                      _openAppSettings,
                    ),
                    _permissionRow(
                      'Mikrofon izni',
                      _microphoneGranted,
                      _openAppSettings,
                    ),
                    _permissionRow(
                      'Varsayılan telefon rolü (normal UX korunur)',
                      _defaultDialerGranted,
                      _openDefaultDialerSettings,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Çağrı zinciri', _callRoleStatus),
                    const SizedBox(height: 6),
                    _buildInfoRow('Streaming ASR', _streamingAsrStatus),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      'ASR mod',
                      _streamingAsrReady ? 'Embedded' : 'Hazır değil',
                    ),
                  ],
                ),
              ),
              _buildCallNotesSection(),
              _buildReminderSection(),
              _buildCard(
                title: 'Güvenlik',
                icon: Icons.shield_rounded,
                seed: riskColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Risk', _securityRiskLevel),
                    _buildInfoRow('Containment', _nativeKillStage),
                    _buildInfoRow(
                      'Rapor',
                      _securityIncidents.isEmpty
                          ? 'Yok'
                          : '$_securityIncidentCount adet',
                    ),
                    _buildInfoRow(
                      'Titreşim',
                      _securityVibrationStopped ? 'Durduruldu' : 'Aktif',
                    ),
                    if (_nativeSecurityMessage.trim().isNotEmpty)
                      _buildInfoRow('Native mesaj', _nativeSecurityMessage),
                    const SizedBox(height: 8),
                    Text(
                      _securityStatusText,
                      style: const TextStyle(color: Color(0xFF6A3E3A)),
                    ),
                    if (_securityIncidents.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        constraints: const BoxConstraints(
                          minHeight: 80,
                          maxHeight: 220,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3EA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE7CFC4)),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _securityIncidents.length,
                          itemBuilder: (context, index) {
                            final item = _securityIncidents[index];
                            return ListTile(
                              leading: Icon(
                                Icons.report_gmailerrorred_rounded,
                                color:
                                    item.riskLevel.toLowerCase() == 'critical'
                                    ? Colors.redAccent
                                    : item.riskLevel.toLowerCase() == 'high'
                                    ? Colors.orangeAccent
                                    : const Color(0xFFED2C2E),
                              ),
                              title: Text(
                                item.title.isEmpty
                                    ? 'Şüpheli hareket'
                                    : item.title,
                                style: const TextStyle(
                                  color: Color(0xFF2A0709),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                item.description.isEmpty
                                    ? 'Açıklama yok.'
                                    : item.description,
                                style: const TextStyle(
                                  color: Color(0xFF6A3E3A),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: _securityActionRunning
                              ? null
                              : () => _refreshSecurityState(
                                  vibrateIfHighRisk: true,
                                ),
                          child: const Text('Güvenliği Yenile'),
                        ),
                        OutlinedButton(
                          onPressed: _securityActionRunning
                              ? null
                              : _runSecurityCleanup,
                          child: Text(
                            _securityActionRunning
                                ? 'İşleniyor...'
                                : '48 Saatlik Temizliği Uygula',
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _securityActionRunning
                              ? null
                              : _securityVibrationStopped
                              ? _resumeSecurityVibration
                              : _stopSecurityVibration,
                          child: Text(
                            _securityVibrationStopped
                                ? 'Titreşimi Yeniden Aç'
                                : 'Titreşimi Durdur',
                          ),
                        ),
                        if (_securityIncidents.isNotEmpty)
                          OutlinedButton(
                            onPressed: _securityActionRunning
                                ? null
                                : _clearAllSecurityReports,
                            child: const Text('Raporları Temizle'),
                          ),
                        if (_hasMediumSecurityIncident ||
                            _hasHighSecurityIncident ||
                            _hasCriticalSecurityIncident)
                          FilledButton(
                            onPressed: _securityActionRunning
                                ? null
                                : _applyRiskAction,
                            child: Text(
                              _hasCriticalSecurityIncident
                                  ? 'Final Containment'
                                  : _hasHighSecurityIncident
                                  ? 'Revival Block'
                                  : 'Hard Kill',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildCard(
                title: 'Voice-First Giriş',
                icon: Icons.record_voice_over_rounded,
                seed: _panelSeed(1),
                child: Column(
                  children: [
                    const Text(
                      'Dashboard üzerinden konuşma geçmişi izlenmez. Bu panel yalnız sesli komut odaklı çalışır.',
                      style: TextStyle(color: Color(0xFF6A3E3A), height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _promptController,
                      minLines: 2,
                      maxLines: 5,
                      style: const TextStyle(color: Color(0xFF4A1417)),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            'Ses öncelikli panel. Yazı alanı yalnız not amaçlıdır.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _sendPrompt,
                        child: const Text('Yazılı Giriş Devre Dışı'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isLikelyMediaRequest(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    const markers = <String>[
      'müzik',
      'muzik',
      'medya',
      'media',
      'spotify',
      'şarkı',
      'sarki',
      'oynat',
      'durdur',
      'devam ettir',
      'sesi kıs',
      'sesi aç',
    ];
    return markers.any(normalized.contains);
  }
}
