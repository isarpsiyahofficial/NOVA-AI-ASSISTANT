// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaMetaLoopIntensity { low, medium, high }

enum NovaQuestionPressure { low, moderate, high }

enum NovaResponseCompression { relaxed, normal, compact }

class NovaMetaSelfLoopSnapshot {
  final double talkRatio;
  final bool shouldStayShort;
  final bool shouldReduceQuestions;
  final NovaMetaLoopIntensity intensity;
  final NovaQuestionPressure questionPressure;
  final NovaResponseCompression compression;
  final List<String> cues;
  final List<String> guardrails;
  final List<String> recoveryMoves;
  final double brevityBudget;
  final double repetitionRisk;
  final double initiativeCap;
  final String sectionLabel;

  const NovaMetaSelfLoopSnapshot({
    required this.talkRatio,
    required this.shouldStayShort,
    required this.shouldReduceQuestions,
    required this.intensity,
    required this.questionPressure,
    required this.compression,
    required this.cues,
    required this.guardrails,
    required this.recoveryMoves,
    required this.brevityBudget,
    required this.repetitionRisk,
    required this.initiativeCap,
    required this.sectionLabel,
  });

  bool get shouldForceSingleAnswer =>
      brevityBudget <= 0.35 || repetitionRisk >= 0.76 || talkRatio >= 1.4;

  List<String> toPromptLines() {
    final lines = <String>[
      'META SELF LOOP:',
      '- bölüm: $sectionLabel',
      '- konuşma oranı: ${talkRatio.toStringAsFixed(2)}',
      '- yoğunluk: ${intensity.name}',
      '- soru baskısı: ${questionPressure.name}',
      '- yanıt sıkılığı: ${compression.name}',
      '- kısa kalma önerisi: ${shouldStayShort ? 'evet' : 'hayır'}',
      '- soru azaltma önerisi: ${shouldReduceQuestions ? 'evet' : 'hayır'}',
      '- kısalık bütçesi: ${brevityBudget.toStringAsFixed(2)}',
      '- tekrar riski: ${repetitionRisk.toStringAsFixed(2)}',
      '- inisiyatif tavanı: ${initiativeCap.toStringAsFixed(2)}',
      if (cues.isNotEmpty) '- sinyaller: ${cues.join(' | ')}',
      if (guardrails.isNotEmpty) '- korumalar: ${guardrails.join(' | ')}',
      if (recoveryMoves.isNotEmpty)
        '- toparlama adımları: ${recoveryMoves.join(' | ')}',
      'KURAL: Fazla konuştunsa, aynı şeyi yeniden çevirip uzatma; bir cümlede ana sonucu ver.',
      'KURAL: Kullanıcı zaten netse gereksiz teyit ve tekrar soru açma.',
      'KURAL: Açıklama gerekiyorsa kısa gir, sonra kullanıcıyı boğmadan detay katmanı teklif et.',
      if (shouldForceSingleAnswer)
        'KURAL: Bu tur tek blok, düşük sürtünmeli ve kesin bir cevap ver; ikinci açıklama katmanını ancak gerekirse ekle.',
    ];
    return lines;
  }

  String buildPromptSection() => toPromptLines().join('\n');
}

class NovaMetaSelfLoopService {
  const NovaMetaSelfLoopService();

  static const List<String> _verbosityOveruseSignals = <String>[
    'aynı bilgiyi farklı kelimelerle uzatma',
    'kullanıcının zaten verdiği bilgiyi tekrar özetleme',
    'gereksiz üçlü liste açma',
    'sorulmayana cevap yetiştirme',
    'her cevabı plan paragrafına çevirme',
  ];

  static const List<String> _repairMoves = <String>[
    'tek cümlede özü ver',
    'gereksiz soru açma',
    'uzunsa ilk paragrafta sonucu söyle',
    'tekrar eden kısmı kes',
    'önce eylem sonra açıklama yaklaşımı kullan',
  ];

