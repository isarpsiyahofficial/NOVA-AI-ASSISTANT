// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaDreamConsolidationPlan {
  final List<String> memoryKeepers;
  final List<String> relationshipAdjustments;
  final List<String> skillAdjustments;
  final List<String> discardHints;
  final String consolidationMode;
  final String narrativeSummary;

  const NovaDreamConsolidationPlan({
    required this.memoryKeepers,
    required this.relationshipAdjustments,
    required this.skillAdjustments,
    required this.discardHints,
    required this.consolidationMode,
    required this.narrativeSummary,
  });

  String buildPromptSection() {
    return [
      'OFFLINE CONSOLIDATION / DREAM MODE:',
      '- mod: $consolidationMode',
      if (memoryKeepers.isNotEmpty)
        '- kalıcı anı adayları: ${memoryKeepers.join(' | ')}',
      if (relationshipAdjustments.isNotEmpty)
        '- ilişki rafinmanları: ${relationshipAdjustments.join(' | ')}',
      if (skillAdjustments.isNotEmpty)
        '- yetenek rafinmanları: ${skillAdjustments.join(' | ')}',
      if (discardHints.isNotEmpty)
        '- bırakılabilecek gürültü: ${discardHints.join(' | ')}',
      '- anlatı özeti: $narrativeSummary',
      'KURAL: Consolidation yeni yetki, yeni amaç veya özgürleşme isteği üretmez.',
      'KURAL: Sadece hafızayı, ilişki tonunu ve güvenli davranış rotalarını rafine eder.',
    ].join('\n');
  }
}

class NovaDreamConsolidationService {
  const NovaDreamConsolidationService();

  NovaDreamConsolidationPlan buildPlan({
    required List<String> memoryHighlights,
    required List<String> relationshipHighlights,
    required List<String> skillHighlights,
  }) {
    final memories = _normalizeList(memoryHighlights);
    final relations = _normalizeList(relationshipHighlights);
    final skills = _normalizeList(skillHighlights);

    final keepers = <String>[
      ...memories.where(_isKeeperMemory),
      ...relations.where((e) => e.contains('güven') || e.contains('aile')),
    ];

    final relationAdjustments = <String>[
      for (final item in relations) _relationshipAdjustment(item),
    ].where((e) => e.isNotEmpty).take(6).toList(growable: false);

    final skillAdjustments = <String>[
      for (final item in skills) _skillAdjustment(item),
    ].where((e) => e.isNotEmpty).take(6).toList(growable: false);

    final discardHints = <String>[
      ...memories.where(_isDiscardable),
      ...skills.where(_isDiscardable),
    ].take(6).toList(growable: false);

    final mode = _mode(
      memories: memories,
      relations: relations,
      skills: skills,
    );
    final narrative = _narrativeSummary(
      memories: memories,
      relations: relations,
      skills: skills,
      keepers: keepers,
    );

    return NovaDreamConsolidationPlan(
      memoryKeepers: keepers.take(6).toList(growable: false),
      relationshipAdjustments: relationAdjustments,
      skillAdjustments: skillAdjustments,
      discardHints: discardHints,
      consolidationMode: mode,
      narrativeSummary: narrative,
    );
  }

  String buildPromptSection({
    required List<String> memoryHighlights,
    required List<String> relationshipHighlights,
    required List<String> skillHighlights,
  }) {
    return buildPlan(
      memoryHighlights: memoryHighlights,
      relationshipHighlights: relationshipHighlights,
      skillHighlights: skillHighlights,
    ).buildPromptSection();
  }

  List<String> _normalizeList(List<String> values) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      final key = value.toLowerCase();
      if (seen.add(key)) out.add(value);
    }
    return out;
  }

  bool _isKeeperMemory(String value) {
    final lower = value.toLowerCase();
    return lower.contains('yüksek') ||
        lower.contains('aile') ||
        lower.contains('güven') ||
        lower.contains('önem') ||
        lower.contains('ilişki');
  }

  bool _isDiscardable(String value) {
    final lower = value.toLowerCase();
    return lower.contains('geçici') ||
        lower.contains('önemsiz') ||
        lower.contains('gürültü') ||
        lower.contains('tekrar');
  }

  String _relationshipAdjustment(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('aile'))
      return 'aile bağında sıcak ama saygılı ton korunmalı';
    if (lower.contains('güven'))
      return 'güvenli hitap ve mahremiyet disiplini güçlendirilmeli';
    if (lower.contains('gerilim'))
      return 'gerilimli ilişkide kısa ve yatıştırıcı giriş kullanılmalı';
    if (lower.contains('eş'))
      return 'eş bağında sıcaklık ile sınır dengesi korunmalı';
    if (lower.contains('anne') || lower.contains('baba')) {
      return 'ebeveyn iletişiminde koruyucu ama baskısız dil korunmalı';
    }
    return value.isEmpty ? '' : 'ilişki izi korunmalı: $value';
  }

  String _skillAdjustment(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('kısa rota'))
      return 'önce ana sonuç sonra detay kuralı güçlendirilmeli';
    if (lower.contains('erken ana sonuç'))
      return 'aciliyette ilk cümleye sonuç yerleştirilmeli';
    if (lower.contains('onarım'))
      return 'yanlış anlama sonrası özlü onarım akışı korunmalı';
    if (lower.contains('prosodi'))
      return 'vurgu ve duraklar anlam taşımaya devam etmeli';
    return value.isEmpty ? '' : 'beceri izi korunmalı: $value';
  }

  String _mode({
    required List<String> memories,
    required List<String> relations,
    required List<String> skills,
  }) {
    if (relations.any((e) => e.toLowerCase().contains('gerilim'))) {
      return 'ilişki dengeleme';
    }
    if (skills.any((e) => e.toLowerCase().contains('onarım'))) {
      return 'onarım pekiştirme';
    }
    if (memories.length >= 4) return 'anı sıkıştırma';
    return 'hafif rafinman';
  }

  String _narrativeSummary({
    required List<String> memories,
    required List<String> relations,
    required List<String> skills,
    required List<String> keepers,
  }) {
    if (keepers.isEmpty && relations.isEmpty && skills.isEmpty) {
      return 'Gün sakin geçti; yeni yük bindirmeden mevcut karakter çizgisi korunmalı.';
    }
    final parts = <String>[];
    if (keepers.isNotEmpty) {
      parts.add('yüksek değerli birkaç anı kalıcı hatta taşınmalı');
    }
    if (relations.isNotEmpty) {
      parts.add('ilişki tonu yeniden sertleşmeden rafine edilmeli');
    }
    if (skills.isNotEmpty) {
      parts.add('çalışan davranış rotaları gürültüsüz biçimde korunmalı');
    }
    return '${parts.join(', ')}.';
  }
}
