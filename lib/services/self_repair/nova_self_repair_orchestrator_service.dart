// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_runtime_restart_target.dart';
import '../../core/self_repair/nova_system_issue.dart';
import '../system/nova_background_bridge_service.dart';
import '../tts/nova_tts_service.dart';
import 'nova_controlled_restart_service.dart';
import 'nova_repair_voice_narration_service.dart';
import 'nova_self_repair_report_service.dart';
import 'nova_self_repair_security_service.dart';

class NovaSelfRepairOrchestratorService {
  final NovaTtsService ttsService;
  final Future<void> Function()? endListeningSessionAction;
  final Future<void> Function()? ensureListeningAction;
  final NovaBackgroundBridgeService backgroundBridgeService;
  final NovaSelfRepairReportService reportService;
  final NovaSelfRepairSecurityService securityService;
  final NovaControlledRestartService controlledRestartService;
  final NovaRepairVoiceNarrationService? narrationService;

  const NovaSelfRepairOrchestratorService({
    required this.ttsService,
    this.endListeningSessionAction,
    this.ensureListeningAction,
    required this.backgroundBridgeService,
    required this.reportService,
    required this.securityService,
    required this.controlledRestartService,
    this.narrationService,
  });

  Future<NovaSystemIssue> trySelfRepair(
    NovaSystemIssue issue, {
    bool voiceNarrationEnabled = true,
  }) async {
    NovaSystemIssue next = issue;

    try {
      await _speakStart(voiceNarrationEnabled);
      await _speakProgress(40, voiceNarrationEnabled);

      switch (issue.capabilityId) {
        case 'speech_understanding':
          if (endListeningSessionAction != null) {
            await endListeningSessionAction!.call();
          }
          await controlledRestartService.restart({
            NovaRuntimeRestartTarget.continuousListening,
            NovaRuntimeRestartTarget.ttsStt,
            NovaRuntimeRestartTarget.backgroundOverlay,
          });
          await backgroundBridgeService.startBackground();
          await backgroundBridgeService.showOverlayIdle();
          if (ensureListeningAction != null) {
            await ensureListeningAction!.call();
          }
          next = issue.copyWith(
            status: NovaSystemIssueStatus.open,
            updatedAt: DateTime.now(),
          );
          break;

        case 'speech_response':
          await ttsService.stop();
          await controlledRestartService.restart({
            NovaRuntimeRestartTarget.ttsStt,
          });
          next = issue.copyWith(
            status: NovaSystemIssueStatus.open,
            updatedAt: DateTime.now(),
          );
          break;

        case 'listening_runtime':
          if (endListeningSessionAction != null) {
            await endListeningSessionAction!.call();
          }
          await controlledRestartService.restart({
            NovaRuntimeRestartTarget.continuousListening,
            NovaRuntimeRestartTarget.backgroundOverlay,
          });
          await backgroundBridgeService.startBackground();
          await backgroundBridgeService.showOverlayIdle();
          if (ensureListeningAction != null) {
            await ensureListeningAction!.call();
          }
          next = issue.copyWith(
            status: NovaSystemIssueStatus.open,
            updatedAt: DateTime.now(),
          );
          break;

        case 'overlay_background':
          await controlledRestartService.restart({
            NovaRuntimeRestartTarget.backgroundOverlay,
          });
          await backgroundBridgeService.startBackground();
          await backgroundBridgeService.showOverlayIdle();
          if (ensureListeningAction != null) {
            await ensureListeningAction!.call();
          }
          next = issue.copyWith(
            status: NovaSystemIssueStatus.open,
            updatedAt: DateTime.now(),
          );
          break;

        case 'ai_response':
          await backgroundBridgeService.showOverlayIdle();
          await controlledRestartService.restart({
            NovaRuntimeRestartTarget.ttsStt,
          });
          next = issue.copyWith(
            status: NovaSystemIssueStatus.open,
            updatedAt: DateTime.now(),
          );
          break;

        case 'reminder_runtime':
          await controlledRestartService.restart({
            NovaRuntimeRestartTarget.reminderRuntime,
          });
          next = issue.copyWith(
            status: NovaSystemIssueStatus.open,
            updatedAt: DateTime.now(),
          );
          break;

        case 'setup_lifecycle':
        case 'local_model_boot':
          await ttsService.stop();
          if (endListeningSessionAction != null) {
            await endListeningSessionAction!.call();
          }
          await controlledRestartService.restart({
            NovaRuntimeRestartTarget.ttsStt,
            NovaRuntimeRestartTarget.backgroundOverlay,
          });
          await backgroundBridgeService.startBackground();
          await backgroundBridgeService.showOverlayIdle();
          next = issue.copyWith(
            status: NovaSystemIssueStatus.open,
            updatedAt: DateTime.now(),
          );
          break;

        case 'contacts_runtime':
        case 'dashboard_ui':
        case 'debug_runtime':
        case 'personality_runtime':
        case 'knowledge_guides':
        case 'power_modes':
        case 'call_instruction_runtime':
        case 'permissions_runtime':
        case 'media_control':
        case 'call_systems':
          await backgroundBridgeService.showOverlayIdle();
          await controlledRestartService.restart({
            NovaRuntimeRestartTarget.continuousListening,
            NovaRuntimeRestartTarget.backgroundOverlay,
          });
          next = issue.copyWith(
            status: NovaSystemIssueStatus.open,
            updatedAt: DateTime.now(),
          );
          break;

        default:
          next = issue.copyWith(
            status: NovaSystemIssueStatus.needsOwnerAction,
            updatedAt: DateTime.now(),
          );
          break;
      }

      // Runtime restarts/rebinds are attempts, not proof of healing. The issue
      // stays open until a later runtime signal verifies that ASR/TTS/overlay/model
      // behavior actually changed. This prevents fake "self repaired" reports.
      await reportService.upsert(next);

      if (next.status == NovaSystemIssueStatus.selfHealed) {
        await _speakCompleted(voiceNarrationEnabled);
      } else {
        await _speakBackgroundContinue(voiceNarrationEnabled);
      }

      return next;
    } catch (_) {
      next = issue.copyWith(
        status: NovaSystemIssueStatus.needsOwnerAction,
        updatedAt: DateTime.now(),
      );
      await reportService.upsert(next);
      await _speakOwnerRequired(voiceNarrationEnabled);
      return next;
    }
  }

