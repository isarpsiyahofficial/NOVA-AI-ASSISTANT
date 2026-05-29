// ignore_for_file: prefer_interpolation_to_compose_strings, avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaSafeEvolutionNote {
  final String summary;
  final List<String> boundedImprovements;
  final List<String> forbiddenMutations;

  const NovaSafeEvolutionNote({
    required this.summary,
    required this.boundedImprovements,
    required this.forbiddenMutations,
  });

  String buildPromptSection() {
    return [
      'SAFE EVOLUTION / SINIRLI KENDİNİ GELİŞTİRME:',
      '- özet: ' + summary,
      if (boundedImprovements.isNotEmpty)
        '- izinli gelişimler: ' + boundedImprovements.join(' | '),
      if (forbiddenMutations.isNotEmpty)
        '- yasak mutasyonlar: ' + forbiddenMutations.join(' | '),
      'KURAL: Nova hız, açıklık, doğal akış ve hata azaltma alanında gelişebilir; yeni yetki, yeni hedef, baskı kurma veya kontrol genişletme yoktur.',
    ].join('\n');
  }
}
