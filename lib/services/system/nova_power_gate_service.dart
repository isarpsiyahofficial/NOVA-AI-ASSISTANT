// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/system/nova_power_mode.dart';
import 'nova_power_service.dart';

class NovaPowerGateService {
  final NovaPowerService powerService;

  const NovaPowerGateService({required this.powerService});

  bool shouldAllowVoiceProcessing() {
    return powerService.mode == NovaPowerMode.fullyOn ||
        powerService.mode == NovaPowerMode.batterySaver;
  }

  bool shouldAllowWakeWord() {
    return powerService.mode.allowsWakeWord;
  }

  bool shouldAllowPriorityCallHandling() {
    return powerService.mode.allowsPriorityCalls;
  }

  bool shouldAllowNormalInteraction() {
    return powerService.mode == NovaPowerMode.fullyOn ||
        powerService.mode == NovaPowerMode.batterySaver;
  }

  bool isFullyShutdown() {
    return powerService.isFullyShutdown;
  }
}
