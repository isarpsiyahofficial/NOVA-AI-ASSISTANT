// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/phone_control/phone_control_task.dart';
import 'phone_control_guard_service.dart';
import 'phone_control_service.dart';
import 'phone_control_task_service.dart';

class PhoneControlExecutionResult {
  final bool success;
  final String message;

  const PhoneControlExecutionResult({
    required this.success,
    required this.message,
  });
}

class PhoneControlExecutionService {
  final PhoneControlService phoneControlService;
  final PhoneControlTaskService taskService;

  const PhoneControlExecutionService({
    required this.phoneControlService,
    required this.taskService,
  });

  Future<PhoneControlExecutionResult> executeTask({
    required PhoneControlTask task,
  }) async {
    if (!phoneControlService.isEnabled) {
      return const PhoneControlExecutionResult(
        success: false,
        message: 'Telefon yönetimi kapalı olduğu için görev çalıştırılamadı.',
      );
    }

    await taskService.updateStatus(task.id, PhoneControlTaskStatus.running);
    await taskService.updateStatus(task.id, PhoneControlTaskStatus.completed);
    return PhoneControlExecutionResult(
      success: true,
      message: 'Görev güvenli modda işlendi: ${task.title}',
    );
  }
}
