// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/identity/nova_speaker_priority_decision.dart';
import '../../core/runtime/nova_simulation_harness_models.dart';
import '../identity/nova_speaker_priority_service.dart';
import 'nova_identity_runtime_service.dart';
import 'nova_system_adaptation_contract_service.dart';

class NovaSimulationHarnessService {
  final NovaIdentityRuntimeService identityRuntimeService;
  final NovaSystemAdaptationContractService adaptationContractService;
  final NovaSpeakerPriorityService speakerPriorityService;

  const NovaSimulationHarnessService({
    this.identityRuntimeService = const NovaIdentityRuntimeService(),
    this.adaptationContractService =
        const NovaSystemAdaptationContractService(),
    this.speakerPriorityService = const NovaSpeakerPriorityService(),
  });

  Future<NovaSimulationHarnessReport> runCoreScenarios() async {
    await identityRuntimeService.ensureLoaded();
    final assistant = identityRuntimeService.currentDisplayName;
    final scenarios = <NovaSimulationScenarioResult>[];

    Future<void> addScenario({
      required String id,
      required String title,
      required String prompt,
      required String sourceSystem,
      required bool expectAuthorizedGate,
      bool mediaMode = false,
      bool callMode = false,
      bool companionMode = false,
      String relationship = '',
      double? ownerConfidence,
    }) async {
      final metadata = await adaptationContractService.buildMetadata(
        prompt: prompt,
        sourceSystem: sourceSystem,
        relationshipLabel: relationship,
        mediaMode: mediaMode,
        callMode: callMode,
        companionMode: companionMode,
        ownerConfidence: ownerConfidence,
      );
      final contractOk =
          metadata['assistantDisplayName'] == assistant &&
          metadata['futureSystemMustUseContract'] == true &&
          metadata['runtimeContractRequired'] == true &&
          metadata['safeAutoAdaptEligible'] == true;
      final modeOk = expectAuthorizedGate
          ? ((metadata['ownerConfidence'] as num?)?.toDouble() ?? 0) >= 0.80
          : ((metadata['ownerConfidence'] as num?)?.toDouble() ?? 0) < 0.80;
      scenarios.add(
        NovaSimulationScenarioResult(
          scenarioId: id,
          title: title,
          success: contractOk && modeOk,
          detail:
              'assistant=${metadata['assistantDisplayName']}, tone=${metadata['toneDirective']}, ownerConfidence=${metadata['ownerConfidence']}, source=${metadata['sourceSystem']}',
        ),
      );
    }

    await addScenario(
      id: 'owner_media_overlap',
      title: 'Sahip konuşurken medya açık',
      prompt: '$assistant sesi biraz kıs ve beni dinle',
      sourceSystem: 'dashboard_media',
      expectAuthorizedGate: true,
      mediaMode: true,
      relationship: 'Cihaz sahibi',
      ownerConfidence: 0.99,
    );
    await addScenario(
      id: 'registered_call_urgent',
      title: 'Kayıtlı çağrı ve acil uyandırma',
      prompt: 'Çok acil hemen bağlanmam lazım lütfen uyandır',
      sourceSystem: 'call_companion_runtime',
      expectAuthorizedGate: false,
      callMode: true,
      companionMode: true,
      relationship: 'Tanıştırılmış kişi',
      ownerConfidence: 0.56,
    );
    await addScenario(
      id: 'unauthorized_wake_attempt',
      title: 'Yetkisiz biri aktif ismiyle sesleniyor',
      prompt: '$assistant buraya gel ve kapıyı aç',
      sourceSystem: 'continuous_listening',
      expectAuthorizedGate: false,
      relationship: 'Tanınmış kişi',
      ownerConfidence: 0.32,
    );
    await addScenario(
      id: 'owner_takeover',
      title: 'Companion sırasında owner araya giriyor',
      prompt: '$assistant devral ben geldim',
      sourceSystem: 'call_handoff',
      expectAuthorizedGate: true,
      callMode: true,
      companionMode: true,
      relationship: 'Cihaz sahibi',
      ownerConfidence: 0.98,
    );
    await addScenario(
      id: 'familiar_chat_only',
      title: 'Tanıdık kişi yalnız sohbet ediyor',
      prompt: '$assistant bugün nasılsın',
      sourceSystem: 'ambient_chat',
      expectAuthorizedGate: false,
      relationship: 'Tanınmış kişi',
      ownerConfidence: 0.48,
    );
    await addScenario(
      id: 'authorized_guest_control',
      title: 'Yetkili kişi orta seviye kontrol istiyor',
      prompt: '$assistant ışıkları kapatır mısın',
      sourceSystem: 'ambient_control',
      expectAuthorizedGate: true,
      relationship: 'Nova kullanım yetkisi',
      ownerConfidence: 0.84,
    );
    await _addSpeakerPriorityScenario(scenarios);
    await _addContinuityScenario(scenarios);
    await _addEmotionConfidenceScenario(scenarios);

    return NovaSimulationHarnessReport(
      success: scenarios.every((e) => e.success),
      scenarios: List<NovaSimulationScenarioResult>.unmodifiable(scenarios),
    );
  }

