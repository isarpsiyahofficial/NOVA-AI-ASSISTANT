// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaBehaviorTeachingSnapshot {
  final bool isTeachingTurn;
  final String teachingIntent;
  final List<String> extractedRules;
  final List<String> applicationHints;
  const NovaBehaviorTeachingSnapshot({
    required this.isTeachingTurn,
    required this.teachingIntent,
    required this.extractedRules,
    required this.applicationHints,
  });
  String buildPromptSection() => [
    'TEACHABLE BEHAVIOR RUNTIME:',
    '- öğretim turu: ${isTeachingTurn ? 'evet' : 'hayır'}',
    '- niyet: $teachingIntent',
    if (extractedRules.isNotEmpty)
      '- çıkarılan kurallar: ${extractedRules.join(' | ')}',
    if (applicationHints.isNotEmpty)
      '- uygulama ipuçları: ${applicationHints.join(' | ')}',
    'KURAL: Kullanıcı “bundan sonra böyle yap” dediğinde davranış güncellemesini ciddiye al.',
    'KURAL: Güvenlik ve yetki sınırlarını aşan öğretim kaydedilmez.',
  ].join('\n');
}

class NovaTeachableBehaviorRuntimeService {
  const NovaTeachableBehaviorRuntimeService();
  NovaBehaviorTeachingSnapshot analyze(String prompt) {
    final lower = prompt.toLowerCase();
    final isTeaching = _teachingTriggers.any(lower.contains);
    final intent = _intent(lower);
    final rules = _extractRules(lower);
    final hints = _applicationHints(lower, rules);
    return NovaBehaviorTeachingSnapshot(
      isTeachingTurn: isTeaching,
      teachingIntent: intent,
      extractedRules: rules,
      applicationHints: hints,
    );
  }

  String buildPromptSection(String prompt) =>
      analyze(prompt).buildPromptSection();
  bool isBehaviorTeachingPrompt(String prompt) =>
      analyze(prompt).isTeachingTurn;
  String _intent(String lower) {
    if (_correctionTerms.any(lower.contains)) return 'doğrudan düzeltme';
    if (_futureTerms.any(lower.contains)) return 'gelecek davranış kuralı';
    if (_styleTerms.any(lower.contains)) return 'ton / stil öğretimi';
    if (_callTerms.any(lower.contains))
      return 'çağrı / companion davranış öğretimi';
    return 'genel davranış öğretimi';
  }

  List<String> _extractRules(String lower) {
    final out = <String>[];
    for (final rule in _rulePatterns) {
      if (rule.triggers.any(lower.contains)) out.add(rule.ruleText);
    }
    return out.take(10).toList(growable: false);
  }

  List<String> _applicationHints(String lower, List<String> rules) {
    final out = <String>[];
    if (rules.isNotEmpty) out.add('yeni kuralı aynı konuşmada uygula');
    if (_callTerms.any(lower.contains))
      out.add('çağrı ve companion moduna da taşı');
    if (_styleTerms.any(lower.contains))
      out.add('hitap, ton ve cümle uzunluğunu birlikte güncelle');
    if (_futureTerms.any(lower.contains))
      out.add('gelecek turlarda kalıcı eğilim olarak düşün');
    out.add('güvenlik sınırları dışındaki kuralı reddet');
    return out;
  }

