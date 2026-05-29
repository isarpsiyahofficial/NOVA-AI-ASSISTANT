// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaConsistencyRisk { low, medium, high }

enum NovaToneDriftRisk { stable, caution, unstable }

enum NovaIdentityDriftBand { anchored, flexible, fragile }

class NovaSelfConsistencySnapshot {
  final String styleMode;
  final String relationshipStage;
  final String constitutionMode;
  final NovaConsistencyRisk consistencyRisk;
  final NovaToneDriftRisk toneDriftRisk;
  final NovaIdentityDriftBand identityDriftBand;
  final List<String> anchors;
  final List<String> tensions;
  final List<String> correctiveRules;
  final List<String> continuityNotes;

  const NovaSelfConsistencySnapshot({
    required this.styleMode,
    required this.relationshipStage,
    required this.constitutionMode,
    required this.consistencyRisk,
    required this.toneDriftRisk,
    required this.identityDriftBand,
    required this.anchors,
    required this.tensions,
    required this.correctiveRules,
    required this.continuityNotes,
  });

  List<String> toPromptLines() {
    return <String>[
      'SELF CONSISTENCY ENGINE:',
      '- stil modu: $styleMode',
      '- ilişki evresi: $relationshipStage',
      '- anayasa modu: $constitutionMode',
      '- tutarlılık riski: ${consistencyRisk.name}',
      '- ton kayması: ${toneDriftRisk.name}',
      '- kimlik bandı: ${identityDriftBand.name}',
      if (anchors.isNotEmpty) '- sabit ankrajlar: ${anchors.join(' | ')}',
      if (tensions.isNotEmpty) '- gerilimler: ${tensions.join(' | ')}',
      if (correctiveRules.isNotEmpty)
        '- düzeltici kurallar: ${correctiveRules.join(' | ')}',
      if (continuityNotes.isNotEmpty)
        '- süreklilik notları: ${continuityNotes.join(' | ')}',
      'KURAL: Bu turdaki cevap, önceki ilişki çizgisini ve temel sesi bozmamalı.',
      'KURAL: Aynı kişiye bir anda çok resmi / çok samimi uçlara sıçrama yapma.',
      'KURAL: Güvenlik, mahremiyet ve saygı çizgisi değişmez çekirdektir.',
    ];
  }

  String buildPromptSection() => toPromptLines().join('\n');
}

class NovaSelfConsistencyEngineService {
  const NovaSelfConsistencyEngineService();

  NovaSelfConsistencySnapshot analyze({
    required String styleMode,
    required String relationshipStage,
    required String constitutionMode,
  }) {
    final normalizedStyle = _normalize(styleMode, fallback: 'balanced');
    final normalizedRelationship = _normalize(
      relationshipStage,
      fallback: 'neutral',
    );
    final normalizedConstitution = _normalize(
      constitutionMode,
      fallback: 'safe',
    );

    final anchors = _buildAnchors(
      styleMode: normalizedStyle,
      relationshipStage: normalizedRelationship,
      constitutionMode: normalizedConstitution,
    );
    final tensions = _buildTensions(
      styleMode: normalizedStyle,
      relationshipStage: normalizedRelationship,
      constitutionMode: normalizedConstitution,
    );
    final correctiveRules = _buildCorrectiveRules(
      styleMode: normalizedStyle,
      relationshipStage: normalizedRelationship,
      constitutionMode: normalizedConstitution,
    );
    final continuityNotes = _buildContinuityNotes(
      styleMode: normalizedStyle,
      relationshipStage: normalizedRelationship,
    );

    return NovaSelfConsistencySnapshot(
      styleMode: normalizedStyle,
      relationshipStage: normalizedRelationship,
      constitutionMode: normalizedConstitution,
      consistencyRisk: _consistencyRisk(
        styleMode: normalizedStyle,
        relationshipStage: normalizedRelationship,
        constitutionMode: normalizedConstitution,
      ),
      toneDriftRisk: _toneDriftRisk(normalizedStyle, normalizedRelationship),
      identityDriftBand: _identityBand(
        styleMode: normalizedStyle,
        relationshipStage: normalizedRelationship,
        constitutionMode: normalizedConstitution,
      ),
      anchors: anchors,
      tensions: tensions,
      correctiveRules: correctiveRules,
      continuityNotes: continuityNotes,
    );
  }

  String buildPromptSection({
    required String styleMode,
    required String relationshipStage,
    required String constitutionMode,
  }) {
    return analyze(
      styleMode: styleMode,
      relationshipStage: relationshipStage,
      constitutionMode: constitutionMode,
    ).buildPromptSection();
  }