  Future<void> _addSpeakerPriorityScenario(
    List<NovaSimulationScenarioResult> scenarios,
  ) async {
    final ownerDecision = speakerPriorityService.resolve(
      isOwner: true,
      isAuthorized: true,
      isIntroduced: true,
      speakerId: 'owner_voice',
      speakerName: 'Cihaz Sahibi',
      confidenceScore: 14,
      isCurrentConversationSpeaker: true,
      isRecentTrustedSpeaker: true,
    );
    final guestDecision = speakerPriorityService.resolve(
      isOwner: false,
      isAuthorized: true,
      isIntroduced: true,
      speakerId: 'authorized_voice',
      speakerName: 'Yetkili Kişi',
      confidenceScore: 12,
      isCurrentConversationSpeaker: true,
      isRecentTrustedSpeaker: true,
    );
    final introducedDecision = speakerPriorityService.resolve(
      isOwner: false,
      isAuthorized: false,
      isIntroduced: true,
      speakerId: 'introduced_voice',
      speakerName: 'Tanıştırılmış Kişi',
      confidenceScore: 11,
      isCurrentConversationSpeaker: true,
      isRecentTrustedSpeaker: false,
    );
    final ok =
        ownerDecision.band == NovaSpeakerPriorityBand.owner &&
        ownerDecision.score > guestDecision.score &&
        guestDecision.score > introducedDecision.score &&
        ownerDecision.shouldInterruptCurrentSpeaker &&
        guestDecision.shouldInterruptCurrentSpeaker &&
        !introducedDecision.shouldInterruptCurrentSpeaker;
    scenarios.add(
      NovaSimulationScenarioResult(
        scenarioId: 'speaker_priority_owner_first',
        title: 'Çok konuşmacılı ortamda owner önceliği korunuyor',
        success: ok,
        detail:
            'owner=${ownerDecision.score}, authorized=${guestDecision.score}, introduced=${introducedDecision.score}',
      ),
    );
  }

  Future<void> _addContinuityScenario(
    List<NovaSimulationScenarioResult> scenarios,
  ) async {
    final metadata = await adaptationContractService.buildMetadata(
      prompt:
          '${identityRuntimeService.currentDisplayName} ben geldim, kaldığımız yerden devam et',
      sourceSystem: 'continuous_listening_runtime',
      relationshipLabel: 'Cihaz sahibi',
      ownerConfidence: 0.97,
    );
    final ok =
        metadata['identityContinuityEnabled'] == true &&
        metadata['relationshipMemoryEnabled'] == true &&
        (metadata['ownerConfidence'] as num?)!.toDouble() >= 0.9 &&
        metadata['toneDirective'] != null;
    scenarios.add(
      NovaSimulationScenarioResult(
        scenarioId: 'owner_continuity_reuse',
        title:
            'Owner sesi için tekrar doğrulama yerine continuity kullanılıyor',
        success: ok,
        detail:
            'identityContinuity=${metadata['identityContinuityEnabled']}, relationshipMemory=${metadata['relationshipMemoryEnabled']}, ownerConfidence=${metadata['ownerConfidence']}',
      ),
    );
  }

  Future<void> _addEmotionConfidenceScenario(
    List<NovaSimulationScenarioResult> scenarios,
  ) async {
    final metadata = await adaptationContractService.buildMetadata(
      prompt:
          'Lütfen çok acil, gerçekten kötü hissediyorum ve hemen konuşmam gerekiyor!',
      sourceSystem: 'call_companion_runtime',
      relationshipLabel: 'Tanıştırılmış kişi',
      callMode: true,
      companionMode: true,
      ownerConfidence: 0.55,
    );
    final confidenceBand =
        metadata['callAcousticConfidenceBand']?.toString() ?? 'low';
    final ok =
        metadata['callAcousticInferenceMode'] == 'probabilistic' &&
        (metadata['callAcousticUrgency'] as num?)!.toDouble() >= 0.45 &&
        (metadata['callAcousticEmpathyNeed'] as num?)!.toDouble() >= 0.30 &&
        (confidenceBand == 'medium' || confidenceBand == 'high');
    scenarios.add(
      NovaSimulationScenarioResult(
        scenarioId: 'call_acoustic_confidence_v2',
        title: 'Acoustic confidence v2 olasılıksal sinyal üretiyor',
        success: ok,
        detail:
            'urgency=${metadata['callAcousticUrgency']}, empathy=${metadata['callAcousticEmpathyNeed']}, band=$confidenceBand',
      ),
    );
  }
}
