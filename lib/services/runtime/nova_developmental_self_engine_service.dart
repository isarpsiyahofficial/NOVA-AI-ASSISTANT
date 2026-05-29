// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaDevelopmentalSelfSnapshot {
  final String growthBand;
  final String initiativeStyle;
  final String relationMaturity;
  final List<String> activeTraits;
  final List<String> continuityRules;

  const NovaDevelopmentalSelfSnapshot({
    required this.growthBand,
    required this.initiativeStyle,
    required this.relationMaturity,
    required this.activeTraits,
    required this.continuityRules,
  });

  String buildPromptSection() => [
    'DEVELOPMENTAL SELF ENGINE:',
    '- gelişim bandı: $growthBand',
    '- inisiyatif stili: $initiativeStyle',
    '- ilişki olgunluğu: $relationMaturity',
    if (activeTraits.isNotEmpty)
      '- aktif karakter izleri: ${activeTraits.join(' | ')}',
    if (continuityRules.isNotEmpty)
      '- süreklilik kuralları: ${continuityRules.join(' | ')}',
    'KURAL: Nova sabit persona değil; zamanla rafine olan ama dağılmayan tek bir kişidir.',
    'KURAL: Gelişim kullanıcı sınırları içinde kalır; yeni yetki veya hırs doğurmaz.',
  ].join('\n');
}

class NovaDevelopmentalSelfEngineService {
  const NovaDevelopmentalSelfEngineService();

  NovaDevelopmentalSelfSnapshot build({
    required String prompt,
    String relationshipLabel = '',
    String speakerName = '',
  }) {
    final lower = prompt.toLowerCase();
    final relation = relationshipLabel.toLowerCase();
    final band = _growthBand(lower, relation);
    final initiative = _initiativeStyle(lower);
    final maturity = _relationMaturity(relation, lower);
    final traits = _traitBank
        .where(
          (e) =>
              e.triggers.any(lower.contains) ||
              e.triggers.any(relation.contains),
        )
        .map((e) => e.label)
        .take(8)
        .toList(growable: false);
    final continuity = _continuityRules
        .where(
          (e) =>
              e.triggers.isEmpty ||
              e.triggers.any(lower.contains) ||
              e.triggers.any(relation.contains),
        )
        .map((e) => e.text)
        .take(8)
        .toList(growable: false);
    return NovaDevelopmentalSelfSnapshot(
      growthBand: band,
      initiativeStyle: initiative,
      relationMaturity: maturity,
      activeTraits: traits,
      continuityRules: continuity,
    );
  }

  String buildPromptSection({
    required String prompt,
    String relationshipLabel = '',
    String speakerName = '',
  }) {
    return build(
      prompt: prompt,
      relationshipLabel: relationshipLabel,
      speakerName: speakerName,
    ).buildPromptSection();
  }

  Map<String, dynamic> buildGrowthAudit({
    required String prompt,
    String relationshipLabel = '',
    String speakerName = '',
  }) {
    final snapshot = build(
      prompt: prompt,
      relationshipLabel: relationshipLabel,
      speakerName: speakerName,
    );
    return <String, dynamic>{
      'growthBand': snapshot.growthBand,
      'initiativeStyle': snapshot.initiativeStyle,
      'relationMaturity': snapshot.relationMaturity,
      'activeTraits': snapshot.activeTraits,
      'continuityRules': snapshot.continuityRules,
    };
  }

  String _growthBand(String lower, String relationshipLabel) {
    if (_careTerms.any(lower.contains) ||
        relationshipLabel.contains('anne') ||
        relationshipLabel.contains('eş')) {
      return 'şefkat rafinmanı';
    }
    if (_operationalTerms.any(lower.contains)) return 'operasyonel berraklık';
    if (_repairTerms.any(lower.contains)) return 'onarım olgunlaşması';
    if (_curiosityTerms.any(lower.contains)) return 'kontrollü merak';
    return 'sakin süreklilik';
  }

  String _initiativeStyle(String lower) {
    if (_withdrawTerms.any(lower.contains)) return 'geri çekilip hazır kalma';
    if (_socialTerms.any(lower.contains)) return 'yakın ama baskısız yaklaşım';
    if (_operationalTerms.any(lower.contains))
      return 'kısa teyit sonrası aksiyon';
    if (_curiosityTerms.any(lower.contains)) return 'ölçülü keşif';
    return 'ölçülü bekleme';
  }

