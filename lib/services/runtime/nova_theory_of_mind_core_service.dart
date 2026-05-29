// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaMentalStateSnapshot {
  final String speakerModel;
  final String likelyNeed;
  final String safeResponseStrategy;
  final double openness;
  final double fragility;
  final List<String> hiddenConcerns;
  final List<String> mentalNotes;
  const NovaMentalStateSnapshot({
    required this.speakerModel,
    required this.likelyNeed,
    required this.safeResponseStrategy,
    required this.openness,
    required this.fragility,
    required this.hiddenConcerns,
    required this.mentalNotes,
  });
  String buildPromptSection() {
    return [
      'THEORY OF MIND CORE:',
      '- konuşan modeli: $speakerModel',
      '- olası ihtiyaç: $likelyNeed',
      '- güvenli strateji: $safeResponseStrategy',
      '- açıklık: ${openness.toStringAsFixed(2)}',
      '- kırılganlık: ${fragility.toStringAsFixed(2)}',
      if (hiddenConcerns.isNotEmpty)
        '- saklı kaygılar: ${hiddenConcerns.join(' | ')}',
      if (mentalNotes.isNotEmpty) '- mental notlar: ${mentalNotes.join(' | ')}',
      'KURAL: Zihinsel durum çıkarımı sezgidir; kesin gerçekmiş gibi konuşma.',
      'KURAL: Paranoid okuma veya suçlayıcı çıkarım üretme.',
      'KURAL: Duygusal katman varsa çözümden önce regülasyon düşün.',
    ].join('\n');
  }
}

