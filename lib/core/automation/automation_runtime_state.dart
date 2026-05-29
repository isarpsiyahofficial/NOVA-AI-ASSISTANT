// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum AutomationRuntimeStatus {
  idle,
  running,
  paused,
  cancelled,
  completed,
  failed,
}

class AutomationRuntimeState {
  final AutomationRuntimeStatus status;
  final String workflowId;
  final int currentCommandIndex;
  final int retryCount;
  final String lastError;
  final bool chatGptPermissionAsked;
  final bool chatGptPermissionGranted;

  const AutomationRuntimeState({
    required this.status,
    required this.workflowId,
    required this.currentCommandIndex,
    required this.retryCount,
    required this.lastError,
    required this.chatGptPermissionAsked,
    required this.chatGptPermissionGranted,
  });

  const AutomationRuntimeState.idle()
    : status = AutomationRuntimeStatus.idle,
      workflowId = '',
      currentCommandIndex = 0,
      retryCount = 0,
      lastError = '',
      chatGptPermissionAsked = false,
      chatGptPermissionGranted = false;

  AutomationRuntimeState copyWith({
    AutomationRuntimeStatus? status,
    String? workflowId,
    int? currentCommandIndex,
    int? retryCount,
    String? lastError,
    bool? chatGptPermissionAsked,
    bool? chatGptPermissionGranted,
  }) {
    return AutomationRuntimeState(
      status: status ?? this.status,
      workflowId: workflowId ?? this.workflowId,
      currentCommandIndex: currentCommandIndex ?? this.currentCommandIndex,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      chatGptPermissionAsked:
          chatGptPermissionAsked ?? this.chatGptPermissionAsked,
      chatGptPermissionGranted:
          chatGptPermissionGranted ?? this.chatGptPermissionGranted,
    );
  }
}
