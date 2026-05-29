// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_relationship_profile.dart';
import '../../services/memory/nova_semantic_memory_service.dart';
import 'relationship_profile_store.dart';

class RelationshipRetrievalService {
  final RelationshipProfileStore profileStore;
  final NovaSemanticMemoryService semanticMemoryService;

  const RelationshipRetrievalService({
    this.profileStore = const RelationshipProfileStore(),
    this.semanticMemoryService = const NovaSemanticMemoryService(),
  });

  Future<NovaRelationshipProfile> resolve({
    required String speakerName,
    required String relationshipLabel,
    required String latestPrompt,
  }) async {
    final speakerKey = _speakerKey(speakerName, relationshipLabel);
    var profile =
        await profileStore.getByKey(speakerKey) ??
        NovaRelationshipProfile.fallback(
          speakerKey: speakerKey,
          displayName: speakerName.trim(),
          relationshipLabel: relationshipLabel.trim(),
        );

    final semanticMatches = await semanticMemoryService.search(
      '${speakerName.trim()} ${relationshipLabel.trim()} $latestPrompt',
      limit: 2,
    );
    if (semanticMatches.isNotEmpty) {
      final anchors = <String>[...profile.sharedAnchors];
      for (final item in semanticMatches) {
        final compact = item.content.trim();
        if (compact.isEmpty) continue;
        if (anchors.any((e) => e.toLowerCase() == compact.toLowerCase()))
          continue;
        anchors.insert(
          0,
          compact.length > 96 ? '${compact.substring(0, 93)}...' : compact,
        );
        if (anchors.length > 8) anchors.removeLast();
      }
      profile = profile.copyWith(sharedAnchors: anchors);
    }
    return profile;
  }

  String buildPromptSection(NovaRelationshipProfile profile) =>
      profile.buildPromptSection();

  String speakerKeyFor(String speakerName, String relationshipLabel) =>
      _speakerKey(speakerName, relationshipLabel);

  String _speakerKey(String speakerName, String relationshipLabel) {
    final left = speakerName.trim().toLowerCase();
    final right = relationshipLabel.trim().toLowerCase();
    final raw = '${left}_$right'.replaceAll(
      RegExp(r'[^a-z0-9çğıöşü_]+', unicode: true),
      '_',
    );
    return raw
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '')
            .isEmpty
        ? 'unknown_person'
        : raw.replaceAll(RegExp(r'_+'), '_');
  }
}
