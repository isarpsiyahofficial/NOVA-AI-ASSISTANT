// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaSpeechNativeCognitionBridgeService {
  const NovaSpeechNativeCognitionBridgeService();

  Map<String, dynamic> resolve({
    required Map<String, dynamic> metadata,
    required String latestPrompt,
  }) {
    final mode = (metadata['inputMode']?.toString() ?? 'voice').trim();
    final streaming = (metadata['streamingAsrActive'] as bool?) ?? true;
    final partial = (metadata['partialTranscriptStable'] as bool?) ?? false;
    final interruption = (metadata['possibleInterruption'] as bool?) ?? false;
    final speechFirst = mode != 'text';
    final tokenCount = latestPrompt
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .length;
    final normalizedPrompt = latestPrompt.toLowerCase().trim();
    final voiceIdentityLocked =
        (metadata['voiceIdentityLocked'] as bool?) ?? false;
    final ownerConfidence =
        (metadata['ownerConfidence'] as num?)?.toDouble() ?? 0.0;
    final inCall = (metadata['inCall'] as bool?) ?? false;
    final ttsActive = (metadata['ttsActive'] as bool?) ?? false;
    final farField = (metadata['farField'] as bool?) ?? true;
    final roomNoise = (metadata['roomNoise'] as num?)?.toDouble() ?? 0.0;

    final planningMode = _planningMode(
      tokenCount,
      streaming,
      partial,
      interruption,
      inCall,
    );
    final latencyBias = _latencyBias(
      speechFirst,
      tokenCount,
      inCall,
      roomNoise,
    );
    final turnTakingBias = _turnTakingBias(
      interruption,
      partial,
      ttsActive,
      inCall,
    );
    final cognitionProfile = _cognitionProfile(
      speechFirst: speechFirst,
      streaming: streaming,
      partial: partial,
      interruption: interruption,
      voiceIdentityLocked: voiceIdentityLocked,
      ownerConfidence: ownerConfidence,
      farField: farField,
      roomNoise: roomNoise,
      normalizedPrompt: normalizedPrompt,
    );

    return <String, dynamic>{
      'speechFirst': speechFirst,
      'streamingActive': streaming,
      'partialStable': partial,
      'possibleInterruption': interruption,
      'promptShape': tokenCount <= 8
          ? 'kısa sözlü komut'
          : tokenCount <= 18
          ? 'orta sözlü akış'
          : 'uzun sözlü akış',
      'planningMode': planningMode,
      'latencyBias': latencyBias,
      'turnTakingBias': turnTakingBias,
      'ownerConfidence': ownerConfidence,
      'voiceIdentityLocked': voiceIdentityLocked,
      'inCall': inCall,
      'ttsActive': ttsActive,
      'farField': farField,
      'roomNoise': roomNoise,
      'cognitionProfile': cognitionProfile,
      'chunkBudget': _chunkBudget(tokenCount, interruption, inCall),
      'repairTolerance': _repairTolerance(partial, roomNoise, interruption),
      'entityRetentionMode': _entityRetentionMode(normalizedPrompt, tokenCount),
      'listeningPriority': _listeningPriority(
        interruption,
        ttsActive,
        inCall,
        roomNoise,
      ),
    };
  }

  String buildPromptSection(Map<String, dynamic> bridge) {
    return [
      'SPEECH-NATIVE COGNITION KÖPRÜSÜ:',
      '- speech-first: ${bridge['speechFirst'] == true ? 'evet' : 'hayır'}',
      '- streaming aktif: ${bridge['streamingActive'] == true ? 'evet' : 'hayır'}',
      '- partial transcript stabil: ${bridge['partialStable'] == true ? 'evet' : 'hayır'}',
      '- olası araya giriş: ${bridge['possibleInterruption'] == true ? 'evet' : 'hayır'}',
      '- sözlü akış tipi: ${bridge['promptShape']}',
      '- planlama modu: ${bridge['planningMode']}',
      '- gecikme eğilimi: ${bridge['latencyBias']}',
      '- sıra alma eğilimi: ${bridge['turnTakingBias']}',
      '- cognition profile: ${bridge['cognitionProfile']}',
      '- chunk budget: ${bridge['chunkBudget']}',
      '- repair tolerance: ${bridge['repairTolerance']}',
      '- entity retention: ${bridge['entityRetentionMode']}',
      '- listening priority: ${bridge['listeningPriority']}',
      'KURAL: Yanıtı yazı gibi değil, duyulacak akış gibi kur; düşük gecikme, doğal sıra alma ve kısmi planlama öncelikli olsun.',
      'KURAL: Streaming ve partial durumunda tek nefeste uzun paragraf kurma; gerektiğinde kısa bloklarla ilerle.',
      'KURAL: Owner kimliği ve çağrı durumu speech-native biliş planını doğrudan değiştirmeli.',
    ].join('\n');
  }

  String _planningMode(
    int tokenCount,
    bool streaming,
    bool partial,
    bool interruption,
    bool inCall,
  ) {
    if (inCall && interruption) return 'çağrı-içi mikro plan';
    if (tokenCount <= 5) return 'anlık mikro plan';
    if (streaming && !partial) return 'erken başlat / geç kesinleştir';
    if (tokenCount <= 14) return 'kısa akış planı';
    return 'kademeli kısmi planlama';
  }

  String _latencyBias(
    bool speechFirst,
    int tokenCount,
    bool inCall,
    double roomNoise,
  ) {
    if (inCall) return 'çok düşük gecikme / çağrı dostu';
    if (!speechFirst) return 'dengeli';
    if (roomNoise >= 0.56) return 'erken kısa başla / sonra netleştir';
    if (tokenCount <= 8) return 'düşük gecikme öncelikli';
    return 'düşük gecikme / kademeli';
  }

  String _turnTakingBias(
    bool interruption,
    bool partial,
    bool ttsActive,
    bool inCall,
  ) {
    if (inCall && interruption) return 'çağrı güvenli hızlı yield';
    if (interruption) return 'erken bitirme ve araya giriş farkındalığı';
    if (!partial) return 'partial bekle ama floor kaptırma';
    if (ttsActive) return 'barge-in duyarlı';
    return 'dengeli sıra alma';
  }

  String _cognitionProfile({
    required bool speechFirst,
    required bool streaming,
    required bool partial,
    required bool interruption,
    required bool voiceIdentityLocked,
    required double ownerConfidence,
    required bool farField,
    required double roomNoise,
    required String normalizedPrompt,
  }) {
    final parts = <String>[];
    parts.add(speechFirst ? 'speech_first' : 'text_fallback');
    if (streaming) parts.add('streaming');
    if (partial) parts.add('partial_stable');
    if (interruption) parts.add('interrupt_watch');
    if (voiceIdentityLocked) parts.add('identity_locked');
    if (ownerConfidence >= 0.80) parts.add('owner_confident');
    if (farField) parts.add('far_field');
    if (roomNoise >= 0.56) parts.add('noisy_room');
    if (_containsAny(normalizedPrompt, const <String>['acil', 'hemen']))
      parts.add('urgent_prompt');
    if (_containsAny(normalizedPrompt, const <String>[
      'üzgün',
      'gergin',
      'bunaldım',
    ]))
      parts.add('emotional_prompt');
    return parts.join('|');
  }

  String _chunkBudget(int tokenCount, bool interruption, bool inCall) {
    if (inCall || interruption) return '4-8 kelime ilk blok';
    if (tokenCount <= 6) return 'tek kısa blok';
    if (tokenCount <= 16) return 'iki kısa blok';
    return 'çok bloklu kademeli çıktı';
  }

  String _repairTolerance(bool partial, double roomNoise, bool interruption) {
    if (roomNoise >= 0.56) return 'yüksek';
    if (!partial) return 'orta-yüksek';
    if (interruption) return 'orta';
    return 'düşük-orta';
  }

  String _entityRetentionMode(String normalizedPrompt, int tokenCount) {
    if (_containsAny(normalizedPrompt, const <String>[
      'kim',
      'kime',
      'ahmet',
      'mehmet',
      'nova',
      'nova',
    ])) {
      return 'agresif_kişi_tutma';
    }
    if (tokenCount <= 6) return 'çekirdek_token_tutma';
    return 'denge';
  }

  String _listeningPriority(
    bool interruption,
    bool ttsActive,
    bool inCall,
    double roomNoise,
  ) {
    if (inCall) return 'çok yüksek';
    if (interruption || ttsActive) return 'yüksek';
    if (roomNoise >= 0.56) return 'yüksek';
    return 'orta';
  }

  String _n(String input) => input.trim().toLowerCase();

  static const List<String> _directAddressCues = <String>[
    'nova',
    'nova',
    'buraya bak',
    'beni dinle',
  ];
  static const List<String> _repairCues = <String>[
    'dur',
    'yanlış',
    'duzelt',
    'düzelt',
    'öyle değil',
    'oyle degil',
  ];
  static const List<String> _urgencyCues = <String>[
    'acil',
    'hemen',
    'çabuk',
    'cabuk',
  ];

  bool _containsAny(String text, List<String> cues) {
    for (final cue in cues) {
      if (text.contains(cue)) return true;
    }
    return false;
  }

  Map<String, dynamic> buildNativeCognitionAudit({
    required String transcript,
    required bool hasQuestion,
    required bool hasInterruptionRisk,
  }) {
    final normalized = _n(transcript);
    return <String, dynamic>{
      'normalizedLength': normalized.length,
      'hasQuestion': hasQuestion,
      'hasInterruptionRisk': hasInterruptionRisk,
      'containsDirectAddress': _containsAny(normalized, _directAddressCues),
      'containsRepairCue': _containsAny(normalized, _repairCues),
      'containsUrgencyCue': _containsAny(normalized, _urgencyCues),
    };
  }

  String buildTurnTimingHint({
    required bool hasInterruptionRisk,
    required bool hasQuestion,
  }) {
    if (hasInterruptionRisk) return 'çok kısa gecikme ile cevap başlat';
    if (hasQuestion) return 'kısa düşünme arasıyla net cevap ver';
    return 'doğal mikro duraklamayı koru';
  }

  List<String> buildProsodyBridgeHints(String transcript) {
    final normalized = _n(transcript);
    return <String>[
      if (_containsAny(normalized, _urgencyCues))
        'vurgu: aciliyet ama panik yok',
      if (_containsAny(normalized, _repairCues))
        'vurgu: toparlayıcı ve yumuşak',
      if (_containsAny(normalized, _directAddressCues))
        'vurgu: doğrudan hitap ve netlik',
      if (!_containsAny(normalized, _urgencyCues) &&
          !_containsAny(normalized, _repairCues))
        'vurgu: dengeli ve doğal',
    ];
  }
}
