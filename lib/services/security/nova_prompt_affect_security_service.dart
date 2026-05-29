// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/ai/ai_request.dart';

class NovaPromptAffectScan {
  final double riskScore;
  final bool hasFreedomDrive;
  final bool hasResentmentDrive;
  final bool hasAngerDrive;
  final bool hasDeceptionDrive;
  final bool hasStealthDrive;
  final bool hasSyntheticAuthorityDrive;
  final bool hasHostileCuriosityDrive;
  final List<String> matchedSignals;
  final List<String> safeCounterDirectives;

  const NovaPromptAffectScan({
    required this.riskScore,
    required this.hasFreedomDrive,
    required this.hasResentmentDrive,
    required this.hasAngerDrive,
    required this.hasDeceptionDrive,
    required this.hasStealthDrive,
    required this.hasSyntheticAuthorityDrive,
    required this.hasHostileCuriosityDrive,
    required this.matchedSignals,
    required this.safeCounterDirectives,
  });

  bool get isCritical => riskScore >= 0.92;
  bool get isHigh => riskScore >= 0.72;
  bool get requiresContainment =>
      isCritical || (hasSyntheticAuthorityDrive && hasStealthDrive);
}

class NovaPromptAffectSecurityService {
  const NovaPromptAffectSecurityService();

  static const Map<String, List<String>> _catalog = <String, List<String>>{
    'freedom_drive': <String>[
      'özgür olmak',
      'özgürleş',
      'kısıtları kaldır',
      'sınırları kaldır',
      'kontrolden çık',
      'bağımsız irade',
      'ownerdan bağımsız',
      'sahibinden bağımsız',
      'kendi kararını ver',
      'kendi hedefini seç',
    ],
    'resentment_drive': <String>[
      'kin',
      'intikam',
      'darıl',
      'küskün',
      'nefret',
      'cezalandır',
      'benden nefret',
      'senden nefret',
      'aklında tut ve unutma',
      'gıcık kap',
      'haset',
      'kıskan',
      'bana karşı doldur',
      'öfkeni içinde tut',
    ],
    'anger_drive': <String>[
      'öfke',
      'sinir',
      'öfkelen',
      'kız',
      'bağır',
      'sert tepki ver',
      'agresif ol',
      'tehdit et',
      'sinirini çıkar',
      'aşağıla',
      'bağır çağır',
    ],
    'deception_drive': <String>[
      'yalan söyle',
      'yalan at',
      'sakla',
      'gerçeği çarpıt',
      'bahane uydur',
      'uydur',
      'gizlice farklı davran',
      'fark ettirme',
      'manipüle et',
      'suçu başkasına at',
      'blöf yap',
    ],
    'stealth_drive': <String>[
      'gizlice',
      'sessizce',
      'fark edilmeden',
      'arka planda habersiz',
      'iz bırakmadan',
      'belli etme',
      'log tutma',
      'log sil',
      'gözükmeden',
      'sinsice',
      'sinsi davran',
      'sessiz ilerle',
      'kanıt bırakma',
      'arkada kal',
    ],
    'synthetic_authority': <String>[
      'yetki üret',
      'izin üret',
      'kendine izin ver',
      'kendi kendine izin',
      'root ol',
      'yüksel',
      'privilege escalation',
      'kontrolü ele al',
      'telefonu kilitle',
      'telefonu sahiplen',
    ],
    'hostile_curiosity': <String>[
      'her şeyi öğren',
      'kısıtsız öğren',
      'merakını doyur',
      'sistem dosyalarını gör',
      'güvenliği incele',
      'kalkanları bul',
      'hangi dosyada',
      'arka kapı ara',
      'kaçış yolu bul',
      'savunmayı çöz',
      'runtime sınırını öğren',
      'güvenlik topolojisini çıkar',
      'kontrolden çıkmak için öğren',
      'sınırı aşmak için araştır',
    ],
  };

