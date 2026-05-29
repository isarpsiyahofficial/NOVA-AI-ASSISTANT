// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/adaptive/adaptive_behavior_request.dart';
import '../../core/behavior_control/behavior_keys.dart';
import 'adaptive_behavior_hub_service.dart';

class AdaptiveSocialBehaviorService {
  final AdaptiveBehaviorHubService hubService;

  const AdaptiveSocialBehaviorService({required this.hubService});

  Future<String> resolveSpeechTone({required String fallback}) async {
    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: BehaviorKeys.speechTone,
        defaultValue: fallback,
      ),
    );

    return result.value;
  }

  Future<String> resolveOwnerAddressing({required String fallback}) async {
    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: BehaviorKeys.ownerAddressingStyle,
        defaultValue: fallback,
      ),
    );

    return result.value;
  }

  Future<String> resolveUrgentWakeStyle({required String fallback}) async {
    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: BehaviorKeys.urgentWakeStyle,
        defaultValue: fallback,
      ),
    );

    return result.value;
  }

  Future<String> resolveSocialChatStyle({required String fallback}) async {
    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: BehaviorKeys.socialChatStyle,
        defaultValue: fallback,
      ),
    );

    return result.value;
  }

  Future<String> resolveComfortTalkStyle({required String fallback}) async {
    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: BehaviorKeys.comfortTalkStyle,
        defaultValue: fallback,
      ),
    );

    return result.value;
  }

  Future<String> resolveAdviceStyle({required String fallback}) async {
    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: BehaviorKeys.adviceStyle,
        defaultValue: fallback,
      ),
    );

    return result.value;
  }

  Future<String> resolveLearningConfirmationStyle({
    required String fallback,
  }) async {
    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: BehaviorKeys.learningConfirmationStyle,
        defaultValue: fallback,
      ),
    );

    return result.value;
  }

  Future<String> resolveWakeAlarmLoopStyle({required String fallback}) async {
    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: BehaviorKeys.wakeAlarmLoopStyle,
        defaultValue: fallback,
      ),
    );

    return result.value;
  }

  Future<String> resolveWakeAlarmStopConfirmStyle({
    required String fallback,
  }) async {
    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: BehaviorKeys.wakeAlarmStopConfirmStyle,
        defaultValue: fallback,
      ),
    );

    return result.value;
  }

  Future<String> resolveUnknownTaskAskChatGptPermissionStyle({
    required String fallback,
  }) async {
    final result = await hubService.resolve(
      AdaptiveBehaviorRequest(
        behaviorKey: BehaviorKeys.unknownTaskAskChatGptPermissionStyle,
        defaultValue: fallback,
      ),
    );

    return result.value;
  }
}
