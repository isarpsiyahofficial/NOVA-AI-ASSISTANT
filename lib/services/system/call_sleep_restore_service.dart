// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/system/call_session_state.dart';
import 'nova_lifecycle_service.dart';

class CallSleepRestoreService {
  final NovaLifecycleService lifecycleService;

  const CallSleepRestoreService({required this.lifecycleService});

  CallSessionState beginCallSession({required bool wokeNovaForThisCall}) {
    return CallSessionState(
      wokeNovaForThisCall: wokeNovaForThisCall,
      modeBeforeCall: lifecycleService.mode,
      keepAwakeAfterCall: false,
    );
  }

  CallSessionState markKeepAwakeAfterCall(CallSessionState state) {
    return state.copyWith(keepAwakeAfterCall: true);
  }

  void finishCallSession(CallSessionState state) {
    if (state.keepAwakeAfterCall) {
      lifecycleService.wake();
      return;
    }

    if (state.wokeNovaForThisCall && state.modeBeforeCall == NovaMode.passive) {
      lifecycleService.sleep();
      return;
    }

    if (state.modeBeforeCall == NovaMode.active) {
      lifecycleService.wake();
      return;
    }

    lifecycleService.sleep();
  }
}