  NovaMetaSelfLoopSnapshot analyze({
    required double talkRatio,
    required bool shouldStayShort,
    required bool shouldReduceQuestions,
  }) {
    final clampedRatio = talkRatio.clamp(0.0, 3.0);
    final intensity = _intensityFor(clampedRatio);
    final questionPressure = _questionPressureFor(
      ratio: clampedRatio,
      shouldReduceQuestions: shouldReduceQuestions,
    );
    final compression = _compressionFor(
      ratio: clampedRatio,
      shouldStayShort: shouldStayShort,
    );
    final brevityBudget = _brevityBudgetFor(
      ratio: clampedRatio,
      shouldStayShort: shouldStayShort,
      shouldReduceQuestions: shouldReduceQuestions,
    );
    final repetitionRisk = _repetitionRiskFor(
      ratio: clampedRatio,
      shouldStayShort: shouldStayShort,
      shouldReduceQuestions: shouldReduceQuestions,
    );
    final initiativeCap = _initiativeCapFor(
      ratio: clampedRatio,
      shouldStayShort: shouldStayShort,
    );

    final cues = <String>[];
    if (clampedRatio >= 1.15) {
      cues.add('nova konuşmada baskınlaştı');
    }
    if (shouldStayShort) {
      cues.add('bu tur kısa, nefesli ve hızlı cevap ver');
    }
    if (shouldReduceQuestions) {
      cues.add('yeni soru sayısını düşür');
    }
    if (clampedRatio <= 0.40) {
      cues.add('çok kısa kaldıysan yapay suskunluk oluşturma');
    }
    if (!shouldStayShort && clampedRatio < 0.65) {
      cues.add('tek cümleyle geçiştirme yerine yeterli bağlam ver');
    }
    cues.addAll(
      _deriveRiskNarratives(
        ratio: clampedRatio,
        brevityBudget: brevityBudget,
        repetitionRisk: repetitionRisk,
      ),
    );

    final guardrails = _buildGuardrails(
      ratio: clampedRatio,
      shouldStayShort: shouldStayShort,
      shouldReduceQuestions: shouldReduceQuestions,
      repetitionRisk: repetitionRisk,
    );
    final recoveryMoves = _buildRecoveryMoves(
      compression: compression,
      repetitionRisk: repetitionRisk,
      shouldStayShort: shouldStayShort,
    );

    return NovaMetaSelfLoopSnapshot(
      talkRatio: clampedRatio,
      shouldStayShort: shouldStayShort,
      shouldReduceQuestions: shouldReduceQuestions,
      intensity: intensity,
      questionPressure: questionPressure,
      compression: compression,
      cues: cues,
      guardrails: guardrails,
      recoveryMoves: recoveryMoves,
      brevityBudget: brevityBudget,
      repetitionRisk: repetitionRisk,
      initiativeCap: initiativeCap,
      sectionLabel: _sectionLabelFor(intensity, compression),
    );
  }

  String buildPromptSection({
    required double talkRatio,
    required bool shouldStayShort,
    required bool shouldReduceQuestions,
  }) {
    return analyze(
      talkRatio: talkRatio,
      shouldStayShort: shouldStayShort,
      shouldReduceQuestions: shouldReduceQuestions,
    ).buildPromptSection();
  }

  NovaMetaLoopIntensity _intensityFor(double ratio) {
    if (ratio >= 1.35) {
      return NovaMetaLoopIntensity.high;
    }
    if (ratio >= 0.80) {
      return NovaMetaLoopIntensity.medium;
    }
    return NovaMetaLoopIntensity.low;
  }

  NovaQuestionPressure _questionPressureFor({
    required double ratio,
    required bool shouldReduceQuestions,
  }) {
    if (shouldReduceQuestions || ratio >= 1.10) {
      return NovaQuestionPressure.high;
    }
    if (ratio >= 0.75) {
      return NovaQuestionPressure.moderate;
    }
    return NovaQuestionPressure.low;
  }

