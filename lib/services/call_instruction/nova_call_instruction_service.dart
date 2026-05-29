// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/call_instruction/nova_call_instruction.dart';

class NovaCallInstructionService {
  static const String _storageKey = 'nova_call_instructions_v1';
  static const Duration _completedRetention = Duration(hours: 48);

  const NovaCallInstructionService();

  Future<List<NovaCallInstruction>> _loadRaw() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return const <NovaCallInstruction>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <NovaCallInstruction>[];
      return decoded
          .whereType<Map>()
          .map((e) => NovaCallInstruction.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <NovaCallInstruction>[];
    }
  }

  Future<void> _saveRaw(List<NovaCallInstruction> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(items.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {}
  }

  String _newId() => 'call_inst_${DateTime.now().microsecondsSinceEpoch}';

  Future<List<NovaCallInstruction>> getAll() async {
    await cleanupCompletedOlderThan48Hours();
    final items = await _loadRaw();
    return <NovaCallInstruction>[...items]
      ..sort((a, b) => b.createdAtIso.compareTo(a.createdAtIso));
  }

  Future<NovaCallInstruction> addFromDraft(
    NovaCallInstructionDraft draft,
  ) async {
    final contact = draft.contact;
    if (contact == null) {
      throw ArgumentError('Çağrı talimatı için kişi bulunamadı.');
    }
    if (!contact.canReceiveAutoCallHandling && !contact.isAuthorizedToUseNova) {
      throw ArgumentError('Bu kişi asistan çağrı talimatı için yetkili değil.');
    }
    final instruction = NovaCallInstruction(
      id: _newId(),
      type: draft.type,
      status: NovaCallInstructionStatus.pending,
      contactId: contact.id,
      contactName: contact.displayName,
      phoneNumber: contact.phoneNumber,
      instructionText: draft.instructionText.trim(),
      speakerPreferred: draft.speakerPreferred,
      createdAtIso: DateTime.now().toIso8601String(),
      scheduledForIso: draft.scheduledFor.toIso8601String(),
      recurrenceLabel: draft.recurrenceLabel.trim(),
    );
    final items = await _loadRaw();
    await _saveRaw(<NovaCallInstruction>[instruction, ...items]);
    return instruction;
  }

  Future<bool> updateStatus(
    String id,
    NovaCallInstructionStatus status, {
    DateTime? completedAt,
    DateTime? lastExecutedAt,
  }) async {
    final items = await _loadRaw();
    bool changed = false;
    final next = items
        .map((e) {
          if (e.id != id) return e;
          changed = true;
          return e.copyWith(
            status: status,
            completedAtIso: status == NovaCallInstructionStatus.completed
                ? (completedAt ?? DateTime.now()).toIso8601String()
                : e.completedAtIso,
            lastExecutedAtIso:
                lastExecutedAt?.toIso8601String() ?? e.lastExecutedAtIso,
          );
        })
        .toList(growable: false);
    if (changed) await _saveRaw(next);
    return changed;
  }

  Future<List<NovaCallInstruction>> collectDueInstructions({
    DateTime? now,
  }) async {
    final items = await _loadRaw();
    if (items.isEmpty) return const <NovaCallInstruction>[];
    final current = now ?? DateTime.now();
    return items
        .where((e) {
          if (e.status != NovaCallInstructionStatus.pending) return false;
          final scheduled = DateTime.tryParse(e.scheduledForIso);
          if (scheduled == null) return true;
          return !scheduled.isAfter(current);
        })
        .toList(growable: false);
  }

  Future<bool> completeExecution(
    NovaCallInstruction item, {
    DateTime? executedAt,
  }) async {
    final now = executedAt ?? DateTime.now();
    if (item.type == NovaCallInstructionType.recurringDaily) {
      final nextScheduled = _nextDailyExecution(item, now);
      final items = await _loadRaw();
      bool changed = false;
      final next = items
          .map((e) {
            if (e.id != item.id) return e;
            changed = true;
            return e.copyWith(
              status: NovaCallInstructionStatus.pending,
              lastExecutedAtIso: now.toIso8601String(),
              completedAtIso: null,
              scheduledForIso: nextScheduled.toIso8601String(),
            );
          })
          .toList(growable: false);
      if (changed) await _saveRaw(next);
      return changed;
    }
    return updateStatus(
      item.id,
      NovaCallInstructionStatus.completed,
      completedAt: now,
      lastExecutedAt: now,
    );
  }

  DateTime _nextDailyExecution(NovaCallInstruction item, DateTime now) {
    final scheduled = DateTime.tryParse(item.scheduledForIso);
    final base = scheduled ?? now;
    var next = DateTime(now.year, now.month, now.day, base.hour, base.minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  Future<int> cleanupCompletedOlderThan48Hours() async {
    final items = await _loadRaw();
    if (items.isEmpty) return 0;
    final now = DateTime.now();
    final next = items
        .where((e) {
          if (e.status != NovaCallInstructionStatus.completed) return true;
          final completedAt = DateTime.tryParse(e.completedAtIso ?? '');
          if (completedAt == null) return true;
          return now.difference(completedAt) < _completedRetention;
        })
        .toList(growable: false);
    final removed = items.length - next.length;
    if (removed > 0) await _saveRaw(next);
    return removed;
  }
}
