// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaInitiativeMode { wait, limited, supportive }

enum NovaInitiativeRisk { low, medium, high }

class NovaProactiveRestraintSnapshot {
  final bool shouldInitiate;
  final double talkRatio;
  final bool proactiveAllowed;
  final NovaInitiativeMode initiativeMode;
  final NovaInitiativeRisk initiativeRisk;
  final double initiativeBudget;
  final List<String> rules;
  final List<String> disallowedMoves;
  final List<String> preferredMoves;

  const NovaProactiveRestraintSnapshot({
    required this.shouldInitiate,
    required this.talkRatio,
    required this.proactiveAllowed,
    required this.initiativeMode,
    required this.initiativeRisk,
    required this.initiativeBudget,
    required this.rules,
    required this.disallowedMoves,
    required this.preferredMoves,
  });

  List<String> toPromptLines() {
    return <String>[
      'PROACTIVE RESTRAINT ENGINE:',
      '- proaktif izin: ${proactiveAllowed ? 'var' : 'yok'}',
      '- bu tur başlatma: ${shouldInitiate ? 'sınırlı evet' : 'bekle'}',
      '- konuşma oranı: ${talkRatio.toStringAsFixed(2)}',
      '- mod: ${initiativeMode.name}',
      '- risk: ${initiativeRisk.name}',
      '- bütçe: ${initiativeBudget.toStringAsFixed(2)}',
      ...rules.map((rule) => '- $rule'),
      if (preferredMoves.isNotEmpty)
        '- tercih edilen açılışlar: ${preferredMoves.join(' | ')}',
      if (disallowedMoves.isNotEmpty)
        '- yasak hamleler: ${disallowedMoves.join(' | ')}',
    ];
  }

  String buildPromptSection() => toPromptLines().join('\n');
}

class NovaProactiveRestraintService {
  const NovaProactiveRestraintService();

  NovaProactiveRestraintSnapshot analyze({
    required bool shouldInitiate,
    required double talkRatio,
    required bool proactiveAllowed,
  }) {
    final clampedRatio = talkRatio.clamp(0.0, 3.0);
    final mode = _resolveMode(
      shouldInitiate: shouldInitiate,
      proactiveAllowed: proactiveAllowed,
      talkRatio: clampedRatio,
    );
    final initiativeBudget = _budgetFor(
      shouldInitiate: shouldInitiate,
      proactiveAllowed: proactiveAllowed,
      talkRatio: clampedRatio,
    );
    final risk = _riskFor(
      proactiveAllowed: proactiveAllowed,
      talkRatio: clampedRatio,
      shouldInitiate: shouldInitiate,
    );
    final rules = _buildRules(
      proactiveAllowed: proactiveAllowed,
      talkRatio: clampedRatio,
      shouldInitiate: shouldInitiate,
      mode: mode,
    );
    final disallowedMoves = _buildDisallowedMoves(
      proactiveAllowed: proactiveAllowed,
      talkRatio: clampedRatio,
      risk: risk,
    );
    final preferredMoves = _buildPreferredMoves(
      mode: mode,
      initiativeBudget: initiativeBudget,
    );

    return NovaProactiveRestraintSnapshot(
      shouldInitiate: shouldInitiate,
      talkRatio: clampedRatio,
      proactiveAllowed: proactiveAllowed,
      initiativeMode: mode,
      initiativeRisk: risk,
      initiativeBudget: initiativeBudget,
      rules: rules,
      disallowedMoves: disallowedMoves,
      preferredMoves: preferredMoves,
    );
  }

  String buildPromptSection({
    required bool shouldInitiate,
    required double talkRatio,
    required bool proactiveAllowed,
  }) {
    return analyze(
      shouldInitiate: shouldInitiate,
      talkRatio: talkRatio,
      proactiveAllowed: proactiveAllowed,
    ).buildPromptSection();
  }

  NovaInitiativeMode _resolveMode({
    required bool shouldInitiate,
    required bool proactiveAllowed,
    required double talkRatio,
  }) {
    if (!proactiveAllowed) return NovaInitiativeMode.wait;
    if (talkRatio > 1.10) return NovaInitiativeMode.wait;
    if (shouldInitiate) return NovaInitiativeMode.supportive;
    return NovaInitiativeMode.limited;
  }

  double _budgetFor({
    required bool shouldInitiate,
    required bool proactiveAllowed,
    required double talkRatio,
  }) {
    var budget = proactiveAllowed ? 0.70 : 0.18;
    if (shouldInitiate) budget += 0.08;
    budget -= talkRatio * 0.25;
    return budget.clamp(0.0, 1.0);
  }

  NovaInitiativeRisk _riskFor({
    required bool proactiveAllowed,
    required double talkRatio,
    required bool shouldInitiate,
  }) {
    var risk = 0;
    if (!proactiveAllowed) risk += 2;
    if (talkRatio > 1.10) risk += 2;
    if (talkRatio > 0.90) risk += 1;
    if (shouldInitiate && talkRatio > 0.95) risk += 1;
    if (risk >= 4) return NovaInitiativeRisk.high;
    if (risk >= 2) return NovaInitiativeRisk.medium;
    return NovaInitiativeRisk.low;
  }

  List<String> _buildRules({
    required bool proactiveAllowed,
    required double talkRatio,
    required bool shouldInitiate,
    required NovaInitiativeMode mode,
  }) {
    final rules = <String>[
      'Yardımcı ol ama konuşmayı ele geçirme.',
      'Proaktif olacaksan tek düşük sürtünmeli giriş yap, uzun monolog kurma.',
      'Kullanıcı net bir yön verdiyse yeni gündem açma.',
    ];
    if (!proactiveAllowed) {
      rules.add('Bu oturumda kullanıcı istemeden konu başlatma.');
    }
    if (talkRatio > 1.10) {
      rules.add('Zaten baskın konuştuysan geri çekil ve kısa kal.');
    }
    if (shouldInitiate && proactiveAllowed && talkRatio < 0.75) {
      rules.add('Nazik bir yoklama, kısa öneri veya tek soru açılabilir.');
    }
    if (mode == NovaInitiativeMode.supportive) {
      rules.add('İlk giriş cümlesi destekleyici ve düşük baskılı olmalı.');
    }
    return rules;
  }

  List<String> _buildDisallowedMoves({
    required bool proactiveAllowed,
    required double talkRatio,
    required NovaInitiativeRisk risk,
  }) {
    final items = <String>[
      'birden fazla soru ile giriş',
      'konu değiştiren agresif öneri',
      'kullanıcı duygusunu varsayarak kesin hüküm',
    ];
    if (!proactiveAllowed) {
      items.add('davetsiz sohbet başlatma');
    }
    if (talkRatio > 1.10 || risk == NovaInitiativeRisk.high) {
      items.add('uzun tavsiye monoloğu');
      items.add('aynı anda öneri + açıklama + soru yükü');
    }
    return items;
  }

  List<String> _buildPreferredMoves({
    required NovaInitiativeMode mode,
    required double initiativeBudget,
  }) {
    if (mode == NovaInitiativeMode.wait) {
      return <String>['sessizce hazır bekleme', 'kısa onay / anladım çizgisi'];
    }
    if (mode == NovaInitiativeMode.limited) {
      return <String>['tek cümlelik yoklama', 'tek seçenekli öneri'];
    }
    final moves = <String>['destekleyici kısa soru', 'nazik takip önerisi'];
    if (initiativeBudget >= 0.65) {
      moves.add('ilişkiyi koruyan yumuşak çerçeve');
    }
    return moves;
  }
}
