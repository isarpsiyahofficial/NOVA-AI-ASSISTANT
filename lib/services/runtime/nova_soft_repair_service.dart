// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_RUNTIME_LEXICAL_MUTATION_DISABLED_V3
class NovaSoftRepairService {
  const NovaSoftRepairService();

  String apply({
    required String text,
    required bool shouldPreferSoftRepair,
    required bool shouldClarify,
  }) {
    // Soft-repair may inform the next model prompt as metadata, but it must not
    // author repair phrases after the model has produced final text.
    return text.trim();
  }
}
