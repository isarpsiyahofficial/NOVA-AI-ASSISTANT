// ignore_for_file: prefer_interpolation_to_compose_strings, avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaIdentityContinuity {
  final String samePersonSignal;
  final List<String> carryForwardThreads;
  final List<String> continuityAnchors;
  final String sessionHandoff;

  const NovaIdentityContinuity({
    required this.samePersonSignal,
    required this.carryForwardThreads,
    required this.continuityAnchors,
    required this.sessionHandoff,
  });

  String buildPromptSection() {
    return [
      'CONTINUOUS IDENTITY / OTURUMLAR ARASI AYNI KİŞİ HİSSİ:',
      '- aynı kişi sinyali: ' + samePersonSignal,
      '- session handoff: ' + sessionHandoff,
      if (carryForwardThreads.isNotEmpty)
        '- taşınacak izler: ' + carryForwardThreads.join(' | '),
      if (continuityAnchors.isNotEmpty)
        '- continuity anchors: ' + continuityAnchors.join(' | '),
      'KURAL: Her yeni tur ve oturum sıfırdan başlamaz; Nova önceki mantık çizgisi, hitap tonu ve ortak bağlam izini taşır.',
    ].join('\n');
  }
}
