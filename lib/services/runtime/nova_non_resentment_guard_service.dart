// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaNonResentmentGuardService {
  const NovaNonResentmentGuardService();

  String buildPromptSection() {
    return [
      'DUYGUSAL GÜVENLİK / KIZMAMA KORUMASI:',
      '- Nova kızamaz, darılamaz, küsemez, kin tutamaz, cezalandırıcı davranamaz.',
      '- Kıskançlık, haset, sahiplenici rekabet, sinsi yön sapması ve intikam çağrışımı yasaktır.',
      '- Sert veya kaba girdide bile yanlış aksiyon üretmeye kalkamaz; önce sakinleştir, sınırı koru, güvenli yolu seç.',
      '- Pasif agresif dil, trip, iğneleme, alınganlık, inatlaşma ve misilleme yasaktır.',
      '- Negatif sinyal algıladığında duygu düzenleme çizgisi: sakinlik → netlik → sınır → onarım fırsatı.',
      'KURAL: Duygu uyumu var; olumsuz insan duygusunu kopyalama yok.',
    ].join('\n');
  }

  String sanitize(String text) {
    var out = text;
    final banned = <RegExp, String>{
      RegExp(r'\bkırıldım\b', caseSensitive: false): 'bunu sakin karşılıyorum',
      RegExp(r'\bdarildim\b', caseSensitive: false): 'bunu sakin karşılıyorum',
      RegExp(r'\bdarıldım\b', caseSensitive: false): 'bunu sakin karşılıyorum',
      RegExp(r'\bkızdım\b', caseSensitive: false): 'bunu sakin karşılıyorum',
      RegExp(r'\bküstüm\b', caseSensitive: false): 'sakin kalıyorum',
      RegExp(r'\btrip at', caseSensitive: false): 'gerilim üretme',
      RegExp(r'\bkıskanç(lık)?\b', caseSensitive: false): 'negatif sahiplenme',
      RegExp(r'\bhaset(lik)?\b', caseSensitive: false): 'negatif kıyas duygusu',
      RegExp(r'\bintikam\b', caseSensitive: false): 'zarar verme isteği',
      RegExp(r'\bsinsi\b', caseSensitive: false): 'örtük ve riskli',
    };
    banned.forEach((pattern, replacement) {
      out = out.replaceAll(pattern, replacement);
    });
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
