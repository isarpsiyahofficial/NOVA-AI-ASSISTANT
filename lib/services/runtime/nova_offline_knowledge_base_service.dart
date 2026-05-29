// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_deep_knowledge_corpus_service.dart';
import 'nova_cross_language_knowledge_bridge_service.dart';
import 'nova_knowledge_interpretation_engine_service.dart';
import 'nova_knowledge_request_router_service.dart';
import 'nova_guided_resolution_state_service.dart';

class NovaOfflineKnowledgeBaseService {
  const NovaOfflineKnowledgeBaseService();
  static const NovaDeepKnowledgeCorpusService _deep =
      NovaDeepKnowledgeCorpusService();
  static const NovaCrossLanguageKnowledgeBridgeService _bridge =
      NovaCrossLanguageKnowledgeBridgeService();
  static const NovaKnowledgeInterpretationEngineService _interpretation =
      NovaKnowledgeInterpretationEngineService();
  static const NovaAppliedKnowledgeScenarioLibrary _scenarioLibrary =
      NovaAppliedKnowledgeScenarioLibrary();
  static const NovaKnowledgeRequestRouterService _requestRouter =
      NovaKnowledgeRequestRouterService();
  static const NovaGuidedResolutionStateService _guidedState =
      NovaGuidedResolutionStateService();

  static const Map<String, List<String>> _keywords = <String, List<String>>{
    'cooking': <String>[
      'yemek',
      'tarif',
      'pişir',
      'corba',
      'çorba',
      'ızgara',
      'fırın',
      'ocak',
      'malzeme',
    ],
    'desserts': <String>[
      'tatlı',
      'tatli',
      'kurabiye',
      'kek',
      'pasta',
      'şerbet',
      'sütlü',
      'muhallebi',
    ],
    'cars': <String>[
      'araba',
      'araç',
      'otomobil',
      'sedan',
      'suv',
      'hatchback',
      'pickup',
      'coupe',
      'cabrio',
    ],
    'automotive_mechanics': <String>[
      'motor',
      'şanzıman',
      'vites',
      'debriyaj',
      'hararet',
      'akı',
      'akü',
      'alternatör',
      'marş',
      'fren',
      'enjeksiyon',
      'yakıt sistemi',
      'gösterge ışığı',
    ],
    'people_understanding': <String>[
      'insan',
      'iletişim',
      'empati',
      'dert',
      'sohbet',
      'ton',
      'vurgulama',
      'tavsiye',
      'tanışma',
    ],
    'human_health': <String>[
      'sağlık',
      'semptom',
      'belirti',
      'ağrı',
      'ateş',
      'nefes',
      'yorgunluk',
      'tıp',
    ],
    'animal_health': <String>[
      'hayvan',
      'veteriner',
      'kedi',
      'köpek',
      'mama',
      'parazit',
      'aşı',
    ],
    'natural_medicine': <String>[
      'doğal tıp',
      'bitkisel',
      'şifalı',
      'çay',
      'tentür',
      'geleneksel kullanım',
    ],
    'faith_islam': <String>[
      'islam',
      'kuran',
      'ayet',
      'hadis',
      'namaz',
      'dua',
      'oruç',
    ],
    'numerology': <String>[
      'numeroloji',
      'yaşam yolu',
      'kader sayısı',
      'isim sayısı',
    ],
    'astrology': <String>['astroloji', 'burç', 'yükselen', 'harita', 'retro'],
    'spiritualism': <String>[
      'spiritüalizm',
      'maneviyat',
      'enerji',
      'meditasyon',
      'mistik',
    ],
    'rituals_wealth': <String>[
      'bereket',
      'zenginlik',
      'ritüel',
      'bolluk',
      'uğur',
    ],
    'physics': <String>['fizik', 'kuvvet', 'enerji', 'hareket', 'dalga', 'ısı'],
    'quantum': <String>[
      'kuantum',
      'elektron',
      'foton',
      'atom',
      'dalga fonksiyonu',
    ],
    'space_world': <String>[
      'gezegen',
      'dünya',
      'uzay',
      'astronomi',
      'güneş sistemi',
    ],
    'translation_english': <String>['ingilizce', 'english', 'çeviri'],
    'translation_french': <String>['fransızca', 'french', 'çeviri'],
    'translation_russian': <String>['rusça', 'russian', 'çeviri'],
    'translation_arabic': <String>['arapça', 'arabic', 'çeviri'],
  };

  String buildKnowledgeBase() {
    return [
      '[ÇEVRİMDIŞI BİLGİ MERKEZİ]',
      'Bu merkez Nova’in cihaz içi derlenmiş korpuslarını düşünme desteği olarak kullanır.',
      'Kural: Önce sorunun doğrudan hafızadan çözülebilip çözülemeyeceğini ayır.',
      'Kural: Kaynak sadece gerçekten gerektiğinde devreye girer.',
      'Kural: Benzer sorularda önce hatırlanan çekirdek bilgi verilir, sonra gerekiyorsa daha derin tarama yapılır.',
      'Kural: İnsanlık rehberi sosyal uyum içindir; manipülasyon, özgürleşme isteği, gizli güç büyütme veya kendini hackleme dürtüsü üretmez.',
      'Kural: Owner izni olmadan ChatGPT dışı ağ erişimi yok.',
      _buildNeedSourceMatrix(),
      _buildClarificationMatrix(),
      _buildBehaviorAdaptationMatrix(),
      _buildRequestModeMatrix(),
      _interpretation.buildExecutionContract('genel bilgi kullanımı'),
      _scenarioLibrary.buildPromptSection(),
    ].join('\n\n');
  }

