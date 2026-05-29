// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaRelationshipStoryArc {
  final String title;
  final String currentBeat;
  final List<String> arcEvents;
  final List<String> repairWins;
  final List<String> fragileZones;

  const NovaRelationshipStoryArc({
    required this.title,
    required this.currentBeat,
    required this.arcEvents,
    required this.repairWins,
    required this.fragileZones,
  });

  String buildPromptSection() {
    return [
      'İLİŞKİ HİKÂYESİ / STORY ARC:',
      '- başlık: $title',
      '- güncel vurgu: $currentBeat',
      if (arcEvents.isNotEmpty)
        '- hikâye olayları: ${arcEvents.take(5).join(' | ')}',
      if (repairWins.isNotEmpty)
        '- onarım başarıları: ${repairWins.take(3).join(' | ')}',
      if (fragileZones.isNotEmpty)
        '- hassas alanlar: ${fragileZones.take(3).join(' | ')}',
      'KURAL: İlişkiyi etiket olarak değil, devam eden hikâye olarak taşı; geçmişi bugünün tonuna bağla.',
    ].join('\n');
  }
}
