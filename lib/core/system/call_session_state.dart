// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../services/system/nova_lifecycle_service.dart';

class CallSessionState {
  final bool wokeNovaForThisCall;
  final NovaMode modeBeforeCall;
  final bool keepAwakeAfterCall;

  const CallSessionState({
    required this.wokeNovaForThisCall,
    required this.modeBeforeCall,
    this.keepAwakeAfterCall = false,
  });

  CallSessionState copyWith({
    bool? wokeNovaForThisCall,
    NovaMode? modeBeforeCall,
    bool? keepAwakeAfterCall,
  }) {
    return CallSessionState(
      wokeNovaForThisCall: wokeNovaForThisCall ?? this.wokeNovaForThisCall,
      modeBeforeCall: modeBeforeCall ?? this.modeBeforeCall,
      keepAwakeAfterCall: keepAwakeAfterCall ?? this.keepAwakeAfterCall,
    );
  }
}