  Future<void> _speakStart(bool enabled) async {
    if (!enabled) return;
    if (narrationService != null) {
      try {
        await narrationService!.speakStart();
        return;
      } catch (_) {}
    }
    await _speakNatural('', enabled: enabled);
  }

  Future<void> _speakProgress(int percent, bool enabled) async {
    if (!enabled) return;
    if (narrationService != null) {
      try {
        await narrationService!.speakProgress(percent);
        return;
      } catch (_) {}
    }
    await _speakNatural('', enabled: enabled);
  }

  Future<void> _speakOwnerRequired(bool enabled) async {
    if (!enabled) return;
    if (narrationService != null) {
      try {
        await narrationService!.speakOwnerPatchRequired();
        return;
      } catch (_) {}
    }
    await _speakNatural('', enabled: enabled);
  }

  Future<void> _speakBackgroundContinue(bool enabled) async {
    if (!enabled) return;
    if (narrationService != null) {
      try {
        await narrationService!.speakBackgroundContinue();
        return;
      } catch (_) {}
    }
    await _speakNatural('', enabled: enabled);
  }

  Future<void> _speakCompleted(bool enabled) async {
    if (!enabled) return;
    if (narrationService != null) {
      try {
        await narrationService!.speakCompleted();
        return;
      } catch (_) {}
    }
    await _speakNatural('', enabled: enabled);
  }

  Future<void> _speakNatural(String text, {required bool enabled}) async {
    // V4 detox: self-repair events are diagnostics. They must not be rewritten
    // into user-facing speech outside NovaCoreTurnController.
    return;
  }
}
