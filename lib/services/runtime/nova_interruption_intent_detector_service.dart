// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaInterruptionIntentDecision {
  final bool wantsToTakeTurn;
  final bool wantsClarification;
  final bool isSoftInterruption;
  final String label;

  const NovaInterruptionIntentDecision({
    required this.wantsToTakeTurn,
    required this.wantsClarification,
    required this.isSoftInterruption,
    required this.label,
  });

  String buildPromptSection() {
    return 'BÖLME NİYETİ ALGILAMA: etiket=$label; sözAlma=$wantsToTakeTurn; netleştirme=$wantsClarification; yumuşakBölme=$isSoftInterruption';
  }
}

class NovaInterruptionIntentDetectorService {
  const NovaInterruptionIntentDetectorService();

  NovaInterruptionIntentDecision detect(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const NovaInterruptionIntentDecision(
        wantsToTakeTurn: false,
        wantsClarification: false,
        isSoftInterruption: false,
        label: 'none',
      );
    }
    final clarification =
        normalized.contains('dur') ||
        normalized.contains('bir dakika') ||
        normalized.contains('anlamadım') ||
        normalized.contains('yanlış') ||
        normalized.contains('tekrar');
    final soft =
        normalized.contains('hmm') ||
        normalized.contains('evet') ||
        normalized.contains('tamam') ||
        normalized.contains('bir saniye');
    final takeTurn =
        clarification ||
        normalized.contains('?') ||
        normalized.contains('sence') ||
        normalized.contains('dinle');
    return NovaInterruptionIntentDecision(
      wantsToTakeTurn: takeTurn,
      wantsClarification: clarification,
      isSoftInterruption: soft && !clarification,
      label: clarification
          ? 'clarification_interrupt'
          : (soft ? 'soft_interrupt' : (takeTurn ? 'take_turn' : 'none')),
    );
  }
}
