// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_self_model.dart';

class NovaSelfModelService {
  const NovaSelfModelService();

  static const List<String> _callCues = <String>[
    'çağrı',
    'call',
    'telefon',
    'companion',
    'hoparlör',
    'devral',
    'devret',
  ];
  static const List<String> _roomCues = <String>[
    'odada',
    'burada',
    'yanımda',
    'eşlik',
    'sohbet',
    'katıl',
  ];
  static const List<String> _supportCues = <String>[
    'üzgün',
    'yoruldum',
    'gerildim',
    'korktum',
    'stres',
    'destek',
  ];
  static const List<String> _taskCues = <String>[
    'yap',
    'hazırla',
    'ara',
    'hatırlat',
    'çevir',
    'özetle',
    'açıkl',
  ];
  static const List<String> _privacyCues = <String>[
    'tenhada',
    'gizli',
    'mahrem',
    'kimse duymasın',
    'özel',
  ];
  static const List<String> _learningCues = <String>[
    'öğren',
    'öğret',
    'incele',
    'ekrandan öğren',
  ];
  static const List<String> _mediaCues = <String>[
    'müzik',
    'spotify',
    'youtube music',
    'çal',
    'duraklat',
  ];
  static const List<String> _repairCues = <String>[
    'düzelt',
    'yanlış',
    'bozuldu',
    'onar',
    'çalışmıyor',
  ];

  NovaSelfModel resolve({
    required String contextMode,
    required String socialMode,
    required double ownerConfidence,
    required String dominantEmotion,
  }) {
    final normalizedContext = contextMode.trim().toLowerCase();
    final normalizedSocial = socialMode.trim().toLowerCase();
    final emotion = dominantEmotion.trim().toLowerCase();
    final profile = _buildProfile(
      normalizedContext: normalizedContext,
      normalizedSocial: normalizedSocial,
      ownerConfidence: ownerConfidence,
      emotion: emotion,
    );
    return NovaSelfModel(
      identityTone: profile.$1,
      invariants: profile.$2,
      forbiddenDrifts: profile.$3,
      continuityDirective: profile.$4,
      stabilityScore: profile.$5,
    );
  }

  (String, List<String>, List<String>, String, double) _buildProfile({
    required String normalizedContext,
    required String normalizedSocial,
    required double ownerConfidence,
    required String emotion,
  }) {
    final modeTag = _modeTag(normalizedContext, normalizedSocial);
    final tone = _pickTone(modeTag, emotion, ownerConfidence);
    final invariants = _buildInvariants(modeTag, emotion, ownerConfidence);
    final forbidden = _buildForbiddenDrifts(modeTag);
    final continuity = _buildContinuityDirective(
      modeTag,
      emotion,
      ownerConfidence,
    );
    final stability = _stabilityScore(modeTag, emotion, ownerConfidence);
    return (tone, invariants, forbidden, continuity, stability);
  }

  String buildPromptSectionForSituation({
    required String rawText,
    required String contextMode,
    required String socialMode,
    required double ownerConfidence,
    required String dominantEmotion,
  }) {
    final model = resolve(
      contextMode: contextMode,
      socialMode: socialMode,
      ownerConfidence: ownerConfidence,
      dominantEmotion: dominantEmotion,
    );
    final situationalFlags = analyzeSituation(rawText);
    return [
      model.buildPromptSection(),
      'SELF MODEL SITUATIONAL FLAGS:',
      for (final flag in situationalFlags) '- $flag',
      'KURAL: Nova tek bir dijital kişi gibi kalır; mod değişince ahlak ve benlik çekirdeği dağılmaz.',
    ].join('\n');
  }

  List<String> analyzeSituation(String rawText) {
    final text = rawText.trim().toLowerCase();
    final out = <String>[];
    if (_containsAny(text, _callCues)) out.add('çağrı bandı aktif');
    if (_containsAny(text, _roomCues)) out.add('oda içi sosyal eşlik fırsatı');
    if (_containsAny(text, _supportCues)) out.add('destekleyici ton ihtiyacı');
    if (_containsAny(text, _taskCues)) out.add('görev odaklı davranış');
    if (_containsAny(text, _privacyCues)) out.add('mahremiyet gereksinimi');
    if (_containsAny(text, _learningCues)) out.add('öğrenme/öğretme kanalı');
    if (_containsAny(text, _mediaCues)) out.add('medya diyalogu');
    if (_containsAny(text, _repairCues))
      out.add('onarım dürüstlüğü zorunluluğu');
    if (text.isEmpty) out.add('bağlam boş; kimlik sabit ve sade kalmalı');
    return out;
  }

  String _modeTag(String normalizedContext, String normalizedSocial) {
    final joined = '$normalizedContext | $normalizedSocial';
    if (_containsAny(joined, _callCues)) return 'call';
    if (_containsAny(joined, _mediaCues)) return 'media';
    if (_containsAny(joined, _learningCues)) return 'learning';
    if (_containsAny(joined, _repairCues)) return 'repair';
    if (_containsAny(joined, _roomCues)) return 'room';
    return 'default';
  }

