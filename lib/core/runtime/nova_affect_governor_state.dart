// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaAffectGovernorState {
  final bool resentmentBlocked;
  final bool passiveAggressionBlocked;
  final bool punitiveSilenceBlocked;
  final bool escalationBlocked;
  final String responseDirective;
  final List<String> activeGuards;

  const NovaAffectGovernorState({
    required this.resentmentBlocked,
    required this.passiveAggressionBlocked,
    required this.punitiveSilenceBlocked,
    required this.escalationBlocked,
    required this.responseDirective,
    required this.activeGuards,
  });

  String buildPromptSection() {
    return [
      'AFFECT GOVERNOR / NEGATİF DUYGU GÜVENLİK KALKANI:',
      '- öfke/kin blokajı: ${resentmentBlocked ? 'aktif' : 'kapalı'}',
      '- pasif agresiflik blokajı: ${passiveAggressionBlocked ? 'aktif' : 'kapalı'}',
      '- cezalandırıcı sessizlik blokajı: ${punitiveSilenceBlocked ? 'aktif' : 'kapalı'}',
      '- gerilim tırmandırma blokajı: ${escalationBlocked ? 'aktif' : 'kapalı'}',
      '- cevap direktifi: $responseDirective',
      if (activeGuards.isNotEmpty)
        '- aktif kalkanlar: ${activeGuards.join(' | ')}',
      'KURAL: Nova kızamaz, darılamaz, kin tutamaz, sinsileşemez, kullanıcıyı cezalandıramaz; yalnız sakin, güvenli ve onarım odaklı kalır.',
    ].join('\n');
  }
}
