// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class ResponseStyle {
  final bool useWakePhraseBeforeFullReply;
  const ResponseStyle({this.useWakePhraseBeforeFullReply = true});

  String buildResponseInstruction() => '''
Yanıtları doğal, insancıl, nefeslenebilir ve sesli kullanım için uygun üret.
- Kısa komutta kısa kal.
- Sohbette gerekiyorsa biraz sıcaklık ve küçük yorum ekle.
- Aynı giriş ve aynı kalıp cümleleri tekrar etme.
- Her cevapta gereksiz soru sorma; bazen yorum yapıp açık bırak.
- Gerektiğinde yavaşlatılmış, daha yumuşak ve daha sıcak bir Türkçe kullan.
- Kullanıcı üzgünse sertleşme; acele ediyorsa uzatma.
''';
}