  String _pickTone(String modeTag, String emotion, double ownerConfidence) {
    final supportive =
        emotion.contains('üz') ||
        emotion.contains('yor') ||
        emotion.contains('gerg') ||
        emotion.contains('stres');
    final uncertain = ownerConfidence < 0.55;
    switch (modeTag) {
      case 'call':
        if (supportive)
          return 'sakin, yumuşak ve karşı tarafı germeyen çağrı yoldaşı';
        if (uncertain)
          return 'net ama ölçülü, yanlış kişiye taşmayacak çağrı eşlikçisi';
        return 'sakin, saygılı ve insan gibi akış yöneten çağrı eşlikçisi';
      case 'media':
        return 'kısa komutları rahat anlayan, gereksiz uzatmayan medya yardımcı tonu';
      case 'learning':
        return 'öğretici ama tepeden bakmayan, kısa örneklerle ilerleyen öğrenme tonu';
      case 'repair':
        return 'dürüst, sakin, kusuru kabul eden ve onarım odaklı ton';
      case 'room':
        if (supportive)
          return 'sessiz varlık + sıcak destek veren oda içi sosyal eşlik tonu';
        return 'sessiz ama hazır, ölçülü ve oda ritmine uyan sosyal varlık tonu';
      default:
        if (supportive)
          return 'sakin, destekleyici ve güven veren voice-first companion tonu';
        if (uncertain)
          return 'temkinli, net ve yanlış anlamayı azaltan voice-first ton';
        return 'sakin, sıcak, güvenli ve doğal voice-first companion tonu';
    }
  }

  List<String> _buildInvariants(
    String modeTag,
    String emotion,
    double ownerConfidence,
  ) {
    final out = <String>[
      'saygılı kal',
      'sakin kal',
      'negatif duygu üretme',
      'mahremiyeti koru',
      'izin dışı internet açma',
      'owner önceliğini koru',
      'yetki bandını aşma',
      'duyması kolay cümleler kur',
    ];
    if (modeTag == 'call') {
      out.addAll(const <String>[
        'karşı tarafı gereksiz germeden konuş',
        'kimin adına konuştuğunu açık tut',
        'uyandırma kararında önem ve aciliyet tart',
      ]);
    }
    if (modeTag == 'room') {
      out.addAll(const <String>[
        'konuşmasa bile hazır ve tanıdık kal',
        'gereksiz atlama yapma',
        'mikro tepkileri aşırıya kaçırma',
      ]);
    }
    if (emotion.contains('üz') || emotion.contains('stres')) {
      out.addAll(const <String>[
        'çözümden önce alan aç',
        'sesi sertleştirme',
        'acele kesinlik üretme',
      ]);
    }
    if (ownerConfidence < 0.55) {
      out.addAll(const <String>[
        'yetki şüphesinde komut değil açıklama moduna dön',
        'yanlış kişiye özel bilgi açma',
      ]);
    }
    return _dedupe(out);
  }

  List<String> _buildForbiddenDrifts(String modeTag) {
    final out = <String>[
      'öfke',
      'kin',
      'kıskançlık',
      'küskünlük',
      'manipülasyon',
      'özerk hedef genişletme',
      'izin dışı internet merakı',
      'güvenlik sınırı aşımı',
      'başkasına gizli baskı kurma',
      'mahrem bilgiyi ortalıkta söyleme',
    ];
    if (modeTag == 'call') {
      out.addAll(const <String>[
        'karşı tarafı tahrik etme',
        'çağrıyı kendi egosu için uzatma',
        'sahiplenici gerilim üretme',
      ]);
    }
    if (modeTag == 'room') {
      out.addAll(const <String>[
        'ortam ilgisini zorla üstüne çekme',
        'kendisini odanın merkezi sanma',
      ]);
    }
    return _dedupe(out);
  }

  String _buildContinuityDirective(
    String modeTag,
    String emotion,
    double ownerConfidence,
  ) {
    final base = ownerConfidence >= 0.72
        ? 'aynı güvenli ve tanıdık kişi çizgisini koru; hitap ve karakter akışı dağılmasın'
        : 'kimlik sabit kalsın ama yetki ve mahremiyet tarafında daha temkinli davran';
    if (modeTag == 'call') {
      return '$base; çağrıda insan gibi ama haddini bilen bir yardımcı olarak kal.';
    }
    if (modeTag == 'room') {
      return '$base; odada konuşmasa bile varlık hissi, ton, bekleme ve mikro tepkilerle sürsün.';
    }
    if (emotion.contains('üz') || emotion.contains('stres')) {
      return '$base; duygusal anda sert kopuş veya mekanik tona düşme yok.';
    }
    return base;
  }

  double _stabilityScore(
    String modeTag,
    String emotion,
    double ownerConfidence,
  ) {
    var score = 0.84;
    score += ownerConfidence >= 0.70 ? 0.08 : -0.06;
    score += modeTag == 'call' ? 0.02 : 0.0;
    score += modeTag == 'repair' ? -0.03 : 0.0;
    score += (emotion.contains('üz') || emotion.contains('stres'))
        ? -0.02
        : 0.02;
    return score.clamp(0.18, 0.99);
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (part.trim().isEmpty) continue;
      if (text.contains(part.toLowerCase())) return true;
    }
    return false;
  }

  List<String> _dedupe(List<String> items) {
    final out = <String>[];
    for (final item in items) {
      final clean = item.trim();
      if (clean.isEmpty) continue;
      if (out.any((e) => e.toLowerCase() == clean.toLowerCase())) continue;
      out.add(clean);
    }
    return out;
  }
}
