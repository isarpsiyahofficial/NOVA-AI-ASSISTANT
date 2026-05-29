// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NovaPowerSchedule {
  final bool enabled;
  final String sleepStart;
  final String sleepEnd;
  const NovaPowerSchedule({
    this.enabled = false,
    this.sleepStart = '00:00',
    this.sleepEnd = '06:00',
  });
  NovaPowerSchedule copyWith({
    bool? enabled,
    String? sleepStart,
    String? sleepEnd,
  }) => NovaPowerSchedule(
    enabled: enabled ?? this.enabled,
    sleepStart: sleepStart ?? this.sleepStart,
    sleepEnd: sleepEnd ?? this.sleepEnd,
  );
  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'sleepStart': sleepStart,
    'sleepEnd': sleepEnd,
  };
  factory NovaPowerSchedule.fromMap(Map<String, dynamic> map) =>
      NovaPowerSchedule(
        enabled: map['enabled'] as bool? ?? false,
        sleepStart: (map['sleepStart'] as String? ?? '00:00').trim(),
        sleepEnd: (map['sleepEnd'] as String? ?? '06:00').trim(),
      );
}

class NovaPowerScheduleWindow {
  final bool active;
  final DateTime start;
  final DateTime end;

  const NovaPowerScheduleWindow({
    required this.active,
    required this.start,
    required this.end,
  });
}

class NovaPowerScheduleService {
  static const String _k = 'nova_power_schedule_v1';
  const NovaPowerScheduleService();
  Future<NovaPowerSchedule> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw == null || raw.trim().isEmpty) return const NovaPowerSchedule();
      final d = jsonDecode(raw);
      if (d is! Map) return const NovaPowerSchedule();
      return NovaPowerSchedule.fromMap(Map<String, dynamic>.from(d));
    } catch (_) {
      return const NovaPowerSchedule();
    }
  }

  Future<void> save(NovaPowerSchedule schedule) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_k, jsonEncode(schedule.toMap()));
  }

  int _parseMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  NovaPowerScheduleWindow resolveWindow(
    NovaPowerSchedule schedule,
    DateTime now,
  ) {
    final startMinutes = _parseMinutes(schedule.sleepStart);
    final endMinutes = _parseMinutes(schedule.sleepEnd);
    final startToday = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(minutes: startMinutes));
    final endToday = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(minutes: endMinutes));

    if (!schedule.enabled || startMinutes == endMinutes) {
      return NovaPowerScheduleWindow(
        active: false,
        start: startToday,
        end: endToday,
      );
    }

    if (startMinutes < endMinutes) {
      final active = !now.isBefore(startToday) && now.isBefore(endToday);
      return NovaPowerScheduleWindow(
        active: active,
        start: startToday,
        end: endToday,
      );
    }

    if (!now.isBefore(startToday)) {
      final endTomorrow = endToday.add(const Duration(days: 1));
      return NovaPowerScheduleWindow(
        active: true,
        start: startToday,
        end: endTomorrow,
      );
    }

    final yesterdayStart = startToday.subtract(const Duration(days: 1));
    final active = now.isBefore(endToday);
    return NovaPowerScheduleWindow(
      active: active,
      start: yesterdayStart,
      end: endToday,
    );
  }

  bool shouldSleepNow(NovaPowerSchedule schedule, DateTime now) {
    return resolveWindow(schedule, now).active;
  }
}
