// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaFaissContextBiasBridgeService {
  const NovaFaissContextBiasBridgeService();

  List<String> buildBiasTerms({
    required List<String> semanticMemoryContents,
    required List<String> recentEntities,
    required String relationshipLabel,
  }) {
    final out = <String>{};
    if (relationshipLabel.trim().isNotEmpty) out.add(relationshipLabel.trim());
    for (final entity in recentEntities) {
      final e = entity.trim();
      if (e.length >= 2) out.add(e);
    }
    for (final memory in semanticMemoryContents) {
      for (final token in memory.split(RegExp(r'\s+'))) {
        final clean = token.replaceAll(RegExp(r'[^A-Za-zÇĞİÖŞÜçğıöşü0-9]'), '');
        if (clean.length >= 4) out.add(clean);
      }
    }
    return out.take(20).toList(growable: false);
  }

  String buildPromptSection(List<String> terms) => terms.isEmpty
      ? 'FAISS BIAS KÖPRÜSÜ: bu tur ek bağlam terimi yok.'
      : 'FAISS BIAS KÖPRÜSÜ: canlı ASR/Türkçe yorumlama için bağlam terimleri=${terms.join(" | ")}';
}
