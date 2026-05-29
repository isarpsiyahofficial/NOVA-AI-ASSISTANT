// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/identity/voice_access_decision.dart';

class NovaRecentSpeakerObservation {
  final String voiceId;
  final String speakerName;
  final String relationshipLabel;
  final VoiceAccessLevel level;
  final DateTime observedAt;
  final int hitCount;

  const NovaRecentSpeakerObservation({
    required this.voiceId,
    required this.speakerName,
    required this.relationshipLabel,
    required this.level,
    required this.observedAt,
    required this.hitCount,
  });

  NovaRecentSpeakerObservation copyWith({
    String? voiceId,
    String? speakerName,
    String? relationshipLabel,
    VoiceAccessLevel? level,
    DateTime? observedAt,
    int? hitCount,
  }) {
    return NovaRecentSpeakerObservation(
      voiceId: voiceId ?? this.voiceId,
      speakerName: speakerName ?? this.speakerName,
      relationshipLabel: relationshipLabel ?? this.relationshipLabel,
      level: level ?? this.level,
      observedAt: observedAt ?? this.observedAt,
      hitCount: hitCount ?? this.hitCount,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'voiceId': voiceId,
    'speakerName': speakerName,
    'relationshipLabel': relationshipLabel,
    'level': level.name,
    'observedAt': observedAt.toIso8601String(),
    'hitCount': hitCount,
  };

  factory NovaRecentSpeakerObservation.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return NovaRecentSpeakerObservation(
      voiceId: (map['voiceId'] as String? ?? '').trim(),
      speakerName: (map['speakerName'] as String? ?? '').trim(),
      relationshipLabel: (map['relationshipLabel'] as String? ?? '').trim(),
      level: VoiceAccessLevel.values.firstWhere(
        (e) => e.name == (map['level'] as String? ?? '').trim(),
        orElse: () => VoiceAccessLevel.denied,
      ),
      observedAt: DateTime.tryParse(map['observedAt'] as String? ?? '') ?? now,
      hitCount: (map['hitCount'] as num?)?.toInt() ?? 1,
    );
  }
}

class NovaRecentSpeakerService {
  static const String _storageKey = 'nova_recent_speakers_v1';
  static const Duration retention = Duration(days: 7);
  static const int _maxItems = 72;

  const NovaRecentSpeakerService();

