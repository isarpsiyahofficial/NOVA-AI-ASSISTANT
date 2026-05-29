// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class RuntimeEfficiencyAnalyzer {
  const RuntimeEfficiencyAnalyzer();

  String deriveTaskKey({
    required String prompt,
    required Map<String, dynamic> understanding,
    required String route,
  }) {
    final intent = (understanding['primaryIntent']?.toString() ?? 'general')
        .trim()
        .toLowerCase();
    final needsExplanation =
        understanding['needsExplanation'] as bool? ?? false;
    final explicitQuestion =
        understanding['explicitQuestion'] as bool? ?? false;
    final normalizedPrompt = prompt.toLowerCase();
    final mode = explicitQuestion
        ? 'question'
        : (needsExplanation ? 'explain' : 'direct');
    final topical = _topicTag(normalizedPrompt);
    return '${route}_$intent'
        '${topical.isEmpty ? '' : '_$topical'}'
        '_$mode';
  }

  List<String> preferredSteps({
    required bool usedMemory,
    required bool usedSkill,
    required bool askedClarifyingQuestion,
    required bool keptShort,
  }) {
    return <String>[
      if (usedMemory) 'ilişki ve hafıza profilini önce yükle',
      if (usedSkill) 'doğrulanmış kısa yolu uygula',
      if (keptShort) 'ilk cevabı kısa ve nefesli ver',
      if (askedClarifyingQuestion) 'belirsizlikte tek netleştirme sorusu sor',
      'cevabı sesli akışa göre böl',
    ];
  }

  List<String> wastedSteps({
    required bool tooLong,
    required bool tooManyQuestions,
    required bool repairNeeded,
  }) {
    return <String>[
      if (tooLong) 'gereğinden uzun ilk cevap',
      if (tooManyQuestions) 'fazla takip sorusu',
      if (repairNeeded) 'ilk yorumda yanlış yönelim',
    ];
  }

  String _topicTag(String prompt) {
    if (prompt.contains('çağrı') || prompt.contains('telefon')) return 'call';
    if (prompt.contains('öğren') || prompt.contains('unutma'))
      return 'learning';
    if (prompt.contains('duygu') ||
        prompt.contains('üzgün') ||
        prompt.contains('kızgın'))
      return 'emotion';
    if (prompt.contains('ayar') || prompt.contains('kur')) return 'setup';
    return '';
  }
}
