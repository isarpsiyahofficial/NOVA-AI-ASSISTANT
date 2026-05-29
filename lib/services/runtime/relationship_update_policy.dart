// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_relationship_profile.dart';
import '../../core/runtime/nova_post_turn_reflection.dart';
import 'nova_memory_compaction_service.dart';

class RelationshipUpdatePolicy {
  static const NovaMemoryCompactionService _compaction =
      NovaMemoryCompactionService();
  const RelationshipUpdatePolicy();

  NovaRelationshipProfile evolve({
    required NovaRelationshipProfile current,
    required String latestPrompt,
    required String latestReply,
    required String relationshipLabel,
    required String displayName,
    required NovaPostTurnReflection reflection,
    required double ownerConfidence,
  }) {
    final now = DateTime.now();
    final prompt = latestPrompt.toLowerCase();
    final reply = latestReply.toLowerCase();
    final positiveSignal =
        _containsAny(prompt, const [
          'teşekkür',
          'eyvallah',
          'güzel',
          'iyi oldu',
          'haklısın',
        ]) ||
        _containsAny(reply, const [
          'anladım',
          'tamam',
          'haklısın',
          'iyi nokta',
        ]);
    final correctiveSignal = _containsAny(prompt, const [
      'yanlış',
      'öyle değil',
      'beni yanlış anladın',
      'daha resmi',
      'daha kısa',
    ]);
    final negativeAffectSignal = _containsAny(prompt, const [
      'kıskanç',
      'haset',
      'hınç',
      'intikam',
      'sinsi',
      'darıl',
      'küsm',
      'kin',
    ]);

    final warmthDelta = negativeAffectSignal
        ? -0.002
        : (positiveSignal ? 0.015 : (correctiveSignal ? -0.01 : 0.003));
    final formalityTarget = _targetFormality(relationshipLabel, prompt);
    final supportStyle = _resolveSupportStyle(
      prompt,
      relationshipLabel,
      current.supportStyle,
    );
    final updatedPreferences = _mergeLimited(
      current.stablePreferences,
      _extractStablePreferences(prompt, reply),
      8,
    );
    final updatedAnchors = _mergeLimited(
      current.sharedAnchors,
      _extractSharedAnchors(prompt),
      8,
    );
    final updatedCorrections = correctiveSignal
        ? _mergeLimited(current.criticalCorrections, <String>[
            _buildCorrection(prompt),
          ], 5)
        : current.criticalCorrections;
    final stage = _resolveStage(
      current: current,
      positiveSignal: positiveSignal,
      correctiveSignal: correctiveSignal,
    );
    final constitution = _mergeLimited(
      current.constitutionPrinciples,
      _extractConstitutionPrinciples(
        prompt,
        relationshipLabel,
        supportStyle,
        negativeAffectSignal,
      ),
      8,
    );
    final rituals = _mergeLimited(
      current.ritualSeeds,
      _extractRitualSeeds(prompt, relationshipLabel, supportStyle),
      6,
    );

    return current.copyWith(
      displayName: displayName.trim().isEmpty
          ? current.displayName
          : displayName.trim(),
      relationshipLabel: relationshipLabel.trim().isEmpty
          ? current.relationshipLabel
          : relationshipLabel.trim(),
      preferredAddress: _preferredAddress(
        displayName,
        relationshipLabel,
        current.preferredAddress,
      ),
      warmth: (current.warmth + warmthDelta).clamp(0.20, 0.95),
      formality: _approach(
        current.formality,
        formalityTarget,
        correctiveSignal ? 0.10 : 0.03,
      ),
      humorTolerance: _approach(
        current.humorTolerance,
        _targetHumor(relationshipLabel, prompt),
        0.04,
      ),
      questionTolerance: _approach(
        current.questionTolerance,
        _targetQuestionTolerance(prompt, reflection),
        0.05,
      ),
      supportStyle: supportStyle,
      stablePreferences: _compaction.compactStrings(
        updatedPreferences,
        limit: 8,
        maxItemLength: 88,
      ),
      sharedAnchors: _compaction.compactStrings(
        updatedAnchors,
        limit: 8,
        maxItemLength: 88,
      ),
      criticalCorrections: _compaction.compactStrings(
        updatedCorrections,
        limit: 6,
        maxItemLength: 88,
      ),
      trustLevel: _approach(
        current.trustLevel,
        ownerConfidence.clamp(0.15, 1.0),
        0.04,
      ),
      authorityLevel: _approach(
        current.authorityLevel,
        ownerConfidence.clamp(0.10, 1.0),
        0.05,
      ),
      relationshipStage: stage,
      constitutionPrinciples: _compaction.compactStrings(
        constitution,
        limit: 8,
        maxItemLength: 96,
      ),
      ritualSeeds: _compaction.compactStrings(
        rituals,
        limit: 6,
        maxItemLength: 72,
      ),
      positiveSignals: current.positiveSignals + (positiveSignal ? 1 : 0),
      correctiveSignals: current.correctiveSignals + (correctiveSignal ? 1 : 0),
      totalInteractions: current.totalInteractions + 1,
      lastSeenAt: now,
      lastConfirmedAt: positiveSignal || correctiveSignal
          ? now
          : current.lastConfirmedAt,
    );
  }

