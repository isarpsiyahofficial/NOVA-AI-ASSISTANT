// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/reminder/nova_reminder.dart';

class NovaReminderItem {
  final String id;
  final String title;
  final String kind;
  final DateTime dueAt;
  final bool completed;
  final NovaReminderStatus status;

  const NovaReminderItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.dueAt,
    this.completed = false,
    this.status = NovaReminderStatus.pending,
  });
}

class NovaReminderDueAnnouncement {
  final NovaReminder item;
  final String speechText;

  const NovaReminderDueAnnouncement({
    required this.item,
    String speechText = '',
  }) : speechText = '';
}

class NovaReminderService {
  static const String _storageKey = 'nova_reminders_v1';

  const NovaReminderService();

  Future<List<NovaReminder>> _loadRaw() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) return const <NovaReminder>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <NovaReminder>[];
      return decoded
          .whereType<Map>()
          .map((e) => NovaReminder.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <NovaReminder>[];
    }
  }

  Future<void> _saveRaw(List<NovaReminder> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(items.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {}
  }

  String _newId() => 'rem_${DateTime.now().microsecondsSinceEpoch}';

  Future<List<NovaReminderItem>> getAll() async {
    final items = await _loadRaw();
    return items
        .map(
          (e) => NovaReminderItem(
            id: e.id,
            title: e.text,
            kind: e.kind.name,
            dueAt: DateTime.tryParse(e.dueAtIso) ?? DateTime.now(),
            completed: e.status == NovaReminderStatus.completed,
            status: e.status,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  }

  Future<NovaReminder> add({
    required String text,
    required DateTime dueAt,
    NovaReminderKind kind = NovaReminderKind.reminder,
    bool repeatUntilAcknowledged = false,
    int maxActiveMinutes = 10,
    String wakeStyleKey = 'wake_alarm_loop_style',
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      throw ArgumentError('Hatırlatıcı metni boş olamaz.');
    }

    final nowIso = DateTime.now().toIso8601String();
    final reminder = NovaReminder(
      id: _newId(),
      text: normalizedText,
      dueAtIso: dueAt.toIso8601String(),
      status: NovaReminderStatus.pending,
      createdAtIso: nowIso,
      kind: kind,
      repeatUntilAcknowledged: repeatUntilAcknowledged,
      maxActiveMinutes: maxActiveMinutes,
      wakeStyleKey: wakeStyleKey,
    );

    final items = await _loadRaw();
    final next = <NovaReminder>[...items, reminder];
    await _saveRaw(next);
    return reminder;
  }

  Future<bool> complete(String id) async {
    return _updateStatus(
      id,
      status: NovaReminderStatus.completed,
      setAcknowledged: true,
    );
  }

  Future<bool> cancel(String id) async {
    return _updateStatus(id, status: NovaReminderStatus.cancelled);
  }

  Future<bool> delete(String id) async {
    final items = await _loadRaw();
    final next = items.where((e) => e.id != id).toList(growable: false);
    if (next.length == items.length) return false;
    await _saveRaw(next);
    return true;
  }

  Future<bool> postpone(String id, Duration duration) async {
    if (duration.inSeconds <= 0) return false;
    final items = await _loadRaw();
    bool changed = false;
    final next = items
        .map((e) {
          if (e.id != id) return e;
          changed = true;
          final dueAt = DateTime.tryParse(e.dueAtIso) ?? DateTime.now();
          return e.copyWith(
            dueAtIso: dueAt.add(duration).toIso8601String(),
            status: NovaReminderStatus.pending,
            completedAtIso: null,
            acknowledgedAtIso: null,
            activeUntilIso: null,
          );
        })
        .toList(growable: false);
    if (changed) {
      await _saveRaw(next);
    }
    return changed;
  }

  Future<bool> _updateStatus(
    String id, {
    required NovaReminderStatus status,
    bool setAcknowledged = false,
  }) async {
    final items = await _loadRaw();
    bool changed = false;
    final nowIso = DateTime.now().toIso8601String();
    final next = items
        .map((e) {
          if (e.id != id) return e;
          changed = true;
          return e.copyWith(
            status: status,
            completedAtIso: status == NovaReminderStatus.pending
                ? null
                : nowIso,
            acknowledgedAtIso: setAcknowledged ? nowIso : e.acknowledgedAtIso,
          );
        })
        .toList(growable: false);
    if (changed) {
      await _saveRaw(next);
    }
    return changed;
  }

  Future<List<NovaReminderDueAnnouncement>> collectDueAnnouncements() async {
    final items = await _loadRaw();
    if (items.isEmpty) return const <NovaReminderDueAnnouncement>[];

    final now = DateTime.now();
    bool changed = false;
    final announcements = <NovaReminderDueAnnouncement>[];
    final next = <NovaReminder>[];

    for (final item in items) {
      if (item.status != NovaReminderStatus.pending) {
        next.add(item);
        continue;
      }

      final dueAt = DateTime.tryParse(item.dueAtIso);
      if (dueAt == null || dueAt.isAfter(now)) {
        next.add(item);
        continue;
      }

      if (item.kind == NovaReminderKind.wakeAlarm) {
        final activeUntil = DateTime.tryParse(item.activeUntilIso ?? '');
        final nextActiveUntil =
            activeUntil ?? dueAt.add(Duration(minutes: item.maxActiveMinutes));
        final lastTriggered = DateTime.tryParse(item.lastTriggeredAtIso ?? '');
        final canTriggerAgain =
            lastTriggered == null ||
            now.difference(lastTriggered).inSeconds >= 45;

        if (now.isAfter(nextActiveUntil)) {
          changed = true;
          next.add(
            item.copyWith(
              status: NovaReminderStatus.completed,
              completedAtIso: now.toIso8601String(),
              activeUntilIso: nextActiveUntil.toIso8601String(),
            ),
          );
          continue;
        }

        if (canTriggerAgain) {
          changed = true;
          announcements.add(
            NovaReminderDueAnnouncement(
              item: item,
              speechText: '',
            ),
          );
          next.add(
            item.copyWith(
              activeUntilIso: nextActiveUntil.toIso8601String(),
              lastTriggeredAtIso: now.toIso8601String(),
              triggerCount: item.triggerCount + 1,
            ),
          );
        } else {
          next.add(
            item.copyWith(activeUntilIso: nextActiveUntil.toIso8601String()),
          );
        }
        continue;
      }

      changed = true;
      announcements.add(
        NovaReminderDueAnnouncement(
          item: item,
          speechText: '',
        ),
      );
      next.add(
        item.copyWith(
          status: NovaReminderStatus.completed,
          completedAtIso: now.toIso8601String(),
          lastTriggeredAtIso: now.toIso8601String(),
          triggerCount: item.triggerCount + 1,
        ),
      );
    }

    if (changed) {
      await _saveRaw(next);
    }

    return announcements;
  }

  Future<bool> tryAcknowledgeWakeAlarmFromInput(String raw) async {
    final normalized = raw.toLowerCase().trim();
    if (normalized.isEmpty) return false;
    final looksLikeAck =
        normalized.contains('tamam') ||
        normalized.contains('uyand') ||
        normalized.contains('kapat') ||
        normalized.contains('dur');
    if (!looksLikeAck) return false;

    final items = await _loadRaw();
    bool changed = false;
    final nowIso = DateTime.now().toIso8601String();
    final updated = items
        .map((e) {
          final isWake = e.kind == NovaReminderKind.wakeAlarm;
          final stillPending = e.status == NovaReminderStatus.pending;
          if (isWake && stillPending) {
            changed = true;
            return e.copyWith(
              status: NovaReminderStatus.completed,
              completedAtIso: nowIso,
              acknowledgedAtIso: nowIso,
            );
          }
          return e;
        })
        .toList(growable: false);
    if (changed) await _saveRaw(updated);
    return changed;
  }

  Future<void> cleanupCompleted() async {
    final items = await _loadRaw();
    final kept = items
        .where((e) {
          if (e.status != NovaReminderStatus.completed) return true;
          final completedAt = DateTime.tryParse(e.completedAtIso ?? '');
          if (completedAt == null) return false;
          return DateTime.now().difference(completedAt).inHours < 24;
        })
        .toList(growable: false);
    await _saveRaw(kept);
  }

  Future<int> cleanupCompletedManually() async {
    final items = await _loadRaw();
    final before = items.length;
    final kept = items
        .where((e) => e.status != NovaReminderStatus.completed)
        .toList(growable: false);
    await _saveRaw(kept);
    return before - kept.length;
  }
}