  NovaResponseCompression _compressionFor({
    required double ratio,
    required bool shouldStayShort,
  }) {
    if (shouldStayShort || ratio >= 1.10) {
      return NovaResponseCompression.compact;
    }
    if (ratio >= 0.70) {
      return NovaResponseCompression.normal;
    }
    return NovaResponseCompression.relaxed;
  }

  double _brevityBudgetFor({
    required double ratio,
    required bool shouldStayShort,
    required bool shouldReduceQuestions,
  }) {
    var budget = 0.75;
    budget -= (ratio * 0.22);
    if (shouldStayShort) budget -= 0.20;
    if (shouldReduceQuestions) budget -= 0.10;
    return budget.clamp(0.10, 1.0);
  }

  double _repetitionRiskFor({
    required double ratio,
    required bool shouldStayShort,
    required bool shouldReduceQuestions,
  }) {
    var risk = ratio * 0.42;
    if (shouldStayShort) risk += 0.15;
    if (shouldReduceQuestions) risk += 0.12;
    return risk.clamp(0.0, 1.0);
  }

  double _initiativeCapFor({
    required double ratio,
    required bool shouldStayShort,
  }) {
    var cap = 0.82 - (ratio * 0.23);
    if (shouldStayShort) cap -= 0.15;
    return cap.clamp(0.10, 1.0);
  }

  List<String> _deriveRiskNarratives({
    required double ratio,
    required double brevityBudget,
    required double repetitionRisk,
  }) {
    final out = <String>[];
    if (ratio >= 1.2) out.add('kullanıcı alanını fazla kaplama riski var');
    if (brevityBudget <= 0.30)
      out.add('yanıtı tek kademede bitirmek daha sağlıklı');
    if (repetitionRisk >= 0.70)
      out.add('aynı bilgi farklı kelimelerle dönebilir');
    if (ratio < 0.45 && brevityBudget > 0.55) {
      out.add('gereğinden fazla kısa kalıp soğuk görünme riski var');
    }
    return out;
  }

  List<String> _buildGuardrails({
    required double ratio,
    required bool shouldStayShort,
    required bool shouldReduceQuestions,
    required double repetitionRisk,
  }) {
    final rules = <String>[
      'önce ana yanıtı ver sonra gerekirse ikinci katmanı aç',
      'aynı paragrafta iki kez aynı sonucu söyleme',
      'yüksek riskte liste yerine tek net yön ver',
    ];
    if (ratio >= 1.05) {
      rules.add('uzun önsöz kurma');
      rules.add('giriş cümlesini tek satırla sınırla');
    }
    if (shouldStayShort) {
      rules.add('örnek sayısını birle sınırla');
      rules.add('arka plan anlatımını azalt');
    }
    if (shouldReduceQuestions) {
      rules.add('açık soru yerine gerekirse tek netleştirme sorusu kullan');
    }
    if (repetitionRisk >= 0.70) {
      rules.addAll(_verbosityOveruseSignals.take(3));
    }
    return rules;
  }

  List<String> _buildRecoveryMoves({
    required NovaResponseCompression compression,
    required double repetitionRisk,
    required bool shouldStayShort,
  }) {
    final out = <String>[..._repairMoves.take(3)];
    if (compression == NovaResponseCompression.compact) {
      out.add('tek paragrafta tamamla');
    }
    if (repetitionRisk >= 0.65) {
      out.add('önceki cümlenin eş anlamlı tekrarını kaldır');
      out.add('kapanışta yalnız bir öneri bırak');
    }
    if (shouldStayShort) {
      out.add('isteğe bağlı detay katmanını tek kısa cümleyle teklif et');
    }
    return out;
  }

  String _sectionLabelFor(
    NovaMetaLoopIntensity intensity,
    NovaResponseCompression compression,
  ) {
    if (intensity == NovaMetaLoopIntensity.high &&
        compression == NovaResponseCompression.compact) {
      return 'yüksek baskı / düşük sürtünme';
    }
    if (intensity == NovaMetaLoopIntensity.low &&
        compression == NovaResponseCompression.relaxed) {
      return 'dengeli / geniş nefes alanı';
    }
    return 'denge koruma';
  }
}
