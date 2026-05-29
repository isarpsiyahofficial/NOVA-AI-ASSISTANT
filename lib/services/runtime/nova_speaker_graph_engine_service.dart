// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
import 'dart:math';

import '../../core/identity/voice_access_decision.dart';

enum NovaSpeakerGraphBand { owner, delegated, familiar, socialOnly, unknown }

class NovaSpeakerGraphObservation {
  final String voiceId;
  final String displayName;
  final String relationLabel;
  final NovaSpeakerGraphBand band;
  final double similarity;
  final bool addressedNova;
  final bool containsCommand;
  final bool commandPriority;
  final bool activeCall;
  final bool companionActive;
  final bool syntheticPlaybackGuarded;
  final String transcript;
  final DateTime observedAt;
  final Map<String, dynamic> metadata;

  const NovaSpeakerGraphObservation({
    required this.voiceId,
    required this.displayName,
    required this.relationLabel,
    required this.band,
    required this.similarity,
    required this.addressedNova,
    required this.containsCommand,
    required this.commandPriority,
    required this.activeCall,
    required this.companionActive,
    required this.syntheticPlaybackGuarded,
    required this.transcript,
    required this.observedAt,
    this.metadata = const <String, dynamic>{},
  });

  NovaSpeakerGraphObservation copyWith({
    String? voiceId,
    String? displayName,
    String? relationLabel,
    NovaSpeakerGraphBand? band,
    double? similarity,
    bool? addressedNova,
    bool? containsCommand,
    bool? commandPriority,
    bool? activeCall,
    bool? companionActive,
    bool? syntheticPlaybackGuarded,
    String? transcript,
    DateTime? observedAt,
    Map<String, dynamic>? metadata,
  }) {
    return NovaSpeakerGraphObservation(
      voiceId: voiceId ?? this.voiceId,
      displayName: displayName ?? this.displayName,
      relationLabel: relationLabel ?? this.relationLabel,
      band: band ?? this.band,
      similarity: similarity ?? this.similarity,
      addressedNova: addressedNova ?? this.addressedNova,
      containsCommand: containsCommand ?? this.containsCommand,
      commandPriority: commandPriority ?? this.commandPriority,
      activeCall: activeCall ?? this.activeCall,
      companionActive: companionActive ?? this.companionActive,
      syntheticPlaybackGuarded:
          syntheticPlaybackGuarded ?? this.syntheticPlaybackGuarded,
      transcript: transcript ?? this.transcript,
      observedAt: observedAt ?? this.observedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'voiceId': voiceId,
    'displayName': displayName,
    'relationLabel': relationLabel,
    'band': band.name,
    'similarity': similarity,
    'addressedNova': addressedNova,
    'containsCommand': containsCommand,
    'commandPriority': commandPriority,
    'activeCall': activeCall,
    'companionActive': companionActive,
    'syntheticPlaybackGuarded': syntheticPlaybackGuarded,
    'transcript': transcript,
    'observedAt': observedAt.toIso8601String(),
    'metadata': metadata,
  };

  factory NovaSpeakerGraphObservation.fromMap(Map<String, dynamic> map) {
    NovaSpeakerGraphBand parseBand(String raw) {
      for (final value in NovaSpeakerGraphBand.values) {
        if (value.name == raw) return value;
      }
      return NovaSpeakerGraphBand.unknown;
    }

    return NovaSpeakerGraphObservation(
      voiceId: map['voiceId']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      relationLabel: map['relationLabel']?.toString() ?? '',
      band: parseBand(map['band']?.toString() ?? ''),
      similarity: (map['similarity'] as num?)?.toDouble() ?? 0,
      addressedNova: map['addressedNova'] as bool? ?? false,
      containsCommand: map['containsCommand'] as bool? ?? false,
      commandPriority: map['commandPriority'] as bool? ?? false,
      activeCall: map['activeCall'] as bool? ?? false,
      companionActive: map['companionActive'] as bool? ?? false,
      syntheticPlaybackGuarded:
          map['syntheticPlaybackGuarded'] as bool? ?? false,
      transcript: map['transcript']?.toString() ?? '',
      observedAt:
          DateTime.tryParse(map['observedAt']?.toString() ?? '') ??
          DateTime.now(),
      metadata:
          (map['metadata'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
  }
}

class NovaSpeakerGraphNode {
  final String voiceId;
  final String displayName;
  final String relationLabel;
  final NovaSpeakerGraphBand band;
  final double trustScore;
  final double commandScore;
  final double socialCloseness;
  final double recencyScore;
  final DateTime firstObservedAt;
  final DateTime lastObservedAt;
  final int observationCount;
  final int commandCount;
  final int socialTurnCount;
  final int directAddressCount;
  final List<String> lastTopics;
  final Map<String, dynamic> metadata;

  const NovaSpeakerGraphNode({
    required this.voiceId,
    required this.displayName,
    required this.relationLabel,
    required this.band,
    required this.trustScore,
    required this.commandScore,
    required this.socialCloseness,
    required this.recencyScore,
    required this.firstObservedAt,
    required this.lastObservedAt,
    required this.observationCount,
    required this.commandCount,
    required this.socialTurnCount,
    required this.directAddressCount,
    required this.lastTopics,
    this.metadata = const <String, dynamic>{},
  });

  factory NovaSpeakerGraphNode.seed(NovaSpeakerGraphObservation observation) {
    return NovaSpeakerGraphNode(
      voiceId: observation.voiceId,
      displayName: observation.displayName,
      relationLabel: observation.relationLabel,
      band: observation.band,
      trustScore: _baseTrustForBand(observation.band),
      commandScore: observation.containsCommand ? 0.62 : 0.18,
      socialCloseness: observation.addressedNova ? 0.54 : 0.22,
      recencyScore: 1,
      firstObservedAt: observation.observedAt,
      lastObservedAt: observation.observedAt,
      observationCount: 1,
      commandCount: observation.containsCommand ? 1 : 0,
      socialTurnCount: observation.containsCommand ? 0 : 1,
      directAddressCount: observation.addressedNova ? 1 : 0,
      lastTopics: _extractTopics(observation.transcript),
      metadata: observation.metadata,
    );
  }

  static double _baseTrustForBand(NovaSpeakerGraphBand band) {
    switch (band) {
      case NovaSpeakerGraphBand.owner:
        return 1.0;
      case NovaSpeakerGraphBand.delegated:
        return 0.86;
      case NovaSpeakerGraphBand.familiar:
        return 0.62;
      case NovaSpeakerGraphBand.socialOnly:
        return 0.44;
      case NovaSpeakerGraphBand.unknown:
        return 0.18;
    }
  }

  static List<String> _extractTopics(String transcript) {
    final normalized = transcript
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-ZçğıöşüÇĞİÖŞÜ0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return const <String>[];
    final stopWords = <String>{
      've',
      'ile',
      'bir',
      'bunu',
      'şunu',
      'bana',
      'beni',
      'icin',
      'için',
      'ama',
      'fakat',
      'gibi',
      'olan',
      'olanı',
      'mı',
      'mi',
      'mu',
      'mü',
      'ki',
      'bu',
      'o',
      'da',
      'de',
      'sen',
      'nova',
    };
    final tokens = normalized
        .split(' ')
        .where(
          (token) =>
              token.trim().length >= 3 && !stopWords.contains(token.trim()),
        )
        .toList(growable: false);
    return tokens.take(8).toList(growable: false);
  }

  NovaSpeakerGraphNode absorb(NovaSpeakerGraphObservation observation) {
    final spanMinutes = max(
      1,
      observation.observedAt.difference(lastObservedAt).inMinutes.abs(),
    );
    final recencyBoost = 1 / (1 + spanMinutes / 30);
    final similarityBoost = observation.similarity.clamp(0, 1) * 0.28;
    final addressBoost = observation.addressedNova ? 0.09 : 0.01;
    final commandBoost = observation.containsCommand ? 0.11 : -0.01;
    final syntheticPenalty = observation.syntheticPlaybackGuarded ? 0.08 : 0;
    final updatedTopics = <String>{
      ...lastTopics,
      ..._extractTopics(observation.transcript),
    }.take(10).toList(growable: false);

    return NovaSpeakerGraphNode(
      voiceId: voiceId,
      displayName: observation.displayName.trim().isEmpty
          ? displayName
          : observation.displayName.trim(),
      relationLabel: observation.relationLabel.trim().isEmpty
          ? relationLabel
          : observation.relationLabel.trim(),
      band: _resolveBand(band, observation.band),
      trustScore: _clamp01(
        (trustScore * 0.80) +
            _baseTrustForBand(observation.band) * 0.10 +
            similarityBoost +
            addressBoost -
            syntheticPenalty,
      ),
      commandScore: _clamp01(
        (commandScore * 0.78) +
            (observation.containsCommand ? 0.18 : 0.04) +
            similarityBoost / 2 +
            commandBoost,
      ),
      socialCloseness: _clamp01(
        (socialCloseness * 0.82) +
            (observation.containsCommand ? 0.02 : 0.11) +
            (observation.addressedNova ? 0.04 : 0.01),
      ),
      recencyScore: _clamp01((recencyScore * 0.55) + recencyBoost * 0.45),
      firstObservedAt: firstObservedAt,
      lastObservedAt: observation.observedAt,
      observationCount: observationCount + 1,
      commandCount: commandCount + (observation.containsCommand ? 1 : 0),
      socialTurnCount: socialTurnCount + (observation.containsCommand ? 0 : 1),
      directAddressCount:
          directAddressCount + (observation.addressedNova ? 1 : 0),
      lastTopics: updatedTopics,
      metadata: <String, dynamic>{
        ...metadata,
        ...observation.metadata,
        'lastObservationSimilarity': observation.similarity,
        'lastObservationCommand': observation.containsCommand,
        'lastObservationTranscript': observation.transcript,
      },
    );
  }

  static double _clamp01(double value) {
    if (value.isNaN) return 0;
    return value.clamp(0.0, 1.0).toDouble();
  }

  static NovaSpeakerGraphBand _resolveBand(
    NovaSpeakerGraphBand current,
    NovaSpeakerGraphBand incoming,
  ) {
    final order = <NovaSpeakerGraphBand, int>{
      NovaSpeakerGraphBand.owner: 5,
      NovaSpeakerGraphBand.delegated: 4,
      NovaSpeakerGraphBand.familiar: 3,
      NovaSpeakerGraphBand.socialOnly: 2,
      NovaSpeakerGraphBand.unknown: 1,
    };
    return (order[incoming] ?? 0) >= (order[current] ?? 0) ? incoming : current;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'voiceId': voiceId,
    'displayName': displayName,
    'relationLabel': relationLabel,
    'band': band.name,
    'trustScore': trustScore,
    'commandScore': commandScore,
    'socialCloseness': socialCloseness,
    'recencyScore': recencyScore,
    'firstObservedAt': firstObservedAt.toIso8601String(),
    'lastObservedAt': lastObservedAt.toIso8601String(),
    'observationCount': observationCount,
    'commandCount': commandCount,
    'socialTurnCount': socialTurnCount,
    'directAddressCount': directAddressCount,
    'lastTopics': lastTopics,
    'metadata': metadata,
  };

  factory NovaSpeakerGraphNode.fromMap(Map<String, dynamic> map) {
    NovaSpeakerGraphBand parseBand(String raw) {
      for (final value in NovaSpeakerGraphBand.values) {
        if (value.name == raw) return value;
      }
      return NovaSpeakerGraphBand.unknown;
    }

    return NovaSpeakerGraphNode(
      voiceId: map['voiceId']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      relationLabel: map['relationLabel']?.toString() ?? '',
      band: parseBand(map['band']?.toString() ?? ''),
      trustScore: (map['trustScore'] as num?)?.toDouble() ?? 0,
      commandScore: (map['commandScore'] as num?)?.toDouble() ?? 0,
      socialCloseness: (map['socialCloseness'] as num?)?.toDouble() ?? 0,
      recencyScore: (map['recencyScore'] as num?)?.toDouble() ?? 0,
      firstObservedAt:
          DateTime.tryParse(map['firstObservedAt']?.toString() ?? '') ??
          DateTime.now(),
      lastObservedAt:
          DateTime.tryParse(map['lastObservedAt']?.toString() ?? '') ??
          DateTime.now(),
      observationCount: (map['observationCount'] as num?)?.toInt() ?? 0,
      commandCount: (map['commandCount'] as num?)?.toInt() ?? 0,
      socialTurnCount: (map['socialTurnCount'] as num?)?.toInt() ?? 0,
      directAddressCount: (map['directAddressCount'] as num?)?.toInt() ?? 0,
      lastTopics: (map['lastTopics'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      metadata:
          (map['metadata'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
  }
}

class NovaSpeakerGraphDecision {
  final String chosenVoiceId;
  final String chosenDisplayName;
  final String chosenRelationLabel;
  final NovaSpeakerGraphBand chosenBand;
  final bool allowCommand;
  final bool allowConversation;
  final bool ownerDominated;
  final bool needsOwnerApprovalForNewPerson;
  final bool shouldSoftReject;
  final double confidence;
  final String spokenResponse;
  final List<String> reasons;
  final Map<String, dynamic> metadata;

  const NovaSpeakerGraphDecision({
    required this.chosenVoiceId,
    required this.chosenDisplayName,
    required this.chosenRelationLabel,
    required this.chosenBand,
    required this.allowCommand,
    required this.allowConversation,
    required this.ownerDominated,
    required this.needsOwnerApprovalForNewPerson,
    required this.shouldSoftReject,
    required this.confidence,
    String spokenResponse = '',
    required this.reasons,
    this.metadata = const <String, dynamic>{},
  }) : spokenResponse = '';
}

class NovaSpeakerGraphSnapshot {
  final Map<String, NovaSpeakerGraphNode> nodes;
  final String ownerVoiceId;
  final String delegatedVoiceId;
  final DateTime updatedAt;
  final List<NovaSpeakerGraphObservation> recentObservations;

  const NovaSpeakerGraphSnapshot({
    required this.nodes,
    required this.ownerVoiceId,
    required this.delegatedVoiceId,
    required this.updatedAt,
    required this.recentObservations,
  });

  factory NovaSpeakerGraphSnapshot.initial({
    String ownerVoiceId = '',
    String delegatedVoiceId = '',
  }) {
    return NovaSpeakerGraphSnapshot(
      nodes: const <String, NovaSpeakerGraphNode>{},
      ownerVoiceId: ownerVoiceId,
      delegatedVoiceId: delegatedVoiceId,
      updatedAt: DateTime.now(),
      recentObservations: const <NovaSpeakerGraphObservation>[],
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'nodes': nodes.map((key, value) => MapEntry(key, value.toMap())),
    'ownerVoiceId': ownerVoiceId,
    'delegatedVoiceId': delegatedVoiceId,
    'updatedAt': updatedAt.toIso8601String(),
    'recentObservations': recentObservations
        .map((e) => e.toMap())
        .toList(growable: false),
  };
}

class NovaSpeakerGraphEngineService {
  const NovaSpeakerGraphEngineService();

  NovaSpeakerGraphBand bandForLevel(VoiceAccessLevel? level) {
    switch (level) {
      case VoiceAccessLevel.owner:
        return NovaSpeakerGraphBand.owner;
      case VoiceAccessLevel.authorizedGuest:
        return NovaSpeakerGraphBand.delegated;
      case VoiceAccessLevel.familiar:
        return NovaSpeakerGraphBand.familiar;
      case VoiceAccessLevel.knownButUnauthorized:
        return NovaSpeakerGraphBand.socialOnly;
      case VoiceAccessLevel.denied:
      case null:
        return NovaSpeakerGraphBand.unknown;
    }
  }

  NovaSpeakerGraphSnapshot ingest({
    required NovaSpeakerGraphSnapshot snapshot,
    required NovaSpeakerGraphObservation observation,
  }) {
    final voiceId = observation.voiceId.trim();
    if (voiceId.isEmpty) {
      return snapshot;
    }
    final nodes = <String, NovaSpeakerGraphNode>{...snapshot.nodes};
    final existing = nodes[voiceId];
    nodes[voiceId] = existing == null
        ? NovaSpeakerGraphNode.seed(observation)
        : existing.absorb(observation);
    final recent = <NovaSpeakerGraphObservation>[
      observation,
      ...snapshot.recentObservations,
    ].take(18).toList(growable: false);
    return NovaSpeakerGraphSnapshot(
      nodes: nodes,
      ownerVoiceId: snapshot.ownerVoiceId,
      delegatedVoiceId: snapshot.delegatedVoiceId,
      updatedAt: observation.observedAt,
      recentObservations: recent,
    );
  }

  NovaSpeakerGraphDecision decide({
    required NovaSpeakerGraphSnapshot snapshot,
    required String transcript,
    String addressedName = '',
    bool containsCommand = false,
    bool activeCall = false,
    bool companionActive = false,
  }) {
    final normalizedTranscript = _normalize(transcript);
    final normalizedAddressedName = _normalize(addressedName);
    final candidates = snapshot.nodes.values.toList(growable: false);
    if (candidates.isEmpty) {
      final softReject =
          containsCommand || normalizedTranscript.contains('nova');
      return NovaSpeakerGraphDecision(
        chosenVoiceId: '',
        chosenDisplayName: '',
        chosenRelationLabel: '',
        chosenBand: NovaSpeakerGraphBand.unknown,
        allowCommand: false,
        allowConversation: !containsCommand,
        ownerDominated: false,
        needsOwnerApprovalForNewPerson: true,
        shouldSoftReject: softReject,
        confidence: 0.24,
        spokenResponse: '',
        reasons: const <String>['boş speaker graph'],
        metadata: <String, dynamic>{'candidateCount': 0},
      );
    }

    final scored = <MapEntry<NovaSpeakerGraphNode, double>>[];
    for (final node in candidates) {
      final score = _scoreNode(
        node: node,
        normalizedTranscript: normalizedTranscript,
        normalizedAddressedName: normalizedAddressedName,
        containsCommand: containsCommand,
        activeCall: activeCall,
        companionActive: companionActive,
        snapshot: snapshot,
      );
      scored.add(MapEntry(node, score));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    final best = scored.first;
    final second = scored.length > 1 ? scored[1] : null;
    final gap = second == null ? best.value : (best.value - second.value);
    final confidence = _clamp01(0.42 + best.value * 0.42 + gap * 0.30);

    final node = best.key;
    final ownerDominated =
        node.band == NovaSpeakerGraphBand.owner ||
        node.voiceId == snapshot.ownerVoiceId;
    final allowCommand =
        node.band == NovaSpeakerGraphBand.owner ||
        node.band == NovaSpeakerGraphBand.delegated;
    final allowConversation =
        allowCommand ||
        node.band == NovaSpeakerGraphBand.familiar ||
        node.band == NovaSpeakerGraphBand.socialOnly;
    final needsOwnerApprovalForNewPerson =
        node.band == NovaSpeakerGraphBand.unknown && !ownerDominated;
    final shouldSoftReject = containsCommand && !allowCommand;

    return NovaSpeakerGraphDecision(
      chosenVoiceId: node.voiceId,
      chosenDisplayName: node.displayName,
      chosenRelationLabel: node.relationLabel,
      chosenBand: node.band,
      allowCommand: allowCommand,
      allowConversation: allowConversation,
      ownerDominated: ownerDominated,
      needsOwnerApprovalForNewPerson: needsOwnerApprovalForNewPerson,
      shouldSoftReject: shouldSoftReject,
      confidence: confidence,
      spokenResponse: '',
      reasons: <String>[
        'band=${node.band.name}',
        'trust=${node.trustScore.toStringAsFixed(2)}',
        'command=${node.commandScore.toStringAsFixed(2)}',
        'social=${node.socialCloseness.toStringAsFixed(2)}',
        'recency=${node.recencyScore.toStringAsFixed(2)}',
        'gap=${gap.toStringAsFixed(2)}',
      ],
      metadata: <String, dynamic>{
        'topScore': best.value,
        'secondScore': second?.value ?? 0,
        'candidateCount': scored.length,
        'topCandidates': scored
            .take(4)
            .map(
              (entry) => <String, dynamic>{
                'voiceId': entry.key.voiceId,
                'displayName': entry.key.displayName,
                'band': entry.key.band.name,
                'score': entry.value,
              },
            )
            .toList(growable: false),
      },
    );
  }

  String buildPromptSection(NovaSpeakerGraphSnapshot snapshot) {
    final nodes = snapshot.nodes.values.toList(growable: false)
      ..sort((a, b) => b.trustScore.compareTo(a.trustScore));
    final lines = <String>[
      'SPEAKER GRAPH ENGINE:',
      '- düğüm sayısı: ${nodes.length}',
      '- owner voice id: ${snapshot.ownerVoiceId.isEmpty ? 'yok' : snapshot.ownerVoiceId}',
      '- delegated voice id: ${snapshot.delegatedVoiceId.isEmpty ? 'yok' : snapshot.delegatedVoiceId}',
      '- güncellendi: ${snapshot.updatedAt.toIso8601String()}',
      'KURAL: komut yetkisi owner > delegated > familiar/socialOnly > unknown sırasındadır.',
      'KURAL: aynı anda owner ve başka yetkili konuşursa owner baskın kalır.',
      'KURAL: tanışılmamış kişi sohbet başlatabilir ama komut zincirine giremez; gerekiyorsa owner izni istenir.',
    ];
    for (final node in nodes.take(5)) {
      lines.add(
        '- ${node.displayName.isEmpty ? node.voiceId : node.displayName}: ${node.band.name} | trust=${node.trustScore.toStringAsFixed(2)} | command=${node.commandScore.toStringAsFixed(2)} | social=${node.socialCloseness.toStringAsFixed(2)} | topics=${node.lastTopics.take(4).join(', ')}',
      );
    }
    return lines.join('\n');
  }

  Map<String, dynamic> buildAuthorityHints({
    required NovaSpeakerGraphSnapshot snapshot,
    required String transcript,
    required bool containsCommand,
    required bool activeCall,
    required bool companionActive,
  }) {
    final decision = decide(
      snapshot: snapshot,
      transcript: transcript,
      containsCommand: containsCommand,
      activeCall: activeCall,
      companionActive: companionActive,
    );
    return <String, dynamic>{
      'chosenVoiceId': decision.chosenVoiceId,
      'chosenDisplayName': decision.chosenDisplayName,
      'chosenRelationLabel': decision.chosenRelationLabel,
      'chosenBand': decision.chosenBand.name,
      'allowCommand': decision.allowCommand,
      'allowConversation': decision.allowConversation,
      'ownerDominated': decision.ownerDominated,
      'needsOwnerApprovalForNewPerson': decision.needsOwnerApprovalForNewPerson,
      'shouldSoftReject': decision.shouldSoftReject,
      'confidence': decision.confidence,
      'spokenResponse': decision.spokenResponse,
      'reasons': decision.reasons,
      ...decision.metadata,
    };
  }

  String buildRelationshipNarrative({
    required String ownerName,
    required NovaSpeakerGraphNode node,
  }) {
    final owner = ownerName.trim().isEmpty ? 'patronum' : ownerName.trim();
    final relation = node.relationLabel.trim();
    if (relation.isEmpty) {
      switch (node.band) {
        case NovaSpeakerGraphBand.owner:
          return '$owner ile birincil sahiplik bağı.';
        case NovaSpeakerGraphBand.delegated:
          return '$owner tarafından yetkilendirilmiş güvenli konuşmacı.';
        case NovaSpeakerGraphBand.familiar:
          return '$owner çevresinden tanışılmış kişi; sosyal devamlılık var ama komut zinciri sınırlı.';
        case NovaSpeakerGraphBand.socialOnly:
          return '$owner çevresinden tanınan kişi; sosyal hitap mümkün, işlem yetkisi yok.';
        case NovaSpeakerGraphBand.unknown:
          return 'Henüz tanışılmamış kişi.';
      }
    }
    return '$relation bağlamı $owner ile ilişki tonunu belirliyor.';
  }

  double _scoreNode({
    required NovaSpeakerGraphNode node,
    required String normalizedTranscript,
    required String normalizedAddressedName,
    required bool containsCommand,
    required bool activeCall,
    required bool companionActive,
    required NovaSpeakerGraphSnapshot snapshot,
  }) {
    var score =
        node.trustScore * 0.30 +
        node.commandScore * 0.24 +
        node.socialCloseness * 0.16 +
        node.recencyScore * 0.18;
    if (containsCommand) {
      score += node.band == NovaSpeakerGraphBand.owner ? 0.22 : 0;
      score += node.band == NovaSpeakerGraphBand.delegated ? 0.15 : 0;
      score -= node.band == NovaSpeakerGraphBand.socialOnly ? 0.08 : 0;
      score -= node.band == NovaSpeakerGraphBand.unknown ? 0.18 : 0;
    }
    if (activeCall || companionActive) {
      score += node.relationLabel.toLowerCase().contains('anne') ? 0.05 : 0;
      score += node.relationLabel.toLowerCase().contains('baba') ? 0.05 : 0;
      score += node.relationLabel.toLowerCase().contains('eş') ? 0.05 : 0;
      score += node.relationLabel.toLowerCase().contains('es') ? 0.05 : 0;
    }
    if (normalizedAddressedName.isNotEmpty) {
      final display = _normalize(node.displayName);
      final relation = _normalize(node.relationLabel);
      if (display.contains(normalizedAddressedName) ||
          relation.contains(normalizedAddressedName)) {
        score += 0.22;
      }
    }
    if (normalizedTranscript.contains('patron') &&
        node.band == NovaSpeakerGraphBand.owner) {
      score += 0.16;
    }
    if (normalizedTranscript.contains('babam') &&
        _normalize(node.relationLabel).contains('baba')) {
      score += 0.18;
    }
    if (normalizedTranscript.contains('annem') &&
        _normalize(node.relationLabel).contains('anne')) {
      score += 0.18;
    }
    if (normalizedTranscript.contains('esim') &&
        _normalize(node.relationLabel).contains('es')) {
      score += 0.18;
    }
    if (snapshot.ownerVoiceId.isNotEmpty &&
        node.voiceId == snapshot.ownerVoiceId) {
      score += 0.08;
    }
    return _clamp01(score);
  }

  String _buildResponse({
    required NovaSpeakerGraphNode node,
    required bool containsCommand,
    required bool activeCall,
    required bool companionActive,
    required bool allowCommand,
    required bool allowConversation,
  }) {
    // Speaker graph is a trust/route signal only.
    // Final speech must be generated by NovaCoreTurnController/AI.
    return '';
  }

  String _normalize(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll('ê', 'e')
        .replaceAll('ô', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static double _clamp01(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}