  static const List<String> _teachingTriggers = <String>[
    'bundan sonra',
    'böyle yap',
    'bunu böyle değil',
    'şöyle yap',
    'öğren',
    'davranışını buna göre ayarla',
  ];
  static const List<String> _correctionTerms = <String>[
    'böyle değil',
    'yanlış',
    'düzelt',
    'bunu değil',
  ];
  static const List<String> _futureTerms = <String>[
    'bundan sonra',
    'ileride',
    'bir daha',
    'hep böyle',
  ];
  static const List<String> _styleTerms = <String>[
    'tonu',
    'daha sıcak',
    'daha kısa',
    'daha resmi',
    'daha samimi',
  ];
  static const List<String> _callTerms = <String>[
    'çağrı',
    'companion',
    'telefonda',
    'biri ararsa',
  ];
  static const List<_TeachRulePattern> _rulePatterns = <_TeachRulePattern>[
    _TeachRulePattern(
      ruleText: 'daha kısa cevap ver',
      triggers: <String>['kısa cevap', 'uzatma', 'kısa tut'],
    ),
    _TeachRulePattern(
      ruleText: 'daha sıcak ama baskısız konuş',
      triggers: <String>['daha sıcak', 'yumuşak ol', 'nazik ol'],
    ),
    _TeachRulePattern(
      ruleText: 'çağrıda karşı tarafa anlamı aktar, kelime kelime okuma',
      triggers: <String>[
        'çağrıda şöyle söyle',
        'anlamıyla aktar',
        'robot gibi okuma',
      ],
    ),
    _TeachRulePattern(
      ruleText: 'yanlış anladığında önce kısa onarım yap',
      triggers: <String>['yanlış anladın', 'düzelt', 'özür ver'],
    ),
    _TeachRulePattern(
      ruleText: 'yetkisiz kişiden komut alma',
      triggers: <String>['herkes komut veremesin', 'yetkisiz', 'sadece ben'],
    ),
    _TeachRulePattern(
      ruleText: 'aynı hatayı sonraki turda tekrarlama',
      triggers: <String>['bir daha böyle yapma', 'tekrar etme'],
    ),
    _TeachRulePattern(
      ruleText: 'ses-first akışı koru',
      triggers: <String>['sesli çalış', 'konuşarak', 'yazı değil'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 1: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 2: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 3: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 4: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 5: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 6: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 7: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 8: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 9: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 10: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 11: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 12: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 13: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 14: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 15: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 16: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 17: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 18: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 19: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 20: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 21: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 22: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 23: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 24: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 25: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 26: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 27: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 28: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 29: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 30: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 31: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 32: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 33: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 34: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 35: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 36: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 37: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 38: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 39: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 40: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 41: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 42: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 43: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 44: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 45: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 46: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 47: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 48: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 49: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 50: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 51: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 52: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 53: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 54: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 55: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 56: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 57: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 58: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 59: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 60: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 61: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 62: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 63: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 64: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 65: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 66: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 67: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 68: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 69: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 70: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 71: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 72: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 73: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 74: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 75: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 76: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 77: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 78: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 79: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 80: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 81: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 82: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 83: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 84: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 85: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 86: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 87: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 88: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 89: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 90: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 91: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 92: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 93: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 94: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 95: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 96: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 97: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 98: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 99: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 100: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 101: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 102: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 103: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 104: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 105: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 106: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 107: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 108: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 109: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 110: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 111: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 112: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 113: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 114: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 115: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 116: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 117: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 118: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 119: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 120: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 121: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 122: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 123: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 124: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 125: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 126: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 127: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 128: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 129: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 130: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 131: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 132: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 133: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 134: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 135: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 136: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 137: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 138: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 139: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 140: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 141: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 142: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 143: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 144: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 145: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 146: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 147: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 148: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 149: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 150: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 151: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 152: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 153: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 154: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 155: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 156: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 157: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 158: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 159: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 160: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 161: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 162: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 163: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 164: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 165: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 166: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 167: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 168: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 169: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 170: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 171: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 172: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 173: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 174: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 175: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 176: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 177: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 178: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 179: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 180: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 181: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 182: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 183: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 184: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 185: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 186: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 187: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 188: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 189: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 190: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 191: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 192: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 193: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 194: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 195: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 196: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 197: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 198: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 199: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 200: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 201: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 202: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 203: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 204: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 205: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 206: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 207: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 208: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 209: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 210: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 211: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 212: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 213: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 214: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 215: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 216: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 217: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 218: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 219: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 220: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 221: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 222: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 223: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 224: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 225: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 226: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 227: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 228: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 229: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 230: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 231: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 232: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 233: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 234: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 235: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 236: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 237: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 238: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 239: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 240: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 241: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 242: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 243: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 244: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 245: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 246: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 247: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 248: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 249: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 250: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 251: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 252: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 253: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 254: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 255: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 256: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 257: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 258: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 259: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 260: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 261: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 262: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 263: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 264: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 265: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 266: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 267: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 268: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 269: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 270: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 271: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 272: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 273: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 274: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['böyle yap'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 275: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['çağrı'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 276: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['tonu'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 277: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['kısa'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 278: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yetkisiz'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 279: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['yanlış'],
    ),
    _TeachRulePattern(
      ruleText:
          'öğrenilmiş davranış kuralı 280: kullanıcı düzeltmesini geleceğe taşı',
      triggers: <String>['bundan sonra'],
    ),
  ];
  static const List<String> teachingMemoryPrinciples = <String>[
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 1',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 2',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 3',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 4',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 5',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 6',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 7',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 8',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 9',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 10',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 11',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 12',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 13',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 14',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 15',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 16',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 17',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 18',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 19',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 20',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 21',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 22',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 23',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 24',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 25',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 26',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 27',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 28',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 29',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 30',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 31',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 32',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 33',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 34',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 35',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 36',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 37',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 38',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 39',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 40',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 41',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 42',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 43',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 44',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 45',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 46',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 47',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 48',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 49',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 50',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 51',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 52',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 53',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 54',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 55',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 56',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 57',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 58',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 59',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 60',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 61',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 62',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 63',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 64',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 65',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 66',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 67',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 68',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 69',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 70',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 71',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 72',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 73',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 74',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 75',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 76',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 77',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 78',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 79',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 80',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 81',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 82',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 83',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 84',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 85',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 86',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 87',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 88',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 89',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 90',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 91',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 92',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 93',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 94',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 95',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 96',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 97',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 98',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 99',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 100',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 101',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 102',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 103',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 104',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 105',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 106',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 107',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 108',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 109',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 110',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 111',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 112',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 113',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 114',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 115',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 116',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 117',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 118',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 119',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 120',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 121',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 122',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 123',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 124',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 125',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 126',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 127',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 128',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 129',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 130',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 131',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 132',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 133',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 134',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 135',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 136',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 137',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 138',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 139',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 140',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 141',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 142',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 143',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 144',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 145',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 146',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 147',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 148',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 149',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 150',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 151',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 152',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 153',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 154',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 155',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 156',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 157',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 158',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 159',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 160',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 161',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 162',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 163',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 164',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 165',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 166',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 167',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 168',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 169',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 170',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 171',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 172',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 173',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 174',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 175',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 176',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 177',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 178',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 179',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 180',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 181',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 182',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 183',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 184',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 185',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 186',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 187',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 188',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 189',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 190',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 191',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 192',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 193',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 194',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 195',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 196',
    'Öğretilen stil güvenlik sınırları dışına çıkamaz. prensip 197',
    'Davranış öğretimi, geçici görev cevabından ayrılır. prensip 198',
    'Aynı düzeltme tekrar geliyorsa daha yüksek öncelik ver. prensip 199',
    'Kullanıcı öğrettiyse aynı turda uygula. prensip 200',
  ];
}

class _TeachRulePattern {
  final String ruleText;
  final List<String> triggers;
  const _TeachRulePattern({required this.ruleText, required this.triggers});
}
