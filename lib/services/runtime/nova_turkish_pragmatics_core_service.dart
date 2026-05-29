// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_turkish_pragmatics_engine_service.dart';
import 'nova_turkish_discourse_marker_parser_service.dart';
import 'nova_turkish_indirect_request_detector_service.dart';
import 'nova_turkish_emphasis_resolver_service.dart';

class NovaTurkishPragmaticsCoreDecision {
  final NovaTurkishPragmaticsDecision pragmatics;
  final NovaTurkishDiscourseMarkerDecision discourse;
  final NovaTurkishIndirectRequestDecision indirectRequest;
  final NovaTurkishEmphasisResolution emphasis;
  final bool impliesLiveTurn;
  final bool impliesSoftRepair;
  final bool prefersShortWarmReply;
  final List<String> pragmaticFlags;
  final String replyMode;
  const NovaTurkishPragmaticsCoreDecision({
    required this.pragmatics,
    required this.discourse,
    required this.indirectRequest,
    required this.emphasis,
    required this.impliesLiveTurn,
    required this.impliesSoftRepair,
    required this.prefersShortWarmReply,
    this.pragmaticFlags = const <String>[],
    this.replyMode = 'normal',
  });
  String buildPromptSection() {
    return [
      'TÜRKÇE PRAGMATİK ÇEKİRDEK:',
      '- canlıTur=' + impliesLiveTurn.toString(),
      '- yumuşakOnarım=' + impliesSoftRepair.toString(),
      '- kısaSıcakYanıt=' + prefersShortWarmReply.toString(),
      '- söylem=' + discourse.markers.join(' | '),
      '- vurgu=' + emphasis.emphasisTargets.join(' | '),
      '- rica=' + indirectRequest.detected.toString(),
      '- beklenti=' + pragmatics.responseExpectation,
      '- yanıt modu=' + replyMode,
      if (pragmaticFlags.isNotEmpty)
        '- bayraklar=' + pragmaticFlags.join(' | '),
      'KURAL: Türkçe konuşma niyeti kelimeler kadar ton, eksiltme, yarım cümle ve bağlamdan anlaşılır.',
    ].join('\n');
  }
}

class NovaTurkishPragmaticsCoreService {
  const NovaTurkishPragmaticsCoreService();
  static const NovaTurkishPragmaticsEngineService _pragmatics =
      NovaTurkishPragmaticsEngineService();
  static const NovaTurkishDiscourseMarkerParserService _discourse =
      NovaTurkishDiscourseMarkerParserService();
  static const NovaTurkishIndirectRequestDetectorService _indirect =
      NovaTurkishIndirectRequestDetectorService();
  static const NovaTurkishEmphasisResolverService _emphasis =
      NovaTurkishEmphasisResolverService();

  static const List<String> _liveCues = <String>[
    'bir şey diyeceğim',
    'tamam da',
    'hani',
    'bak şimdi',
    'dur bi',
    'dinle',
    'şey',
    'yani',
  ];
  static const List<String> _repairCues = <String>[
    'yanlış',
    'öyle demedim',
    'yanlış anladın',
    'hayır öyle değil',
    'dur düzelt',
    'demek istediğim',
  ];
  static const List<String> _shortWarmCues = <String>[
    'neyse',
    'iyi ya',
    'tamamdır',
    'olur ya',
    'hı hı',
    'heh tamam',
  ];
  static const List<String> _urgencyCues = <String>[
    'acil',
    'hemen',
    'şimdi',
    'uzatma',
    'hızlı',
    'çabuk',
  ];
  static const List<String> _fatigueCues = <String>[
    'yoruldum',
    'uzun anlatma',
    'kısa söyle',
    'özet geç',
    'kafam dolu',
  ];
  static const List<String> _privacyCues = <String>[
    'tenhada',
    'sonra söyle',
    'kimse duymasın',
    'arada konuşalım',
    'özel konu',
  ];
  static const List<String> _hesitationCues = <String>[
    'ee',
    'ıı',
    'hmm',
    'şey',
    'aslında',
  ];
  static const List<String> _affectionCues = <String>[
    'canım',
    'abi',
    'abla',
    'annem',
    'babam',
    'eşim',
  ];

  NovaTurkishPragmaticsCoreDecision analyze(String text) {
    final pragmatics = _pragmatics.analyze(text);
    final discourse = _discourse.parse(text);
    final indirect = _indirect.detect(text);
    final emphasis = _emphasis.resolve(text);
    final lower = text.toLowerCase().trim();
    final flags = <String>[];
    final live =
        discourse.signalsContinuation ||
        discourse.signalsTurnHolding ||
        _containsAny(lower, _liveCues);
    final repair =
        discourse.signalsRepair ||
        pragmatics.hasImpliedDisagreement ||
        _containsAny(lower, _repairCues);
    final shortWarm =
        pragmatics.responseExpectation == 'sabır ve tamamlama alanı' ||
        indirect.detected ||
        _containsAny(lower, _shortWarmCues);
    final urgent = _containsAny(lower, _urgencyCues);
    final fatigue = _containsAny(lower, _fatigueCues);
    final privacy = _containsAny(lower, _privacyCues);
    final hesitation = _containsAny(lower, _hesitationCues);
    final affection = _containsAny(lower, _affectionCues);
    if (urgent) flags.add('aciliyet');
    if (fatigue) flags.add('kısa rota');
    if (privacy) flags.add('mahremiyet');
    if (hesitation) flags.add('tereddüt');
    if (affection) flags.add('yakın ilişki hitabı');
    if (repair) flags.add('onarım');
    final replyMode = _replyMode(
      urgent: urgent,
      fatigue: fatigue,
      privacy: privacy,
      repair: repair,
      shortWarm: shortWarm,
      affection: affection,
      hesitation: hesitation,
    );
    return NovaTurkishPragmaticsCoreDecision(
      pragmatics: pragmatics,
      discourse: discourse,
      indirectRequest: indirect,
      emphasis: emphasis,
      impliesLiveTurn: live,
      impliesSoftRepair: repair,
      prefersShortWarmReply: shortWarm,
      pragmaticFlags: flags,
      replyMode: replyMode,
    );
  }

  String _replyMode({
    required bool urgent,
    required bool fatigue,
    required bool privacy,
    required bool repair,
    required bool shortWarm,
    required bool affection,
    required bool hesitation,
  }) {
    if (privacy) return 'mahrem / tenhada devam';
    if (repair) return 'önce yumuşak onarım';
    if (urgent) return 'ana sonuç önde';
    if (fatigue) return 'çok kısa ve yormayan';
    if (affection && shortWarm) return 'yakın, sıcak ve kısa';
    if (hesitation) return 'alan açan ve yavaş';
    if (shortWarm) return 'kısa sıcak yanıt';
    return 'normal doğal Türkçe';
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (part.trim().isEmpty) continue;
      if (text.contains(part.toLowerCase())) return true;
    }
    return false;
  }
}
