// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:async';

import '../../core/runtime/nova_runtime_signal.dart';
import '../behavior_control/behavior_override_service.dart';
import '../runtime/nova_runtime_signal_service.dart';
import 'nova_reminder_service.dart';

class NovaReminderRuntimeService {
  final NovaReminderService reminderService;
  final BehaviorOverrideService behaviorOverrideService;

  Timer? _timer;
  DateTime? _lastHealthyRunAt;

  NovaReminderRuntimeService({
    required this.reminderService,
    required this.behaviorOverrideService,
  });

  void start() {
    _timer?.cancel();
    unawaited(runDueReminderCheck());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await runDueReminderCheck();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> runDueReminderCheck() async {
    try {
      final dueAnnouncements = await reminderService.collectDueAnnouncements();
      for (final announcement in dueAnnouncements) {
        // Operational reminder text is intentionally not spoken here.
        // User-facing reminder speech must be produced by NovaCoreTurnController
        // from a structured reminder event in a future event bridge.
        await NovaRuntimeSignalService.instance.record(
          kind: NovaRuntimeSignalKind.reminder,
          level: NovaRuntimeSignalLevel.info,
          code: 'reminder_due_event_detected_speech_suppressed',
          message: 'Hatırlatıcı zamanı geldi; doğrudan TTS konuşması yapılmadı.',
          technicalDetails:
              'item=${announcement.item.id}; kind=${announcement.item.kind.name}; speechChars=${announcement.speechText.trim().length}',
          diagnosticCandidate: false,
          metadata: const <String, dynamic>{
            'source': 'nova_reminder_runtime_service',
            'speechSuppressed': true,
            'requiresCoreTurnEventBridge': true,
          },
        );
      }
      await reminderService.cleanupCompleted();
      _lastHealthyRunAt = DateTime.now();
    } catch (error) {
      await NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.reminder,
        level: NovaRuntimeSignalLevel.error,
        code: 'reminder_due_check_failed',
        message: 'Hatırlatıcı çalışma zinciri hata verdi.',
        technicalDetails: error.toString(),
        diagnosticCandidate: true,
      );
    }
  }

  DateTime? get lastHealthyRunAt => _lastHealthyRunAt;
}
