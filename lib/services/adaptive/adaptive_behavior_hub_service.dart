// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/adaptive/adaptive_behavior_request.dart';
import '../../core/adaptive/adaptive_behavior_result.dart';
import '../behavior_control/behavior_override_service.dart';
import '../call_learning/learned_call_response_service.dart';

class AdaptiveBehaviorHubService {
  final BehaviorOverrideService behaviorOverrideService;
  final LearnedCallResponseService learnedCallResponseService;

  const AdaptiveBehaviorHubService({
    required this.behaviorOverrideService,
    required this.learnedCallResponseService,
  });

  Future<AdaptiveBehaviorResult> resolve(
    AdaptiveBehaviorRequest request,
  ) async {
    try {
      final String key = request.behaviorKey.trim();
      final String safeDefault = request.defaultValue.trim();

      // NOVA_ADAPTIVE_METADATA_ONLY_V1:
      // User overrides and learned call responses must not become final spoken text.
      // They can be interpreted later by the single AI turn controller as context,
      // but this hub returns only the caller-provided fallback style/value.
      if (key.isNotEmpty) {
        await behaviorOverrideService.resolveInstruction(key);
      }
      await learnedCallResponseService.resolve(
        callerName: request.callerName,
        statusLabel: request.statusLabel,
        rawTrigger: request.rawTrigger,
      );

      return AdaptiveBehaviorResult(
        value: safeDefault,
        source: 'default_metadata_only',
      );
    } catch (_) {
      return AdaptiveBehaviorResult(
        value: request.defaultValue.trim(),
        source: 'default_metadata_only',
      );
    }
  }
}
