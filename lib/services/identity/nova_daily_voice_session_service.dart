// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/identity/voice_access_decision.dart';

class NovaDailyVoiceSessionSnapshot {
  final String dateKey;
  final String voiceId;
  final String recognizedName;
  final VoiceAccessLevel level;
  final DateTime updatedAt;

  const NovaDailyVoiceSessionSnapshot({
    required this.dateKey,
    required this.voiceId,
    required this.recognizedName,
    required this.level,
    required this.updatedAt,
  });

  bool get isTrusted =>
      level == VoiceAccessLevel.owner ||
      level == VoiceAccessLevel.authorizedGuest;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'dateKey': dateKey,
    'voiceId': voiceId,
    'recognizedName': recognizedName,
    'level': level.name,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NovaDailyVoiceSessionSnapshot.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return NovaDailyVoiceSessionSnapshot(
      dateKey: (map['dateKey'] as String? ?? '').trim(),
      voiceId: (map['voiceId'] as String? ?? '').trim(),
      recognizedName: (map['recognizedName'] as String? ?? '').trim(),
      level: VoiceAccessLevel.values.firstWhere(
        (e) => e.name == (map['level'] as String? ?? '').trim(),
        orElse: () => VoiceAccessLevel.denied,
      ),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? now,
    );
  }
}

class NovaDailyVoiceSessionService {
  static const String _storageKey = 'nova_daily_voice_session_v1';
  static const int _maxTrustedSpeakersPerDay = 6;

  const NovaDailyVoiceSessionService();

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<List<NovaDailyVoiceSessionSnapshot>> _loadTrustedSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return const <NovaDailyVoiceSessionSnapshot>[];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
              (e) => NovaDailyVoiceSessionSnapshot.fromMap(
                Map<String, dynamic>.from(e),
              ),
            )
            .where((e) => e.voiceId.trim().isNotEmpty)
            .toList(growable: true);
      }
      if (decoded is Map) {
        final migrated = NovaDailyVoiceSessionSnapshot.fromMap(
          Map<String, dynamic>.from(decoded),
        );
        return migrated.voiceId.trim().isEmpty
            ? const <NovaDailyVoiceSessionSnapshot>[]
            : <NovaDailyVoiceSessionSnapshot>[migrated];
      }
      return const <NovaDailyVoiceSessionSnapshot>[];
    } catch (_) {
      return const <NovaDailyVoiceSessionSnapshot>[];
    }
  }

  Future<void> _saveTrustedSessions(
    List<NovaDailyVoiceSessionSnapshot> items,
  ) async {
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

  List<NovaDailyVoiceSessionSnapshot> _cleanup(
    List<NovaDailyVoiceSessionSnapshot> items,
  ) {
    final today = _dateKey(DateTime.now());
    final filtered = items
        .where(
          (e) =>
              e.dateKey == today && e.isTrusted && e.voiceId.trim().isNotEmpty,
        )
        .toList(growable: true);
    filtered.sort((a, b) {
      final byPriority = _priority(b.level).compareTo(_priority(a.level));
      if (byPriority != 0) return byPriority;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    if (filtered.length <= _maxTrustedSpeakersPerDay) return filtered;
    return filtered.take(_maxTrustedSpeakersPerDay).toList(growable: false);
  }

  Future<List<NovaDailyVoiceSessionSnapshot>>
  loadActiveTrustedSessions() async {
    final items = _cleanup(await _loadTrustedSessions());
    await _saveTrustedSessions(items);
    return items;
  }

  Future<NovaDailyVoiceSessionSnapshot?> loadActiveTrustedSession() async {
    final items = await loadActiveTrustedSessions();
    if (items.isEmpty) return null;
    return items.first;
  }

  Future<bool> hasTrustedSessionToday() async {
    final items = await loadActiveTrustedSessions();
    return items.isNotEmpty;
  }

  Future<bool> isTrustedVoiceToday(String voiceId) async {
    final target = voiceId.trim();
    if (target.isEmpty) return false;
    final items = await loadActiveTrustedSessions();
    return items.any((e) => e.voiceId == target && e.isTrusted);
  }

  Future<void> rememberTrustedSpeaker({
    required String voiceId,
    required VoiceAccessLevel level,
    String recognizedName = '',
  }) async {
    final cleanedVoiceId = voiceId.trim();
    if (cleanedVoiceId.isEmpty) return;
    if (level != VoiceAccessLevel.owner &&
        level != VoiceAccessLevel.authorizedGuest) {
      return;
    }
    try {
      final items = List<NovaDailyVoiceSessionSnapshot>.from(
        await _loadTrustedSessions(),
      );
      final now = DateTime.now();
      final today = _dateKey(now);
      final index = items.indexWhere(
        (e) => e.voiceId == cleanedVoiceId && e.dateKey == today,
      );
      final snapshot = NovaDailyVoiceSessionSnapshot(
        dateKey: today,
        voiceId: cleanedVoiceId,
        recognizedName: recognizedName.trim(),
        level: level,
        updatedAt: now,
      );
      if (index >= 0) {
        final current = items[index];
        items[index] = NovaDailyVoiceSessionSnapshot(
          dateKey: today,
          voiceId: cleanedVoiceId,
          recognizedName: recognizedName.trim().isEmpty
              ? current.recognizedName
              : recognizedName.trim(),
          level: _priority(level) >= _priority(current.level)
              ? level
              : current.level,
          updatedAt: now,
        );
      } else {
        items.add(snapshot);
      }
      await _saveTrustedSessions(_cleanup(items));
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