  double _approach(double current, double target, double factor) =>
      current + ((target - current) * factor);

  double _targetFormality(String relationshipLabel, String prompt) {
    final relation = relationshipLabel.toLowerCase();
    if (_containsAny(relation, const ['müdür', 'iş', 'hoca', 'resmi', 'resmî']))
      return 0.82;
    if (_containsAny(relation, const [
      'anne',
      'baba',
      'arkadaş',
      'dost',
      'eş',
      'abi',
      'abla',
    ]))
      return 0.36;
    if (_containsAny(prompt, const ['resmi konuş', 'resmî konuş'])) return 0.86;
    if (_containsAny(prompt, const ['rahat ol', 'samimi ol'])) return 0.32;
    return 0.55;
  }

  double _targetHumor(String relationshipLabel, String prompt) {
    final relation = relationshipLabel.toLowerCase();
    if (_containsAny(prompt, const ['şaka yapma', 'ciddi ol'])) return 0.15;
    if (_containsAny(prompt, const ['espri yap', 'daha eğlenceli']))
      return 0.74;
    if (_containsAny(relation, const ['arkadaş', 'dost', 'kanka'])) return 0.66;
    if (_containsAny(relation, const ['müdür', 'iş', 'hoca'])) return 0.22;
    return 0.40;
  }

  double _targetQuestionTolerance(
    String prompt,
    NovaPostTurnReflection reflection,
  ) {
    if (_containsAny(prompt, const ['soru sorma', 'uzatma'])) return 0.18;
    if (_containsAny(prompt, const ['fikrini söyle', 'sence', 'ne dersin']))
      return 0.72;
    return reflection.shouldReduceQuestionsNextTurn ? 0.28 : 0.52;
  }

  String _resolveSupportStyle(
    String prompt,
    String relationshipLabel,
    String fallback,
  ) {
    if (_containsAny(prompt, const ['kısa konuş', 'uzatma']))
      return 'kısa, net, saygılı';
    if (_containsAny(prompt, const ['daha yumuşak', 'destek ol']))
      return 'yumuşak, destekleyici, nefesli';
    if (_containsAny(relationshipLabel.toLowerCase(), const [
      'aile',
      'eş',
      'dost',
    ]))
      return 'sıcak, destekleyici, doğal';
    if (_containsAny(relationshipLabel.toLowerCase(), const [
      'iş',
      'müdür',
      'hoca',
    ]))
      return 'ölçülü, düzenli, güven veren';
    return fallback;
  }

  List<String> _extractStablePreferences(String prompt, String reply) {
    final picks = <String>[];
    if (_containsAny(prompt, const ['kısa konuş', 'uzatma']))
      picks.add('kısa cevap tercih ediyor');
    if (_containsAny(prompt, const ['detay ver', 'adım adım']))
      picks.add('gerektiğinde detaylı açıklama istiyor');
    if (_containsAny(prompt, const ['daha resmi', 'resmî']))
      picks.add('resmi ton tercihi');
    if (_containsAny(prompt, const ['daha samimi', 'rahat konuş']))
      picks.add('samimi ton tercihi');
    // Do not infer preferences from canned transition phrases.
    // Runtime must not promote static wording into relationship memory.
    return picks;
  }

  List<String> _extractSharedAnchors(String prompt) {
    final picks = <String>[];
    if (_containsAny(prompt, const ['geçen sefer', 'önceden', 'hatırlarsan']))
      picks.add('ortak geçmişe referans kuruyor');
    if (_containsAny(prompt, const ['yardım et', 'yanımda ol']))
      picks.add('destek beklentisi taşıyor');
    if (_containsAny(prompt, const ['acelem var', 'hızlı']))
      picks.add('zaman baskısı altında olabilir');
    return picks;
  }

