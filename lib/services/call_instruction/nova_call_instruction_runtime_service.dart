// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:async';

import '../../core/call_instruction/nova_call_instruction.dart';
import '../phone_control/phone_control_native_bridge_service.dart';
import '../phone_control/phone_control_service.dart';
import '../runtime/nova_runtime_signal_service.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import 'nova_call_instruction_service.dart';

class NovaCallInstructionRuntimeService {
  final NovaCallInstructionService instructionService;
  final PhoneControlService phoneControlService;
  final NovaPhoneControlNativeBridgeService phoneBridgeService;

  Timer? _timer;
  bool _busy = false;

  NovaCallInstructionRuntimeService({
    required this.instructionService,
    required this.phoneControlService,
    required this.phoneBridgeService,
  });

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await runPendingCheck();
    });
    unawaited(runPendingCheck());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> runPendingCheck() async {
    if (_busy) return;
    _busy = true;
    try {
      await instructionService.cleanupCompletedOlderThan48Hours();
      final dueItems = await instructionService.collectDueInstructions();
      for (final item in dueItems) {
        await _execute(item);
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _execute(NovaCallInstruction item) async {
    if (!phoneControlService.isEnabled) {
      await instructionService.updateStatus(
        item.id,
        NovaCallInstructionStatus.failed,
        lastExecutedAt: DateTime.now(),
      );
      await NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.call,
        level: NovaRuntimeSignalLevel.error,
        code: 'call_instruction_execution_failed',
        message:
            'Telefon yönetimi kapalı olduğu için talimatlı çağrı çalıştırılamadı.',
        technicalDetails: item.id,
        diagnosticCandidate: true,
      );
      await _recordSuppressedOperationalSpeech(
        item: item,
        reason: 'phone_control_disabled',
      );
      return;
    }

    await instructionService.updateStatus(
      item.id,
      NovaCallInstructionStatus.failed,
      lastExecutedAt: DateTime.now(),
    );
    await NovaRuntimeSignalService.instance.record(
      kind: NovaRuntimeSignalKind.call,
      level: NovaRuntimeSignalLevel.warning,
      code: 'call_instruction_owner_confirmation_required',
      message:
          'Talimatlı çağrı otomatik başlatılmadı; owner onayı olmadan dış arama yapılmayacağı için görev güvenli şekilde durduruldu.',
      technicalDetails: item.id,
      diagnosticCandidate: false,
    );
    await _recordSuppressedOperationalSpeech(
      item: item,
      reason: 'owner_confirmation_required',
    );
  }

  Future<void> _recordSuppressedOperationalSpeech({
    required NovaCallInstruction item,
    required String reason,
  }) async {
    // Operational call-instruction events must remain structured runtime data.
    // They must not carry prewritten spoken text or be rewritten into speech here.
    await NovaRuntimeSignalService.instance.record(
      kind: NovaRuntimeSignalKind.call,
      level: NovaRuntimeSignalLevel.info,
      code: 'call_instruction_operational_speech_suppressed',
      message: 'Talimatlı çağrı operasyon olayı sesli konuşmaya çevrilmedi.',
      technicalDetails: 'item=${item.id}; reason=$reason',
      diagnosticCandidate: false,
      metadata: const <String, dynamic>{
        'source': 'nova_call_instruction_runtime_service',
        'speechSuppressed': true,
        'requiresCoreTurnEventBridge': true,
      },
    );
  }
}
