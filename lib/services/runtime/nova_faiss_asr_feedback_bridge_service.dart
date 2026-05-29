// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_faiss_context_bias_bridge_service.dart';

class NovaFaissAsrFeedbackBridgeDecision {
  final List<String> biasTerms;
  final List<String> boostedEntities;

  const NovaFaissAsrFeedbackBridgeDecision({
    required this.biasTerms,
    required this.boostedEntities,
  });

  String buildPromptSection() => biasTerms.isEmpty
      ? 'FAISS→ASR GERİ BESLEME: ek terim yok.'
      : 'FAISS→ASR GERİ BESLEME: bias=' +
            biasTerms.join(' | ') +
            '; boost=' +
            boostedEntities.join(' | ');
}

class NovaFaissAsrFeedbackBridgeService {
  const NovaFaissAsrFeedbackBridgeService();
  static const NovaFaissContextBiasBridgeService _base =
      NovaFaissContextBiasBridgeService();

  NovaFaissAsrFeedbackBridgeDecision resolve({
    required List<String> semanticMemoryContents,
    required List<String> recentEntities,
    required String relationshipLabel,
    required String speakerName,
  }) {
    final boosted = <String>{
      ...recentEntities.where((e) => e.trim().isNotEmpty),
    };
    if (speakerName.trim().isNotEmpty) boosted.add(speakerName.trim());
    final terms = _base.buildBiasTerms(
      semanticMemoryContents: semanticMemoryContents,
      recentEntities: boosted.toList(growable: false),
      relationshipLabel: relationshipLabel,
    );
    return NovaFaissAsrFeedbackBridgeDecision(
      biasTerms: terms,
      boostedEntities: boosted.take(10).toList(growable: false),
    );
  }
}
