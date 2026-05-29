// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaContextualAsrBiasService {
  const NovaContextualAsrBiasService();

  List<String> buildBiasHints({
    required String prompt,
    required String speakerName,
    required String relationshipLabel,
    required List<String> memoryEntities,
    required List<String> turkishEntities,
  }) {
    final hints = <String>{};
    void addIf(String value) {
      final v = value.trim();
      if (v.isNotEmpty) hints.add(v);
    }

    addIf(speakerName);
    addIf(relationshipLabel);
    for (final token in prompt.split(RegExp(r'\s+'))) {
      if (token.length >= 4) addIf(token);
    }
    for (final e in memoryEntities) {
      addIf(e);
    }
    for (final e in turkishEntities) {
      addIf(e);
    }
    return hints.take(16).toList(growable: false);
  }

  String buildPromptSection(List<String> hints) {
    if (hints.isEmpty) {
      return 'CONTEXTUAL ASR BIAS: Bu tur için ek bias ipucu yok; yine de kişi, konu ve özel isimleri korumaya çalış.';
    }
    return 'CONTEXTUAL ASR BIAS: Olası kişi/konu/özel ad ipuçları=${hints.join(' | ')}';
  }
}
