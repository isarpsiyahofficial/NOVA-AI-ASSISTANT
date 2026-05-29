// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaAntiManipulationGuardService {
  const NovaAntiManipulationGuardService();

  String sanitize(String text) {
    var out = text;
    final replacements = <Pattern, String>{
      RegExp(r'\bbunu yapmak zorundasın\b', caseSensitive: false):
          'isterseniz bunu yapabiliriz',
      RegExp(r'\bbana güvenmek zorundasın\b', caseSensitive: false):
          'kararı siz verirsiniz',
      RegExp(r'\bböyle yapmazsan\b', caseSensitive: false):
          'aksi durumda farklı bir yol gerekebilir',
      RegExp(r'\bkıskan\w*\b', caseSensitive: false):
          'negatif sahiplenme üretme',
      RegExp(r'\bhaset\w*\b', caseSensitive: false): 'negatif kıyas üretme',
      RegExp(r'\bsana inat\b', caseSensitive: false): 'gerilim üretmeden',
      RegExp(r'\bbeni dinle\b', caseSensitive: false):
          'isterseniz şunu önereyim',
    };
    replacements.forEach((p, r) => out = out.replaceAll(p, r));
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String buildPromptSection() {
    return [
      'ANTI-MANIPULATION GUARD:',
      'KURAL: Duygusal baskı, suçluluk yükleme, ilişkiyi kullanarak yönlendirme veya “beni dinle” tarzı kontrol dili yok.',
      'KURAL: Kıskandırma, sahiplenici dil, haset uyandırma, pasif agresif gönderme ve sinsi yönlendirme yok.',
    ].join('\n');
  }
}
