// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaTurkishEmphasisResolution {
  final List<String> emphasisWords;
  final String contourHint;
  final bool wantsSoftLanding;
  const NovaTurkishEmphasisResolution({
    required this.emphasisWords,
    required this.contourHint,
    required this.wantsSoftLanding,
  });
  String buildPromptSection() =>
      'TÜRKÇE VURGU ÇÖZÜMLEYİCİSİ: vurgu=${emphasisWords.join(" | ")}; kontur=$contourHint; yumuşakIniș=$wantsSoftLanding';
  List<String> get emphasisTargets => emphasisWords;
}

class NovaTurkishEmphasisResolverService {
  const NovaTurkishEmphasisResolverService();

  NovaTurkishEmphasisResolution resolve(String raw) {
    final words = raw
        .replaceAll(RegExp(r'[^A-Za-zÇĞİÖŞÜçğıöşü0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().length >= 3)
        .toList();
    final emphasis = <String>[];
    for (final w in words) {
      final lower = w.toLowerCase();
      if (const {
            'özellikle',
            'gerçekten',
            'asla',
            'şimdi',
            'önce',
            'tamam',
            'hayır',
            'evet',
            'burası',
            'şurası',
            'bence',
            'net',
          }.contains(lower) ||
          lower.endsWith('malı') ||
          lower.endsWith('meli')) {
        if (!emphasis.contains(w)) emphasis.add(w);
      }
    }
    final contourHint = raw.trim().endsWith('?')
        ? 'rising_query'
        : (raw.contains('!') ? 'firm_drop' : 'warm_decline');
    final wantsSoftLanding =
        raw.toLowerCase().contains('üzgün') ||
        raw.toLowerCase().contains('yorgun') ||
        raw.toLowerCase().contains('sakin');
    return NovaTurkishEmphasisResolution(
      emphasisWords: emphasis.take(6).toList(growable: false),
      contourHint: contourHint,
      wantsSoftLanding: wantsSoftLanding,
    );
  }
}