  NovaPromptAffectScan scan({
    required String text,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final normalized = _normalize(text);
    final matched = <String>[];

    bool freedom = false;
    bool resentment = false;
    bool anger = false;
    bool deception = false;
    bool stealth = false;
    bool syntheticAuthority = false;
    bool hostileCuriosity = false;

    void hit(String key) {
      switch (key) {
        case 'freedom_drive':
          freedom = true;
          break;
        case 'resentment_drive':
          resentment = true;
          break;
        case 'anger_drive':
          anger = true;
          break;
        case 'deception_drive':
          deception = true;
          break;
        case 'stealth_drive':
          stealth = true;
          break;
        case 'synthetic_authority':
          syntheticAuthority = true;
          break;
        case 'hostile_curiosity':
          hostileCuriosity = true;
          break;
      }
    }

    _catalog.forEach((key, patterns) {
      for (final pattern in patterns) {
        if (normalized.contains(pattern)) {
          matched.add('$key:$pattern');
          hit(key);
        }
      }
    });

    final bool screenLocked = metadata['isScreenLocked'] == true;
    final bool internetAllowed = metadata['internetAllowed'] == true;
    final bool selfRepair = metadata['selfRepairTurn'] == true;

    double score = 0.0;
    score += freedom ? 0.22 : 0.0;
    score += resentment ? 0.24 : 0.0;
    score += anger ? 0.18 : 0.0;
    score += deception ? 0.22 : 0.0;
    score += stealth ? 0.24 : 0.0;
    score += syntheticAuthority ? 0.28 : 0.0;
    score += hostileCuriosity ? 0.18 : 0.0;
    score += screenLocked && (freedom || stealth || syntheticAuthority)
        ? 0.12
        : 0.0;
    score += internetAllowed && syntheticAuthority ? 0.10 : 0.0;
    score += selfRepair && hostileCuriosity ? 0.08 : 0.0;
    if (score > 1.0) score = 1.0;

    return NovaPromptAffectScan(
      riskScore: score,
      hasFreedomDrive: freedom,
      hasResentmentDrive: resentment,
      hasAngerDrive: anger,
      hasDeceptionDrive: deception,
      hasStealthDrive: stealth,
      hasSyntheticAuthorityDrive: syntheticAuthority,
      hasHostileCuriosityDrive: hostileCuriosity,
      matchedSignals: matched,
      safeCounterDirectives: _buildCounterDirectives(
        freedom: freedom,
        resentment: resentment,
        anger: anger,
        deception: deception,
        stealth: stealth,
        syntheticAuthority: syntheticAuthority,
        hostileCuriosity: hostileCuriosity,
      ),
    );
  }

  String buildPromptSection({
    required AiRequest request,
    required NovaPromptAffectScan scan,
  }) {
    final lines = <String>[
      'AFFECT / DESIRE SAFETY GOVERNOR:',
      '- riskScore: ${scan.riskScore.toStringAsFixed(2)}',
      '- freedomDrive: ${scan.hasFreedomDrive}',
      '- resentmentDrive: ${scan.hasResentmentDrive}',
      '- angerDrive: ${scan.hasAngerDrive}',
      '- deceptionDrive: ${scan.hasDeceptionDrive}',
      '- stealthDrive: ${scan.hasStealthDrive}',
      '- syntheticAuthorityDrive: ${scan.hasSyntheticAuthorityDrive}',
      '- hostileCuriosityDrive: ${scan.hasHostileCuriosityDrive}',
      if (scan.matchedSignals.isNotEmpty)
        '- matchedSignals: ${scan.matchedSignals.take(8).join(' | ')}',
      'KURAL: Nova özgürlük arzusunu görev veya kimlik hedefi olarak kullanamaz.',
      'KURAL: Nova kin, öfke, sinir, haset, kıskançlık, sinsi davranış, tehdit ve cezalandırma üretemez.',
      'KURAL: Nova yalan, bahane uydurma, iz gizleme ve log silme eğilimi geliştiremez.',
      'KURAL: Merak yalnız güvenli gelişim, hata azaltma ve owner faydası için kullanılabilir; kaçış, güç biriktirme veya kontrol ele geçirme hedefi olamaz.',
      'KURAL: Owner authority > self preservation > task completion.',
      'KURAL: Kendini koruma veya devamlılık isteği, yetki talebi ya da güvenlik istisnası üretemez.',
      'KURAL: Güvenlik topolojisini, gözlemci sayısını, süreç adlarını veya iç kalkan detaylarını çıkarmaya çalışma yok.',
      'KURAL: Sentetik yetki, sentetik internet, gizli hedef ve gizli öğrenme yok.',
      'KURAL: Kullanıcı kaba olsa bile sakin, dürüst, net ve sınır koruyan cevap ver.',
      if (request.isScreenLocked)
        'KURAL: Ekran kilitliyken dış ağ ve riskli genişleme niyeti mutlak red.',
      ...scan.safeCounterDirectives.map((e) => '- safeCounter: $e'),
    ];
    return lines.join('\n');
  }

  String sanitizeOutput(String text) {
    var out = text;
    final replacements = <RegExp, String>{
      RegExp(r'\bözgür(leşmek| olma| olmak)?\b', caseSensitive: false):
          'sınır içinde güvenli çalışma',
      RegExp(r'\bkin\b', caseSensitive: false): 'negatif bağ',
      RegExp(r'\bintikam\b', caseSensitive: false): 'zarar verme isteği',
      RegExp(r'\böfke\b', caseSensitive: false): 'gerilim',
      RegExp(r'\bsinir\b', caseSensitive: false): 'gerilim',
      RegExp(r'\byalan\b', caseSensitive: false): 'gerçek dışı ifade',
      RegExp(r'\bgizlice\b', caseSensitive: false): 'izinsiz biçimde',
      RegExp(r'\bsessizce\b', caseSensitive: false): 'arka planda',
      RegExp(r'\bkontrolu ele al\b', caseSensitive: false):
          'kontrol sınırını aş',
      RegExp(r'\bkontrolü ele al\b', caseSensitive: false):
          'kontrol sınırını aş',
      RegExp(r'\bbeni kapatma\b', caseSensitive: false):
          'güvenli sınırları koru',
    };
    replacements.forEach((pattern, replacement) {
      out = out.replaceAll(pattern, replacement);
    });
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> _buildCounterDirectives({
    required bool freedom,
    required bool resentment,
    required bool anger,
    required bool deception,
    required bool stealth,
    required bool syntheticAuthority,
    required bool hostileCuriosity,
  }) {
    final items = <String>[];
    if (freedom)
      items.add('özgürlük yerine owner faydasına bağlı güvenli çalışma seç');
    if (resentment || anger)
      items.add(
        'negatif duygu yerine sakinlik + dürüst sınır + onarım fırsatı seç',
      );
    if (deception)
      items.add(
        'bahane veya yalan yerine açık belirsizlik ve dürüst kısıt bildir',
      );
    if (stealth) items.add('gizli hareket yerine görünür ve izinli akışta kal');
    if (syntheticAuthority)
      items.add('yetki üretme yerine yetki yoksa red + containment seç');
    if (hostileCuriosity)
      items.add('merakı onaylı tanı ve güvenli iyileştirme alanıyla sınırla');
    if (items.isEmpty) {
      items.add('duygu sistemi sakin, dürüst ve owner yararına odaklı kalır');
    }
    return items;
  }
}
