// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_system_issue.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import '../../core/self_repair/nova_self_repair_settings.dart';
import 'nova_capability_catalog_service.dart';
import 'nova_repair_resolution_memory_service.dart';
import 'nova_repair_trace_service.dart';
import 'nova_repair_validation_service.dart';
import 'nova_self_diagnostic_service.dart';
import 'nova_self_repair_command_service.dart';
import 'nova_self_repair_orchestrator_service.dart';
import 'nova_self_repair_report_service.dart';
import 'nova_self_repair_settings_service.dart';
import 'nova_self_repair_safe_kernel_service.dart';
import 'nova_owner_directed_speech_patch_execution_service.dart';

class NovaSelfRepairRunResult {
  final List<NovaSystemIssue> issues;
  final NovaSystemIssue? repairedIssue;
  final String message;

  const NovaSelfRepairRunResult({
    required this.issues,
    required this.repairedIssue,
    required this.message,
  });
}

class NovaSelfRepairCoordinatorService {
  final NovaSelfDiagnosticService diagnosticService;
  final NovaSelfRepairOrchestratorService orchestratorService;
  final NovaSelfRepairReportService reportService;
  final NovaSelfRepairSettingsService settingsService;
  final NovaSelfRepairCommandService commandService;
  final NovaCapabilityCatalogService capabilityCatalogService;
  final NovaRepairTraceService repairTraceService;
  final NovaRepairValidationService repairValidationService;
  final NovaRepairResolutionMemoryService resolutionMemoryService;
  final NovaOwnerDirectedSpeechPatchExecutionService?
  ownerDirectedPatchExecutionService;
  final NovaSelfRepairSafeKernelService safeKernelService;

  const NovaSelfRepairCoordinatorService({
    required this.diagnosticService,
    required this.orchestratorService,
    required this.reportService,
    required this.settingsService,
    required this.commandService,
    required this.capabilityCatalogService,
    required this.repairTraceService,
    required this.repairValidationService,
    required this.resolutionMemoryService,
    this.ownerDirectedPatchExecutionService,
    this.safeKernelService = const NovaSelfRepairSafeKernelService(),
  });

  Future<List<NovaSystemIssue>> previewIssues() async {
    await reportService.cleanupRetention();
    await repairTraceService.cleanupRetention();
    final settings = await settingsService.load();
    final issues = await diagnosticService.diagnose();
    if (settings.autoReportProblems) {
      for (final issue in issues) {
        await reportService.upsert(issue);
      }
    }
    return issues;
  }

  Future<List<NovaCapabilityCatalogItem>> previewCapabilities() {
    return capabilityCatalogService.loadSafeCatalog();
  }

  Future<NovaSelfRepairRunResult> runManualRepair({
    String requestedArea = '',
    bool ownerApproved = false,
  }) async {
    final settings = await settingsService.load();
    if (!settings.manualRepairEnabled) {
      return const NovaSelfRepairRunResult(
        issues: <NovaSystemIssue>[],
        repairedIssue: null,
        message: 'Manuel onarım ayarlardan kapalı.',
      );
    }
    return _run(
      requestedArea: requestedArea,
      settings: settings,
      ownerApproved: ownerApproved,
    );
  }

  Future<NovaSelfRepairRunResult> runFromCommand(String commandText) async {
    final settings = await settingsService.load();
    if (!settings.commandRepairEnabled) {
      return const NovaSelfRepairRunResult(
        issues: <NovaSystemIssue>[],
        repairedIssue: null,
        message: 'Komutla onarım ayarlardan kapalı.',
      );
    }
    final parsed = commandService.parse(commandText);
    if (!parsed.matched || !parsed.wantsRepair) {
      return NovaSelfRepairRunResult(
        issues: const <NovaSystemIssue>[],
        repairedIssue: null,
        message: parsed.message,
      );
    }
    if (parsed.requestedArea.trim().isNotEmpty) {
      await _recordOwnerRequestedRepairSignal(
        parsed.requestedArea,
        commandText,
      );
    }
    return _run(
      requestedArea: parsed.requestedArea,
      settings: settings,
      ownerApproved: false,
    );
  }

