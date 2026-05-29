// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:async';

// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
import '../../core/runtime/nova_runtime_intent.dart';
import '../../core/system/nova_power_mode.dart';
import '../call/nova_call_control_bridge_service.dart';
import '../call/nova_call_state_service.dart';
import '../phone_control/phone_control_service.dart';
import '../reminder/nova_reminder_service.dart';
import '../self_repair/nova_self_repair_command_service.dart';
import '../system/nova_background_bridge_service.dart';
import '../system/nova_continuous_listening_runtime_service.dart';
import '../system/nova_power_schedule_service.dart';
import '../system/nova_power_service.dart';
import 'nova_runtime_intent_router_service.dart';
import 'nova_single_brain_authority_service.dart';

class NovaRuntimeOrchestratorResult {
  final bool handled;
  final bool success;
  final String spokenText;
  final Map<String, dynamic> actionSummaryJson;
  final NovaRuntimeIntentMatch match;

  NovaRuntimeOrchestratorResult({
    required this.handled,
    required this.success,
    String spokenText = '',
    Map<String, dynamic>? actionSummaryJson,
    required this.match,
  }) : spokenText = '',
       actionSummaryJson = Map<String, dynamic>.unmodifiable(
         actionSummaryJson ??
             <String, dynamic>{
               'handled': handled,
               'success': success,
               'actionType': match.intent.name,
               'confidence': match.confidence,
               'safeToSummarizeToUser': true,
             },
       );

  factory NovaRuntimeOrchestratorResult.unhandled(
    NovaRuntimeIntentMatch match,
  ) => NovaRuntimeOrchestratorResult(
    handled: false,
    success: false,
    spokenText: '',
    match: match,
  );
}

class NovaRuntimeOrchestratorService {
  final NovaRuntimeIntentRouterService intentRouterService;
  final NovaPowerService powerService;
  final NovaBackgroundBridgeService backgroundBridgeService;
  final NovaContinuousListeningRuntimeService continuousListeningRuntimeService;
  final NovaCallControlBridgeService callControlService;
  final NovaCallStateService callStateService;
  final NovaReminderService reminderService;
  final NovaSelfRepairCommandService selfRepairCommandService;
  final PhoneControlService phoneControlService;
  final NovaPowerScheduleService powerScheduleService;
  final Future<void> Function()? ensureListeningAction;
  Future<void> _serializedExecution = Future<void>.value();

  NovaRuntimeOrchestratorService({
    required this.intentRouterService,
    required this.powerService,
    required this.backgroundBridgeService,
    required this.continuousListeningRuntimeService,
    required this.callControlService,
    required this.callStateService,
    required this.reminderService,
    required this.selfRepairCommandService,
    required this.phoneControlService,
    this.ensureListeningAction,
    NovaPowerScheduleService? powerScheduleService,
  }) : powerScheduleService =
           powerScheduleService ?? const NovaPowerScheduleService();

  Future<NovaRuntimeOrchestratorResult> tryHandle(String rawInput) {
    return _runSerialized<NovaRuntimeOrchestratorResult>(
      label: 'runtime_orchestrator',
      action: () => _tryHandleInternal(rawInput),
    );
  }

