// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaLearnedItemType {
  behaviorOverride,
  learnedCallResponse,
  permanentMemory,
}

class NovaLearnedItem {
  final String id;
  final NovaLearnedItemType type;
  final String title;
  final String subtitle;
  final String description;
  final String source;
  final DateTime updatedAt;
  final bool canDelete;
  final String deleteKey;

  const NovaLearnedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.source,
    required this.updatedAt,
    required this.canDelete,
    required this.deleteKey,
  });
}
