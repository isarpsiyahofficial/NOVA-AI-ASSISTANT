// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/system/nova_power_mode.dart';

class NovaPowerService {
  static const String _storageKey = 'nova_power_mode_v1';
  static const String _scheduledNightHoldUntilKey =
      'nova_power_manual_night_hold_until_v1';

  NovaPowerMode _mode = NovaPowerMode.fullyOn;
  DateTime? _scheduledNightHoldUntil;

  NovaPowerMode get mode => _mode;
  bool get isFullyShutdown => _mode == NovaPowerMode.fullyShutdown;
  bool get isPassiveSleep => _mode == NovaPowerMode.passiveSleep;
  bool get isLimbo => _mode == NovaPowerMode.limbo;
  bool get isBatterySaver => _mode == NovaPowerMode.batterySaver;
  bool get isOperational => _mode.isOperational;
  DateTime? get scheduledNightHoldUntil => _scheduledNightHoldUntil;

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        _mode = NovaPowerMode.fullyOn;
      } else {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final key = (decoded['mode'] as String? ?? 'fullyOn').trim();
          _mode = NovaPowerMode.values.firstWhere(
            (e) => e.name == key,
            orElse: () => NovaPowerMode.fullyOn,
          );
        } else {
          _mode = NovaPowerMode.fullyOn;
        }
      }

      final holdRaw = prefs.getString(_scheduledNightHoldUntilKey);
      final parsedHold = DateTime.tryParse((holdRaw ?? '').trim());
      if (parsedHold != null && parsedHold.isAfter(DateTime.now())) {
        _scheduledNightHoldUntil = parsedHold;
      } else {
        _scheduledNightHoldUntil = null;
        await prefs.remove(_scheduledNightHoldUntilKey);
      }
    } catch (_) {
      _mode = NovaPowerMode.fullyOn;
      _scheduledNightHoldUntil = null;
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(<String, dynamic>{'mode': _mode.name}),
      );
      if (_scheduledNightHoldUntil != null &&
          _scheduledNightHoldUntil!.isAfter(DateTime.now())) {
        await prefs.setString(
          _scheduledNightHoldUntilKey,
          _scheduledNightHoldUntil!.toIso8601String(),
        );
      } else {
        _scheduledNightHoldUntil = null;
        await prefs.remove(_scheduledNightHoldUntilKey);
      }
    } catch (_) {}
  }

  Future<void> clearScheduledNightHold() async {
    _scheduledNightHoldUntil = null;
    await _persist();
  }

  DateTime buildScheduledNightHoldEnd({
    required DateTime now,
    required DateTime windowEnd,
  }) {
    final minimum = now.add(const Duration(minutes: 60));
    var candidate = DateTime(
      minimum.year,
      minimum.month,
      minimum.day,
      minimum.hour + 1,
    );
    if (!candidate.isAfter(minimum)) {
      candidate = candidate.add(const Duration(hours: 1));
    }
    if (candidate.isAfter(windowEnd)) {
      return windowEnd;
    }
    return candidate;
  }

  bool shouldKeepScheduledNightHold(DateTime now) {
    final hold = _scheduledNightHoldUntil;
    if (hold == null) return false;
    return now.isBefore(hold);
  }

  Future<void> setMode(
    NovaPowerMode mode, {
    bool userInitiated = false,
    DateTime? scheduledNightHoldUntil,
  }) async {
    _mode = mode;

    if (mode == NovaPowerMode.passiveSleep) {
      _scheduledNightHoldUntil = null;
    } else if (scheduledNightHoldUntil != null &&
        scheduledNightHoldUntil.isAfter(DateTime.now())) {
      _scheduledNightHoldUntil = scheduledNightHoldUntil;
    } else if (userInitiated && mode == NovaPowerMode.fullyShutdown) {
      _scheduledNightHoldUntil = null;
    }

    await _persist();
  }

  Future<void> setFullyOn({
    bool userInitiated = false,
    DateTime? scheduledNightHoldUntil,
  }) async => setMode(
    NovaPowerMode.fullyOn,
    userInitiated: userInitiated,
    scheduledNightHoldUntil: scheduledNightHoldUntil,
  );

  Future<void> setPassiveSleep({bool userInitiated = false}) async =>
      setMode(NovaPowerMode.passiveSleep, userInitiated: userInitiated);

  Future<void> setLimbo({
    bool userInitiated = false,
    DateTime? scheduledNightHoldUntil,
  }) async => setMode(
    NovaPowerMode.limbo,
    userInitiated: userInitiated,
    scheduledNightHoldUntil: scheduledNightHoldUntil,
  );

  Future<void> setBatterySaver({
    bool userInitiated = false,
    DateTime? scheduledNightHoldUntil,
  }) async => setMode(
    NovaPowerMode.batterySaver,
    userInitiated: userInitiated,
    scheduledNightHoldUntil: scheduledNightHoldUntil,
  );

  Future<void> setFullyShutdown({bool userInitiated = false}) async =>
      setMode(NovaPowerMode.fullyShutdown, userInitiated: userInitiated);

  Future<void> resetToDefault() async => setMode(NovaPowerMode.fullyOn);

  Future<String> getStartupGreeting({
    String fallback = 'Hoş geldin patron.',
  }) async {
    await restore();
    return fallback;
  }
}
