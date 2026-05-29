// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/reminder/nova_reminder.dart';
import 'nova_reminder_service.dart';

class NovaReminderCommandResult {
  final bool success;
  final String message;

  const NovaReminderCommandResult({
    required this.success,
    required this.message,
  });
}

class NovaReminderCommandService {
  const NovaReminderCommandService();

  /// Compatibility form: createFromText('2 saat sonra beni uyandır', reminderService: ...)
  /// Keeps older callers working by accepting the reminder text as the first
  /// positional argument while still allowing named dependencies.
  Future<NovaReminderCommandResult> createFromText(
    String text, {
    NovaReminderService? reminderService,
    DateTime? now,
  }) async {
    final service = reminderService;
    final raw = text.trim();
    if (raw.isEmpty) {
      return const NovaReminderCommandResult(
        success: false,
        message: 'Hatırlatıcı metni boş olamaz.',
      );
    }
    if (service == null) {
      return const NovaReminderCommandResult(
        success: false,
        message: 'Hatırlatıcı servisi bulunamadı.',
      );
    }

    final normalized = raw.toLowerCase();
    final baseNow = now ?? DateTime.now();
    final isWakeAlarm =
        normalized.contains('uyandır') || normalized.contains('alarm');
    final dueAt =
        _resolveDueAt(normalized, baseNow) ??
        baseNow.add(const Duration(minutes: 10));
    final cleanedText = _extractContent(raw);

    await service.add(
      text: cleanedText,
      dueAt: dueAt,
      kind: isWakeAlarm
          ? NovaReminderKind.wakeAlarm
          : NovaReminderKind.reminder,
      repeatUntilAcknowledged: isWakeAlarm,
      maxActiveMinutes: isWakeAlarm ? 10 : 10,
    );

    return NovaReminderCommandResult(
      success: true,
      message: isWakeAlarm
          ? 'Efendim alarm kuruldu: ${_formatDueAt(dueAt)}'
          : 'Efendim hatırlatıcı kuruldu: ${_formatDueAt(dueAt)}',
    );
  }

  DateTime? _resolveDueAt(String raw, DateTime now) {
    final hoursMatch = RegExp(r'(\d+)\s*saat').firstMatch(raw);
    if (hoursMatch != null) {
      final value = int.tryParse(hoursMatch.group(1) ?? '');
      if (value != null && value > 0) {
        return now.add(Duration(hours: value));
      }
    }

    final minutesMatch = RegExp(r'(\d+)\s*dakika').firstMatch(raw);
    if (minutesMatch != null) {
      final value = int.tryParse(minutesMatch.group(1) ?? '');
      if (value != null && value > 0) {
        return now.add(Duration(minutes: value));
      }
    }

    if (raw.contains('yarın')) {
      return DateTime(now.year, now.month, now.day + 1, 9);
    }

    final clock = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(raw);
    if (clock != null) {
      final hour = int.tryParse(clock.group(1) ?? '');
      final minute = int.tryParse(clock.group(2) ?? '');
      if (hour != null && minute != null) {
        var due = DateTime(now.year, now.month, now.day, hour, minute);
        if (!due.isAfter(now)) {
          due = due.add(const Duration(days: 1));
        }
        return due;
      }
    }

    return null;
  }

  String _extractContent(String raw) {
    var text = raw.trim();
    final lower = text.toLowerCase();
    const prefixes = <String>[
      'nova',
      'hatırlat',
      'bana',
      'beni',
      'alarm',
      'uyandır',
    ];
    for (final prefix in prefixes) {
      if (lower.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
      }
    }
    return text.isEmpty ? raw.trim() : text;
  }

  String _formatDueAt(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year} ${two(value.hour)}:${two(value.minute)}';
  }
}