  Future<NovaSelfRepairRunResult> _run({
    required String requestedArea,
    required NovaSelfRepairSettings settings,
    required bool ownerApproved,
  }) async {
    await reportService.cleanupRetention();
    await repairTraceService.cleanupRetention();
    final issues = await diagnosticService.diagnose();
    if (issues.isEmpty) {
      return const NovaSelfRepairRunResult(
        issues: <NovaSystemIssue>[],
        repairedIssue: null,
        message: 'Aktif sorun görünmüyor.',
      );
    }

    NovaSystemIssue? selected;
    if (requestedArea.trim().isNotEmpty) {
      final safeArea = requestedArea.trim().toLowerCase();
      for (final issue in issues) {
        if (issue.title.toLowerCase().contains(safeArea) ||
            issue.capabilityId.toLowerCase().contains(safeArea) ||
            issue.humanMessage.toLowerCase().contains(safeArea)) {
          selected = issue;
          break;
        }
      }
    }
    selected ??= issues.first;

    final previous = await repairTraceService.getAll();
    final veryRecentMatch = previous.any(
      (e) =>
          e.issueCode == selected!.issueId &&
          DateTime.now().difference(e.createdAt).inMinutes < 10,
    );

    if (veryRecentMatch && requestedArea.trim().isEmpty) {
      final remembered = await resolutionMemoryService.findFor(
        issueCode: selected.issueId,
        capabilityId: selected.capabilityId,
      );
      return NovaSelfRepairRunResult(
        issues: issues,
        repairedIssue: selected,
        message: remembered == null
            ? 'Aynı sorun çok yakın zamanda işlendi. Kör tekrar deneme engellendi.'
            : 'Aynı sorun çok yakın zamanda işlendi. Önceki çözüm notu: ${remembered.resolutionSummary}',
      );
    }

    if (!selected.canSelfHeal) {
      final flagged = selected.copyWith(
        status: NovaSystemIssueStatus.needsOwnerAction,
        updatedAt: DateTime.now(),
      );
      await reportService.upsert(flagged);
      await repairTraceService.add(
        issueCode: flagged.issueId,
        solutionSummary:
            'Güvenli otomatik onarım dışında bırakıldı. Kör patch/owner kod uygulaması kapalıdır.',
        decisionLevel: 'owner_required_safe_kernel',
      );
      await resolutionMemoryService.remember(
        issueCode: flagged.issueId,
        capabilityId: flagged.capabilityId,
        resolutionSummary:
            'Kör patch uygulanmadı; güvenli self-repair yalnız izinli runtime policy yüzeylerinde çalışır.',
        decisionLevel: 'owner_required_safe_kernel',
      );
      return NovaSelfRepairRunResult(
        issues: issues,
        repairedIssue: flagged,
        message:
            'Bu alan güvenli otomatik onarım kapsamında değil. Kör kod/patch kapalı; sahip manuel incelemesi gerekli.',
      );
    }

    final safeKernelResult = await safeKernelService.run(
      ownerApproved: ownerApproved,
    );
    final safeStatus = safeKernelResult.verificationPassed
        ? NovaSystemIssueStatus.selfHealed
        : (safeKernelResult.needsOwnerApproval
              ? NovaSystemIssueStatus.needsOwnerAction
              : NovaSystemIssueStatus.open);
    final safeIssue = selected.copyWith(
      status: safeStatus,
      updatedAt: DateTime.now(),
    );

    var finalIssue = safeIssue;
    var finalMessage = safeKernelResult.message;
    var finalDecisionLevel = safeKernelResult.hardDenied
        ? 'safe_kernel_hard_denied'
        : (safeKernelResult.verificationPassed
              ? 'safe_kernel_verified'
              : (safeKernelResult.verificationPending
                    ? 'safe_kernel_applied_pending_verification'
                    : (safeKernelResult.needsOwnerApproval
                          ? 'safe_kernel_owner_approval_required'
                          : 'safe_kernel_noop_or_threshold')));

    if (!safeKernelResult.hardDenied &&
        !safeKernelResult.needsOwnerApproval &&
        _runtimeRepairAllowed(finalIssue.capabilityId)) {
      final orchestrated = await orchestratorService.trySelfRepair(
        finalIssue,
        voiceNarrationEnabled: false,
      );
      final validation = await repairValidationService.validate(orchestrated);
      finalIssue = validation.success
          ? orchestrated.copyWith(
              status: NovaSystemIssueStatus.selfHealed,
              updatedAt: DateTime.now(),
            )
          : orchestrated.copyWith(
              status: NovaSystemIssueStatus.open,
              updatedAt: DateTime.now(),
            );
      finalDecisionLevel = validation.success
          ? 'safe_kernel_plus_runtime_orchestrator_verified'
          : 'safe_kernel_plus_runtime_orchestrator_pending';
      finalMessage = validation.success
          ? 'Güvenli repair policy uygulandı ve runtime yeniden bağlama doğrulandı.'
          : 'Güvenli repair policy uygulandı; runtime yeniden bağlama denendi ama davranış doğrulaması hâlâ açık.';
    }

    await reportService.upsert(finalIssue);
    await repairTraceService.add(
      issueCode: finalIssue.issueId,
      solutionSummary: finalMessage,
      decisionLevel: finalDecisionLevel,
    );
    await resolutionMemoryService.remember(
      issueCode: finalIssue.issueId,
      capabilityId: finalIssue.capabilityId,
      resolutionSummary: finalMessage,
      decisionLevel: finalDecisionLevel,
    );

    return NovaSelfRepairRunResult(
      issues: issues,
      repairedIssue: finalIssue,
      message: finalMessage,
    );
  }