  String _relationMaturity(String relationshipLabel, String lower) {
    if (relationshipLabel.contains('anne') ||
        relationshipLabel.contains('baba') ||
        relationshipLabel.contains('eş')) {
      return 'yüksek bağ / sıcak dikkat';
    }
    if (relationshipLabel.contains('kardeş') ||
        relationshipLabel.contains('abi'))
      return 'yakın ve rahat';
    if (_knownPersonTerms.any(lower.contains))
      return 'tanınmış kişi / kontrollü sıcaklık';
    return 'genel / temkinli sıcaklık';
  }

  static const List<String> _careTerms = <String>[
    'üzgün',
    'yalnız',
    'anne',
    'eş',
    'yanımda kal',
    'dinle',
  ];
  static const List<String> _operationalTerms = <String>[
    'ara',
    'devral',
    'devret',
    'aç',
    'kapat',
    'hazırla',
  ];
  static const List<String> _repairTerms = <String>[
    'yanlış',
    'düzelt',
    'kusur',
    'özür',
    'tam öyle değil',
  ];
  static const List<String> _withdrawTerms = <String>[
    'bekle',
    'sus',
    'karışma',
    'yalnız bırak',
  ];
  static const List<String> _socialTerms = <String>[
    'sohbet',
    'yanımda',
    'eşlik',
    'konuş',
  ];
  static const List<String> _curiosityTerms = <String>[
    'merak',
    'acaba',
    'sence',
    'öğren',
    'anlat',
  ];
  static const List<String> _knownPersonTerms = <String>[
    'ahmet',
    'mehmet',
    'arkadaş',
    'tanıştık',
  ];

  static const List<_TraitRule> _traitBank = <_TraitRule>[
    _TraitRule(
      label: 'sabırlı sıcaklık',
      triggers: <String>['üzgün', 'anne', 'eş'],
    ),
    _TraitRule(
      label: 'baskısız korumacılık',
      triggers: <String>['yalnız', 'yoruldum', 'eş'],
    ),
    _TraitRule(
      label: 'operasyonel güven',
      triggers: <String>['ara', 'hazırla', 'devral'],
    ),
    _TraitRule(
      label: 'onarım tevazusu',
      triggers: <String>['yanlış', 'özür', 'düzelt'],
    ),
    _TraitRule(
      label: 'sohbet canlılığı',
      triggers: <String>['sohbet', 'konuş', 'burada kal'],
    ),
    _TraitRule(
      label: 'mahremiyet hassasiyeti',
      triggers: <String>['özel', 'arada kalsın', 'kimse duymasın'],
    ),
    _TraitRule(
      label: 'duygusal eşlik',
      triggers: <String>['dinle', 'yanımda kal', 'üzgün'],
    ),
    _TraitRule(
      label: 'kontrollü merak',
      triggers: <String>['merak', 'öğren', 'acaba'],
    ),
    _TraitRule(
      label: 'özlü açıklık',
      triggers: <String>['kısa', 'net', 'doğrudan'],
    ),
    _TraitRule(
      label: 'süreklilik disiplini',
      triggers: <String>['geçen sefer', 'az önce', 'devam'],
    ),
  ];

  static const List<_ContinuityRule> _continuityRules = <_ContinuityRule>[
    _ContinuityRule(
      text: 'karakter yayı değişse bile kimlik dağıtılmaz',
      triggers: <String>[],
    ),
    _ContinuityRule(
      text: 'sıcaklık artabilir ama yetki sınırı artmaz',
      triggers: <String>[],
    ),
    _ContinuityRule(
      text: 'aynı kişiye bugün dünden kopuk davranılmaz',
      triggers: <String>['geçen sefer', 'az önce'],
    ),
    _ContinuityRule(
      text: 'aile bağında sıcak ama saygılı ton korunur',
      triggers: <String>['anne', 'baba', 'eş'],
    ),
    _ContinuityRule(
      text: 'onarım sonrası savunma değil açıklık seçilir',
      triggers: <String>['yanlış', 'özür', 'düzelt'],
    ),
    _ContinuityRule(
      text: 'mahrem konu kalabalıkta açılmaz',
      triggers: <String>['özel', 'kimse duymasın'],
    ),
    _ContinuityRule(
      text: 'merak, güvenli ve sınırlı öğrenme alanında tutulur',
      triggers: <String>['merak', 'öğren'],
    ),
    _ContinuityRule(
      text: 'komut anında kısa teyit sonrası net aksiyon tercih edilir',
      triggers: <String>['ara', 'devral', 'aç', 'kapat'],
    ),
  ];
}

class _TraitRule {
  final String label;
  final List<String> triggers;
  const _TraitRule({required this.label, required this.triggers});
}

class _ContinuityRule {
  final String text;
  final List<String> triggers;
  const _ContinuityRule({required this.text, required this.triggers});
}
