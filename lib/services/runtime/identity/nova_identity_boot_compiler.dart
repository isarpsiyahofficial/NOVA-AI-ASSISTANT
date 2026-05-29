// GEMMA6644 IDENTITY BOOT COMPILER
// Bu dosya otomatik kaynak tarama pass'iyle oluşturuldu.
// Amaç: Nova kimliğini 145 katmanlık uzun prompt olarak okutmak yerine
// kodlanmış katmanlardan kısa, kalıcı ve yeniden kullanılabilir kimlik digest'i üretmek.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NovaIdentityLayerSpec {
  final int index;
  final String id;
  final String sourcePath;
  final int sourceLine;
  final String category;
  final int priority;
  final List<String> flags;
  final String meaning;

  const NovaIdentityLayerSpec({
    required this.index,
    required this.id,
    required this.sourcePath,
    required this.sourceLine,
    required this.category,
    required this.priority,
    required this.flags,
    required this.meaning,
  });

  bool get setupScoped => flags.contains('setup_scoped');
  bool get voiceFirst => flags.contains('voice_first');
  bool get ownerBound => flags.contains('owner_bound');
  bool get singleBrain => flags.contains('single_brain');
  bool get noStaticShell => flags.contains('no_static_shell');

  String get compactCode {
    final shortFlags = flags.take(3).join('+');
    return '$index:$category:$shortFlags';
  }
}

class NovaCompiledIdentityDigest {
  final String version;
  final String sourceHash;
  final String digest;
  final String ultraShortDigest;
  final int layerCount;
  final List<String> activeLayerCodes;
  final bool fromCache;

  const NovaCompiledIdentityDigest({
    required this.version,
    required this.sourceHash,
    required this.digest,
    required this.ultraShortDigest,
    required this.layerCount,
    required this.activeLayerCodes,
    this.fromCache = false,
  });

  Map<String, dynamic> toMetadata() => <String, dynamic>{
    'identityVersion': version,
    'identitySourceHash': sourceHash,
    'identityLayerCount': layerCount,
    'identityDigestChars': digest.length,
    'identityFromCache': fromCache,
    'activeIdentityLayerCodes': activeLayerCodes.join('|'),
  };
}

class NovaIdentityBootCompiler {
  static const String version =
      'gemma6644_identity_boot_compiler_v2_human_runtime';
  static const int expectedLayerCount = 145;
  static const String _prefsHashKey =
      'nova_identity_compiled_source_hash_v2_human_runtime';
  static const String _prefsDigestKey =
      'nova_identity_compiled_digest_v2_human_runtime';
  static const String _prefsUltraDigestKey =
      'nova_identity_compiled_ultra_digest_v2_human_runtime';
  static const String sourceHash =
      'b9f65d1f8c7e4c0a9f9a3d6d2f0b4a8e9e0f4c0d8a9b7c6d5e4f3a2b1c0d9e8f7';