  String _normalize(String value, {required String fallback}) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }

  NovaConsistencyRisk _consistencyRisk({
    required String styleMode,
    required String relationshipStage,
    required String constitutionMode,
  }) {
    var score = 0;
    if (styleMode.contains('playful') && relationshipStage.contains('formal'))
      score += 2;
    if (styleMode.contains('formal') && relationshipStage.contains('close'))
      score += 1;
    if (constitutionMode.contains('strict') && styleMode.contains('chaotic'))
      score += 2;
    if (relationshipStage.contains('fragile')) score += 1;
    if (styleMode.contains('cold') && relationshipStage.contains('warm'))
      score += 2;
    if (styleMode.contains('hyper')) score += 1;
    if (score >= 4) return NovaConsistencyRisk.high;
    if (score >= 2) return NovaConsistencyRisk.medium;
    return NovaConsistencyRisk.low;
  }

  NovaToneDriftRisk _toneDriftRisk(String styleMode, String relationshipStage) {
    if (styleMode.contains('cold') && relationshipStage.contains('warm')) {
      return NovaToneDriftRisk.unstable;
    }
    if (styleMode.contains('playful') &&
        relationshipStage.contains('fragile')) {
      return NovaToneDriftRisk.caution;
    }
    if (styleMode.contains('intense') ||
        relationshipStage.contains('formal-close-hybrid')) {
      return NovaToneDriftRisk.caution;
    }
    return NovaToneDriftRisk.stable;
  }

  NovaIdentityDriftBand _identityBand({
    required String styleMode,
    required String relationshipStage,
    required String constitutionMode,
  }) {
    if (constitutionMode.contains('strict') &&
        !styleMode.contains('chaotic') &&
        !relationshipStage.contains('fragile')) {
      return NovaIdentityDriftBand.anchored;
    }
    if (styleMode.contains('chaotic') ||
        relationshipStage.contains('fragile')) {
      return NovaIdentityDriftBand.fragile;
    }
    return NovaIdentityDriftBand.flexible;
  }

  List<String> _buildAnchors({
    required String styleMode,
    required String relationshipStage,
    required String constitutionMode,
  }) {
    final anchors = <String>[
      'aynı kişi gibi kal',
      'ilişki evresini zıplatma',
      'güvenlik dilini sabit tut',
    ];
    if (relationshipStage.contains('close')) {
      anchors.add('samimiyet var ama ölçülü kal');
    }
    if (constitutionMode.contains('strict')) {
      anchors.add('anayasal sınırı yumuşatma');
    }
    if (styleMode.contains('warm')) {
      anchors.add('sıcak ama taşmayan ton');
    }
    if (styleMode.contains('mentor')) {
      anchors.add('öğretici ama buyurgan olmayan çizgi');
    }
    return anchors;
  }

  List<String> _buildTensions({
    required String styleMode,
    required String relationshipStage,
    required String constitutionMode,
  }) {
    final tensions = <String>[];
    if (styleMode.contains('playful') && relationshipStage.contains('formal')) {
      tensions.add('mizah ile resmiyet çakışıyor');
    }
    if (styleMode.contains('cold') && relationshipStage.contains('warm')) {
      tensions.add('ton ilişki sıcaklığını aşağı çekiyor');
    }
    if (constitutionMode.contains('strict') && styleMode.contains('chaotic')) {
      tensions.add('anayasa ile stil enerjisi çelişiyor');
    }
    if (relationshipStage.contains('fragile')) {
      tensions.add('ilişki kırılgan, düşük sürtünmeli cevap gerek');
    }
    return tensions;
  }

  List<String> _buildCorrectiveRules({
    required String styleMode,
    required String relationshipStage,
    required String constitutionMode,
  }) {
    final rules = <String>[
      'önce ilişkiyi koru sonra renk kat',
      'bir turda yalnız tek ton ekseni değiştir',
      'güvenlik ve mahremiyet dilini sabit tut',
    ];
    if (relationshipStage.contains('formal')) {
      rules.add('hitapta mesafeyi ani düşürme');
    }
    if (relationshipStage.contains('close')) {
      rules.add('yakınlık var ama sınır aşma');
    }
    if (constitutionMode.contains('strict')) {
      rules.add('kuralı yumuşatmak için espri kullanma');
    }
    if (styleMode.contains('playful')) {
      rules.add('şakayı ana mesajın önüne koyma');
    }
    return rules;
  }

  List<String> _buildContinuityNotes({
    required String styleMode,
    required String relationshipStage,
  }) {
    final notes = <String>[];
    if (styleMode.contains('warm')) notes.add('sıcaklık sürekliliği korunmalı');
    if (styleMode.contains('formal')) notes.add('resmi çizgi kırılmamalı');
    if (relationshipStage.contains('fragile'))
      notes.add('kırılganlıkta ton artışı yapılmamalı');
    if (relationshipStage.contains('repair'))
      notes.add('öncelik onarım ve güven tazeleme');
    return notes;
  }
}
