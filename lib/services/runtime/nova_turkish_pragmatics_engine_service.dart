// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaTurkishPragmaticsDecision {
  final List<String> discourseMarkers;
  final List<String> pragmaticSignals;
  final bool hasIndirectRequest;
  final bool hasImpliedDisagreement;
  final bool hasSoftening;
  final String likelyRegister;
  final String responseExpectation;

  const NovaTurkishPragmaticsDecision({
    required this.discourseMarkers,
    required this.pragmaticSignals,
    required this.hasIndirectRequest,
    required this.hasImpliedDisagreement,
    required this.hasSoftening,
    required this.likelyRegister,
    required this.responseExpectation,
  });

  String buildPromptSection() {
    return 'TÜRKÇE PRAGMATİK MOTORU: belirteçler=${discourseMarkers.join(" | ")}; sinyaller=${pragmaticSignals.join(" | ")}; dolaylıRica=$hasIndirectRequest; örtülüİtiraz=$hasImpliedDisagreement; yumuşatma=$hasSoftening; kayıt=$likelyRegister; beklenti=$responseExpectation';
  }
}

class NovaTurkishPragmaticsEngineService {
  const NovaTurkishPragmaticsEngineService();

  NovaTurkishPragmaticsDecision analyze(String raw) {
    final normalized = _normalize(raw);
    final markers = <String>[];
    final signals = <String>[];

    void addMarker(String m) {
      if (!markers.contains(m)) markers.add(m);
    }

    void addSignal(String s) {
      if (!signals.contains(s)) signals.add(s);
    }

    const discourse = {
      'ya': 'yakınlık/itiraz taşıyabilir',
      'hani': 'ortak zemin çağırıyor',
      'işte': 'düşünme veya vurgulu bağlama',
      'şey': 'yarım cümle/düşünme boşluğu',
      'yok artık': 'şaşkınlık veya itiraz',
      'tamam da': 'sınırlı itiraz',
      'neyse': 'konuyu kapatma veya gerilim azaltma',
      'bak': 'odak çağrısı',
      'yani': 'açıklama / yeniden kurma',
      'aslında': 'düzeltme / yumuşatma',
    };
    for (final entry in discourse.entries) {
      if (normalized.contains(entry.key)) {
        addMarker(entry.key);
        addSignal(entry.value);
      }
    }

    final hasIndirectRequest = _containsAny(normalized, const [
      'bakabilir misin',
      'yardımcı olur musun',
      'müsaitsen',
      'mümkünse',
      'bir baksana',
      'el atar mısın',
      'şuna da bakar mısın',
      'halledebilir misin',
    ]);
    final hasImpliedDisagreement = _containsAny(normalized, const [
      'tamam da',
      'öyle değil',
      'pek olmadı',
      'o kadar da değil',
      'yok artık',
      'bence pek',
      'mantıklı değil',
      'emin değilim ama',
    ]);
    final hasSoftening = _containsAny(normalized, const [
      'galiba',
      'sanırım',
      'acaba',
      'mümkünse',
      'sanki',
      'biraz',
      'gibi',
    ]);

    if (hasIndirectRequest) addSignal('komut olmayan rica');
    if (hasImpliedDisagreement) addSignal('örtülü itiraz');
    if (hasSoftening) addSignal('yumuşatılmış ifade');

    final likelyRegister =
        _containsAny(normalized, const ['efendim', 'lütfen', 'rica etsem'])
        ? 'resmi'
        : _containsAny(normalized, const ['ya', 'hani', 'işte', 'kanka', 'abi'])
        ? 'gündelik'
        : 'nötr';

    String responseExpectation = 'nötr';
    if (hasIndirectRequest) {
      responseExpectation = 'yardım veya aksiyon';
    } else if (hasImpliedDisagreement) {
      responseExpectation = 'savunmasız açıklama';
    } else if (markers.contains('şey') || markers.contains('yani')) {
      responseExpectation = 'sabır ve tamamlama alanı';
    } else if (markers.contains('ya') || markers.contains('hani')) {
      responseExpectation = 'bağlamsal duyarlılık';
    }

    return NovaTurkishPragmaticsDecision(
      discourseMarkers: markers,
      pragmaticSignals: signals,
      hasIndirectRequest: hasIndirectRequest,
      hasImpliedDisagreement: hasImpliedDisagreement,
      hasSoftening: hasSoftening,
      likelyRegister: likelyRegister,
      responseExpectation: responseExpectation,
    );
  }

  bool _containsAny(String text, List<String> parts) =>
      parts.any(text.contains);

  String _normalize(String raw) =>
      raw.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}
