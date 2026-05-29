// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaConversationRitualMemoryService {
  const NovaConversationRitualMemoryService();

  List<String> curate(List<String> rituals, {int maxCount = 6}) {
    final seen = <String>{};
    final curated = <String>[];
    for (final ritual in rituals) {
      final trimmed = ritual.trim();
      if (trimmed.isEmpty) continue;
      final normalized = trimmed.toLowerCase();
      if (!seen.add(normalized)) continue;
      curated.add(trimmed);
      if (curated.length >= maxCount) break;
    }
    return curated;
  }

  String buildPromptSection(List<String> rituals) {
    final curated = curate(rituals, maxCount: 5);
    return [
      'CONVERSATION RITUAL MEMORY:',
      if (curated.isNotEmpty) '- hafif ritüeller: ${curated.join(' | ')}',
      'KURAL: Küçük ortak alışkanlıkları kullanabilirsin; ama yapay tekrar, yapışkan ifade veya abartılı sıcaklık oluşturma.',
      'KURAL: Ritüeller hafif bağ hissi verir; kimlik taklidi ya da sahte yakınlık üretmez.',
    ].join('\n');
  }
}
