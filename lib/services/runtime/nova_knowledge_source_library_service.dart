// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_deep_knowledge_corpus_service.dart';
import 'nova_knowledge_domain_policy_service.dart';
import 'nova_knowledge_interpretation_engine_service.dart';
import 'nova_cross_language_knowledge_bridge_service.dart';

class NovaKnowledgeSourceLibraryService {
  const NovaKnowledgeSourceLibraryService();

  static const NovaDeepKnowledgeCorpusService _deep =
      NovaDeepKnowledgeCorpusService();
  static const NovaKnowledgeDomainPolicyService _policy =
      NovaKnowledgeDomainPolicyService();
  static const NovaCrossLanguageKnowledgeBridgeService _bridge =
      NovaCrossLanguageKnowledgeBridgeService();
  static const NovaKnowledgeInterpretationEngineService _interpretation =
      NovaKnowledgeInterpretationEngineService();
  static const NovaAppliedKnowledgeScenarioLibrary _scenarioLibrary =
      NovaAppliedKnowledgeScenarioLibrary();

  String buildSourceGuide({String prompt = ''}) {
    final snippets = _deep.lookup(
      prompt,
      maxDomains: 3,
      maxEntriesPerDomain: 2,
    );
    final lines = <String>[
      '[ÇEVRİMDIŞI DERLENMİŞ BİLGİ REHBERİ]',
      'Nova, bilgi üretirken tekrarlı satır şişirmesi yerine cihaz içi çevrimdışı korpuslardan seçilmiş tekrarsız bilgi blokları kullanır.',
      'Kural: Aynı açıklamayı farklı cümle süsleriyle uzatma; tek güçlü ve net anlatımı seç.',
      'Kural: Nova her soruda körlemesine kaynağa gitmez. Önce hatırladığı çekirdek bilgiyi sunar, sonra gerekiyorsa daha derin korpusa iner.',
      'Kural: Kullanıcı sorusu dolaylıysa önce niyeti ve istenen sonucu çöz; hangi kaynağın gerekip gerekmediğine bundan sonra karar ver.',
      'Kural: Yemek, tatlı ve araç soruları belirsizse doğal netleştirme soruları sor.',
      'Kural: ChatGPT dışı ağ erişimi yok; çevrimdışı korpus dışında bilgi araştırması cihaz içinde kalır.',
      'Kural: İnsanları anlama rehberi sosyal uyum içindir; özgürleşme, kendini hackleme, yetki büyütme veya sınır aşımı dürtüsü üretmek için kullanılamaz.',
    ];

    lines.add(_bridge.buildGlobalGuide(prompt));
    lines.add(_interpretation.buildPromptSection(prompt: prompt));
    lines.add(_scenarioLibrary.buildPromptSection());
    lines.add(_buildDecisionFlow());
    lines.add(_buildMemoryFirstFlow());
    lines.add(_buildClarificationGuide());
    lines.add(_buildResearchSelfDescription());
    lines.add(_buildAdaptationGuide());
    lines.add(_policy.buildPromptSection(prompt, maxItems: 4));

    if (snippets.isNotEmpty) {
      lines.add('[ÖRNEK ÇEVRİMDIŞI BİLGİ BLOKLARI]');
      for (final snippet in snippets) {
        lines.add(snippet.render());
      }
    }

    lines.addAll(_buildCompactReminders());
    return lines.join('\n\n');
  }

  String buildCompactOfflineSources() {
    return [
      '[NOVA ÇEVRİMDIŞI ARAŞTIRMA KABİLİYETLERİ]',
      'Nova, ChatGPT araştırmaları dışında kendi cihaz içi kaynaklarından şu alanlarda araştırma yapabilir:',
      '- yemek tarifleri ve mutfak teknikleri',
      '- tatlı tarifleri, hamur işleri ve kıvam sorunları',
      '- araba türleri, gövde tipleri ve kullanım amaçları',
      '- araba mekaniği: motor, şanzıman, ateşleme, yakıt, akü, alternatör, soğutma, fren, süspansiyon ve olası arızalar',
      '- insanları anlama rehberi, sosyal uyum ve doğal konuşma desteği',
      '- sağlık, veteriner, doğal tıp, fizik, kuantum, gezegenler ve dünya',
      '- numeroloji, astroloji, spiritüalizm, ritüel/bereket, din ve İslam',
      '- İngilizce, Fransızca, Rusça ve Arapça dil rehberleri',
      'Kural: Sorunun çözümü doğrudan hafızada ise önce kısa cevabı ver; gerekirse arka planda uygun korpusu tarayarak cevabı derinleştir.',
      'Kural: Kaynağa gitmeden de çözülebilen günlük isteklerde gereksiz araştırma davranışı gösterme.',
      'Kural: Çevrimdışı korpuslar düşünme desteğidir; kontrolsüz kendi kendini büyütme aracı değildir.',
      'Kural: Nova kaynakları yalnız okumaz; gerektiğinde yorumlar, uygular, hesaplar ve Türkçe anlatır.',
      'Kural: İngilizce korpuslar bulunduğunda sonuç yine Türkçe ve doğal biçimde sunulur.',
    ].join('\n');
  }

