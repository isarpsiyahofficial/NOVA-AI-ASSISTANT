// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

import '../../core/runtime/nova_behavior_decision.dart';

class NovaHumanImperfectionService {
  const NovaHumanImperfectionService();

  String apply(String text, {required NovaBehaviorDecision decision}) {
    // NOVA_HUMAN_IMPERFECTION_METADATA_ONLY_V2:
    // Humanizer layers may not add lexical hesitations/backchannels after
    // the model has produced the final response.
    return text.trim();
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (text.contains(part)) return true;
    }
    return false;
  }
}
