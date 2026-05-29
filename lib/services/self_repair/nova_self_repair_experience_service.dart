// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// Generated strengthening patch for digital-human voice-first behavior.

class NovaRepairExperienceCard {
  final String issueCode;
  final String summary;
  final int attempts;
  final int successes;
  final int failures;
  final double confidence;
  final List<String> knownFixPatterns;
  const NovaRepairExperienceCard({
    required this.issueCode,
    required this.summary,
    required this.attempts,
    required this.successes,
    required this.failures,
    required this.confidence,
    required this.knownFixPatterns,
  });
}

class NovaSelfRepairExperienceService {
  const NovaSelfRepairExperienceService();
  NovaRepairExperienceCard buildCard({
    required String issueCode,
    required List<Map<String, dynamic>> history,
  }) {
    int attempts = 0, successes = 0, failures = 0;
    final fixes = <String>[];
    for (final item in history) {
      if ((item['issueCode'] ?? '') != issueCode) continue;
      attempts++;
      if (item['resolved'] == true)
        successes++;
      else
        failures++;
      final fix = (item['fix'] ?? '').toString().trim();
      if (fix.isNotEmpty && !fixes.contains(fix)) fixes.add(fix);
    }
    final confidence = attempts == 0 ? 0.08 : (successes / attempts);
    return NovaRepairExperienceCard(
      issueCode: issueCode,
      summary: _summary(issueCode, attempts, successes, failures),
      attempts: attempts,
      successes: successes,
      failures: failures,
      confidence: confidence,
      knownFixPatterns: fixes,
    );
  }

  Map<String, dynamic> buildRepairPlan({
    required String issueCode,
    required String subsystem,
    required NovaRepairExperienceCard card,
    required bool canSelfRepair,
    required bool ownerPatchAllowed,
  }) {
    final shouldEscalate =
        !canSelfRepair || (card.attempts >= 3 && card.confidence < 0.34);
    final shouldNarrateFailure = card.attempts >= 1 && card.confidence < 0.25;
    final plan = <String, dynamic>{
      'issueCode': issueCode,
      'subsystem': subsystem,
      'canSelfRepair': canSelfRepair,
      'ownerPatchAllowed': ownerPatchAllowed,
      'shouldEscalate': shouldEscalate,
      'shouldNarrateFailure': shouldNarrateFailure,
      'shouldRetryWithExperience': card.knownFixPatterns.isNotEmpty,
      'retryBudget': _retryBudget(card),
      'honestyLine': honestyLine(
        issueCode: issueCode,
        shouldEscalate: shouldEscalate,
        shouldNarrateFailure: shouldNarrateFailure,
      ),
      'experienceConfidence': card.confidence,
      'knownFixPatterns': card.knownFixPatterns,
    };
    return plan;
  }

  String honestyLine({
    required String issueCode,
    required bool shouldEscalate,
    required bool shouldNarrateFailure,
  }) {
    if (shouldEscalate)
      return 'Bu sorunu tek başıma güvenle kapatamıyorum; kontrollü destek istemem gerekiyor.';
    if (shouldNarrateFailure)
      return 'Sorunu fark ettim, birkaç deneme yaptım ama henüz kararlı biçimde düzelmedi.';
    return 'Sorunu tanımladım ve deneyim hafızamla çözmeye çalışıyorum.';
  }

  int _retryBudget(NovaRepairExperienceCard card) {
    if (card.confidence >= 0.74) return 1;
    if (card.confidence >= 0.48) return 2;
    if (card.confidence >= 0.22) return 3;
    return 2;
  }

  String _summary(
    String issueCode,
    int attempts,
    int successes,
    int failures,
  ) => '$issueCode için deneme=$attempts başarı=$successes başarısız=$failures';
  Map<String, dynamic> buildExperienceAudit({
    required String issueCode,
    required String subsystem,
    required List<Map<String, dynamic>> history,
  }) {
    final card = buildCard(issueCode: issueCode, history: history);
    return <String, dynamic>{
      'issueCode': issueCode,
      'subsystem': subsystem,
      'attempts': card.attempts,
      'successes': card.successes,
      'failures': card.failures,
      'confidence': card.confidence,
      'knownFixPatterns': card.knownFixPatterns,
      'retryBudget': _retryBudget(card),
    };
  }

  List<Map<String, dynamic>> mergeHistories(
    List<Map<String, dynamic>> base,
    List<Map<String, dynamic>> incoming,
  ) {
    final merged = <Map<String, dynamic>>[...base];
    for (final item in incoming) {
      if (!merged.contains(item)) merged.add(item);
    }
    return merged;
  }

  String buildRecoveryHint(NovaRepairExperienceCard card) {
    if (card.confidence >= 0.74)
      return 'Geçmiş deneyim güçlü; dar ve kontrollü onarım uygula.';
    if (card.confidence >= 0.48)
      return 'Deneyim var; önce güvenli tekrar dene sonra doğrula.';
    if (card.confidence >= 0.22)
      return 'Sınırlı deneyim var; küçük adımlarla ilerle ve sonucu seslendir.';
    return 'Deneyim zayıf; güvenli sınırda kal ve gerekirse owner yönlendirmesi iste.';
  }
}