  Future<T> _runSerialized<T>({
    required String label,
    required Future<T> Function() action,
  }) {
    final completer = Completer<T>();
    _serializedExecution = _serializedExecution.catchError((_) {}).then((
      _,
    ) async {
      try {
        final result = await action();
        if (!completer.isCompleted) completer.complete(result);
      } catch (error, stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<NovaRuntimeOrchestratorResult> _tryHandleInternal(
    String rawInput,
  ) async {
    NovaSingleBrainAuthorityService.instance.registerSource(
      'runtime_orchestrator',
    );
    final match = intentRouterService.resolve(rawInput);
    final requiresHighConfidence =
        match.intent != NovaRuntimeIntent.generalConversation;
    if ((rawInput.trim().split(RegExp(r'\s+')).length > 6 ||
            rawInput.contains('?')) &&
        match.intent == NovaRuntimeIntent.generalConversation) {
      return NovaRuntimeOrchestratorResult.unhandled(match);
    }
    if (requiresHighConfidence && match.confidence < 0.78) {
      return NovaRuntimeOrchestratorResult.unhandled(match);
    }
    switch (match.intent) {
      case NovaRuntimeIntent.generalConversation:
        return NovaRuntimeOrchestratorResult.unhandled(match);
      case NovaRuntimeIntent.statusReport:
        return _status(match);
      case NovaRuntimeIntent.startListening:
        return _startListening(match);
      case NovaRuntimeIntent.stopListening:
        return _stopListening(match);
      case NovaRuntimeIntent.sleepMode:
        return _sleep(match);
      case NovaRuntimeIntent.wakeMode:
        return _wake(match);
      case NovaRuntimeIntent.shutdownMode:
        return _shutdown(match);
      case NovaRuntimeIntent.batterySaverMode:
        return _batterySaver(match);
      case NovaRuntimeIntent.limboMode:
        return _limbo(match);
      case NovaRuntimeIntent.answerCall:
        return _answerCall(match);
      case NovaRuntimeIntent.rejectCall:
        return _rejectCall(match);
      case NovaRuntimeIntent.handOverCallToNova:
        return _handoverToNova(match);
      case NovaRuntimeIntent.handOverCallToUser:
        return _handoverToUser(match);
      case NovaRuntimeIntent.startSelfRepair:
      case NovaRuntimeIntent.openSelfRepair:
        return _selfRepair(match, rawInput);
      case NovaRuntimeIntent.debugSystems:
        return _debug(match);
      case NovaRuntimeIntent.reminderAction:
        return _reminder(match, rawInput);
    }
  }

  Future<Map<String, dynamic>> healthSnapshot() async {
    final call = await callStateService.getSnapshot();
    final reminders = await reminderService.getAll();
    final background = await backgroundBridgeService.startBackground();
    final schedule = await powerScheduleService.load();
    final singleBrainAudit = NovaSingleBrainAuthorityService.instance
        .auditSpine();
    return <String, dynamic>{
      'powerMode': powerService.mode.name,
      'backgroundReady': background.success,
      'continuousListeningRunning': continuousListeningRuntimeService.isRunning,
      'streamingAsr': continuousListeningRuntimeService
          .streamingAsrRuntimeService
          .latestState
          .toMap(),
      'callState': call.state,
      'phoneControlEnabled': phoneControlService.isEnabled,
      'pendingReminders': reminders
          .where((e) => e.status.name == 'pending')
          .length,
      'conversationRuntime': continuousListeningRuntimeService
          .runtimeSnapshot(),
      'powerScheduleActive': schedule.enabled,
      'singleBrainHealthy': singleBrainAudit.healthy,
      'singleBrainMissingSources': singleBrainAudit.missingCriticalSources,
      'singleBrainRegisteredSources': singleBrainAudit.registeredSources,
    };
  }

  Future<String> _describeCallCapability() async {
    final call = await callStateService.getSnapshot();
    if (call.isRinging) {
      return 'Gelen çağrı var; cevaplama ve devralma zinciri hazır.';
    }
    if (call.isActiveCall) {
      return 'Aktif çağrı var; companion devralma ve kullanıcıya geri verme zinciri hazır.';
    }
    return 'Şu an canlı çağrı yok.';
  }

  Future<NovaRuntimeOrchestratorResult> _status(
    NovaRuntimeIntentMatch match,
  ) async {
    final call = await callStateService.getSnapshot();
    final reminders = await reminderService.getAll();
    final pending = reminders.where((e) => e.status.name == 'pending').length;
    final completed = reminders
        .where((e) => e.status.name == 'completed')
        .length;
    final asrState = continuousListeningRuntimeService
        .streamingAsrRuntimeService
        .latestState;
    final runtime = continuousListeningRuntimeService.runtimeSnapshot();
    final callCapability = await _describeCallCapability();
    final embeddedAsrLabel = asrState.embeddedSherpaReady
        ? 'yerel dinleme hazır'
        : 'dinleme hazır değil';
    final speakerLabel = (runtime['lastRecognizedSpeakerName'] as String? ?? '')
        .trim();
    final recentStreamingFinalText =
        (runtime['recentStreamingFinalText'] as String? ?? '').trim();
    final streamingTrail = recentStreamingFinalText.isEmpty
        ? 'yakın zamanda net konuşma alınmadı'
        : 'yakın zamanda konuşma alındı';
    final text =
        'Durum raporu efendim. Güç modu ${powerService.mode.spokenLabel}. Sürekli dinleme ${continuousListeningRuntimeService.isRunning ? 'aktif' : 'pasif'}. Dinleme durumu: $embeddedAsrLabel; $streamingTrail. Çağrı durumu ${call.state}. $callCapability Bekleyen hatırlatma $pending, tamamlanan $completed. Telefon yönetimi ${phoneControlService.isEnabled ? 'açık' : 'kapalı'}. Konuşma devamlılığı ${runtime['authorizedConversationActive'] == true ? 'korunuyor' : 'beklemede'}. Son tanınan konuşmacı ${speakerLabel.isEmpty ? 'yok' : speakerLabel}.';
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: true,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _startListening(
    NovaRuntimeIntentMatch match,
  ) async {
    if (powerService.isFullyShutdown) {
      await powerService.setFullyOn(userInitiated: true);
    }
    if (!continuousListeningRuntimeService.isRunning) {
      if (ensureListeningAction != null) {
        await ensureListeningAction!.call();
      } else {
        await backgroundBridgeService.startBackground();
        await backgroundBridgeService.showOverlayIdle();
        await continuousListeningRuntimeService.start(
          onAuthorizedPrompt: (_) async {},
          onUnauthorizedOrStatus: (_) async {},
        );
      }
    }
    final bg = await backgroundBridgeService.startBackground();
    final overlay = await backgroundBridgeService.showOverlayListening();
    final ok =
        continuousListeningRuntimeService.isRunning ||
        bg.success ||
        overlay.success;
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: ok,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _stopListening(
    NovaRuntimeIntentMatch match,
  ) async {
    await continuousListeningRuntimeService.stop();
    await backgroundBridgeService.showOverlaySleeping();
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: true,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _sleep(
    NovaRuntimeIntentMatch match,
  ) async {
    await powerService.setPassiveSleep(userInitiated: true);
    await backgroundBridgeService.setBackgroundSleeping();
    await backgroundBridgeService.showOverlaySleeping();
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: true,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _wake(
    NovaRuntimeIntentMatch match,
  ) async {
    await powerService.setFullyOn(userInitiated: true);
    if (ensureListeningAction != null) {
      await ensureListeningAction!.call();
    }
    await backgroundBridgeService.setBackgroundRunning();
    await backgroundBridgeService.showOverlayListening();
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: true,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _shutdown(
    NovaRuntimeIntentMatch match,
  ) async {
    await powerService.setFullyShutdown(userInitiated: true);
    await continuousListeningRuntimeService.fullyShutdown();
    await backgroundBridgeService.setBackgroundFullyOff();
    await backgroundBridgeService.removeOverlay();
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: true,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _limbo(
    NovaRuntimeIntentMatch match,
  ) async {
    await powerService.setLimbo(userInitiated: true);
    await backgroundBridgeService.setBackgroundSleeping();
    await backgroundBridgeService.showOverlaySleeping();
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: true,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _batterySaver(
    NovaRuntimeIntentMatch match,
  ) async {
    await powerService.setBatterySaver(userInitiated: true);
    if (ensureListeningAction != null) {
      await ensureListeningAction!.call();
    }
    await backgroundBridgeService.setBackgroundRunning();
    await backgroundBridgeService.showOverlayListening();
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: true,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _answerCall(
    NovaRuntimeIntentMatch match,
  ) async {
    final result = await callControlService.answerRingingCall(
      userInitiated: true,
    );
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: result.success,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _rejectCall(
    NovaRuntimeIntentMatch match,
  ) async {
    final result = await callControlService.rejectRingingCall(
      userInitiated: true,
    );
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: result.success,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _handoverToNova(
    NovaRuntimeIntentMatch match,
  ) async {
    final result = await callControlService.handOverToNova(userInitiated: true);
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: result.success,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _handoverToUser(
    NovaRuntimeIntentMatch match,
  ) async {
    final result = await callControlService.handOverToUser(userInitiated: true);
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: result.success,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _selfRepair(
    NovaRuntimeIntentMatch match,
    String rawInput,
  ) async {
    final parsed = selfRepairCommandService.parse(rawInput);
    final baseText = parsed.wantsRepair
        ? 'Onarım akışı hazır efendim. Yalnız gerçek sorun bölgesi ve yetkili kör yama zinciri içinde çalışacağım.'
        : 'Onarım paneli ve self repair zinciri hazır görünüyor efendim. Ancak yalnız gerçek sorun varsa çalışacağım.';
    final allowed = powerService.mode.allowsSelfRepairDiagnostics;
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: allowed,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _debug(
    NovaRuntimeIntentMatch match,
  ) async {
    final call = await callStateService.getSnapshot();
    final text =
        'Tanı özeti efendim. Güç modu ${powerService.mode.spokenLabel}, çağrı ${call.state}, dinleme ${continuousListeningRuntimeService.isRunning ? 'açık' : 'kapalı'}, telefon yönetimi ${phoneControlService.isEnabled ? 'açık' : 'kapalı'}. Ayrıntılı dosya ve runtime taraması panelden sürdürülebilir.';
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: true,
      spokenText: '',
      match: match,
    );
  }

  Future<NovaRuntimeOrchestratorResult> _reminder(
    NovaRuntimeIntentMatch match,
    String rawInput,
  ) async {
    final acknowledged = await reminderService.tryAcknowledgeWakeAlarmFromInput(
      rawInput,
    );
    final text = acknowledged
        ? 'Bekleyen uyarı onaylandı efendim.'
        : 'Hatırlatma niyeti algılandı efendim. Bu istek hatırlatma zinciriyle ayrıntılandırılmalı.';
    return NovaRuntimeOrchestratorResult(
      handled: true,
      success: true,
      spokenText: '',
      match: match,
    );
  }
}
