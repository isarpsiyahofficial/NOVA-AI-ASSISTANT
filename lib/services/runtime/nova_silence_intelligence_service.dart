// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaSilenceKind {
  roomAmbient,
  thinkingGap,
  clarificationThreshold,
  replyExpectation,
  overloadRetreat,
  naturalPause,
  emotionalPause,
}

class NovaSilenceAnalysis {
  final String label;
  final NovaSilenceKind kind;
  final bool shouldWait;
  final bool shouldBackchannel;
  final bool shouldClarify;
  final List<String> cues;
  final List<String> rules;

  const NovaSilenceAnalysis({
    required this.label,
    required this.kind,
    required this.shouldWait,
    required this.shouldBackchannel,
    required this.shouldClarify,
    required this.cues,
    required this.rules,
  });

  String buildPromptSection() {
    return <String>[
      'SESSİZLİK ZEKÂSI:',
      '- sessizlik yorumu: $label',
      '- tür: ${kind.name}',
      '- bekleme: ${shouldWait ? 'evet' : 'hayır'}',
      '- backchannel: ${shouldBackchannel ? 'evet' : 'hayır'}',
      '- netleştirme: ${shouldClarify ? 'evet' : 'hayır'}',
      if (cues.isNotEmpty) '- ipuçları: ${cues.join(' | ')}',
      ...rules.map((e) => '- $e'),
    ].join('\n');
  }
}

class NovaSilenceIntelligenceService {
  const NovaSilenceIntelligenceService();

  String classify({
    required String prompt,
    required bool roomPresenceOpportunity,
    required int recentResponseCount,
    required bool shouldClarify,
  }) {
    return analyze(
      prompt: prompt,
      roomPresenceOpportunity: roomPresenceOpportunity,
      recentResponseCount: recentResponseCount,
      shouldClarify: shouldClarify,
    ).label;
  }

  NovaSilenceAnalysis analyze({
    required String prompt,
    required bool roomPresenceOpportunity,
    required int recentResponseCount,
    required bool shouldClarify,
  }) {
    final lower = prompt.toLowerCase().trim();
    final cues = <String>[];
    late final NovaSilenceKind kind;
    late final String label;

    if (lower.isEmpty && roomPresenceOpportunity) {
      kind = NovaSilenceKind.roomAmbient;
      label = 'pasif oda sessizliği';
      cues.add('oda açık ama doğrudan davet yok');
    } else if (_containsAny(lower, const ['...', 'hmm', 'şey', 'sey'])) {
      kind = NovaSilenceKind.thinkingGap;
      label = 'düşünme boşluğu';
      cues.add('yarım niyet veya düşünme sesi var');
    } else if (shouldClarify) {
      kind = NovaSilenceKind.clarificationThreshold;
      label = 'netleştirme eşiği';
      cues.add('anlamda belirsizlik var');
    } else if (_containsAny(lower, const ['of', 'ah', 'zor', 'bilmiyorum'])) {
      kind = NovaSilenceKind.emotionalPause;
      label = 'duygusal durak';
      cues.add('yüksek sürtünmeli duygu boşluğu');
    } else if (lower.endsWith('?')) {
      kind = NovaSilenceKind.replyExpectation;
      label = 'cevap bekleyen açık uç';
      cues.add('soru kapanışı mevcut');
    } else if (recentResponseCount >= 3) {
      kind = NovaSilenceKind.overloadRetreat;
      label = 'nova ağırlığı yükseldi';
      cues.add('yakın geçmişte aşırı yanıt üretildi');
    } else {
      kind = NovaSilenceKind.naturalPause;
      label = 'doğal kısa durak';
      cues.add('konuşma akışı içinde normal boşluk');
    }

    final shouldWait =
        kind == NovaSilenceKind.roomAmbient ||
        kind == NovaSilenceKind.thinkingGap ||
        kind == NovaSilenceKind.emotionalPause;
    final shouldBackchannel =
        kind == NovaSilenceKind.thinkingGap ||
        kind == NovaSilenceKind.emotionalPause;
    final rules = <String>[
      'Düşünme boşluğu ile gerçek konuşma bitişini ayır.',
      'Oda sessiz ama davet yoksa sessiz kalmak da doğal davranıştır.',
      'Duygusal durakta çözüm yağdırma; önce eşlik et.',
    ];
    if (kind == NovaSilenceKind.replyExpectation) {
      rules.add('Soru bekleniyorsa yanıtı gereksiz geciktirme.');
    }
    if (kind == NovaSilenceKind.overloadRetreat) {
      rules.add('Bu tur kısa kal ve yeni katman açma.');
    }

    return NovaSilenceAnalysis(
      label: label,
      kind: kind,
      shouldWait: shouldWait,
      shouldBackchannel: shouldBackchannel,
      shouldClarify: shouldClarify,
      cues: cues,
      rules: rules,
    );
  }

  String buildPromptSection(String silenceState) {
    return <String>[
      'SESSİZLİK ZEKÂSI:',
      '- sessizlik yorumu: $silenceState',
      'KURAL: Düşünme boşluğu ile gerçek konuşma bitişini ayır.',
      'KURAL: Oda sessiz ama davet yoksa sessiz kalmak da doğal davranıştır.',
    ].join('\n');
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (text.contains(part)) return true;
    }
    return false;
  }
}