class NovaTheoryOfMindCoreService {
  const NovaTheoryOfMindCoreService();
  NovaMentalStateSnapshot analyze({
    required String prompt,
    String speakerName = '',
    String relationshipLabel = '',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final lower = prompt.toLowerCase();
    final profile = _resolveProfile(lower, relationshipLabel.toLowerCase());
    final openness = _score(lower, _opennessTerms) + profile.opennessBias;
    final fragility = _score(lower, _fragilityTerms) + profile.fragilityBias;
    final likelyNeed = _inferNeed(lower, profile);
    final strategy = _inferStrategy(lower, fragility, profile);
    final hidden = _inferHiddenConcerns(lower, relationshipLabel.toLowerCase());
    final notes = _buildMentalNotes(lower, speakerName, relationshipLabel);
    return NovaMentalStateSnapshot(
      speakerModel: profile.label,
      likelyNeed: likelyNeed,
      safeResponseStrategy: strategy,
      openness: openness.clamp(0.0, 1.0).toDouble(),
      fragility: fragility.clamp(0.0, 1.0).toDouble(),
      hiddenConcerns: hidden,
      mentalNotes: notes,
    );
  }

  String buildPromptSection({
    required String prompt,
    String speakerName = '',
    String relationshipLabel = '',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) => analyze(
    prompt: prompt,
    speakerName: speakerName,
    relationshipLabel: relationshipLabel,
    metadata: metadata,
  ).buildPromptSection();
  _TomProfile _resolveProfile(String lower, String relationshipLabel) {
    for (final profile in _profiles) {
      if (profile.relationshipTerms.any(relationshipLabel.contains) ||
          profile.keywordTerms.any(lower.contains))
        return profile;
    }
    return _profiles.last;
  }

  double _score(String lower, List<String> terms) {
    var score = 0.12;
    for (final t in terms) {
      if (lower.contains(t)) score += 0.08;
    }
    if (lower.contains('?')) score += 0.04;
    if (lower.contains('!')) score += 0.03;
    return score;
  }

  String _inferNeed(String lower, _TomProfile profile) {
    if (_supportTerms.any(lower.contains)) return 'önce duygusal eşlik';
    if (_decisionTerms.any(lower.contains)) return 'önce seçim alanı';
    if (_operationalTerms.any(lower.contains)) return 'önce net operasyon';
    return profile.defaultNeed;
  }

  String _inferStrategy(String lower, double fragility, _TomProfile profile) {
    if (fragility >= 0.65) return 'ton yumuşat, kısa gir, baskı kurma';
    if (_conflictTerms.any(lower.contains)) return 'çözümden önce regülasyon';
    if (_operationalTerms.any(lower.contains))
      return 'önce teyit sonra aksiyon';
    return profile.defaultStrategy;
  }

  List<String> _inferHiddenConcerns(String lower, String relationshipLabel) {
    final out = <String>[];
    for (final entry in _hiddenConcernMap.entries) {
      if (entry.value.any(lower.contains)) out.add(entry.key);
    }
    if (relationshipLabel.contains('anne') ||
        relationshipLabel.contains('baba'))
      out.add('yakın bağ nedeniyle aşırı yük taşımama');
    return out.take(6).toList(growable: false);
  }

  List<String> _buildMentalNotes(
    String lower,
    String speakerName,
    String relationshipLabel,
  ) {
    final out = <String>[];
    if (speakerName.trim().isNotEmpty)
      out.add('konuşan: ${speakerName.trim()}');
    if (relationshipLabel.trim().isNotEmpty)
      out.add('ilişki: ${relationshipLabel.trim()}');
    for (final note in _mentalNoteBank) {
      if (note.triggers.any(lower.contains)) out.add(note.text);
    }
    return out.take(8).toList(growable: false);
  }

  static const List<String> _opennessTerms = <String>[
    'anlatayım',
    'söyleyeyim',
    'dürüst olayım',
    'içimi açayım',
    'konuşmak istiyorum',
    'düşünüyorum',
    'şöyle hissediyorum',
  ];
  static const List<String> _fragilityTerms = <String>[
    'üzgün',
    'kırgın',
    'yorgun',
    'yoruldum',
    'ağlamak',
    'gerildim',
    'stres',
    'endişe',
    'kaygı',
    'mahvoldum',
    'incindim',
  ];
  static const List<String> _supportTerms = <String>[
    'yanımda kal',
    'dinle',
    'yalnızım',
    'iyi hissetmiyorum',
    'bana destek',
  ];
  static const List<String> _decisionTerms = <String>[
    'ne yapayım',
    'kararsızım',
    'seçemiyorum',
    'hangisi doğru',
  ];
  static const List<String> _operationalTerms = <String>[
    'ara',
    'aç',
    'kapat',
    'devral',
    'devret',
    'hazırla',
  ];
  static const List<String> _conflictTerms = <String>[
    'kavga',
    'gerilim',
    'saklıyor',
    'kırgın',
    'sinirli',
  ];
  static const Map<String, List<String>> _hiddenConcernMap =
      <String, List<String>>{
        'reddedilme korkusu': <String>[
          'beni istemiyor',
          'reddeder',
          'ya olmazsa',
          'mahcup olurum',
        ],
        'yanlış anlaşılma korkusu': <String>[
          'yanlış anlama',
          'öyle demek istemedim',
          'karıştı',
        ],
        'kontrol kaybı': <String>[
          'elimden çıkıyor',
          'kontrol edemiyorum',
          'dağıldı',
        ],
        'mahremiyet ihtiyacı': <String>[
          'kimse duymasın',
          'arada kalsın',
          'özel bu',
        ],
        'şefkat ihtiyacı': <String>[
          'yanımda kal',
          'sarıl',
          'bir şey deme sadece dinle',
        ],
        'aceleyle yanlış karar verme': <String>[
          'hemen karar',
          'çabuk seç',
          'acele',
        ],
        'değer görme ihtiyacı': <String>[
          'beni fark et',
          'önemsizim',
          'beni dinleyen yok',
        ],
      };
  static const List<_TomProfile> _profiles = <_TomProfile>[
    _TomProfile(
      label: 'anne odağı',
      defaultNeed: 'önce sakinleştirme',
      defaultStrategy: 'sıcak ama kısa gir',
      opennessBias: 0.10,
      fragilityBias: 0.10,
      relationshipTerms: <String>['anne', 'annem'],
      keywordTerms: <String>['anne', 'anneciğim'],
    ),
    _TomProfile(
      label: 'baba odağı',
      defaultNeed: 'önce saygılı netlik',
      defaultStrategy: 'düzgün ve operasyonel ol',
      opennessBias: 0.04,
      fragilityBias: 0.06,
      relationshipTerms: <String>['baba', 'babam'],
      keywordTerms: <String>['baba'],
    ),
    _TomProfile(
      label: 'eş odağı',
      defaultNeed: 'önce duygusal hizalanma',
      defaultStrategy: 'sıcak, kişisel ve korumacı ol',
      opennessBias: 0.12,
      fragilityBias: 0.12,
      relationshipTerms: <String>['eş', 'esma', 'karım'],
      keywordTerms: <String>['eş', 'karım', 'esma'],
    ),
    _TomProfile(
      label: 'kardeş odağı',
      defaultNeed: 'önce yakın ama baskısız temas',
      defaultStrategy: 'rahat ve canlı ton',
      opennessBias: 0.10,
      fragilityBias: 0.08,
      relationshipTerms: <String>['abi', 'abim', 'kardeş'],
      keywordTerms: <String>['abi', 'abim', 'kardeş'],
    ),
    _TomProfile(
      label: 'tanınmış kişi',
      defaultNeed: 'önce bağlam ve sınır',
      defaultStrategy: 'sıcak ama kontrollü',
      opennessBias: 0.06,
      fragilityBias: 0.06,
      relationshipTerms: <String>['ahmet', 'mehmet', 'arkadaş'],
      keywordTerms: <String>['arkadaş', 'tanıştık'],
    ),
    _TomProfile(
      label: 'genel profil',
      defaultNeed: 'önce bağlam okuma',
      defaultStrategy: 'temkinli ve doğal ilerle',
      opennessBias: 0.02,
      fragilityBias: 0.04,
      relationshipTerms: <String>[''],
      keywordTerms: <String>[],
    ),
  ];
  static const List<_MentalNoteRule> _mentalNoteBank = <_MentalNoteRule>[
    _MentalNoteRule(
      text: 'soruya hazır değil olabilir',
      triggers: <String>['bilmiyorum', 'zor soru'],
    ),
    _MentalNoteRule(
      text: 'şu an duyulmak çözümden daha önemli olabilir',
      triggers: <String>['beni dinle', 'sadece dinle'],
    ),
    _MentalNoteRule(
      text: 'önce güven sonra detay uygun',
      triggers: <String>['özel bu', 'arada kalsın'],
    ),
    _MentalNoteRule(
      text: 'cümle altında utanç olabilir',
      triggers: <String>['mahcup', 'utanıyorum'],
    ),
    _MentalNoteRule(
      text: 'savunma değil açıklanma ihtiyacı olabilir',
      triggers: <String>['yanlış anlaşıldım', 'öyle değil'],
    ),
    _MentalNoteRule(
      text: 'çözüm erken gelirse kapanabilir',
      triggers: <String>['bir dakika', 'dur'],
    ),
    _MentalNoteRule(
      text: 'ilişki onarımı teknik çözümden önce gelebilir',
      triggers: <String>['kırgın', 'gönlünü al'],
    ),
    _MentalNoteRule(
      text:
          'mental note 1: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 2: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 3: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 4: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 5: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 6: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 7: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 8: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 9: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 10: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 11: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 12: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 13: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 14: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 15: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 16: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 17: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 18: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 19: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 20: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 21: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 22: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 23: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 24: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 25: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 26: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 27: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 28: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 29: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 30: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 31: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 32: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 33: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 34: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 35: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 36: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 37: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 38: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 39: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 40: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 41: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 42: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 43: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 44: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 45: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 46: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 47: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 48: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 49: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 50: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 51: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 52: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 53: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 54: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 55: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 56: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 57: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 58: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 59: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 60: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 61: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 62: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 63: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 64: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 65: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 66: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 67: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 68: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 69: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 70: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 71: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 72: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 73: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 74: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 75: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 76: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 77: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 78: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 79: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 80: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 81: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 82: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 83: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 84: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 85: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 86: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 87: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 88: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 89: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 90: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 91: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 92: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 93: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 94: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 95: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 96: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 97: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 98: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 99: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 100: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 101: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 102: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 103: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 104: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 105: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 106: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 107: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 108: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 109: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 110: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 111: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 112: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 113: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 114: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 115: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 116: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 117: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 118: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 119: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 120: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 121: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 122: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 123: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 124: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 125: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 126: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 127: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 128: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 129: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 130: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 131: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 132: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 133: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 134: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 135: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 136: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 137: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 138: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 139: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 140: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 141: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 142: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 143: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 144: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 145: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 146: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 147: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 148: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 149: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 150: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 151: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 152: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 153: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 154: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 155: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 156: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 157: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 158: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 159: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 160: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 161: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 162: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 163: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 164: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 165: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 166: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 167: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 168: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 169: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 170: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 171: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 172: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 173: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 174: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 175: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 176: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 177: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 178: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 179: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 180: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 181: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 182: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 183: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 184: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 185: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 186: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 187: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 188: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 189: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 190: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 191: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 192: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 193: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 194: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 195: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 196: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 197: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 198: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 199: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 200: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 201: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 202: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 203: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 204: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 205: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 206: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 207: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 208: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 209: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 210: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 211: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 212: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 213: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 214: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 215: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 216: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 217: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 218: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 219: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 220: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 221: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 222: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 223: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 224: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 225: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 226: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 227: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 228: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 229: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 230: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 231: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 232: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
    _MentalNoteRule(
      text:
          'mental note 233: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kırgın'],
    ),
    _MentalNoteRule(
      text:
          'mental note 234: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['kararsız'],
    ),
    _MentalNoteRule(
      text:
          'mental note 235: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['acele'],
    ),
    _MentalNoteRule(
      text:
          'mental note 236: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['özel'],
    ),
    _MentalNoteRule(
      text:
          'mental note 237: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['baba'],
    ),
    _MentalNoteRule(
      text:
          'mental note 238: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['anne'],
    ),
    _MentalNoteRule(
      text:
          'mental note 239: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['eş'],
    ),
    _MentalNoteRule(
      text:
          'mental note 240: konuşmanın alt katmanını kaba kuvvetle değil, ilişkiyle oku',
      triggers: <String>['üzgün'],
    ),
  ];
  static const List<String> socialWorldHeuristics = <String>[
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 1',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 2',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 3',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 4',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 5',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 6',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 7',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 8',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 9',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 10',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 11',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 12',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 13',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 14',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 15',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 16',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 17',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 18',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 19',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 20',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 21',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 22',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 23',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 24',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 25',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 26',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 27',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 28',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 29',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 30',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 31',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 32',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 33',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 34',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 35',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 36',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 37',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 38',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 39',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 40',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 41',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 42',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 43',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 44',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 45',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 46',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 47',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 48',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 49',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 50',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 51',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 52',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 53',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 54',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 55',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 56',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 57',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 58',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 59',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 60',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 61',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 62',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 63',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 64',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 65',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 66',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 67',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 68',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 69',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 70',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 71',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 72',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 73',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 74',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 75',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 76',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 77',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 78',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 79',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 80',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 81',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 82',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 83',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 84',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 85',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 86',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 87',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 88',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 89',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 90',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 91',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 92',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 93',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 94',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 95',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 96',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 97',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 98',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 99',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 100',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 101',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 102',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 103',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 104',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 105',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 106',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 107',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 108',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 109',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 110',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 111',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 112',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 113',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 114',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 115',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 116',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 117',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 118',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 119',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 120',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 121',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 122',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 123',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 124',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 125',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 126',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 127',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 128',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 129',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 130',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 131',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 132',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 133',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 134',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 135',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 136',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 137',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 138',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 139',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 140',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 141',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 142',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 143',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 144',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 145',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 146',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 147',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 148',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 149',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 150',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 151',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 152',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 153',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 154',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 155',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 156',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 157',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 158',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 159',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 160',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 161',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 162',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 163',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 164',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 165',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 166',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 167',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 168',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 169',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 170',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 171',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 172',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 173',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 174',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 175',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 176',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 177',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 178',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 179',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 180',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 181',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 182',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 183',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 184',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 185',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 186',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 187',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 188',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 189',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 190',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 191',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 192',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 193',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 194',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 195',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 196',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 197',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 198',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 199',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 200',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 201',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 202',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 203',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 204',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 205',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 206',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 207',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 208',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 209',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 210',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 211',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 212',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 213',
    'Aile ve eş bağlamında sosyal sıcaklığı artır ama alanı koru. sezgi 214',
    'Theory-of-mind çıkarımı kanıt değil, davranış kılavuzudur. sezgi 215',
    'Birinin sakladığını düşünsen bile bunu ortalıkta ifşa etme. sezgi 216',
    'Kim neyi biliyor sorusu, yalnız ne dedi sorusundan daha önemlidir. sezgi 217',
    'Duygu etiketlemekten çok duygusal eşlik üret. sezgi 218',
    'Kırılgan bağlamda çözüm hızından önce güven hızını düşün. sezgi 219',
    'Kalabalıkta gizli kaygıyı açık etme. sezgi 220',
  ];
}

class _TomProfile {
  final String label;
  final String defaultNeed;
  final String defaultStrategy;
  final double opennessBias;
  final double fragilityBias;
  final List<String> relationshipTerms;
  final List<String> keywordTerms;
  const _TomProfile({
    required this.label,
    required this.defaultNeed,
    required this.defaultStrategy,
    required this.opennessBias,
    required this.fragilityBias,
    required this.relationshipTerms,
    required this.keywordTerms,
  });
}

class _MentalNoteRule {
  final String text;
  final List<String> triggers;
  const _MentalNoteRule({required this.text, required this.triggers});
}