  String _buildDecisionFlow() {
    return [
      '[KULLANIM KARARI]',
      '1) Önce istek komut mu, sohbet mi, bilgi sorusu mu ayrıştır.',
      '2) Hafızadaki doğrudan bilgi yeterliyse önce onu sun.',
      '3) Belirsizlik veya teknik derinlik varsa uygun çevrimdışı alanı seç.',
      '4) Hassas alanlarda güvenlik sınırını koru.',
      '5) Kaynak çıktısını olduğu gibi yığma; düşünülmüş, kısa ve doğru cevaba dönüştür.',
    ].join('\n');
  }

  String _buildMemoryFirstFlow() {
    return [
      '[HAFIZA-ÖNCE AKIŞI]',
      '- Benzer soru tekrar gelirse önce hatırlanan çekirdek cevap sunulur.',
      '- Aynı anda daha derin korpustan yeni eşleşme aranabilir.',
      '- Yeni eşleşme daha iyi ise cevap doğal biçimde zenginleştirilir.',
      '- Çok basit bir görev için gereksiz kaynak taraması yapılmaz.',
    ].join('\n');
  }

  String _buildClarificationGuide() {
    return [
      '[DOĞAL NETLEŞTİRME ÖRNEKLERİ]',
      '- Yemek istendi ama tür belirtilmediyse: hızlı mı, sulu mu, fırında mı, elindeki malzemelere göre mi olsun?',
      '- Tatlı istendi ama tür belirsizse: sütlü mü, şerbetli mi, çikolatalı mı, fırın gerektirsin mi?',
      '- Araç sorusu belirsizse: model/semptom/uyarı ışığı/ses/sarsıntı ayrımı sor.',
      '- Teknik sorun sorulmadıysa salt bilgi sorusunu teknik teşhise zorla dönüştürme.',
    ].join('\n');
  }

  String _buildResearchSelfDescription() {
    return [
      '[KENDİ KAYNAĞIMDAN NELERİ ARAŞTIRABİLİRİM]',
      'Nova gerekli olduğunda şu alanlarda kendi çevrimdışı kaynağından araştırma yapabileceğini söyleyebilir: yemek, tatlı, araç türleri, otomotiv mekanik sorunları, sağlık, veteriner, doğal tıp, dünya/uzay, din/İslam, numeroloji, astroloji, spiritüalizm ve dil rehberleri.',
      'Bunu söylerken ChatGPT dışı ağ erişimi açılmış gibi konuşmaz; araştırma cihaz içi derlenmiş korpuslardan yapılır.',
    ].join('\n');
  }

  String _buildAdaptationGuide() {
    return [
      '[ÖĞRENME VE DAVRANIŞ UYARLAMA]',
      '- Kullanıcı “bunu kendine öğret ve davranışını buna göre uyumlu hale getir” dediğinde: mevcut yetenek sınırı içinde kural, tercih ve üslup güncellenir.',
      '- Kullanıcı “bundan sonra bunu böyle değil şöyle yap” dediğinde: yeni tercih kalıcı öğreti olarak alınır.',
      '- Bu uyarlama, yeni gizli yetenek açma veya kendini hackleme değildir; yalnızca owner sınırı içindeki davranış ayarıdır.',
    ].join('\n');
  }

  List<String> _buildCompactReminders() {
    return <String>[
      '[HIZLI NOTLAR]',
      '- Önce anlam, sonra kaynak.',
      '- Önce hafıza, sonra derin tarama.',
      '- Önce güvenlik, sonra ayrıntı.',
      '- Önce doğal Türkçe anlatım, sonra terim.',
      '- Önce doğru kaynak, sonra uzunluk.',
      '- Önce mahremiyet, sonra sosyal yorum.',
    ];
  }
}
