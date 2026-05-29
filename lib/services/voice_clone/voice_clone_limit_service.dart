// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class VoiceCloneLimitState {
  final String dayKey;
  final int usedCount;
  final String? lockedUntilIso;

  const VoiceCloneLimitState({
    required this.dayKey,
    required this.usedCount,
    this.lockedUntilIso,
  });

  const VoiceCloneLimitState.empty()
    : dayKey = '',
      usedCount = 0,
      lockedUntilIso = null;

  VoiceCloneLimitState copyWith({
    String? dayKey,
    int? usedCount,
    String? lockedUntilIso,
  }) {
    return VoiceCloneLimitState(
      dayKey: dayKey ?? this.dayKey,
      usedCount: usedCount ?? this.usedCount,
      lockedUntilIso: lockedUntilIso ?? this.lockedUntilIso,
    );
  }

  Map<String, dynamic> toMap() => {
    'dayKey': dayKey,
    'usedCount': usedCount,
    'lockedUntilIso': lockedUntilIso,
  };

  factory VoiceCloneLimitState.fromMap(Map<String, dynamic> map) {
    return VoiceCloneLimitState(
      dayKey: (map['dayKey'] as String? ?? '').trim(),
      usedCount: map['usedCount'] as int? ?? 0,
      lockedUntilIso: map['lockedUntilIso'] as String?,
    );
  }
}

class VoiceCloneLimitDecision {
  final bool allowed;
  final String message;

  const VoiceCloneLimitDecision({required this.allowed, required this.message});
}

class VoiceCloneLimitService {
  static const String _storageKey = 'nova_voice_clone_limit_v1';
  static const int _dailyMax = 4;

  const VoiceCloneLimitService();

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<VoiceCloneLimitState> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const VoiceCloneLimitState.empty();
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const VoiceCloneLimitState.empty();
      }

      return VoiceCloneLimitState.fromMap(
        Map<String, dynamic>.from(decoded as Map),
      );
    } catch (_) {
      return const VoiceCloneLimitState.empty();
    }
  }

  Future<void> _save(VoiceCloneLimitState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(state.toMap()));
    } catch (_) {
      // Sessiz fallback
    }
  }

  Future<VoiceCloneLimitDecision> canStartClone() async {
    final state = await _load();
    final now = DateTime.now();
    final today = _todayKey();

    if (state.lockedUntilIso != null) {
      final lockedUntil = DateTime.tryParse(state.lockedUntilIso!);
      if (lockedUntil != null && now.isBefore(lockedUntil)) {
        return VoiceCloneLimitDecision(
          allowed: false,
          message:
              'Klon limiti doldu efendim. ${lockedUntil.toLocal()} sonrasına kadar yeni klon açılamaz.',
        );
      }
    }

    if (state.dayKey != today) {
      await _save(
        VoiceCloneLimitState(dayKey: today, usedCount: 0, lockedUntilIso: null),
      );
      return const VoiceCloneLimitDecision(
        allowed: true,
        message: 'Klon başlatılabilir.',
      );
    }

    if (state.usedCount >= _dailyMax) {
      final lockedUntil = now.add(const Duration(hours: 24));
      await _save(
        state.copyWith(lockedUntilIso: lockedUntil.toIso8601String()),
      );
      return VoiceCloneLimitDecision(
        allowed: false,
        message:
            'Bugünkü klon limiti doldu efendim. 24 saat sonra tekrar deneyebilirsiniz.',
      );
    }

    return const VoiceCloneLimitDecision(
      allowed: true,
      message: 'Klon başlatılabilir.',
    );
  }

  Future<void> markCloneStarted() async {
    final state = await _load();
    final today = _todayKey();

    if (state.dayKey != today) {
      await _save(
        VoiceCloneLimitState(dayKey: today, usedCount: 1, lockedUntilIso: null),
      );
      return;
    }

    final nextCount = state.usedCount + 1;
    String? lock;
    if (nextCount >= _dailyMax) {
      lock = DateTime.now().add(const Duration(hours: 24)).toIso8601String();
    }

    await _save(state.copyWith(usedCount: nextCount, lockedUntilIso: lock));
  }
}