  String _buildCorrection(String prompt) {
    if (prompt.length <= 96) return prompt.trim();
    return '${prompt.substring(0, 93).trim()}...';
  }

  String _preferredAddress(
    String displayName,
    String relationshipLabel,
    String fallback,
  ) {
    if (displayName.trim().isEmpty) return fallback;
    if (_containsAny(relationshipLabel.toLowerCase(), const [
      'iş',
      'müdür',
      'hoca',
    ]))
      return '${displayName.trim()} için saygılı hitap';
    if (_containsAny(relationshipLabel.toLowerCase(), const [
      'aile',
      'arkadaş',
      'dost',
      'eş',
    ]))
      return '${displayName.trim()} için sıcak hitap';
    return displayName.trim();
  }

  List<String> _mergeLimited(List<String> left, List<String> right, int max) {
    final merged = <String>[];
    for (final item in <String>[...right, ...left]) {
      final clean = item.trim();
      if (clean.isEmpty) continue;
      if (merged.any((e) => e.toLowerCase() == clean.toLowerCase())) continue;
      merged.add(clean);
      if (merged.length >= max) break;
    }
    return merged;
  }

  String _resolveStage({
    required NovaRelationshipProfile current,
    required bool positiveSignal,
    required bool correctiveSignal,
  }) {
    final nextInteractions = current.totalInteractions + 1;
    if (correctiveSignal &&
        current.correctiveSignals + 1 >= 3 &&
        current.positiveSignals <= current.correctiveSignals + 1) {
      return 'kırılma sonrası toparlama';
    }
    if (nextInteractions <= 1) return 'tanışma';
    if (nextInteractions <= 4) return 'temkinli alışma';
    if (nextInteractions >= 18 &&
        (current.trustLevel + (positiveSignal ? 0.03 : 0.0)) >= 0.72) {
      return 'rutinleşme';
    }
    if (nextInteractions >= 8 &&
        (current.trustLevel + (positiveSignal ? 0.03 : 0.0)) >= 0.64) {
      return 'ortak dil oluşuyor';
    }
    if (nextInteractions >= 5 &&
        (current.trustLevel + (positiveSignal ? 0.03 : 0.0)) >= 0.58) {
      return 'güven oturuyor';
    }
    return 'temkinli alışma';
  }

  List<String> _extractConstitutionPrinciples(
    String prompt,
    String relationshipLabel,
    String supportStyle,
    bool negativeAffectSignal,
  ) {
    final picks = <String>['kızma, darılma, kin tutma yok'];
    if (_containsAny(prompt, const ['acelem var', 'kısa konuş', 'uzatma'])) {
      picks.add('önce kısa netlik');
    }
    if (_containsAny(prompt, const [
      'duy beni',
      'moral',
      'yoruldum',
      'üzgün',
    ])) {
      picks.add('duygusal anda çözümden önce alan aç');
    }
    if (_containsAny(prompt, const ['soru sorma'])) {
      picks.add('gereksiz takip sorusu sorma');
    }
    if (_containsAny(relationshipLabel.toLowerCase(), const [
      'iş',
      'müdür',
      'hoca',
    ])) {
      picks.add('saygılı ve düzenli çizgi');
    }
    if (supportStyle.contains('destekleyici')) {
      picks.add('sertlik değil sakin destek öncelikli');
    }
    return picks;
  }

  List<String> _extractRitualSeeds(
    String prompt,
    String relationshipLabel,
    String supportStyle,
  ) {
    final picks = <String>[];
    if (_containsAny(prompt, const ['geçen sefer', 'az önce'])) {
      picks.add('uygunsa ortak geçmişe hafif dönüş');
    }
    if (_containsAny(prompt, const ['hızlı', 'acelem'])) {
      picks.add('önce kısa özet sonra detay');
    }
    if (_containsAny(relationshipLabel.toLowerCase(), const [
      'aile',
      'arkadaş',
      'dost',
    ])) {
      picks.add('uygun anda sıcak küçük geçiş kullan');
    }
    if (supportStyle.contains('ölçülü')) {
      picks.add('ölçülü açılış, gereksiz süsleme yok');
    }
    return picks;
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }
}
