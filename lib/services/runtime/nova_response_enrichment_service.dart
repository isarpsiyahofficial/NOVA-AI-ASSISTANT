// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_RESPONSE_ENRICHMENT_METADATA_ONLY_V4
import '../../core/conversation/nova_dialogue_policy.dart';
import '../../core/conversation/nova_turn_decision.dart';
import '../../core/runtime/nova_affect_governor_state.dart';
import '../../core/runtime/nova_autobiographic_memory.dart';
import '../../core/runtime/nova_behavior_decision.dart';
import '../../core/runtime/nova_internal_state.dart';
import '../../core/runtime/nova_relationship_profile.dart';
import '../../core/runtime/nova_relationship_story_arc.dart';
import '../../core/runtime/nova_shared_world_state.dart';
import '../../core/runtime/nova_style_profile.dart';
import '../../core/runtime/nova_thinking_models.dart';

class NovaResponseEnrichmentService {
  const NovaResponseEnrichmentService();

  String enrich(
    String rawText, {
    required NovaThinkingSnapshot thinking,
    required NovaInternalState internalState,
    required List<String> recentResponses,
    required NovaTurnDecision turnDecision,
    required NovaDialoguePolicy dialoguePolicy,
    required NovaStyleProfile styleProfile,
    required NovaBehaviorDecision behaviorDecision,
    required Map<String, dynamic> continuitySnapshot,
    required Map<String, dynamic> emotionalMomentum,
    NovaRelationshipProfile? relationshipProfile,
    List<String> constitutionPrinciples = const <String>[],
    List<String> rituals = const <String>[],
    Map<String, dynamic>? anticipatoryPlan,
    NovaSharedWorldState? sharedWorldState,
    NovaAutobiographicMemory? autobiographicMemory,
    NovaRelationshipStoryArc? relationshipStoryArc,
    NovaAffectGovernorState? affectGovernor,
  }) {
    // Runtime enrichment is no longer a lexical text stage. Personality, tone,
    // relationship, memory, and prosody must be supplied before model generation
    // as structured context. Final model text may only be trimmed here.
    return rawText.trim();
  }
}

extension NovaResponseEnrichmentVoiceExtension on NovaResponseEnrichmentService {
  String buildVoiceAwarePrefix({
    required bool shouldStayShort,
    required String backchannelPhrase,
    required bool shouldEncourageContinue,
  }) {
    // No runtime prefix is allowed after model generation.
    return '';
  }
}
