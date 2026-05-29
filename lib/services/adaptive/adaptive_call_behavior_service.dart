// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/adaptive/adaptive_behavior_request.dart';
import '../../core/behavior_control/behavior_keys.dart';
import '../../core/contacts/nova_contact.dart';
import 'adaptive_behavior_hub_service.dart';

class AdaptiveCallBehaviorService {
  final AdaptiveBehaviorHubService hubService;

  const AdaptiveCallBehaviorService({required this.hubService});

  Future<String> resolveCallOpening({
    required NovaContact? contact,
    required String? activeStatusLabel,
    required String fallback,
  }) async {
    final String normalizedStatus = (activeStatusLabel ?? '')
        .trim()
        .toLowerCase();

    String behaviorKey;
    switch (normalizedStatus) {
      case 'sleeping':
        behaviorKey = BehaviorKeys.callOpeningSleep;
        break;
      case 'driving':
        behaviorKey = BehaviorKeys.callOpeningDriving;
        break;
      case 'busy':
        behaviorKey = BehaviorKeys.callOpeningBusy;
        break;
      case 'showering':
        behaviorKey = BehaviorKeys.callOpeningShowering;
        break;
      default:
        behaviorKey = BehaviorKeys.callOpeningGeneral;
        break;
    }

    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: behaviorKey,
        defaultValue: fallback,
        callerName: contact?.displayName,
        statusLabel: activeStatusLabel,
      ),
    );

    return result.value;
  }

  Future<String> resolveNoteAsking({
    required String fallback,
    String? callerName,
    String? activeStatusLabel,
  }) async {
    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: BehaviorKeys.noteAskingStyle,
        defaultValue: fallback,
        callerName: callerName,
        statusLabel: activeStatusLabel,
      ),
    );

    return result.value;
  }

  Future<String> resolveCallTakeOver({required String fallback}) async {
    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: BehaviorKeys.callTakeOverStyle,
        defaultValue: fallback,
      ),
    );

    return result.value;
  }

  Future<String> resolveCallHandBack({required String fallback}) async {
    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: BehaviorKeys.callHandBackStyle,
        defaultValue: fallback,
      ),
    );

    return result.value;
  }
}