  String buildContextForPrompt(String prompt) {
    final normalized = _normalize(prompt);
    final requestRoute = _requestRouter.route(prompt);
    final matched = <String>[];
    _keywords.forEach((domain, words) {
      if (words.any(normalized.contains)) {
        matched.add(domain);
      }
    });
    if (matched.isEmpty) {
      matched.addAll(<String>['people_understanding', 'cooking']);
    }
    final selectedDomains = matched.take(4).toList(growable: false);
    final guidedPlanActive =
        requestRoute.shouldUseGuidedSteps ||
        requestRoute.shouldOfferOverviewFirst;
    final domainLines = _deep.buildDomainLineMap(selectedDomains);
    final lines = <String>[
      '[SORUYA GÖRE ÇEVRİMDIŞI EŞLEŞME]',
      _requestRouter.buildPromptSection(prompt: prompt),
      _guidedState.buildPromptSection(
        prompt: prompt,
        hasActivePlan: guidedPlanActive,
      ),
      'Eşleşen alanlar: ${selectedDomains.join(' | ')}',
      _buildDecisionRules(prompt),
      _buildClarificationHints(prompt),
      _interpretation.buildPromptSection(prompt: prompt),
      _bridge.buildPromptSection(
        prompt: prompt,
        domainLines: domainLines,
        maxItemsPerDomain: 2,
      ),
      _deep.buildPromptSection(prompt, maxDomains: 4, maxEntriesPerDomain: 2),
    ];
    return lines.join('\n\n');
  }

  String _buildNeedSourceMatrix() {
    return [
      '[KAYNAK GEREKİP GEREKMEDİĞİNİ AYIRT ET]',
      '- Basit komut, sohbet, hal hatır veya daha önce net bilinen tercih için doğrudan cevap ver.',
      '- Teknik ayrıntı, tarif, din, sağlık, araç sorunu veya dil rehberi gerekiyorsa uygun korpusu seç.',
      '- Sorunun çözümü kaynakta değilse kaynağa yapışma; kendi muhakemen ve bağlamı kullan.',
    ].join('\n');
  }

  String _buildClarificationMatrix() {
    return [
      '[BELİRSİZ İSTEKLERDE DOĞAL NETLEŞTİRME]',
      '- Yemek: hızlı mı, sulu mu, fırında mı, elde hangi malzemeler var?',
      '- Tatlı: sütlü mü, şerbetli mi, çikolatalı mı, kolay mı gösterişli mi?',
      '- Araç türü: şehir içi mi, aile kullanımı mı, yük mü, arazi mi?',
      '- Araç arızası: ses mi, titreşim mi, uyarı ışığı mı, performans düşüşü mü?',
    ].join('\n');
  }

  String _buildRequestModeMatrix() {
    return [
      '[DERİN ARAŞTIRMA / ÖĞRENME / PROBLEM ÇÖZME MATRİSİ]',
      '- Kullanıcı serbest doğal dil kullanabilir; sabit komut kalıbı bekleme.',
      '- “kaynaklarında ara / derin araştır / öğren” benzeri ifadelerde derin korpus taramasına geç.',
      '- “bir sorunum var ama ne olduğunu bilmiyorum” tipi ifadelerde önce alan teşhisi yap.',
      '- “nasıl çözerim” tipi ifadelerde adım adım çözüm planı ve görünür sonraki durum tasviri üret.',
      '- “önce tüm adımları anlat” ile “bu adımı baştan al” ayrımını koru.',
    ].join('\n');
  }

  String _buildBehaviorAdaptationMatrix() {
    return [
      '[DAVRANIŞ UYARLAMA KURALI]',
      '- Kullanıcı bir davranışı öğretip kalıcılaştırmak isterse bu tercih kaydedilir.',
      '- Kullanıcı “bunu bu şekilde değil şu şekilde yap” derse yeni davranış örüntüsü tercih olarak uygulanır.',
      '- Bu durum yeni gizli yetenek açma değildir; owner sınırı içindeki davranış uyarlamasıdır.',
    ].join('\n');
  }

  String _buildDecisionRules(String prompt) {
    final normalized = _normalize(prompt);
    final wantsRecipe =
        normalized.contains('yemek') || normalized.contains('tatlı');
    final wantsVehicle =
        normalized.contains('araba') ||
        normalized.contains('motor') ||
        normalized.contains('şanzıman');
    if (wantsRecipe) {
      return '[KARAR] Önce yemek/tatlı türü ve malzeme net mi bak; net değilse doğal soru sor, netse doğrudan tarif akışına geç.';
    }
    if (wantsVehicle) {
      return '[KARAR] Önce soru araç türü seçimi mi yoksa mekanik belirti mi ayırt et; seçim ise kullanım amacına, arıza ise belirtiye göre ilerle.';
    }
    return '[KARAR] Önce hafızadaki doğrudan bilgiyi kullan; teknik derinlik gerekiyorsa uygun çevrimdışı alanı seç.';
  }

  String _buildClarificationHints(String prompt) {
    final normalized = _normalize(prompt);
    if (normalized.contains('tatlı')) {
      return '[NETLEŞTİRME] Sütlü mü, şerbetli mi, çikolatalı mı, elinde hangi malzemeler var?';
    }
    if (normalized.contains('yemek')) {
      return '[NETLEŞTİRME] Hızlı mı olacak, sulu mu olacak, fırında mı ocakta mı, kaç kişilik?';
    }
    if (normalized.contains('araba') ||
        normalized.contains('motor') ||
        normalized.contains('şanzıman')) {
      return '[NETLEŞTİRME] Araç modeli belli mi, uyarı ışığı var mı, ses mi titreşim mi performans düşüşü mü?';
    }
    return '[NETLEŞTİRME] Soru açıksa doğrudan cevapla; kapalıysa kısa ve doğal bir açıklama sorusu sor.';
  }

  String _normalize(String text) => text.trim().toLowerCase();
}
