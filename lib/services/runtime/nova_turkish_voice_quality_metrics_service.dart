// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaTurkishVoiceQualityMetrics {
  final bool respectsDiscourseMarkers;
  final bool likelyNaturalPause;
  final bool likelySpeechLikePhrasing;
  final bool likelyTurkishAddressTone;
  final int estimatedFlatnessRisk;
  final double prosodySupport;
  final double relationalWarmth;
  final List<String> cues;
  final List<String> repairs;

  const NovaTurkishVoiceQualityMetrics({
    required this.respectsDiscourseMarkers,
    required this.likelyNaturalPause,
    required this.likelySpeechLikePhrasing,
    required this.likelyTurkishAddressTone,
    required this.estimatedFlatnessRisk,
    required this.prosodySupport,
    required this.relationalWarmth,
    required this.cues,
    required this.repairs,
  });

  String buildPromptSection() {
    return <String>[
      'TÜRKÇE SES KALİTE METRİĞİ:',
      '- söylemBelirteci=$respectsDiscourseMarkers',
      '- doğalDurak=$likelyNaturalPause',
      '- konuşmaGibi=$likelySpeechLikePhrasing',
      '- hitapTonu=$likelyTurkishAddressTone',
      '- düzlükRiski=$estimatedFlatnessRisk',
      '- prosodiDesteği=${prosodySupport.toStringAsFixed(2)}',
      '- ilişkiSıcaklığı=${relationalWarmth.toStringAsFixed(2)}',
      if (cues.isNotEmpty) '- ipuçları: ${cues.join(' | ')}',
      if (repairs.isNotEmpty) '- onarımlar: ${repairs.join(' | ')}',
    ].join('\n');
  }
}

class NovaTurkishVoiceQualityMetricsService {
  const NovaTurkishVoiceQualityMetricsService();

  NovaTurkishVoiceQualityMetrics evaluate(String text) {
    final lower = text.toLowerCase();
    final respectsMarkers = _containsAny(lower, const [
      'ya',
      'hani',
      'işte',
      'aslında',
      'yani',
    ]);
    final naturalPause =
        text.contains('.') ||
        text.contains(';') ||
        text.contains(',') ||
        text.contains('...');
    final speechLike =
        _novaSplitAfterSentencePunctuation(text).length <= 5 &&
        !text.contains(': 1)');
    final addressTone = _containsAny(lower, const [
      'efendim',
      'patron',
      'reis',
      'dostum',
      'abi',
      'abla',
      'hocam',
    ]);
    final cues = <String>[];
    final repairs = <String>[];
    if (respectsMarkers)
      cues.add('konuşma belirteçleri mevcut');
    else
      repairs.add('söylem belirteci eklenebilir');
    if (naturalPause)
      cues.add('doğal duraklama işaretleri var');
    else
      repairs.add('tek blok yerine durak ekle');
    if (speechLike)
      cues.add('yazı değil konuşma akışı hissi var');
    else
      repairs.add('cümleleri kısalt ve konuşma ritmine çek');
    if (addressTone)
      cues.add('ilişkisel hitap sinyali mevcut');
    else
      repairs.add('bağlama uygun hitap sıcaklığı düşünebilirsin');
    final flatnessRisk = [
      if (!naturalPause) 1,
      if (!speechLike) 1,
      if (!respectsMarkers) 1,
    ].length;
    final prosodySupport = _score(
      naturalPause: naturalPause,
      respectsMarkers: respectsMarkers,
      speechLike: speechLike,
      addressTone: addressTone,
    );
    final relationalWarmth = _warmth(lower, addressTone: addressTone);
    return NovaTurkishVoiceQualityMetrics(
      respectsDiscourseMarkers: respectsMarkers,
      likelyNaturalPause: naturalPause,
      likelySpeechLikePhrasing: speechLike,
      likelyTurkishAddressTone: addressTone,
      estimatedFlatnessRisk: flatnessRisk,
      prosodySupport: prosodySupport,
      relationalWarmth: relationalWarmth,
      cues: cues,
      repairs: repairs,
    );
  }

  double _score({
    required bool naturalPause,
    required bool respectsMarkers,
    required bool speechLike,
    required bool addressTone,
  }) {
    var out = 0.20;
    if (naturalPause) out += 0.25;
    if (respectsMarkers) out += 0.20;
    if (speechLike) out += 0.25;
    if (addressTone) out += 0.10;
    return out.clamp(0.0, 1.0);
  }

  double _warmth(String lower, {required bool addressTone}) {
    var out = addressTone ? 0.52 : 0.30;
    if (_containsAny(lower, const [
      'anlıyorum',
      'yanındayım',
      'rahat ol',
      'merak etme',
    ]))
      out += 0.20;
    if (_containsAny(lower, const ['sert', 'kesinlikle hayır', 'imkansız']))
      out -= 0.18;
    return out.clamp(0.0, 1.0);
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (text.contains(part)) return true;
    }
    return false;
  }
}

List<String> _novaSplitAfterSentencePunctuation(String text) {
  if (text.trim().isEmpty) return <String>[];
  const marker = '\u0000NOVA_SENTENCE_BREAK\u0000';
  return text
      .replaceAllMapped(RegExp(r'([.!?])\s+'), (m) => '${m.group(1)}$marker')
      .split(marker);
}