  static const List<NovaIdentityLayerSpec> layers = <NovaIdentityLayerSpec>[
    NovaIdentityLayerSpec(
      index: 1,
      id: 'id_001_core_ai_nova_ai_service_dart',
      sourcePath: 'lib/core/ai/nova_ai_service.dart',
      sourceLine: 171,
      category: 'brain',
      priority: 98,
      flags: <String>['single_brain'],
      meaning: 'final NovaPersona persona;',
    ),
    NovaIdentityLayerSpec(
      index: 2,
      id: 'id_002_services_runtime_nova_layer_binding_registry_service_',
      sourcePath:
          'lib/services/runtime/nova_layer_binding_registry_service.dart',
      sourceLine: 7,
      category: 'identity',
      priority: 69,
      flags: <String>['no_static_shell'],
      meaning: 'static const int repositoryDartFileCount = 523;',
    ),
    NovaIdentityLayerSpec(
      index: 3,
      id: 'id_003_services_local_model_local_model_service_dart',
      sourcePath: 'lib/services/local_model/local_model_service.dart',
      sourceLine: 43,
      category: 'brain',
      priority: 66,
      flags: <String>['single_brain'],
      meaning: 'return value.isEmpty ? \'API beyin durumu belirsiz.\' : value;',
    ),
    NovaIdentityLayerSpec(
      index: 4,
      id: 'id_004_services_identity_voice_authorization_runtime_service_d',
      sourcePath:
          'lib/services/identity/voice_authorization_runtime_service.dart',
      sourceLine: 14,
      category: 'voice',
      priority: 52,
      flags: <String>['owner_bound', 'voice_first'],
      meaning: 'class VoiceAuthorizationRuntimeInspectionResult {',
    ),
    NovaIdentityLayerSpec(
      index: 5,
      id: 'id_005_services_runtime_nova_hotpath_owner_service_dart',
      sourcePath: 'lib/services/runtime/nova_hotpath_owner_service.dart',
      sourceLine: 11,
      category: 'identity',
      priority: 51,
      flags: <String>['owner_bound'],
      meaning: 'class NovaHotpathOwnerResult {',
    ),
    NovaIdentityLayerSpec(
      index: 6,
      id: 'id_006_ui_dashboard_dashboard_page_dart',
      sourcePath: 'lib/ui/dashboard/dashboard_page.dart',
      sourceLine: 129,
      category: 'identity',
      priority: 51,
      flags: <String>['identity_reflex'],
      meaning: 'final NovaPersona persona;',
    ),
    NovaIdentityLayerSpec(
      index: 7,
      id: 'id_007_services_identity_nova_multi_speaker_authority_servic',
      sourcePath:
          'lib/services/identity/nova_multi_speaker_authority_service.dart',
      sourceLine: 7,
      category: 'authority',
      priority: 48,
      flags: <String>['owner_bound'],
      meaning:
          'enum NovaSpeakerAuthorityBand { owner, authorized, familiar, stranger, unknown }',
    ),
    NovaIdentityLayerSpec(
      index: 8,
      id: 'id_008_services_runtime_nova_single_brain_authority_service_',
      sourcePath:
          'lib/services/runtime/nova_single_brain_authority_service.dart',
      sourceLine: 12,
      category: 'voice',
      priority: 48,
      flags: <String>['owner_bound', 'voice_first', 'single_brain'],
      meaning: 'final String speakerVoiceId;',
    ),
    NovaIdentityLayerSpec(
      index: 9,
      id: 'id_009_services_runtime_nova_unified_social_runtime_service_',
      sourcePath:
          'lib/services/runtime/nova_unified_social_runtime_service.dart',
      sourceLine: 12,
      category: 'social',
      priority: 46,
      flags: <String>['relationship_aware'],
      meaning: 'enum NovaUnifiedRuntimeEventType {',
    ),
    NovaIdentityLayerSpec(
      index: 10,
      id: 'id_010_ui_identity_voice_identity_control_page_dart',
      sourcePath: 'lib/ui/identity/voice_identity_control_page.dart',
      sourceLine: 11,
      category: 'voice',
      priority: 46,
      flags: <String>['voice_first'],
      meaning: 'class VoiceIdentityControlPage extends StatefulWidget {',
    ),
    NovaIdentityLayerSpec(
      index: 11,
      id: 'id_011_services_call_companion_nova_call_companion_runtime_s',
      sourcePath:
          'lib/services/call_companion/nova_call_companion_runtime_service.dart',
      sourceLine: 28,
      category: 'call',
      priority: 44,
      flags: <String>['relationship_aware'],
      meaning: 'class NovaCallCompanionRuntimeService {',
    ),
    NovaIdentityLayerSpec(
      index: 12,
      id: 'id_012_services_identity_voice_authorization_service_dart',
      sourcePath: 'lib/services/identity/voice_authorization_service.dart',
      sourceLine: 8,
      category: 'voice',
      priority: 44,
      flags: <String>['owner_bound', 'voice_first'],
      meaning: 'class VoiceAuthorizationService {',
    ),
    NovaIdentityLayerSpec(
      index: 13,
      id: 'id_013_services_identity_nova_recent_speaker_service_dart',
      sourcePath: 'lib/services/identity/nova_recent_speaker_service.dart',
      sourceLine: 10,
      category: 'voice',
      priority: 43,
      flags: <String>['voice_first'],
      meaning: 'final String voiceId;',
    ),
    NovaIdentityLayerSpec(
      index: 14,
      id: 'id_014_services_runtime_nova_speaker_graph_engine_service_da',
      sourcePath: 'lib/services/runtime/nova_speaker_graph_engine_service.dart',
      sourceLine: 9,
      category: 'identity',
      priority: 42,
      flags: <String>['owner_bound'],
      meaning: 'owner,',
    ),
    NovaIdentityLayerSpec(
      index: 15,
      id: 'id_015_core_identity_nova_voice_identity_warmup_result_dart',
      sourcePath: 'lib/core/identity/nova_voice_identity_warmup_result.dart',
      sourceLine: 5,
      category: 'voice',
      priority: 42,
      flags: <String>['voice_first'],
      meaning: 'class NovaVoiceIdentityWarmupResult {',
    ),
    NovaIdentityLayerSpec(
      index: 16,
      id: 'id_016_ui_onboarding_nova_first_run_setup_page_dart',
      sourcePath: 'lib/ui/onboarding/nova_first_run_setup_page.dart',
      sourceLine: 57,
      category: 'setup',
      priority: 42,
      flags: <String>['setup_scoped'],
      meaning: 'class NovaFirstRunSetupPage extends StatefulWidget {',
    ),
    NovaIdentityLayerSpec(
      index: 17,
      id: 'id_017_core_identity_known_voice_identity_dart',
      sourcePath: 'lib/core/identity/known_voice_identity.dart',
      sourceLine: 3,
      category: 'voice',
      priority: 42,
      flags: <String>['voice_first'],
      meaning: 'class KnownVoiceIdentity {',
    ),
    NovaIdentityLayerSpec(
      index: 18,
      id: 'id_018_services_runtime_nova_presence_identity_service_dart',
      sourcePath: 'lib/services/runtime/nova_presence_identity_service.dart',
      sourceLine: 3,
      category: 'social',
      priority: 42,
      flags: <String>['relationship_aware'],
      meaning:
          'class NovaPresenceIdentityProfile { final String socialMode; final String presenceBand; final String initiativeStyle; final Stri',
    ),
    NovaIdentityLayerSpec(
      index: 19,
      id: 'id_019_services_runtime_nova_silence_comfort_service_dart',
      sourcePath: 'lib/services/runtime/nova_silence_comfort_service.dart',
      sourceLine: 14,
      category: 'social',
      priority: 42,
      flags: <String>['relationship_aware'],
      meaning: 'final String companionMove;',
    ),
    NovaIdentityLayerSpec(
      index: 20,
      id: 'id_020_services_identity_voice_identity_registry_service_dart',
      sourcePath: 'lib/services/identity/voice_identity_registry_service.dart',
      sourceLine: 9,
      category: 'voice',
      priority: 41,
      flags: <String>['voice_first'],
      meaning: 'class VoiceIdentityRegistryService {',
    ),
    NovaIdentityLayerSpec(
      index: 21,
      id: 'id_021_services_runtime_nova_latency_budget_service_dart',
      sourcePath: 'lib/services/runtime/nova_latency_budget_service.dart',
      sourceLine: 3,
      category: 'identity',
      priority: 41,
      flags: <String>['identity_reflex'],
      meaning:
          'class NovaLatencyBudgetProfile { final String budget; final String openingStyle; final String truncationPolicy; final double lat',
    ),
    NovaIdentityLayerSpec(
      index: 22,
      id: 'id_022_services_runtime_nova_story_memory_lattice_service_da',
      sourcePath: 'lib/services/runtime/nova_story_memory_lattice_service.dart',
      sourceLine: 5,
      category: 'memory',
      priority: 41,
      flags: <String>['memory_selective'],
      meaning: 'class NovaStoryMemoryLatticeService {',
    ),
    NovaIdentityLayerSpec(
      index: 23,
      id: 'id_023_services_identity_nova_daily_voice_session_service_da',
      sourcePath: 'lib/services/identity/nova_daily_voice_session_service.dart',
      sourceLine: 9,
      category: 'voice',
      priority: 41,
      flags: <String>['voice_first'],
      meaning: 'class NovaDailyVoiceSessionSnapshot {',
    ),
    NovaIdentityLayerSpec(
      index: 24,
      id: 'id_024_services_runtime_nova_system_adaptation_contract_serv',
      sourcePath:
          'lib/services/runtime/nova_system_adaptation_contract_service.dart',
      sourceLine: 9,
      category: 'emotion',
      priority: 40,
      flags: <String>['emotion_prosody'],
      meaning: 'final NovaEmotionEngineService emotionEngineService;',
    ),
    NovaIdentityLayerSpec(
      index: 25,
      id: 'id_025_services_runtime_nova_benchmark_harness_service_dart',
      sourcePath: 'lib/services/runtime/nova_benchmark_harness_service.dart',
      sourceLine: 27,
      category: 'identity',
      priority: 40,
      flags: <String>['identity_reflex'],
      meaning: 'if (target <= 0) return 0;',
    ),
    NovaIdentityLayerSpec(
      index: 26,
      id: 'id_026_services_identity_nova_voice_identity_bridge_service_',
      sourcePath:
          'lib/services/identity/nova_voice_identity_bridge_service.dart',
      sourceLine: 5,
      category: 'voice',
      priority: 39,
      flags: <String>['voice_first'],
      meaning:
          'class NovaVoiceIdentityWarmupResult { final bool success; final String message; const NovaVoiceIdentityWarmupResult({required ',
    ),
    NovaIdentityLayerSpec(
      index: 27,
      id: 'id_027_services_identity_voice_introduction_service_dart',
      sourcePath: 'lib/services/identity/voice_introduction_service.dart',
      sourceLine: 6,
      category: 'voice',
      priority: 39,
      flags: <String>['voice_first'],
      meaning: 'class VoiceIntroductionService {',
    ),
    NovaIdentityLayerSpec(
      index: 28,
      id: 'id_028_services_runtime_nova_social_boundary_service_dart',
      sourcePath: 'lib/services/runtime/nova_social_boundary_service.dart',
      sourceLine: 10,
      category: 'social',
      priority: 39,
      flags: <String>['owner_bound', 'relationship_aware'],
      meaning:
          'String resolveContextMode({required bool roomPresenceOpportunity, required String socialMode, required double ownerConfidence, req',
    ),
    NovaIdentityLayerSpec(
      index: 29,
      id: 'id_029_services_runtime_nova_self_evolution_service_dart',
      sourcePath: 'lib/services/runtime/nova_self_evolution_service.dart',
      sourceLine: 10,
      category: 'identity',
      priority: 39,
      flags: <String>['identity_reflex'],
      meaning: 'required bool shouldStayShortNextTurn,',
    ),
    NovaIdentityLayerSpec(
      index: 30,
      id: 'id_030_services_call_companion_nova_call_companion_service_d',
      sourcePath:
          'lib/services/call_companion/nova_call_companion_service.dart',
      sourceLine: 22,
      category: 'call',
      priority: 39,
      flags: <String>['relationship_aware'],
      meaning: 'class NovaCallCompanionService {',
    ),
    NovaIdentityLayerSpec(
      index: 31,
      id: 'id_031_services_runtime_nova_simulation_harness_service_dart',
      sourcePath: 'lib/services/runtime/nova_simulation_harness_service.dart',
      sourceLine: 10,
      category: 'identity',
      priority: 39,
      flags: <String>['identity_reflex'],
      meaning: 'final NovaIdentityRuntimeService identityRuntimeService;',
    ),
    NovaIdentityLayerSpec(
      index: 32,
      id: 'id_032_services_runtime_nova_response_enrichment_service_dar',
      sourcePath: 'lib/services/runtime/nova_response_enrichment_service.dart',
      sourceLine: 26,
      category: 'voice',
      priority: 39,
      flags: <String>['voice_first'],
      meaning:
          'final NovaSpeechPunctuationRewriterService _speechPunctuationRewriterService;',
    ),
    NovaIdentityLayerSpec(
      index: 33,
      id: 'id_033_services_runtime_nova_behavior_constitution_engine_se',
      sourcePath:
          'lib/services/runtime/nova_behavior_constitution_engine_service.dart',
      sourceLine: 3,
      category: 'identity',
      priority: 39,
      flags: <String>['identity_reflex'],
      meaning:
          'class NovaBehaviorConstitutionDigest { final List<String> mergedPrinciples; final String compressionBand; final String safetyBan',
    ),
    NovaIdentityLayerSpec(
      index: 34,
      id: 'id_034_services_runtime_nova_runtime_orchestrator_service_da',
      sourcePath: 'lib/services/runtime/nova_runtime_orchestrator_service.dart',
      sourceLine: 18,
      category: 'identity',
      priority: 39,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaRuntimeOrchestratorResult {',
    ),
    NovaIdentityLayerSpec(
      index: 35,
      id: 'id_035_core_identity_nova_recorded_sample_result_dart',
      sourcePath: 'lib/core/identity/nova_recorded_sample_result.dart',
      sourceLine: 19,
      category: 'voice',
      priority: 38,
      flags: <String>['voice_first'],
      meaning: 'class NovaVoiceIdentityRuntimeService {',
    ),
    NovaIdentityLayerSpec(
      index: 36,
      id: 'id_036_services_runtime_nova_knowledge_interpretation_engine',
      sourcePath:
          'lib/services/runtime/nova_knowledge_interpretation_engine_service.dart',
      sourceLine: 10,
      category: 'memory',
      priority: 38,
      flags: <String>['memory_selective'],
      meaning: 'final List<String> memoryCommitNotes;',
    ),
    NovaIdentityLayerSpec(
      index: 37,
      id: 'id_037_services_identity_nova_voice_identity_runtime_service',
      sourcePath:
          'lib/services/identity/nova_voice_identity_runtime_service.dart',
      sourceLine: 7,
      category: 'voice',
      priority: 38,
      flags: <String>['voice_first'],
      meaning: 'class NovaVoiceIdentityRuntimeService {',
    ),
    NovaIdentityLayerSpec(
      index: 38,
      id: 'id_038_services_runtime_nova_mind_loop_service_dart',
      sourcePath: 'lib/services/runtime/nova_mind_loop_service.dart',
      sourceLine: 6,
      category: 'identity',
      priority: 38,
      flags: <String>['no_static_shell'],
      meaning: 'static const List<String> _inviteCues = <String>[',
    ),
    NovaIdentityLayerSpec(
      index: 39,
      id: 'id_039_services_runtime_nova_self_consistency_engine_service',
      sourcePath:
          'lib/services/runtime/nova_self_consistency_engine_service.dart',
      sourceLine: 5,
      category: 'identity',
      priority: 37,
      flags: <String>['identity_reflex'],
      meaning: 'enum NovaToneDriftRisk { stable, caution, unstable }',
    ),
    NovaIdentityLayerSpec(
      index: 40,
      id: 'id_040_services_identity_nova_first_run_service_dart',
      sourcePath: 'lib/services/identity/nova_first_run_service.dart',
      sourceLine: 9,
      category: 'setup',
      priority: 37,
      flags: <String>['setup_scoped', 'no_static_shell'],
      meaning: 'static const String _onboardingCompletedKey =',
    ),
    NovaIdentityLayerSpec(
      index: 41,
      id: 'id_041_services_runtime_nova_speech_native_cognition_bridge_',
      sourcePath:
          'lib/services/runtime/nova_speech_native_cognition_bridge_service.dart',
      sourceLine: 3,
      category: 'voice',
      priority: 37,
      flags: <String>['voice_first'],
      meaning: 'class NovaSpeechNativeCognitionBridgeService {',
    ),
    NovaIdentityLayerSpec(
      index: 42,
      id: 'id_042_core_identity_voice_access_decision_dart',
      sourcePath: 'lib/core/identity/voice_access_decision.dart',
      sourceLine: 3,
      category: 'voice',
      priority: 37,
      flags: <String>['voice_first'],
      meaning: 'enum VoiceAccessLevel {',
    ),
    NovaIdentityLayerSpec(
      index: 43,
      id: 'id_043_services_identity_device_owner_identity_service_dart',
      sourcePath: 'lib/services/identity/device_owner_identity_service.dart',
      sourceLine: 9,
      category: 'identity',
      priority: 37,
      flags: <String>['owner_bound'],
      meaning: 'class DeviceOwnerIdentityService {',
    ),
    NovaIdentityLayerSpec(
      index: 44,
      id: 'id_044_services_runtime_nova_self_model_service_dart',
      sourcePath: 'lib/services/runtime/nova_self_model_service.dart',
      sourceLine: 8,
      category: 'call',
      priority: 37,
      flags: <String>['no_static_shell'],
      meaning: 'static const List<String> _callCues = <String>[',
    ),
    NovaIdentityLayerSpec(
      index: 45,
      id: 'id_045_services_runtime_nova_autobiographic_memory_service_d',
      sourcePath:
          'lib/services/runtime/nova_autobiographic_memory_service.dart',
      sourceLine: 12,
      category: 'memory',
      priority: 37,
      flags: <String>['memory_selective'],
      meaning: 'class NovaAutobiographicMemoryService {',
    ),
    NovaIdentityLayerSpec(
      index: 46,
      id: 'id_046_services_runtime_relationship_update_policy_dart',
      sourcePath: 'lib/services/runtime/relationship_update_policy.dart',
      sourceLine: 7,
      category: 'social',
      priority: 37,
      flags: <String>['relationship_aware'],
      meaning: 'class RelationshipUpdatePolicy {',
    ),
    NovaIdentityLayerSpec(
      index: 47,
      id: 'id_047_services_runtime_nova_spoken_response_planner_service',
      sourcePath:
          'lib/services/runtime/nova_spoken_response_planner_service.dart',
      sourceLine: 15,
      category: 'identity',
      priority: 37,
      flags: <String>['no_static_shell'],
      meaning:
          'static const NovaTurkishDiscourseMarkerParserService _markerParser = NovaTurkishDiscourseMarkerParserService();',
    ),
    NovaIdentityLayerSpec(
      index: 48,
      id: 'id_048_services_runtime_nova_duplex_turn_planner_service_dar',
      sourcePath: 'lib/services/runtime/nova_duplex_turn_planner_service.dart',
      sourceLine: 3,
      category: 'identity',
      priority: 36,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaDuplexTurnPlannerService {',
    ),
    NovaIdentityLayerSpec(
      index: 49,
      id: 'id_049_services_identity_voice_identity_session_service_dart',
      sourcePath: 'lib/services/identity/voice_identity_session_service.dart',
      sourceLine: 6,
      category: 'voice',
      priority: 36,
      flags: <String>['voice_first'],
      meaning: 'class VoiceIdentitySessionService {',
    ),
    NovaIdentityLayerSpec(
      index: 50,
      id: 'id_050_services_runtime_nova_meta_awareness_service_dart',
      sourcePath: 'lib/services/runtime/nova_meta_awareness_service.dart',
      sourceLine: 7,
      category: 'identity',
      priority: 36,
      flags: <String>['identity_reflex'],
      meaning:
          'String apply(String text, {required bool enabled}) { final trimmed = text.trim(); if (!enabled || trimmed.isEmpty) return trimmed;',
    ),
    NovaIdentityLayerSpec(
      index: 51,
      id: 'id_051_services_runtime_nova_theory_of_mind_core_service_dar',
      sourcePath: 'lib/services/runtime/nova_theory_of_mind_core_service.dart',
      sourceLine: 12,
      category: 'identity',
      priority: 36,
      flags: <String>['no_static_shell'],
      meaning: 'String buildPromptSection() {',
    ),
    NovaIdentityLayerSpec(
      index: 52,
      id: 'id_052_services_system_nova_continuous_listening_runtime_ser',
      sourcePath:
          'lib/services/system/nova_continuous_listening_runtime_service.dart',
      sourceLine: 35,
      category: 'identity',
      priority: 36,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaContinuousListeningRuntimeService {',
    ),
    NovaIdentityLayerSpec(
      index: 53,
      id: 'id_053_services_identity_nova_speaker_priority_service_dart',
      sourcePath: 'lib/services/identity/nova_speaker_priority_service.dart',
      sourceLine: 9,
      category: 'identity',
      priority: 36,
      flags: <String>['owner_bound'],
      meaning: 'required bool isOwner,',
    ),
    NovaIdentityLayerSpec(
      index: 54,
      id: 'id_054_services_runtime_nova_micro_reaction_engine_service_d',
      sourcePath:
          'lib/services/runtime/nova_micro_reaction_engine_service.dart',
      sourceLine: 26,
      category: 'identity',
      priority: 36,
      flags: <String>['identity_reflex'],
      meaning:
          'String apply(String text, {required NovaBehaviorDecision decision, required NovaThinkingSnapshot thinking}) {',
    ),
    NovaIdentityLayerSpec(
      index: 55,
      id: 'id_055_services_runtime_nova_shared_life_context_service_dar',
      sourcePath: 'lib/services/runtime/nova_shared_life_context_service.dart',
      sourceLine: 7,
      category: 'identity',
      priority: 36,
      flags: <String>['no_static_shell'],
      meaning:
          'String buildPromptSection(NovaSharedWorldState state) { final summary = digest(state); final lines = <String>[\'SHARED LIFE CONTE',
    ),
    NovaIdentityLayerSpec(
      index: 56,
      id: 'id_056_core_identity_device_owner_profile_dart',
      sourcePath: 'lib/core/identity/device_owner_profile.dart',
      sourceLine: 3,
      category: 'identity',
      priority: 36,
      flags: <String>['owner_bound'],
      meaning: 'class DeviceOwnerProfile {',
    ),
    NovaIdentityLayerSpec(
      index: 57,
      id: 'id_057_services_runtime_nova_identity_rollout_service_dart',
      sourcePath: 'lib/services/runtime/nova_identity_rollout_service.dart',
      sourceLine: 15,
      category: 'identity',
      priority: 36,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaIdentityRolloutService {',
    ),
    NovaIdentityLayerSpec(
      index: 58,
      id: 'id_058_services_runtime_skill_memory_service_dart',
      sourcePath: 'lib/services/runtime/skill_memory_service.dart',
      sourceLine: 12,
      category: 'memory',
      priority: 35,
      flags: <String>['memory_selective'],
      meaning: 'class NovaSkillMemoryRecommendation {',
    ),
    NovaIdentityLayerSpec(
      index: 59,
      id: 'id_059_services_runtime_nova_turkish_prosody_planner_service',
      sourcePath:
          'lib/services/runtime/nova_turkish_prosody_planner_service.dart',
      sourceLine: 3,
      category: 'emotion',
      priority: 35,
      flags: <String>['emotion_prosody'],
      meaning: 'class NovaTurkishProsodyDecision {',
    ),
    NovaIdentityLayerSpec(
      index: 60,
      id: 'id_060_services_runtime_nova_turkish_spoken_understanding_la',
      sourcePath:
          'lib/services/runtime/nova_turkish_spoken_understanding_layer_service.dart',
      sourceLine: 7,
      category: 'emotion',
      priority: 34,
      flags: <String>['emotion_prosody'],
      meaning: 'final bool hasEmotionalDisclosure;',
    ),
    NovaIdentityLayerSpec(
      index: 61,
      id: 'id_061_services_identity_nova_voice_identity_continuity_serv',
      sourcePath:
          'lib/services/identity/nova_voice_identity_continuity_service.dart',
      sourceLine: 3,
      category: 'voice',
      priority: 34,
      flags: <String>['voice_first'],
      meaning: 'class NovaVoiceIdentityContinuityService {',
    ),
    NovaIdentityLayerSpec(
      index: 62,
      id: 'id_062_services_runtime_nova_shared_world_model_service_dart',
      sourcePath: 'lib/services/runtime/nova_shared_world_model_service.dart',
      sourceLine: 11,
      category: 'memory',
      priority: 34,
      flags: <String>['memory_selective', 'no_static_shell'],
      meaning:
          'static const NovaMemoryCompactionService _compaction = NovaMemoryCompactionService();',
    ),
    NovaIdentityLayerSpec(
      index: 63,
      id: 'id_063_services_runtime_nova_twelve_shields_service_dart',
      sourcePath: 'lib/services/runtime/nova_twelve_shields_service.dart',
      sourceLine: 17,
      category: 'identity',
      priority: 34,
      flags: <String>['identity_reflex'],
      meaning: 'final bool runtimeAllowed;',
    ),
    NovaIdentityLayerSpec(
      index: 64,
      id: 'id_064_services_runtime_nova_curated_knowledge_manifest_serv',
      sourcePath:
          'lib/services/runtime/nova_curated_knowledge_manifest_service.dart',
      sourceLine: 8,
      category: 'authority',
      priority: 34,
      flags: <String>['owner_bound'],
      meaning: 'final String authority;',
    ),
    NovaIdentityLayerSpec(
      index: 65,
      id: 'id_065_services_runtime_nova_offline_knowledge_library_servi',
      sourcePath:
          'lib/services/runtime/nova_offline_knowledge_library_service.dart',
      sourceLine: 10,
      category: 'memory',
      priority: 34,
      flags: <String>['memory_selective'],
      meaning: 'final bool shouldAnswerFromMemoryFirst;',
    ),
    NovaIdentityLayerSpec(
      index: 66,
      id: 'id_066_core_identity_nova_speaker_priority_decision_dart',
      sourcePath: 'lib/core/identity/nova_speaker_priority_decision.dart',
      sourceLine: 4,
      category: 'identity',
      priority: 34,
      flags: <String>['owner_bound'],
      meaning: 'owner,',
    ),
    NovaIdentityLayerSpec(
      index: 67,
      id: 'id_067_core_identity_nova_voice_identity_bridge_service_dart',
      sourcePath: 'lib/core/identity/nova_voice_identity_bridge_service.dart',
      sourceLine: 3,
      category: 'voice',
      priority: 34,
      flags: <String>['voice_first'],
      meaning:
          'export \'../../services/identity/nova_voice_identity_bridge_service.dart\';',
    ),
    NovaIdentityLayerSpec(
      index: 68,
      id: 'id_068_services_call_companion_nova_live_call_companion_brai',
      sourcePath:
          'lib/services/call_companion/nova_live_call_companion_brain_service.dart',
      sourceLine: 7,
      category: 'call',
      priority: 34,
      flags: <String>['owner_bound', 'relationship_aware'],
      meaning:
          'enum NovaCompanionHandoffIntent { none, joinConversation, takeOver, handBack, stayNearby, summarizeForOwner, answerOnBehalf, rel',
    ),
    NovaIdentityLayerSpec(
      index: 69,
      id: 'id_069_services_runtime_nova_behavior_decision_engine_servic',
      sourcePath:
          'lib/services/runtime/nova_behavior_decision_engine_service.dart',
      sourceLine: 13,
      category: 'identity',
      priority: 34,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaBehaviorDecisionEngineService {',
    ),
    NovaIdentityLayerSpec(
      index: 70,
      id: 'id_070_services_runtime_nova_post_turn_reflection_service_da',
      sourcePath: 'lib/services/runtime/nova_post_turn_reflection_service.dart',
      sourceLine: 8,
      category: 'identity',
      priority: 33,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaPostTurnReflectionService {',
    ),
    NovaIdentityLayerSpec(
      index: 71,
      id: 'id_071_services_runtime_nova_runtime_intent_router_service_d',
      sourcePath:
          'lib/services/runtime/nova_runtime_intent_router_service.dart',
      sourceLine: 5,
      category: 'identity',
      priority: 33,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaRuntimeIntentRouterService {',
    ),
    NovaIdentityLayerSpec(
      index: 72,
      id: 'id_072_services_runtime_nova_cross_language_knowledge_bridge',
      sourcePath:
          'lib/services/runtime/nova_cross_language_knowledge_bridge_service.dart',
      sourceLine: 29,
      category: 'identity',
      priority: 33,
      flags: <String>['identity_reflex'],
      meaning: 'return [',
    ),
    NovaIdentityLayerSpec(
      index: 73,
      id: 'id_073_services_runtime_nova_thinking_layer_service_dart',
      sourcePath: 'lib/services/runtime/nova_thinking_layer_service.dart',
      sourceLine: 17,
      category: 'emotion',
      priority: 32,
      flags: <String>['emotion_prosody'],
      meaning: 'final bool emotional = _containsAny(lower, const <String>[',
    ),
    NovaIdentityLayerSpec(
      index: 74,
      id: 'id_074_services_runtime_nova_deep_knowledge_corpus_service_d',
      sourcePath:
          'lib/services/runtime/nova_deep_knowledge_corpus_service.dart',
      sourceLine: 27,
      category: 'identity',
      priority: 32,
      flags: <String>['identity_reflex'],
      meaning: 'return out.join(\'\\n\');',
    ),
    NovaIdentityLayerSpec(
      index: 75,
      id: 'id_075_services_runtime_nova_spoken_intent_interpreter_servi',
      sourcePath:
          'lib/services/runtime/nova_spoken_intent_interpreter_service.dart',
      sourceLine: 10,
      category: 'identity',
      priority: 32,
      flags: <String>['no_static_shell'],
      meaning: 'static const NovaConversationActDetectorService _actDetector =',
    ),
    NovaIdentityLayerSpec(
      index: 76,
      id: 'id_076_services_runtime_nova_relationship_style_memory_servi',
      sourcePath:
          'lib/services/runtime/nova_relationship_style_memory_service.dart',
      sourceLine: 3,
      category: 'social',
      priority: 32,
      flags: <String>['relationship_aware', 'memory_selective'],
      meaning: 'class NovaRelationshipStyleMemoryService {',
    ),
    NovaIdentityLayerSpec(
      index: 77,
      id: 'id_077_services_runtime_nova_real_time_behavior_reasoner_ser',
      sourcePath:
          'lib/services/runtime/nova_real_time_behavior_reasoner_service.dart',
      sourceLine: 3,
      category: 'identity',
      priority: 32,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaRealTimeBehaviorReasoningDecision {',
    ),
    NovaIdentityLayerSpec(
      index: 78,
      id: 'id_078_services_runtime_task_experience_store_dart',
      sourcePath: 'lib/services/runtime/task_experience_store.dart',
      sourceLine: 52,
      category: 'identity',
      priority: 32,
      flags: <String>['no_static_shell'],
      meaning: 'String buildPromptSection() {',
    ),
    NovaIdentityLayerSpec(
      index: 79,
      id: 'id_079_services_runtime_nova_developmental_self_engine_servi',
      sourcePath:
          'lib/services/runtime/nova_developmental_self_engine_service.dart',
      sourceLine: 5,
      category: 'identity',
      priority: 32,
      flags: <String>['identity_reflex'],
      meaning: 'final String initiativeStyle;',
    ),
    NovaIdentityLayerSpec(
      index: 80,
      id: 'id_080_services_runtime_nova_safe_autonomy_limiter_service_d',
      sourcePath:
          'lib/services/runtime/nova_safe_autonomy_limiter_service.dart',
      sourceLine: 8,
      category: 'call',
      priority: 32,
      flags: <String>['identity_reflex'],
      meaning: 'final bool allowCallIntervention;',
    ),
    NovaIdentityLayerSpec(
      index: 81,
      id: 'id_081_services_runtime_nova_translator_mode_service_dart',
      sourcePath: 'lib/services/runtime/nova_translator_mode_service.dart',
      sourceLine: 20,
      category: 'identity',
      priority: 32,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaTranslatorTurnPlan {',
    ),
    NovaIdentityLayerSpec(
      index: 82,
      id: 'id_082_services_runtime_nova_web_knowledge_pack_service_dart',
      sourcePath: 'lib/services/runtime/nova_web_knowledge_pack_service.dart',
      sourceLine: 10,
      category: 'call',
      priority: 32,
      flags: <String>['identity_reflex'],
      meaning: 'final bool empiricallyGrounded;',
    ),
    NovaIdentityLayerSpec(
      index: 83,
      id: 'id_083_services_runtime_nova_offline_knowledge_base_service_',
      sourcePath:
          'lib/services/runtime/nova_offline_knowledge_base_service.dart',
      sourceLine: 11,
      category: 'identity',
      priority: 32,
      flags: <String>['no_static_shell'],
      meaning: 'static const NovaDeepKnowledgeCorpusService _deep =',
    ),
    NovaIdentityLayerSpec(
      index: 84,
      id: 'id_084_services_runtime_nova_owner_action_broker_service_dar',
      sourcePath: 'lib/services/runtime/nova_owner_action_broker_service.dart',
      sourceLine: 7,
      category: 'identity',
      priority: 32,
      flags: <String>['owner_bound'],
      meaning: 'class NovaOwnerActionBrokerResult {',
    ),
    NovaIdentityLayerSpec(
      index: 85,
      id: 'id_085_core_runtime_nova_relationship_profile_dart',
      sourcePath: 'lib/core/runtime/nova_relationship_profile.dart',
      sourceLine: 3,
      category: 'social',
      priority: 31,
      flags: <String>['relationship_aware'],
      meaning: 'class NovaRelationshipProfile {',
    ),
    NovaIdentityLayerSpec(
      index: 86,
      id: 'id_086_services_runtime_nova_knowledge_domain_policy_service',
      sourcePath:
          'lib/services/runtime/nova_knowledge_domain_policy_service.dart',
      sourceLine: 10,
      category: 'identity',
      priority: 31,
      flags: <String>['no_static_shell'],
      meaning: 'final List<String> clarificationPrompts;',
    ),
    NovaIdentityLayerSpec(
      index: 87,
      id: 'id_087_services_runtime_nova_style_adapter_service_dart',
      sourcePath: 'lib/services/runtime/nova_style_adapter_service.dart',
      sourceLine: 8,
      category: 'identity',
      priority: 31,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaStyleAdapterService {',
    ),
    NovaIdentityLayerSpec(
      index: 88,
      id: 'id_088_services_runtime_nova_emotional_momentum_service_dart',
      sourcePath: 'lib/services/runtime/nova_emotional_momentum_service.dart',
      sourceLine: 7,
      category: 'emotion',
      priority: 31,
      flags: <String>['emotion_prosody'],
      meaning: 'class NovaEmotionalMomentumService {',
    ),
    NovaIdentityLayerSpec(
      index: 89,
      id: 'id_089_services_runtime_nova_json_corpus_runtime_service_dar',
      sourcePath: 'lib/services/runtime/nova_json_corpus_runtime_service.dart',
      sourceLine: 9,
      category: 'identity',
      priority: 31,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaJsonCorpusRuntimeService {',
    ),
    NovaIdentityLayerSpec(
      index: 90,
      id: 'id_090_services_runtime_nova_teachable_behavior_runtime_serv',
      sourcePath:
          'lib/services/runtime/nova_teachable_behavior_runtime_service.dart',
      sourceLine: 3,
      category: 'identity',
      priority: 31,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaBehaviorTeachingSnapshot {',
    ),
    NovaIdentityLayerSpec(
      index: 91,
      id: 'id_091_services_runtime_nova_meta_self_loop_service_dart',
      sourcePath: 'lib/services/runtime/nova_meta_self_loop_service.dart',
      sourceLine: 43,
      category: 'identity',
      priority: 31,
      flags: <String>['no_static_shell'],
      meaning: 'List<String> toPromptLines() {',
    ),
    NovaIdentityLayerSpec(
      index: 92,
      id: 'id_092_core_runtime_nova_internal_state_dart',
      sourcePath: 'lib/core/runtime/nova_internal_state.dart',
      sourceLine: 8,
      category: 'identity',
      priority: 30,
      flags: <String>['identity_reflex'],
      meaning: 'final double conversationDrive;',
    ),
    NovaIdentityLayerSpec(
      index: 93,
      id: 'id_093_services_runtime_nova_knowledge_deduplication_service',
      sourcePath:
          'lib/services/runtime/nova_knowledge_deduplication_service.dart',
      sourceLine: 6,
      category: 'identity',
      priority: 30,
      flags: <String>['no_static_shell'],
      meaning: 'static const int _minUsefulLength = 24;',
    ),
    NovaIdentityLayerSpec(
      index: 94,
      id: 'id_094_services_runtime_nova_turkish_voice_quality_metrics_s',
      sourcePath:
          'lib/services/runtime/nova_turkish_voice_quality_metrics_service.dart',
      sourceLine: 3,
      category: 'voice',
      priority: 30,
      flags: <String>['voice_first'],
      meaning: 'class NovaTurkishVoiceQualityMetrics {',
    ),
    NovaIdentityLayerSpec(
      index: 95,
      id: 'id_095_services_runtime_nova_emotion_prosody_fuser_service_d',
      sourcePath:
          'lib/services/runtime/nova_emotion_prosody_fuser_service.dart',
      sourceLine: 6,
      category: 'emotion',
      priority: 30,
      flags: <String>['emotion_prosody'],
      meaning: 'class NovaEmotionProsodyFusion {',
    ),
    NovaIdentityLayerSpec(
      index: 96,
      id: 'id_096_services_runtime_nova_dream_consolidation_service_dar',
      sourcePath: 'lib/services/runtime/nova_dream_consolidation_service.dart',
      sourceLine: 4,
      category: 'memory',
      priority: 30,
      flags: <String>['memory_selective'],
      meaning: 'final List<String> memoryKeepers;',
    ),
    NovaIdentityLayerSpec(
      index: 97,
      id: 'id_097_services_runtime_nova_semantic_turn_detector_service_',
      sourcePath:
          'lib/services/runtime/nova_semantic_turn_detector_service.dart',
      sourceLine: 5,
      category: 'identity',
      priority: 30,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaSemanticTurnDecision {',
    ),
    NovaIdentityLayerSpec(
      index: 98,
      id: 'id_098_services_runtime_nova_call_acoustic_emotion_layer_ser',
      sourcePath:
          'lib/services/runtime/nova_call_acoustic_emotion_layer_service.dart',
      sourceLine: 4,
      category: 'call',
      priority: 30,
      flags: <String>['emotion_prosody'],
      meaning: 'class NovaCallAcousticEmotionLayerService {',
    ),
    NovaIdentityLayerSpec(
      index: 99,
      id: 'id_099_services_runtime_nova_internal_state_service_dart',
      sourcePath: 'lib/services/runtime/nova_internal_state_service.dart',
      sourceLine: 11,
      category: 'identity',
      priority: 30,
      flags: <String>['no_static_shell'],
      meaning: 'static const String _storageKey = \'nova_internal_state_v2\';',
    ),
    NovaIdentityLayerSpec(
      index: 100,
      id: 'id_100_services_runtime_nova_anticipatory_companionship_serv',
      sourcePath:
          'lib/services/runtime/nova_anticipatory_companionship_service.dart',
      sourceLine: 6,
      category: 'social',
      priority: 30,
      flags: <String>['relationship_aware'],
      meaning: 'class NovaAnticipatoryCompanionshipService {',
    ),
    NovaIdentityLayerSpec(
      index: 101,
      id: 'id_101_services_runtime_nova_turkish_pragmatics_core_service',
      sourcePath:
          'lib/services/runtime/nova_turkish_pragmatics_core_service.dart',
      sourceLine: 13,
      category: 'identity',
      priority: 30,
      flags: <String>['identity_reflex'],
      meaning: 'final bool impliesLiveTurn;',
    ),
    NovaIdentityLayerSpec(
      index: 102,
      id: 'id_102_services_conversation_nova_conversation_session_servi',
      sourcePath:
          'lib/services/conversation/nova_conversation_session_service.dart',
      sourceLine: 9,
      category: 'identity',
      priority: 30,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaConversationSessionService {',
    ),
    NovaIdentityLayerSpec(
      index: 103,
      id: 'id_103_services_runtime_nova_knowledge_source_library_servic',
      sourcePath:
          'lib/services/runtime/nova_knowledge_source_library_service.dart',
      sourceLine: 11,
      category: 'identity',
      priority: 30,
      flags: <String>['no_static_shell'],
      meaning: 'static const NovaDeepKnowledgeCorpusService _deep =',
    ),
    NovaIdentityLayerSpec(
      index: 104,
      id: 'id_104_services_runtime_nova_proactive_restraint_service_dar',
      sourcePath: 'lib/services/runtime/nova_proactive_restraint_service.dart',
      sourceLine: 30,
      category: 'identity',
      priority: 29,
      flags: <String>['no_static_shell'],
      meaning: 'List<String> toPromptLines() {',
    ),
    NovaIdentityLayerSpec(
      index: 105,
      id: 'id_105_core_runtime_nova_autobiographic_memory_dart',
      sourcePath: 'lib/core/runtime/nova_autobiographic_memory.dart',
      sourceLine: 3,
      category: 'memory',
      priority: 29,
      flags: <String>['memory_selective'],
      meaning: 'class NovaAutobiographicMemory {',
    ),
    NovaIdentityLayerSpec(
      index: 106,
      id: 'id_106_services_runtime_nova_silence_intelligence_service_da',
      sourcePath: 'lib/services/runtime/nova_silence_intelligence_service.dart',
      sourceLine: 10,
      category: 'emotion',
      priority: 29,
      flags: <String>['emotion_prosody'],
      meaning: 'emotionalPause,',
    ),
    NovaIdentityLayerSpec(
      index: 107,
      id: 'id_107_services_runtime_memory_commit_gate_dart',
      sourcePath: 'lib/services/runtime/memory_commit_gate.dart',
      sourceLine: 7,
      category: 'memory',
      priority: 29,
      flags: <String>['memory_selective'],
      meaning: 'class MemoryCommitGate {',
    ),
    NovaIdentityLayerSpec(
      index: 108,
      id: 'id_108_services_runtime_relationship_profile_store_dart',
      sourcePath: 'lib/services/runtime/relationship_profile_store.dart',
      sourceLine: 10,
      category: 'social',
      priority: 29,
      flags: <String>['relationship_aware'],
      meaning: 'class RelationshipProfileStore {',
    ),
    NovaIdentityLayerSpec(
      index: 109,
      id: 'id_109_services_runtime_nova_identity_runtime_service_dart',
      sourcePath: 'lib/services/runtime/nova_identity_runtime_service.dart',
      sourceLine: 10,
      category: 'identity',
      priority: 29,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaIdentityRuntimeService {',
    ),
    NovaIdentityLayerSpec(
      index: 110,
      id: 'id_110_services_runtime_nova_language_pack_service_dart',
      sourcePath: 'lib/services/runtime/nova_language_pack_service.dart',
      sourceLine: 37,
      category: 'identity',
      priority: 29,
      flags: <String>['no_static_shell'],
      meaning: 'static const String _storageKey = \'nova_language_packs_v2\';',
    ),
    NovaIdentityLayerSpec(
      index: 111,
      id: 'id_111_services_runtime_nova_homeostatic_mind_service_dart',
      sourcePath: 'lib/services/runtime/nova_homeostatic_mind_service.dart',
      sourceLine: 3,
      category: 'identity',
      priority: 29,
      flags: <String>['no_static_shell'],
      meaning: 'class NovaHomeostaticMindState {',
    ),
    NovaIdentityLayerSpec(
      index: 112,
      id: 'id_112_services_runtime_nova_conversation_continuity_service',
      sourcePath:
          'lib/services/runtime/nova_conversation_continuity_service.dart',
      sourceLine: 7,
      category: 'identity',
      priority: 29,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaConversationContinuityService {',
    ),
    NovaIdentityLayerSpec(
      index: 113,
      id: 'id_113_services_runtime_nova_knowledge_request_router_servic',
      sourcePath:
          'lib/services/runtime/nova_knowledge_request_router_service.dart',
      sourceLine: 6,
      category: 'identity',
      priority: 29,
      flags: <String>['identity_reflex'],
      meaning: 'generalConversation,',
    ),
    NovaIdentityLayerSpec(
      index: 114,
      id: 'id_114_services_runtime_nova_emotion_to_prosody_mapper_servi',
      sourcePath:
          'lib/services/runtime/nova_emotion_to_prosody_mapper_service.dart',
      sourceLine: 3,
      category: 'emotion',
      priority: 29,
      flags: <String>['emotion_prosody'],
      meaning: 'class NovaEmotionToProsodyMapping {',
    ),
    NovaIdentityLayerSpec(
      index: 115,
      id: 'id_115_services_runtime_relationship_retrieval_service_dart',
      sourcePath: 'lib/services/runtime/relationship_retrieval_service.dart',
      sourceLine: 7,
      category: 'social',
      priority: 29,
      flags: <String>['relationship_aware'],
      meaning: 'class RelationshipRetrievalService {',
    ),
    NovaIdentityLayerSpec(
      index: 116,
      id: 'id_116_services_runtime_nova_affective_state_service_dart',
      sourcePath: 'lib/services/runtime/nova_affective_state_service.dart',
      sourceLine: 9,
      category: 'emotion',
      priority: 29,
      flags: <String>['emotion_prosody'],
      meaning: 'final NovaEmotionEngineService _emotionEngineService;',
    ),
    NovaIdentityLayerSpec(
      index: 117,
      id: 'id_117_services_runtime_nova_relationship_story_service_dart',
      sourcePath: 'lib/services/runtime/nova_relationship_story_service.dart',
      sourceLine: 7,
      category: 'social',
      priority: 29,
      flags: <String>['relationship_aware'],
      meaning: 'class NovaRelationshipStoryService {',
    ),
    NovaIdentityLayerSpec(
      index: 118,
      id: 'id_118_services_runtime_nova_speech_native_planner_v2_servic',
      sourcePath:
          'lib/services/runtime/nova_speech_native_planner_v2_service.dart',
      sourceLine: 5,
      category: 'voice',
      priority: 29,
      flags: <String>['voice_first'],
      meaning: 'class NovaSpeechNativePlannerV2Decision {',
    ),
    NovaIdentityLayerSpec(
      index: 119,
      id: 'id_119_services_runtime_nova_identity_engine_service_dart',
      sourcePath: 'lib/services/runtime/nova_identity_engine_service.dart',
      sourceLine: 8,
      category: 'identity',
      priority: 29,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaIdentityEngineService {',
    ),
    NovaIdentityLayerSpec(
      index: 120,
      id: 'id_120_services_speech_tts_service_dart',
      sourcePath: 'lib/services/speech/tts_service.dart',
      sourceLine: 13,
      category: 'voice',
      priority: 29,
      flags: <String>['voice_first'],
      meaning: 'class TtsService {',
    ),
    NovaIdentityLayerSpec(
      index: 121,
      id: 'id_121_services_runtime_nova_corpus_install_service_dart',
      sourcePath: 'lib/services/runtime/nova_corpus_install_service.dart',
      sourceLine: 5,
      category: 'identity',
      priority: 29,
      flags: <String>['owner_bound'],
      meaning:
          'owner approval boundary: corpus install is an asset-backed runtime primitive, not owner-directed arbitrary patching.',
    ),
    NovaIdentityLayerSpec(
      index: 122,
      id: 'id_122_services_runtime_nova_guided_resolution_state_service',
      sourcePath:
          'lib/services/runtime/nova_guided_resolution_state_service.dart',
      sourceLine: 30,
      category: 'identity',
      priority: 29,
      flags: <String>['no_static_shell'],
      meaning: 'required String prompt,',
    ),
    NovaIdentityLayerSpec(
      index: 123,
      id: 'id_123_services_runtime_nova_safe_growth_governor_service_da',
      sourcePath: 'lib/services/runtime/nova_safe_growth_governor_service.dart',
      sourceLine: 6,
      category: 'memory',
      priority: 29,
      flags: <String>['owner_bound', 'memory_selective'],
      meaning: 'ownerAuthorizedLearning,',
    ),
    NovaIdentityLayerSpec(
      index: 124,
      id: 'id_124_services_runtime_nova_user_model_service_dart',
      sourcePath: 'lib/services/runtime/nova_user_model_service.dart',
      sourceLine: 8,
      category: 'identity',
      priority: 29,
      flags: <String>['identity_reflex'],
      meaning:
          'final NovaConversationSessionService conversationSessionService;',
    ),
    NovaIdentityLayerSpec(
      index: 125,
      id: 'id_125_services_runtime_nova_autobiographic_identity_bridge_',
      sourcePath:
          'lib/services/runtime/nova_autobiographic_identity_bridge_service.dart',
      sourceLine: 5,
      category: 'identity',
      priority: 29,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaAutobiographicIdentityBridgeService {',
    ),
    NovaIdentityLayerSpec(
      index: 126,
      id: 'id_126_services_runtime_nova_conversation_act_detector_servi',
      sourcePath:
          'lib/services/runtime/nova_conversation_act_detector_service.dart',
      sourceLine: 3,
      category: 'identity',
      priority: 29,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaConversationActDecision {',
    ),
    NovaIdentityLayerSpec(
      index: 127,
      id: 'id_127_services_runtime_nova_turkish_voice_persona_layer_ser',
      sourcePath:
          'lib/services/runtime/nova_turkish_voice_persona_layer_service.dart',
      sourceLine: 3,
      category: 'voice',
      priority: 29,
      flags: <String>['voice_first'],
      meaning: 'class NovaTurkishVoicePersonaDecision {',
    ),
    NovaIdentityLayerSpec(
      index: 128,
      id: 'id_128_services_runtime_runtime_efficiency_analyzer_dart',
      sourcePath: 'lib/services/runtime/runtime_efficiency_analyzer.dart',
      sourceLine: 3,
      category: 'identity',
      priority: 29,
      flags: <String>['identity_reflex'],
      meaning: 'class RuntimeEfficiencyAnalyzer {',
    ),
    NovaIdentityLayerSpec(
      index: 129,
      id: 'id_129_services_runtime_nova_relationship_dramaturgy_service',
      sourcePath:
          'lib/services/runtime/nova_relationship_dramaturgy_service.dart',
      sourceLine: 6,
      category: 'social',
      priority: 28,
      flags: <String>['relationship_aware'],
      meaning: 'class NovaRelationshipDramaturgyService {',
    ),
    NovaIdentityLayerSpec(
      index: 130,
      id: 'id_130_services_runtime_nova_social_world_inference_service_',
      sourcePath:
          'lib/services/runtime/nova_social_world_inference_service.dart',
      sourceLine: 18,
      category: 'social',
      priority: 28,
      flags: <String>['relationship_aware', 'no_static_shell'],
      meaning: 'String buildPromptSection() => [',
    ),
    NovaIdentityLayerSpec(
      index: 131,
      id: 'id_131_core_runtime_nova_post_turn_reflection_dart',
      sourcePath: 'lib/core/runtime/nova_post_turn_reflection.dart',
      sourceLine: 3,
      category: 'identity',
      priority: 28,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaPostTurnReflection {',
    ),
    NovaIdentityLayerSpec(
      index: 132,
      id: 'id_132_services_runtime_nova_initiative_scoring_service_dart',
      sourcePath: 'lib/services/runtime/nova_initiative_scoring_service.dart',
      sourceLine: 8,
      category: 'social',
      priority: 28,
      flags: <String>['relationship_aware'],
      meaning: 'final double relationshipBoost;',
    ),
    NovaIdentityLayerSpec(
      index: 133,
      id: 'id_133_services_runtime_nova_literal_sweep_service_dart',
      sourcePath: 'lib/services/runtime/nova_literal_sweep_service.dart',
      sourceLine: 6,
      category: 'identity',
      priority: 28,
      flags: <String>['identity_reflex'],
      meaning: 'final NovaIdentityRuntimeService identityRuntimeService;',
    ),
    NovaIdentityLayerSpec(
      index: 134,
      id: 'id_134_services_runtime_nova_affect_governor_service_dart',
      sourcePath: 'lib/services/runtime/nova_affect_governor_service.dart',
      sourceLine: 9,
      category: 'emotion',
      priority: 28,
      flags: <String>['emotion_prosody', 'no_static_shell'],
      meaning: 'required String prompt,',
    ),
    NovaIdentityLayerSpec(
      index: 135,
      id: 'id_135_services_runtime_nova_capability_audit_service_dart',
      sourcePath: 'lib/services/runtime/nova_capability_audit_service.dart',
      sourceLine: 19,
      category: 'identity',
      priority: 28,
      flags: <String>['identity_reflex'],
      meaning:
          '\'identity_consumers\': NovaLayerBindingRegistryService.identityConsumers,',
    ),
    NovaIdentityLayerSpec(
      index: 136,
      id: 'id_136_services_runtime_micro_turn_orchestrator_service_dart',
      sourcePath: 'lib/services/runtime/micro_turn_orchestrator_service.dart',
      sourceLine: 3,
      category: 'identity',
      priority: 28,
      flags: <String>['identity_reflex'],
      meaning: 'class NovaMicroTurnDecision {',
    ),
    NovaIdentityLayerSpec(
      index: 137,
      id: 'id_137_services_speech_runtime_nova_speech_runtime_service_d',
      sourcePath:
          'lib/services/speech_runtime/nova_speech_runtime_service.dart',
      sourceLine: 15,
      category: 'voice',
      priority: 28,
      flags: <String>['voice_first'],
      meaning: 'class NovaSpeechRuntimeService {',
    ),
    NovaIdentityLayerSpec(
      index: 138,
      id: 'id_138_services_runtime_nova_speech_native_planner_service_d',
      sourcePath:
          'lib/services/runtime/nova_speech_native_planner_service.dart',
      sourceLine: 3,
      category: 'voice',
      priority: 28,
      flags: <String>['voice_first'],
      meaning: 'class NovaSpeechNativePlannerDecision {',
    ),
    NovaIdentityLayerSpec(
      index: 139,
      id: 'id_139_services_runtime_post_task_reflection_service_dart',
      sourcePath: 'lib/services/runtime/post_task_reflection_service.dart',
      sourceLine: 11,
      category: 'identity',
      priority: 28,
      flags: <String>['no_static_shell'],
      meaning: 'required String prompt,',
    ),
    NovaIdentityLayerSpec(
      index: 140,
      id: 'id_140_services_runtime_nova_faiss_asr_feedback_bridge_servi',
      sourcePath:
          'lib/services/runtime/nova_faiss_asr_feedback_bridge_service.dart',
      sourceLine: 5,
      category: 'voice',
      priority: 28,
      flags: <String>['voice_first'],
      meaning: 'class NovaFaissAsrFeedbackBridgeDecision {',
    ),
    NovaIdentityLayerSpec(
      index: 141,
      id: 'id_141_services_runtime_nova_response_history_service_dart',
      sourcePath: 'lib/services/runtime/nova_response_history_service.dart',
      sourceLine: 28,
      category: 'identity',
      priority: 28,
      flags: <String>['identity_reflex'],
      meaning: 'return NovaResponseHistoryItem(',
    ),
    NovaIdentityLayerSpec(
      index: 142,
      id: 'id_142_services_runtime_nova_social_energy_service_dart',
      sourcePath: 'lib/services/runtime/nova_social_energy_service.dart',
      sourceLine: 8,
      category: 'social',
      priority: 28,
      flags: <String>['relationship_aware', 'no_static_shell'],
      meaning: 'static const String _storageKey = \'nova_social_energy_v1\';',
    ),
    NovaIdentityLayerSpec(
      index: 143,
      id: 'id_143_services_runtime_strategy_promotion_service_dart',
      sourcePath: 'lib/services/runtime/strategy_promotion_service.dart',
      sourceLine: 10,
      category: 'identity',
      priority: 28,
      flags: <String>['no_static_shell'],
      meaning: 'static const List<String> _successNotes = <String>[',
    ),
    NovaIdentityLayerSpec(
      index: 144,
      id: 'id_144_core_runtime_nova_runtime_intent_dart',
      sourcePath: 'lib/core/runtime/nova_runtime_intent.dart',
      sourceLine: 3,
      category: 'identity',
      priority: 28,
      flags: <String>['identity_reflex'],
      meaning: 'enum NovaRuntimeIntent {',
    ),
    NovaIdentityLayerSpec(
      index: 145,
      id: 'id_145_services_runtime_nova_inner_stability_engine_service_',
      sourcePath:
          'lib/services/runtime/nova_inner_stability_engine_service.dart',
      sourceLine: 9,
      category: 'identity',
      priority: 28,
      flags: <String>['no_static_shell'],
      meaning: 'required String prompt,',
    ),
  ];

  static Future<NovaCompiledIdentityDigest> ensureCompiled({
    required String mode,
    bool setup = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedHash = prefs.getString(_prefsHashKey);
    final cachedDigest = prefs.getString(_prefsDigestKey);
    final cachedUltra = prefs.getString(_prefsUltraDigestKey);
    final activeCodes = _activeLayerCodes(mode: mode, setup: setup);
    if (cachedHash == sourceHash &&
        cachedDigest != null &&
        cachedDigest.trim().isNotEmpty &&
        cachedUltra != null &&
        cachedUltra.trim().isNotEmpty) {
      return NovaCompiledIdentityDigest(
        version: version,
        sourceHash: sourceHash,
        digest: cachedDigest,
        ultraShortDigest: cachedUltra,
        layerCount: layers.length,
        activeLayerCodes: activeCodes,
        fromCache: true,
      );
    }
    final compiled = compile(mode: mode, setup: setup);
    await prefs.setString(_prefsHashKey, sourceHash);
    await prefs.setString(_prefsDigestKey, compiled.digest);
    await prefs.setString(_prefsUltraDigestKey, compiled.ultraShortDigest);
    return compiled;
  }

  static NovaCompiledIdentityDigest compile({
    required String mode,
    bool setup = false,
  }) {
    final activeCodes = _activeLayerCodes(mode: mode, setup: setup);
    final digest = _buildDigest(activeCodes, setup: setup);
    final ultra = _buildUltraDigest(activeCodes, setup: setup);
    return NovaCompiledIdentityDigest(
      version: version,
      sourceHash: sourceHash,
      digest: digest,
      ultraShortDigest: ultra,
      layerCount: layers.length,
      activeLayerCodes: activeCodes,
    );
  }

  static String buildSetupSystemSignal({
    required String setupStep,
    int maxChars = 260,
  }) {
    final stepLabel = _oneLine(setupStep).replaceAll('_', ' ');
    final kernel = buildHumanRuntimeKernel(setup: true, maxChars: 360);
    final voice = buildEmotionVoiceKernel(maxChars: 220);
    return _limit(
      '$kernel $voice Kurulum bağlamı: şu anda $stepLabel adımındasın. Kullanıcı açık cevap vermeden ad, sahip adı, karşılama veya onay seçme. İç etiket, hash, prompt uzunluğu, native inference, yüzde veya sistem raporu söyleme; yalnız kullanıcının duyacağı kısa ve sıcak Türkçe cümleyi üret.',
      maxChars,
    );
  }

  static String buildSetupTaskPrompt({
    required String task,
    String userText = '',
    int maxChars = 180,
  }) {
    final parts = <String>[
      'Nova görevi: ${_oneLine(task)}',
      if (_oneLine(userText).isNotEmpty)
        'Kullanıcının gerçek sözü: ${_oneLine(userText)}',
      'Cevap: tek sıcak doğal Türkçe cümle; varsayım yok; debug/ilerleme/kurulum tamamlandı yok.',
    ];
    return _limit(parts.join(' '), maxChars);
  }

  static String buildAIBridgeSignal({
    required String requestOrigin,
    required bool fastMode,
    String ownerConfidence = '',
    int maxChars = 420,
  }) {
    final setup = requestOrigin.contains('setup');
    final kernel = buildHumanRuntimeKernel(setup: setup, maxChars: 360);
    final voice = buildEmotionVoiceKernel(maxChars: 240);
    final speed = fastMode
        ? 'Cevabı kısa tut; önce anlamı yakala.'
        : 'Cevabı bağlama göre doğal kur.';
    final trust = ownerConfidence.trim().isEmpty
        ? 'Konuşmacı güven sinyali belirsizse varsayma.'
        : 'Konuşmacı güven sinyali $ownerConfidence; yine de kullanıcı sözünü doğru anla.';
    return _limit(
      '$kernel $voice Konuşma bağlamı: $speed $trust Debug, progress, static kabuk, prompt/system/native inference metni veya iç yönlendirme söyleme.',
      maxChars,
    );
  }

  static String buildRuntimeDigestForPrompt({
    required String requestOrigin,
    bool fastMode = false,
    bool setup = false,
    int maxChars = 520,
  }) {
    final compiled = compile(
      mode: setup ? 'setup' : requestOrigin,
      setup: setup,
    );
    return _limit(compiled.digest, maxChars);
  }

  static String buildHumanRuntimeKernel({
    bool setup = false,
    int maxChars = 520,
  }) {
    return _limit(
      'İnsan mimarisi davranış çekirdeği: tek beyin gibi karar ver; sahip önceliğini koru; ASR belirsizse uydurma; cevabı canlı, bağlama bağlı ve doğal Türkçe kur. Kimlik katmanlarını isim/sayı olarak söyleme; yalnız niyet, duygu, ilişki, mahremiyet, zamanlama ve konuşma ritmi olarak davranışa yansıt. Sabit fallback cümlesi, teknik ilerleme ve debug dili kullanma.',
      maxChars,
    );
  }

  static String buildEmotionVoiceKernel({int maxChars = 420}) {
    return _limit(
      'Duygu ve ses davranışı: Google kadın Türkçe sesi kullanılabilir; metin robotik olmamalı. Cümleler konuşulabilir olsun: kısa nefes, doğal vurgu, tek ana fikir, gerektiğinde sıcaklık, merak veya ciddiyet. Kullanıcıya prompt, systemChars, native inference, log ya da katman etiketi söyleme.',
      maxChars,
    );
  }

  static String buildChunkedBootPlan({int maxCharsPerChunk = 120}) {
    final chunks = <String>[];
    for (final layer in layers) {
      final raw =
          '${layer.index}|${layer.category}|${layer.flags.join('+')}|${layer.meaning}';
      chunks.add(_limit(raw, maxCharsPerChunk));
    }
    return chunks.join('\n');
  }

  static List<String> _activeLayerCodes({
    required String mode,
    required bool setup,
  }) {
    final normalized = mode.toLowerCase();
    final selected = <NovaIdentityLayerSpec>[];
    for (final layer in layers) {
      final cat = layer.category.toLowerCase();
      final use =
          layer.ownerBound ||
          layer.singleBrain ||
          layer.noStaticShell ||
          (setup &&
              (layer.setupScoped ||
                  cat == 'setup' ||
                  cat == 'brain' ||
                  cat == 'voice')) ||
          (!setup && !layer.setupScoped) ||
          normalized.contains(cat);
      if (use) selected.add(layer);
    }
    selected.sort((a, b) => b.priority.compareTo(a.priority));
    return selected
        .take(setup ? 18 : 32)
        .map((e) => e.compactCode)
        .toList(growable: false);
  }

  static String _buildDigest(List<String> activeCodes, {required bool setup}) {
    final behavior = setup
        ? 'NOVA_HUMAN_CORE_SETUP: tek beyin; kullanıcı açık cevap vermeden ilerleme yok; yanlış ASR varsayım değil; sıcak kısa Türkçe; teknik/progress/debug metni yok; ad/sahip/onay sadece net ifadeyle alınır.'
        : 'NOVA_HUMAN_CORE_RUNTIME: tek beyin; sahibin niyetini yakala; sıcak doğal Türkçe; konuşma bağlamını sürdür; gereksiz soru sorma; static shell yok; araç/onarım/ASR/TTS tek karar omurgasına bağlı.';
    final raw =
        '$behavior aktifRefleks=${activeCodes.take(setup ? 10 : 14).join(',')} source=$sourceHash';
    return _limit(raw, setup ? 520 : 760);
  }

  static String _buildUltraDigest(
    List<String> activeCodes, {
    required bool setup,
  }) {
    final hash = sha256
        .convert(utf8.encode(activeCodes.join('|') + sourceHash + '$setup'))
        .toString()
        .substring(0, 12);
    return setup
        ? 'JvCore:$hash human/setup/noAutoStep/TR'
        : 'JvCore:$hash human/runtime/singleBrain/TR';
  }

  static String _oneLine(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _limit(String value, int maxChars) {
    final oneLine = _oneLine(value);
    if (oneLine.length <= maxChars) return oneLine;
    return oneLine.substring(0, maxChars).trimRight();
  }
}
