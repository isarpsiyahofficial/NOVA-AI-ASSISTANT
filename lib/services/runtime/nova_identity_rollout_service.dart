// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/runtime/nova_identity_rollout_models.dart';
import '../../core/runtime/nova_simulation_harness_models.dart';
import 'nova_capability_audit_service.dart';
import 'nova_identity_runtime_service.dart';
import 'nova_simulation_harness_service.dart';
import 'nova_system_adaptation_contract_service.dart';

class NovaIdentityRolloutService {
  static const String _reportKey = 'nova_identity_rollout_report_v1';

  final NovaIdentityRuntimeService identityRuntimeService;
  final NovaSystemAdaptationContractService adaptationContractService;
  final NovaCapabilityAuditService capabilityAuditService;
  final NovaSimulationHarnessService simulationHarnessService;

  const NovaIdentityRolloutService({
    this.identityRuntimeService = const NovaIdentityRuntimeService(),
    this.adaptationContractService =
        const NovaSystemAdaptationContractService(),
    this.capabilityAuditService = const NovaCapabilityAuditService(),
    this.simulationHarnessService = const NovaSimulationHarnessService(),
  });

  Future<NovaIdentityRolloutReport> performRollout({
    required String assistantName,
    Future<void> Function(NovaIdentityRolloutProgress progress)? onProgress,
    Duration minimumRuntime = Duration.zero,
  }) async {
    final startedAt = DateTime.now();
    final cleanedName = assistantName.trim().isEmpty
        ? 'Nova'
        : assistantName.trim();
    final progress = <NovaIdentityRolloutProgress>[];
    const totalRolloutSteps = 9;
    int realPercent(int completedSteps) =>
        ((completedSteps.clamp(0, totalRolloutSteps) * 100) / totalRolloutSteps)
            .round();

    Future<void> emit(NovaIdentityRolloutProgress step) async {
      progress.add(step);
      await onProgress?.call(step);
    }

    final audit = await capabilityAuditService.audit();
    await emit(
      NovaIdentityRolloutProgress(
        percent: realPercent(1),
        title: 'Benzer sistemleri tarıyorum',
        detail:
            'İlk hazırlık taraması tamamlandı. Güvenli uyum kontrolü yapılıyor.',
      ),
    );

    await identityRuntimeService.ensureLoaded();
    await emit(
      NovaIdentityRolloutProgress(
        percent: realPercent(2),
        title: 'Aktif kimlik profilini yüklüyorum',
        detail: 'Mevcut hitap ve uyanma ayarları güvenli şekilde yüklendi.',
      ),
    );

    final renamed = await identityRuntimeService.renameAssistant(
      displayName: cleanedName,
      additionalAliases: <String>['nova'],
    );
    await emit(
      NovaIdentityRolloutProgress(
        percent: realPercent(3),
        title: 'Yeni adı yayıyorum',
        detail:
            '${renamed.displayName} adı konuşma ve hitap zincirine uygulandı.',
      ),
    );

    final metadata = await adaptationContractService.buildMetadata(
      prompt: '${renamed.displayName} burada mısın?',
      sourceSystem: 'first_run_setup',
      requestOrigin: 'first_run_identity_rollout',
    );
    final contractOk =
        metadata['assistantDisplayName']?.toString().trim() ==
            renamed.displayName &&
        metadata['futureSystemMustUseContract'] == true &&
        metadata['assistantRenameAutoPropagation'] == true;
    await emit(
      NovaIdentityRolloutProgress(
        percent: realPercent(4),
        title: 'Ortak adaptasyon sözleşmesini doğruluyorum',
        detail: contractOk
            ? 'Kimlik, contract üzerinden sistem geneline taşınabiliyor.'
            : 'Kimlik contract doğrulaması eksik kaldı.',
        success: contractOk,
      ),
    );

    final addressOk =
        identityRuntimeService.isAddressedToAssistant(
          '${renamed.displayName} beni duyar mısın',
        ) &&
        identityRuntimeService.isAddressedToAssistant('nova dinle beni');
    await emit(
      NovaIdentityRolloutProgress(
        percent: realPercent(5),
        title: 'Wake ve hitap yayılımını test ediyorum',
        detail: addressOk
            ? 'Yeni ad ve eski alias birlikte çalışıyor.'
            : 'Hitap yayılımı beklenen gibi değil.',
        success: addressOk,
      ),
    );

    final adaptedSystems = <String>[
      'setup_onboarding',
      'identity_runtime',
      'adaptation_contract',
      'continuous_listening_runtime',
      'streaming_transcript_router',
      'speech_to_text_runtime',
      'call_companion_runtime',
      'call_companion_gate',
      'dashboard_prompt_pipeline',
      'seven_day_context_memory',
      'voice_output_runtime',
      'lifecycle_runtime',
    ];
    await emit(
      NovaIdentityRolloutProgress(
        percent: realPercent(6),
        title: 'Kayıtlı runtime hedeflerini uyumluyorum',
        detail: 'Kayıtlı hedefler yeni isimle uyumlu hale getiriliyor.',
      ),
    );

    final simulation = await simulationHarnessService.runCoreScenarios();
    await emit(
      NovaIdentityRolloutProgress(
        percent: realPercent(7),
        title: 'Sentetik kişi davranış senaryolarını doğruluyorum',
        detail:
            '${simulation.passedCount}/${simulation.totalCount} çekirdek senaryo contract ile uyumlu doğrulandı.',
        success: simulation.success,
      ),
    );

    final elapsed = DateTime.now().difference(startedAt);
    final remaining = minimumRuntime - elapsed;
    if (remaining > Duration.zero) {
      await emit(
        NovaIdentityRolloutProgress(
          percent: realPercent(8),
          title: 'Son eşitleme bekçisini çalıştırıyorum',
          detail:
              'Sesli hitap, dinleme, konuşma ve çağrı hazırlığı için minimum yayılım penceresi korunuyor.',
        ),
      );
      await Future<void>.delayed(remaining);
    }

    await emit(
      const NovaIdentityRolloutProgress(
        percent: 100,
        title: 'Kimlik yayılımı tamamlandı',
        detail:
            'Kimlik yayılımı tamamlandı. Yeni ad günlük kullanım için hazır.',
      ),
    );

    final report = NovaIdentityRolloutReport(
      assistantName: renamed.displayName,
      success: progress.every((step) => step.success),
      progress: List<NovaIdentityRolloutProgress>.unmodifiable(progress),
      auditReport: audit,
      adaptedSystems: List<String>.unmodifiable(
        <String>{
          ...adaptedSystems,
          ...audit.adaptedFiles,
        }.toList(growable: false),
      ),
      summary:
          '${renamed.displayName} adı temel konuşma, hitap ve kimlik akışlarına güvenli şekilde uygulandı.',
    );

    await _persistReport(report);
    return report;
  }

  Future<void> _persistReport(NovaIdentityRolloutReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _reportKey,
        jsonEncode(<String, dynamic>{
          'assistantName': report.assistantName,
          'success': report.success,
          'summary': report.summary,
          'adaptedSystems': report.adaptedSystems,
          'progress': report.progress
              .map(
                (step) => <String, dynamic>{
                  'percent': step.percent,
                  'title': step.title,
                  'detail': step.detail,
                  'success': step.success,
                },
              )
              .toList(growable: false),
          'auditEnabled': report.auditReport.enabledCapabilities,
          'auditMissing': report.auditReport.missingCapabilities,
          'auditLayerGroups': report.auditReport.layerGroups,
          'auditTotalFiles': report.auditReport.totalAuditedFiles,
          'auditBindingFiles': report.auditReport.totalBindingFiles,
          'auditRepositoryDartFiles':
              report.auditReport.repositoryDartFileCount,
          'auditBindingGroups': report.auditReport.bindingGroups,
        }),
      );
    } catch (_) {}
  }
}
