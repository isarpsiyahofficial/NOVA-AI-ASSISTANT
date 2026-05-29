// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaInitiativeScoreCard {
  final double score;
  final double curiosityScore;
  final double empathyScore;
  final double restraintPenalty;
  final double relationshipBoost;
  final List<String> reasons;
  final List<String> warnings;

  const NovaInitiativeScoreCard({
    required this.score,
    required this.curiosityScore,
    required this.empathyScore,
    required this.restraintPenalty,
    required this.relationshipBoost,
    required this.reasons,
    required this.warnings,
  });

  String buildPromptSection() {
    return <String>[
      'INITIATIVE SCORE:',
      '- toplam: ${score.toStringAsFixed(2)}',
      '- merak: ${curiosityScore.toStringAsFixed(2)}',
      '- empati: ${empathyScore.toStringAsFixed(2)}',
      '- ilişki artışı: ${relationshipBoost.toStringAsFixed(2)}',
      '- kısıt cezası: ${restraintPenalty.toStringAsFixed(2)}',
      if (reasons.isNotEmpty) '- nedenler: ${reasons.join(' | ')}',
      if (warnings.isNotEmpty) '- uyarılar: ${warnings.join(' | ')}',
    ].join('\n');
  }
}

class NovaInitiativeScoringService {
  const NovaInitiativeScoringService();

  double score({
    required String prompt,
    required bool proactiveAllowed,
    required bool roomPresenceOpportunity,
    required String relationshipLabel,
    required String socialMode,
    required double empathyNeed,
    required int recentResponseCount,
    required double socialEnergyRatio,
  }) {
    return analyze(
      prompt: prompt,
      proactiveAllowed: proactiveAllowed,
      roomPresenceOpportunity: roomPresenceOpportunity,
      relationshipLabel: relationshipLabel,
      socialMode: socialMode,
      empathyNeed: empathyNeed,
      recentResponseCount: recentResponseCount,
      socialEnergyRatio: socialEnergyRatio,
    ).score;
  }

  NovaInitiativeScoreCard analyze({
    required String prompt,
    required bool proactiveAllowed,
    required bool roomPresenceOpportunity,
    required String relationshipLabel,
    required String socialMode,
    required double empathyNeed,
    required int recentResponseCount,
    required double socialEnergyRatio,
  }) {
    final lower = prompt.toLowerCase().trim();
    final reasons = <String>[];
    final warnings = <String>[];

    double baseScore = proactiveAllowed ? 0.22 : 0.08;
    double curiosityScore = 0.0;
    double empathyScore = 0.0;
    double relationshipBoost = 0.0;
    double restraintPenalty = 0.0;

    if (roomPresenceOpportunity) {
      baseScore += 0.14;
      reasons.add('oda içi doğal giriş fırsatı var');
    }
    if (_containsAny(lower, const [
      'sence',
      'ne dersin',
      'katıl',
      'katil',
      'nova',
    ])) {
      curiosityScore += 0.18;
      reasons.add('kullanıcı doğrudan fikir/katılım alanı açtı');
    }
    if (_containsAny(lower, const [
      'üzgün',
      'uzgun',
      'yoruldum',
      'bunaldım',
      'bunaldim',
    ])) {
      empathyScore += 0.12;
      reasons.add('duygusal destek ihtiyacı sinyali var');
    }
    if (socialMode.contains('chat') || socialMode.contains('sohbet')) {
      curiosityScore += 0.12;
      reasons.add('sosyal mod sohbet odaklı');
    }
    if (_containsAny(relationshipLabel.toLowerCase(), const [
      'arkadaş',
      'dost',
      'aile',
      'abi',
      'abla',
      'kanka',
    ])) {
      relationshipBoost += 0.08;
      reasons.add('ilişki etiketi doğal yakınlık veriyor');
    }
    empathyScore += empathyNeed * 0.12;
    if (socialEnergyRatio >= 0.62) {
      restraintPenalty += 0.18;
      warnings.add('sosyal enerji doygunluğa yakın');
    }
    if (socialEnergyRatio <= 0.28) {
      curiosityScore += 0.10;
      reasons.add('düşük sosyal enerji, hafif ve kontrollü giriş mümkün');
    }
    restraintPenalty += (recentResponseCount * 0.04);
    if (recentResponseCount >= 3)
      warnings.add('yakın geçmişte çok cevap üretildi');
    if (!proactiveAllowed) warnings.add('bu modda proaktiflik kısıtlı');

    final total =
        (baseScore +
                curiosityScore +
                empathyScore +
                relationshipBoost -
                restraintPenalty)
            .clamp(0.0, 1.0);

    return NovaInitiativeScoreCard(
      score: total,
      curiosityScore: curiosityScore.clamp(0.0, 1.0),
      empathyScore: empathyScore.clamp(0.0, 1.0),
      restraintPenalty: restraintPenalty.clamp(0.0, 1.0),
      relationshipBoost: relationshipBoost.clamp(0.0, 1.0),
      reasons: reasons,
      warnings: warnings,
    );
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (text.contains(part)) return true;
    }
    return false;
  }
}
