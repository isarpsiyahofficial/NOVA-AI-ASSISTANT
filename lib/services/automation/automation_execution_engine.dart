// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/automation/automation_runtime_state.dart';
import '../../core/automation/automation_workflow.dart';
import 'automation_cancel_service.dart';
import 'automation_recovery_service.dart';

class AutomationExecutionResult {
  final bool success;
  final bool cancelled;
  final String message;
  final AutomationRuntimeState state;

  const AutomationExecutionResult({
    required this.success,
    required this.cancelled,
    required this.message,
    required this.state,
  });
}

class AutomationExecutionEngine {
  final AutomationCancelService cancelService;
  final AutomationRecoveryService recoveryService;

  const AutomationExecutionEngine({
    required this.cancelService,
    required this.recoveryService,
  });

  Future<AutomationExecutionResult> runWorkflow({
    required AutomationWorkflow workflow,
    required bool canUseChatGpt,
    required bool userAlreadySaidNoToChatGpt,
  }) async {
    cancelService.clearCancel();

    AutomationRuntimeState state = AutomationRuntimeState(
      status: AutomationRuntimeStatus.running,
      workflowId: workflow.id,
      currentCommandIndex: 0,
      retryCount: 0,
      lastError: '',
      chatGptPermissionAsked: false,
      chatGptPermissionGranted: false,
    );

    for (int i = 0; i < workflow.commands.length; i++) {
      if (cancelService.isCancelRequested) {
        return AutomationExecutionResult(
          success: false,
          cancelled: true,
          message: 'Görev sizin isteğinizle durduruldu efendim.',
          state: state.copyWith(
            status: AutomationRuntimeStatus.cancelled,
            currentCommandIndex: i,
          ),
        );
      }

      final command = workflow.commands[i];

      try {
        // Native entegrasyon gelene kadar burada güvenli simülasyon çekirdeği var.
        // Bu sayede engine yapısı oturuyor ama çökme üretmiyor.
        final _ = command.description;

        state = state.copyWith(
          currentCommandIndex: i,
          retryCount: 0,
          lastError: '',
        );
      } catch (e) {
        state = state.copyWith(
          currentCommandIndex: i,
          retryCount: state.retryCount + 1,
          lastError: e.toString(),
        );

        final plan = recoveryService.buildPlan(
          errorText: e.toString(),
          canUseChatGpt: canUseChatGpt,
          userAlreadySaidNo: userAlreadySaidNoToChatGpt,
          retryCount: state.retryCount,
        );

        if (plan.shouldRetryLocally) {
          continue;
        }

        if (plan.shouldAskForChatGpt) {
          return AutomationExecutionResult(
            success: false,
            cancelled: false,
            message: plan.explanation,
            state: state.copyWith(
              status: AutomationRuntimeStatus.paused,
              chatGptPermissionAsked: true,
            ),
          );
        }

        return AutomationExecutionResult(
          success: false,
          cancelled: false,
          message: 'Görev güvenli şekilde durduruldu efendim.',
          state: state.copyWith(status: AutomationRuntimeStatus.failed),
        );
      }
    }

    return AutomationExecutionResult(
      success: true,
      cancelled: false,
      message: 'Görev tamamlandı efendim.',
      state: state.copyWith(status: AutomationRuntimeStatus.completed),
    );
  }
}
