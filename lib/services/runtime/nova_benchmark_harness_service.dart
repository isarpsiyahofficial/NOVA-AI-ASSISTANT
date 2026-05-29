// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:math';

class NovaBenchmarkSample {
  final String metricKey;
  final double value;
  final double target;
  final double weight;
  final String label;
  final String explanation;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const NovaBenchmarkSample({
    required this.metricKey,
    required this.value,
    required this.target,
    required this.weight,
    required this.label,
    required this.explanation,
    required this.createdAt,
    this.metadata = const <String, dynamic>{},
  });

  double get normalizedScore {
    if (target <= 0) return 0;
    return (value / target).clamp(0, 1);
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'metricKey': metricKey,
    'value': value,
    'target': target,
    'weight': weight,
    'label': label,
    'explanation': explanation,
    'createdAt': createdAt.toIso8601String(),
    'metadata': metadata,
  };
}

class NovaBenchmarkSnapshot {
  final List<NovaBenchmarkSample> samples;
  final double weightedScore;
  final double digitalHumanScore;
  final DateTime updatedAt;

  const NovaBenchmarkSnapshot({
    required this.samples,
    required this.weightedScore,
    required this.digitalHumanScore,
    required this.updatedAt,
  });

  factory NovaBenchmarkSnapshot.initial() {
    return NovaBenchmarkSnapshot(
      samples: const <NovaBenchmarkSample>[],
      weightedScore: 0,
      digitalHumanScore: 0,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'samples': samples.map((e) => e.toMap()).toList(growable: false),
    'weightedScore': weightedScore,
    'digitalHumanScore': digitalHumanScore,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class NovaBenchmarkHarnessService {
  NovaBenchmarkSnapshot _snapshot = NovaBenchmarkSnapshot.initial();

  NovaBenchmarkSnapshot get snapshot => _snapshot;

  static const Map<String, double> _weights = <String, double>{
    'backchannel_success': 1.1,
    'interruption_quality': 1.2,
    'speaker_routing': 1.4,
    'owner_priority': 1.5,
    'call_takeover_accuracy': 1.4,
    'call_handoff_accuracy': 1.3,
    'note_delivery_quality': 1.2,
    'relationship_tone_quality': 1.3,
    'tts_self_deafness': 1.4,
    'multi_speaker_stability': 1.3,
    'semantic_turn_accuracy': 1.3,
    'latency_budget': 1.1,
    'memory_commit_quality': 1.2,
    'learning_classification': 1.2,
    'overlay_presence_quality': 0.9,
  };

  static const Map<String, double> _targets = <String, double>{
    'backchannel_success': 0.93,
    'interruption_quality': 0.91,
    'speaker_routing': 0.95,
    'owner_priority': 0.98,
    'call_takeover_accuracy': 0.95,
    'call_handoff_accuracy': 0.95,
    'note_delivery_quality': 0.92,
    'relationship_tone_quality': 0.90,
    'tts_self_deafness': 0.98,
    'multi_speaker_stability': 0.92,
    'semantic_turn_accuracy': 0.91,
    'latency_budget': 0.90,
    'memory_commit_quality': 0.89,
    'learning_classification': 0.89,
    'overlay_presence_quality': 0.86,
  };

  NovaBenchmarkSnapshot record({
    required String metricKey,
    required double value,
    String? label,
    String explanation = '',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final sample = NovaBenchmarkSample(
      metricKey: metricKey,
      value: value.clamp(0, 1),
      target: _targets[metricKey] ?? 1,
      weight: _weights[metricKey] ?? 1,
      label: label ?? metricKey,
      explanation: explanation,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
    final samples = <NovaBenchmarkSample>[
      sample,
      ..._snapshot.samples,
    ].take(320).toList(growable: false);
    _snapshot = _recompute(samples);
    return _snapshot;
  }

  NovaBenchmarkSnapshot recordBatch(List<NovaBenchmarkSample> samples) {
    final merged = <NovaBenchmarkSample>[
      ...samples,
      ..._snapshot.samples,
    ].take(320).toList(growable: false);
    _snapshot = _recompute(merged);
    return _snapshot;
  }

  NovaBenchmarkSnapshot buildSyntheticCoverageSnapshot({
    required bool ownerPriorityPreserved,
    required bool callRoleStackStable,
    required bool semanticTurnStrong,
    required bool learningTyped,
    required bool overlayEmbodied,
    required bool ttsSelfBlindProtected,
  }) {
    final synthetic = <NovaBenchmarkSample>[
      NovaBenchmarkSample(
        metricKey: 'owner_priority',
        value: ownerPriorityPreserved ? 0.98 : 0.62,
        target: _targets['owner_priority']!,
        weight: _weights['owner_priority']!,
        label: 'Owner Önceliği',
        explanation:
            'Aynı anda birden fazla yetkili konuştuğunda owner önceliği korunuyor mu?',
        createdAt: DateTime.now(),
      ),
      NovaBenchmarkSample(
        metricKey: 'call_takeover_accuracy',
        value: callRoleStackStable ? 0.95 : 0.58,
        target: _targets['call_takeover_accuracy']!,
        weight: _weights['call_takeover_accuracy']!,
        label: 'Çağrı Devralma',
        explanation:
            'Normal UX bozulmadan kayıtlı kişi zincirinde çağrı devralma kalitesi.',
        createdAt: DateTime.now(),
      ),
      NovaBenchmarkSample(
        metricKey: 'semantic_turn_accuracy',
        value: semanticTurnStrong ? 0.93 : 0.51,
        target: _targets['semantic_turn_accuracy']!,
        weight: _weights['semantic_turn_accuracy']!,
        label: 'Anlamsal Tur',
        explanation: 'Durak, interruption ve completion ayrımı.',
        createdAt: DateTime.now(),
      ),
      NovaBenchmarkSample(
        metricKey: 'learning_classification',
        value: learningTyped ? 0.91 : 0.49,
        target: _targets['learning_classification']!,
        weight: _weights['learning_classification']!,
        label: 'Typed Learning',
        explanation:
            'Kalıcı kural, geçici not ve tecrübe kartını ayırma kalitesi.',
        createdAt: DateTime.now(),
      ),
      NovaBenchmarkSample(
        metricKey: 'overlay_presence_quality',
        value: overlayEmbodied ? 0.88 : 0.36,
        target: _targets['overlay_presence_quality']!,
        weight: _weights['overlay_presence_quality']!,
        label: 'Embodied Overlay',
        explanation: 'Nefes, duygu, sıcaklık ve okunabilirlik.',
        createdAt: DateTime.now(),
      ),
      NovaBenchmarkSample(
        metricKey: 'tts_self_deafness',
        value: ttsSelfBlindProtected ? 0.99 : 0.42,
        target: _targets['tts_self_deafness']!,
        weight: _weights['tts_self_deafness']!,
        label: 'Self-TTS Körleşme',
        explanation:
            'Kendi TTS eşleşmelerini komut/sosyal giriş saymama kalitesi.',
        createdAt: DateTime.now(),
      ),
    ];
    return recordBatch(synthetic);
  }

  Map<String, dynamic> buildDashboardSummary() {
    final grouped = <String, List<NovaBenchmarkSample>>{};
    for (final sample in _snapshot.samples) {
      grouped
          .putIfAbsent(sample.metricKey, () => <NovaBenchmarkSample>[])
          .add(sample);
    }
    final summary = <String, dynamic>{
      'digitalHumanScore': _snapshot.digitalHumanScore,
      'weightedScore': _snapshot.weightedScore,
      'updatedAt': _snapshot.updatedAt.toIso8601String(),
      'metricCards': <Map<String, dynamic>>[],
    };
    final cards = summary['metricCards'] as List<Map<String, dynamic>>;
    for (final entry in grouped.entries) {
      final values = entry.value.map((e) => e.value).toList(growable: false);
      final avg = values.isEmpty
          ? 0
          : values.reduce((a, b) => a + b) / values.length;
      final best = values.isEmpty ? 0 : values.reduce(max);
      final latest = entry.value.first;
      cards.add(<String, dynamic>{
        'metricKey': entry.key,
        'label': latest.label,
        'average': avg,
        'best': best,
        'latest': latest.value,
        'target': latest.target,
        'weight': latest.weight,
        'status': _statusFor(avg.toDouble(), latest.target.toDouble()),
        'explanation': latest.explanation,
      });
    }
    cards.sort((a, b) => (b['average'] as num).compareTo(a['average'] as num));
    return summary;
  }

  String buildPromptSection() {
    final buffer = StringBuffer();
    buffer.writeln('BENCHMARK HARNESS:');
    buffer.writeln(
      '- weighted score: ${_snapshot.weightedScore.toStringAsFixed(3)}',
    );
    buffer.writeln(
      '- digital human score: ${_snapshot.digitalHumanScore.toStringAsFixed(3)}',
    );
    final top = buildDashboardSummary()['metricCards'] as List<dynamic>;
    for (final card in top.take(8)) {
      final map = card as Map<String, dynamic>;
      buffer.writeln(
        '- ${map['label']}: latest=${(map['latest'] as num).toStringAsFixed(2)} / target=${(map['target'] as num).toStringAsFixed(2)} / status=${map['status']}',
      );
    }
    buffer.writeln(
      'KURAL: Doğallık iddiası sezgiyle değil ölçümle takip edilir; owner priority, interruption, call takeover, note delivery ve self-TTS körleşme metrikleri sürekli izlenir.',
    );
    return buffer.toString().trim();
  }

  Map<String, dynamic> buildFailureHotspots() {
    final cards = buildDashboardSummary()['metricCards'] as List<dynamic>;
    final weak =
        cards
            .cast<Map<String, dynamic>>()
            .where((card) => (card['average'] as num) < (card['target'] as num))
            .toList(growable: false)
          ..sort((a, b) {
            final aGap =
                (a['target'] as num).toDouble() -
                (a['average'] as num).toDouble();
            final bGap =
                (b['target'] as num).toDouble() -
                (b['average'] as num).toDouble();
            return bGap.compareTo(aGap);
          });
    return <String, dynamic>{
      'count': weak.length,
      'items': weak
          .take(8)
          .map(
            (card) => <String, dynamic>{
              'metricKey': card['metricKey'],
              'label': card['label'],
              'average': card['average'],
              'target': card['target'],
              'gap':
                  (card['target'] as num).toDouble() -
                  (card['average'] as num).toDouble(),
            },
          )
          .toList(growable: false),
    };
  }

  List<NovaBenchmarkSample> evaluateConversationEpisode({
    required bool ownerPriorityPreserved,
    required double backchannelQuality,
    required double interruptionQuality,
    required double semanticTurnAccuracy,
    required double memoryCommitQuality,
    required double relationshipToneQuality,
    required bool ttsSelfBlindProtected,
    required bool multiSpeakerStable,
    required bool noteDelivered,
    required double latencyScore,
  }) {
    final now = DateTime.now();
    return <NovaBenchmarkSample>[
      NovaBenchmarkSample(
        metricKey: 'owner_priority',
        value: ownerPriorityPreserved ? 0.98 : 0.54,
        target: _targets['owner_priority']!,
        weight: _weights['owner_priority']!,
        label: 'Owner Priority',
        explanation:
            'Owner ve delegated aynı anda konuştuğunda owner baskın kalmalı.',
        createdAt: now,
      ),
      NovaBenchmarkSample(
        metricKey: 'backchannel_success',
        value: backchannelQuality,
        target: _targets['backchannel_success']!,
        weight: _weights['backchannel_success']!,
        label: 'Backchannel',
        explanation:
            'Kısa dinliyorum/evet/hmm tepkileri doğal ve zamanında mı?',
        createdAt: now,
      ),
      NovaBenchmarkSample(
        metricKey: 'interruption_quality',
        value: interruptionQuality,
        target: _targets['interruption_quality']!,
        weight: _weights['interruption_quality']!,
        label: 'Interruption Quality',
        explanation: 'Yanlış kesme ve gerçek devralma ayrımı.',
        createdAt: now,
      ),
      NovaBenchmarkSample(
        metricKey: 'semantic_turn_accuracy',
        value: semanticTurnAccuracy,
        target: _targets['semantic_turn_accuracy']!,
        weight: _weights['semantic_turn_accuracy']!,
        label: 'Semantic Turn',
        explanation: 'Silence değil anlam temelli turn kararı.',
        createdAt: now,
      ),
      NovaBenchmarkSample(
        metricKey: 'memory_commit_quality',
        value: memoryCommitQuality,
        target: _targets['memory_commit_quality']!,
        weight: _weights['memory_commit_quality']!,
        label: 'Memory Commit',
        explanation: 'Olayın doğru tür hafızaya yazılması.',
        createdAt: now,
      ),
      NovaBenchmarkSample(
        metricKey: 'relationship_tone_quality',
        value: relationshipToneQuality,
        target: _targets['relationship_tone_quality']!,
        weight: _weights['relationship_tone_quality']!,
        label: 'Relation Tone',
        explanation: 'Anne/baba/eş/arkadaş ton ayrımı.',
        createdAt: now,
      ),
      NovaBenchmarkSample(
        metricKey: 'tts_self_deafness',
        value: ttsSelfBlindProtected ? 0.99 : 0.35,
        target: _targets['tts_self_deafness']!,
        weight: _weights['tts_self_deafness']!,
        label: 'Self-TTS Guard',
        explanation: 'Kendi TTS çıktısını giriş saymama.',
        createdAt: now,
      ),
      NovaBenchmarkSample(
        metricKey: 'multi_speaker_stability',
        value: multiSpeakerStable ? 0.95 : 0.48,
        target: _targets['multi_speaker_stability']!,
        weight: _weights['multi_speaker_stability']!,
        label: 'Multi Speaker',
        explanation: 'Kalabalık ortamda kişi karıştırmama.',
        createdAt: now,
      ),
      NovaBenchmarkSample(
        metricKey: 'note_delivery_quality',
        value: noteDelivered ? 0.94 : 0.46,
        target: _targets['note_delivery_quality']!,
        weight: _weights['note_delivery_quality']!,
        label: 'Note Delivery',
        explanation: 'Önemli notun doğru özet ve doğru hatırlatma ile teslimi.',
        createdAt: now,
      ),
      NovaBenchmarkSample(
        metricKey: 'latency_budget',
        value: latencyScore,
        target: _targets['latency_budget']!,
        weight: _weights['latency_budget']!,
        label: 'Latency Budget',
        explanation: 'Ses-first sistemde ilk tepki hızı.',
        createdAt: now,
      ),
    ];
  }

  NovaBenchmarkSnapshot _recompute(List<NovaBenchmarkSample> samples) {
    if (samples.isEmpty) {
      return NovaBenchmarkSnapshot.initial();
    }
    double totalWeight = 0;
    double weighted = 0;
    for (final sample in samples) {
      totalWeight += sample.weight;
      weighted += sample.weight * sample.normalizedScore;
    }
    final weightedScore = totalWeight <= 0 ? 0 : weighted / totalWeight;
    final digitalHumanScore = _composeDigitalHumanScore(
      samples,
      weightedScore.toDouble(),
    );
    return NovaBenchmarkSnapshot(
      samples: samples,
      weightedScore: weightedScore.toDouble(),
      digitalHumanScore: digitalHumanScore,
      updatedAt: DateTime.now(),
    );
  }

  double _composeDigitalHumanScore(
    List<NovaBenchmarkSample> samples,
    double weightedScore,
  ) {
    final latestByKey = <String, NovaBenchmarkSample>{};
    for (final sample in samples) {
      latestByKey.putIfAbsent(sample.metricKey, () => sample);
    }
    final criticalKeys = <String>[
      'speaker_routing',
      'owner_priority',
      'interruption_quality',
      'semantic_turn_accuracy',
      'call_takeover_accuracy',
      'call_handoff_accuracy',
      'note_delivery_quality',
      'relationship_tone_quality',
      'tts_self_deafness',
      'multi_speaker_stability',
    ];
    final criticalValues = criticalKeys
        .map((key) => latestByKey[key]?.value ?? 0.0)
        .toList(growable: false);
    final criticalAverage = criticalValues.isEmpty
        ? 0.0
        : criticalValues.reduce((a, b) => a + b) / criticalValues.length;
    return ((weightedScore * 0.45) + (criticalAverage * 0.55)).clamp(0, 1);
  }

  String _statusFor(double average, double target) {
    if (average >= target) return 'strong';
    if (average >= target - 0.06) return 'watch';
    return 'weak';
  }
}