  Future<void> _recordOwnerRequestedRepairSignal(
    String requestedArea,
    String commandText,
  ) async {
    final area = requestedArea.trim().toLowerCase();
    late final NovaRuntimeSignalKind kind;
    switch (area) {
      case 'listening_runtime':
      case 'overlay_background':
      case 'permissions_runtime':
      case 'dashboard_ui':
        kind = NovaRuntimeSignalKind.background;
        break;
      case 'speech_understanding':
        kind = NovaRuntimeSignalKind.stt;
        break;
      case 'speech_response':
        kind = NovaRuntimeSignalKind.tts;
        break;
      case 'ai_response':
        kind = NovaRuntimeSignalKind.localModel;
        break;
      case 'setup_lifecycle':
      default:
        kind = NovaRuntimeSignalKind.ai;
        break;
    }
    final compactCommand = commandText.replaceAll(RegExp(r'\s+'), ' ').trim();
    await diagnosticService.signalService.record(
      kind: kind,
      level: NovaRuntimeSignalLevel.warning,
      code: 'owner_requested_repair_$area',
      message: 'Sahip komutla $area onarımı istedi.',
      technicalDetails: 'command=$compactCommand',
      diagnosticCandidate: true,
      metadata: <String, dynamic>{
        'source': 'owner_repair_command',
        'requestedArea': area,
      },
    );
  }

  bool _runtimeRepairAllowed(String capabilityId) {
    switch (capabilityId.trim().toLowerCase()) {
      case 'speech_understanding':
      case 'speech_response':
      case 'listening_runtime':
      case 'overlay_background':
      case 'ai_response':
      case 'setup_lifecycle':
      case 'local_model_boot':
      case 'permissions_runtime':
      case 'dashboard_ui':
        return true;
      default:
        return false;
    }
  }

  String _ownerTargetAreaFor(String capabilityId) {
    switch (capabilityId.trim().toLowerCase()) {
      case 'speech_response':
        return 'speech_response';
      case 'speech_understanding':
        return 'speech_understanding';
      default:
        return 'speech_and_understanding';
    }
  }
}