  Future<List<NovaRecentSpeakerObservation>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return const <NovaRecentSpeakerObservation>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <NovaRecentSpeakerObservation>[];
      return decoded
          .whereType<Map>()
          .map(
            (e) => NovaRecentSpeakerObservation.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(growable: true);
    } catch (_) {
      return const <NovaRecentSpeakerObservation>[];
    }
  }

  Future<void> _save(List<NovaRecentSpeakerObservation> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(items.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {}
  }

  int _priority(VoiceAccessLevel level) {
    switch (level) {
      case VoiceAccessLevel.owner:
        return 500;
      case VoiceAccessLevel.authorizedGuest:
        return 400;
      case VoiceAccessLevel.familiar:
        return 300;
      case VoiceAccessLevel.knownButUnauthorized:
        return 200;
      case VoiceAccessLevel.denied:
        return 100;
    }
  }

  List<NovaRecentSpeakerObservation> _cleanup(
    List<NovaRecentSpeakerObservation> items,
  ) {
    final cutoff = DateTime.now().subtract(retention);
    final kept = items
        .where(
          (e) => e.voiceId.trim().isNotEmpty && e.observedAt.isAfter(cutoff),
        )
        .toList(growable: true);
    kept.sort((a, b) {
      final byPriority = _priority(b.level).compareTo(_priority(a.level));
      if (byPriority != 0) return byPriority;
      final byHits = b.hitCount.compareTo(a.hitCount);
      if (byHits != 0) return byHits;
      return b.observedAt.compareTo(a.observedAt);
    });
    if (kept.length <= _maxItems) return kept;
    return kept.take(_maxItems).toList(growable: false);
  }

  Future<void> remember({
    required String voiceId,
    required VoiceAccessLevel level,
    String speakerName = '',
    String relationshipLabel = '',
  }) async {
    final cleanedVoiceId = voiceId.trim();
    if (cleanedVoiceId.isEmpty) return;
    final items = await _load();
    final now = DateTime.now();
    final index = items.indexWhere((e) => e.voiceId == cleanedVoiceId);
    if (index >= 0) {
      final current = items[index];
      items[index] = current.copyWith(
        speakerName: speakerName.trim().isEmpty
            ? current.speakerName
            : speakerName.trim(),
        relationshipLabel: relationshipLabel.trim().isEmpty
            ? current.relationshipLabel
            : relationshipLabel.trim(),
        level: _priority(level) >= _priority(current.level)
            ? level
            : current.level,
        observedAt: now,
        hitCount: current.hitCount + 1,
      );
    } else {
      items.add(
        NovaRecentSpeakerObservation(
          voiceId: cleanedVoiceId,
          speakerName: speakerName.trim(),
          relationshipLabel: relationshipLabel.trim(),
          level: level,
          observedAt: now,
          hitCount: 1,
        ),
      );
    }
    await _save(_cleanup(items));
  }

  Future<NovaRecentSpeakerObservation?> findByVoiceId(String voiceId) async {
    final target = voiceId.trim();
    if (target.isEmpty) return null;
    final items = _cleanup(await _load());
    await _save(items);
    for (final item in items) {
      if (item.voiceId == target) {
        return item;
      }
    }
    return null;
  }

  Future<bool> hasTrustedSpeakerWithin(Duration window) async {
    final items = _cleanup(await _load());
    await _save(items);
    final cutoff = DateTime.now().subtract(window);
    return items.any(
      (item) =>
          (item.level == VoiceAccessLevel.owner ||
              item.level == VoiceAccessLevel.authorizedGuest) &&
          item.observedAt.isAfter(cutoff),
    );
  }

  Future<NovaRecentSpeakerObservation?> bestTrustedSpeaker() async {
    final items = _cleanup(await _load());
    await _save(items);
    final trusted = items
        .where(
          (item) =>
              item.level == VoiceAccessLevel.owner ||
              item.level == VoiceAccessLevel.authorizedGuest,
        )
        .toList(growable: false);
    if (trusted.isEmpty) return null;

    trusted.sort((a, b) {
      final recentCutoff = DateTime.now().subtract(const Duration(hours: 18));
      final aRecent = a.observedAt.isAfter(recentCutoff);
      final bRecent = b.observedAt.isAfter(recentCutoff);
      if (aRecent != bRecent) return bRecent ? 1 : -1;
      final byPriority = _priority(b.level).compareTo(_priority(a.level));
      if (byPriority != 0) return byPriority;
      final byObserved = b.observedAt.compareTo(a.observedAt);
      if (byObserved != 0) return byObserved;
      return b.hitCount.compareTo(a.hitCount);
    });
    return trusted.first;
  }

  Future<NovaRecentSpeakerObservation?> bestConversationCandidate({
    Duration trustedWindow = const Duration(hours: 18),
    Duration familiarWindow = const Duration(hours: 8),
  }) async {
    final items = _cleanup(await _load());
    await _save(items);
    if (items.isEmpty) return null;

    final now = DateTime.now();
    final trustedCutoff = now.subtract(trustedWindow);
    final familiarCutoff = now.subtract(familiarWindow);
    final candidates = items
        .where((item) {
          if (item.level == VoiceAccessLevel.owner ||
              item.level == VoiceAccessLevel.authorizedGuest) {
            return item.observedAt.isAfter(trustedCutoff);
          }
          if (item.level == VoiceAccessLevel.familiar ||
              item.level == VoiceAccessLevel.knownButUnauthorized) {
            return item.observedAt.isAfter(familiarCutoff);
          }
          return false;
        })
        .toList(growable: true);

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final byPriority = _priority(b.level).compareTo(_priority(a.level));
      if (byPriority != 0) return byPriority;
      final byObserved = b.observedAt.compareTo(a.observedAt);
      if (byObserved != 0) return byObserved;
      return b.hitCount.compareTo(a.hitCount);
    });
    return candidates.first;
  }

  Future<NovaRecentSpeakerObservation?> findRecentTrustedByVoiceId(
    String voiceId,
  ) async {
    final target = voiceId.trim();
    if (target.isEmpty) return null;
    final items = _cleanup(await _load());
    await _save(items);
    for (final item in items) {
      if (item.voiceId == target &&
          (item.level == VoiceAccessLevel.owner ||
              item.level == VoiceAccessLevel.authorizedGuest)) {
        return item;
      }
    }
    return null;
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
