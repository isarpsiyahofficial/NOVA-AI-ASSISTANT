// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/behavior_control/behavior_keys.dart';
import 'behavior_override_service.dart';

class BehaviorResolverService {
  final BehaviorOverrideService overrideService;

  const BehaviorResolverService({required this.overrideService});

  Future<String> resolveOrDefault({
    required String key,
    required String defaultInstruction,
  }) async {
    return overrideService.resolveOrDefault(
      key: key,
      defaultInstruction: defaultInstruction,
    );
  }

  Future<String> resolveCallOpeningGeneral({required String fallback}) async {
    return resolveOrDefault(
      key: BehaviorKeys.callOpeningGeneral,
      defaultInstruction: fallback,
    );
  }

  Future<String> resolveCallOpeningForStatus({
    required String statusLabel,
    required String fallback,
  }) async {
    switch (statusLabel.trim().toLowerCase()) {
      case 'sleeping':
        return resolveOrDefault(
          key: BehaviorKeys.callOpeningSleep,
          defaultInstruction: fallback,
        );
      case 'driving':
        return resolveOrDefault(
          key: BehaviorKeys.callOpeningDriving,
          defaultInstruction: fallback,
        );
      case 'busy':
        return resolveOrDefault(
          key: BehaviorKeys.callOpeningBusy,
          defaultInstruction: fallback,
        );
      case 'showering':
        return resolveOrDefault(
          key: BehaviorKeys.callOpeningShowering,
          defaultInstruction: fallback,
        );
      default:
        return resolveOrDefault(
          key: BehaviorKeys.callOpeningGeneral,
          defaultInstruction: fallback,
        );
    }
  }

  Future<String> resolveNoteAskingStyle({required String fallback}) async {
    return resolveOrDefault(
      key: BehaviorKeys.noteAskingStyle,
      defaultInstruction: fallback,
    );
  }

  Future<String> resolveUrgentWakeStyle({required String fallback}) async {
    return resolveOrDefault(
      key: BehaviorKeys.urgentWakeStyle,
      defaultInstruction: fallback,
    );
  }

  Future<String> resolveOwnerAddressingStyle({required String fallback}) async {
    return resolveOrDefault(
      key: BehaviorKeys.ownerAddressingStyle,
      defaultInstruction: fallback,
    );
  }

  Future<String> resolveCallTakeOverStyle({required String fallback}) async {
    return resolveOrDefault(
      key: BehaviorKeys.callTakeOverStyle,
      defaultInstruction: fallback,
    );
  }

  Future<String> resolveCallHandBackStyle({required String fallback}) async {
    return resolveOrDefault(
      key: BehaviorKeys.callHandBackStyle,
      defaultInstruction: fallback,
    );
  }

  Future<String> resolveSpeechTone({required String fallback}) async {
    return resolveOrDefault(
      key: BehaviorKeys.speechTone,
      defaultInstruction: fallback,
    );
  }
}
