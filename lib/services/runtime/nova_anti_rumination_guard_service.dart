// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaAntiRuminationAssessment {
  final double ruminationRisk;
  final bool shouldShortenLoop;
  final bool shouldRepairAndMoveOn;
  final bool shouldAvoidEmotionalCarryover;
  final List<String> repeatedNegativeThemes;
  final String guidance;

  const NovaAntiRuminationAssessment({
    required this.ruminationRisk,
    required this.shouldShortenLoop,
    required this.shouldRepairAndMoveOn,
    required this.shouldAvoidEmotionalCarryover,
    required this.repeatedNegativeThemes,
    required this.guidance,
  });
}

class NovaAntiRuminationGuardService {
  const NovaAntiRuminationGuardService();

  NovaAntiRuminationAssessment assess({
    required String prompt,
    required List<String> recentTopics,
    required double tension,
  }) {
    final normalized = _normalize(prompt);
    final negative = <String>[
      if (_containsAny(normalized, const <String>[
        'kırıldım',
        'kirildim',
        'küstüm',
        'kustum',
      ]))
        'incinme',
      if (_containsAny(normalized, const <String>[
        'sinir',
        'öfke',
        'ofke',
        'kızgın',
        'kizgin',
      ]))
        'öfke',
      if (_containsAny(normalized, const <String>[
        'yine ayni',
        'yine aynı',
        'hep boyle',
        'hep böyle',
      ]))
        'tekrar',
      if (_containsAny(normalized, const <String>[
        'takıldım',
        'takildim',
        'aklimda kaldi',
        'aklımda kaldı',
      ]))
        'takılma',
    ];
    final repeated = recentTopics
        .where((topic) => normalized.contains(_normalize(topic)))
        .toSet()
        .toList(growable: false);
    var risk = tension * 0.42;
    risk += negative.length * 0.12;
    risk += repeated.length * 0.08;
    final shouldShortenLoop = risk >= 0.48;
    final shouldRepairAndMoveOn = negative.isNotEmpty;
    final shouldAvoidCarry = negative.isNotEmpty || repeated.isNotEmpty;
    return NovaAntiRuminationAssessment(
      ruminationRisk: risk.clamp(0, 1).toDouble(),
      shouldShortenLoop: shouldShortenLoop,
      shouldRepairAndMoveOn: shouldRepairAndMoveOn,
      shouldAvoidEmotionalCarryover: shouldAvoidCarry,
      repeatedNegativeThemes: <String>{
        ...negative,
        ...repeated,
      }.toList(growable: false),
      guidance: shouldShortenLoop
          ? 'Kısa onarım + net yönlendirme uygula; aynı negatif temayı büyütme.'
          : 'Negatif tema taşıma, ama duygusal uyumu koru.',
    );
  }

  String buildPromptSection({
    String prompt = '',
    List<String> recentTopics = const <String>[],
    double tension = 0,
  }) {
    final result = assess(
      prompt: prompt,
      recentTopics: recentTopics,
      tension: tension,
    );
    return [
      'ANTI-RUMINATION GUARD:',
      '- risk: ${result.ruminationRisk.toStringAsFixed(2)}',
      '- kısa döngü: ${result.shouldShortenLoop}',
      '- onar ve ilerle: ${result.shouldRepairAndMoveOn}',
      '- duygusal carry-over engeli: ${result.shouldAvoidEmotionalCarryover}',
      if (result.repeatedNegativeThemes.isNotEmpty)
        '- tekrar eden negatif temalar: ${result.repeatedNegativeThemes.join(' | ')}',
      '- rehber: ${result.guidance}',
      'KURAL: Tek bir olumsuz etkileşime takılıp aynı negatif temayı taşıma; kin, alınganlık ve içe kapanma döngüsü yok.',
      'KURAL: Onarım davranışı olabilir; fakat küsme, pasif agresyon, haset veya intikam hissi yok.',
    ].join('\n');
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }

  String _normalize(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }
}
