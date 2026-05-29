// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
class NovaCallAcousticEmotionLayerService {
  const NovaCallAcousticEmotionLayerService();

  Map<String, dynamic> analyze({
    required String transcript,
    required String sourceSystem,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) {
    final text = transcript.trim().toLowerCase();
    final bool callContext =
        sourceSystem.contains('call') ||
        context['callMode'] == true ||
        context['companionMode'] == true;
    final punctuationStress = _clamp(
      (text.contains('!') ? 0.18 : 0) +
          (RegExp(r'\?{2,}').hasMatch(text) ? 0.10 : 0),
    );
    final repeatPressure = _repeatCueScore(text);
    final statedUrgency = _score(text, const <String>[
      'acil',
      'hemen',
      'şimdi',
      'panik',
      'yetiş',
      'çabuk',
      'korktum',
      'endişe',
      'kaygı',
      'yardım et',
      'ulaşmam lazım',
    ]);
    final sadScore = _score(text, const <String>[
      'üzgün',
      'moralim bozuk',
      'kötüyüm',
      'kırıldım',
      'yalnızım',
      'canım sıkkın',
      'iyi değilim',
    ]);
    final angryScore = _score(text, const <String>[
      'sinirli',
      'kızgınım',
      'öfkeliyim',
      'saçmalık',
      'rezalet',
      'yeter',
      'bekletemem',
    ]);
    final calmScore = _score(text, const <String>[
      'rahat',
      'sakin',
      'tamam',
      'sorun değil',
      'müsaitsen',
      'rica etsem',
      'uygunsa',
    ]);
    final ownerEscalationScore = _score(text, const <String>[
      'uyandır',
      'haber ver',
      'önemli',
      'çok önemli',
      'bekleyemem',
    ]);

    final stressedScore = _clamp(
      statedUrgency + punctuationStress + (repeatPressure * 0.75),
    );
    final urgency = _clamp(
      (stressedScore * 0.55) +
          (angryScore * 0.20) +
          (ownerEscalationScore * 0.25),
    );
    final empathyNeed = _clamp(
      (sadScore * 0.62) + (stressedScore * 0.18) + (repeatPressure * 0.10),
    );
    final stability = _clamp(
      1.0 -
          ((stressedScore * 0.42) +
              (angryScore * 0.30) +
              (sadScore * 0.12) +
              (repeatPressure * 0.08)),
    );
    final attentiveness = _clamp(
      (calmScore * 0.45) +
          ((1.0 - urgency) * 0.20) +
          ((1.0 - empathyNeed) * 0.10),
    );

    final scores = <String, double>{
      'stressed': stressedScore,
      'sad': sadScore,
      'angry': angryScore,
      'calm': calmScore,
      'attentive': attentiveness,
    };

    String dominant = 'neutral';
    double dominantScore = 0.0;
    for (final entry in scores.entries) {
      if (entry.value > dominantScore) {
        dominant = entry.key;
        dominantScore = entry.value;
      }
    }
    if (dominantScore < 0.20) dominant = callContext ? 'attentive' : 'neutral';

    final confidence = _clamp(
      (dominantScore * 0.55) +
          (repeatPressure * 0.10) +
          (punctuationStress * 0.15) +
          (callContext ? 0.15 : 0.05),
    );
    return <String, dynamic>{
      'callAcousticEmotionLayerActive': callContext,
      'callAcousticEmotionModel': 'heuristic_v2_confidence',
      'callAcousticDominantEmotion': dominant,
      'callAcousticUrgency': urgency,
      'callAcousticEmpathyNeed': empathyNeed,
      'callAcousticStability': stability,
      'callAcousticAttentiveness': attentiveness,
      'callAcousticSignals': <String, double>{
        ...scores,
        'repeatPressure': repeatPressure,
        'punctuationStress': punctuationStress,
        'ownerEscalation': ownerEscalationScore,
      },
      'callAcousticConfidence': confidence,
      'callAcousticConfidenceBand': _band(confidence),
      'callAcousticInferenceMode': 'probabilistic',
    };
  }

  double _repeatCueScore(String text) {
    if (text.isEmpty) return 0.0;
    double score = 0.0;
    if (RegExp(
      r'\b(lütfen|nolur|ne olur)\b.*\b(lütfen|nolur|ne olur)\b',
    ).hasMatch(text)) {
      score += 0.18;
    }
    if (RegExp(
      r'\b(acil|hemen|şimdi)\b.*\b(acil|hemen|şimdi)\b',
    ).hasMatch(text)) {
      score += 0.22;
    }
    if (RegExp(r'(.)\1{2,}').hasMatch(text)) {
      score += 0.10;
    }
    return _clamp(score);
  }

  String _band(double value) {
    if (value >= 0.78) return 'high';
    if (value >= 0.50) return 'medium';
    return 'low';
  }

  double _score(String text, List<String> cues) {
    if (text.isEmpty) return 0.0;
    double score = 0.0;
    for (final cue in cues) {
      if (text.contains(cue)) score += 0.17;
    }
    return _clamp(score);
  }

  double _clamp(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}
