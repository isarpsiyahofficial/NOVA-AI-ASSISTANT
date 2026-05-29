// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaIdentityMemoryCommitService {
  const NovaIdentityMemoryCommitService();

  bool shouldPersist({
    required String speakerName,
    required String relationshipLabel,
    required double styleConsistency,
    required double ownerConfidence,
    String contentHint = '',
  }) {
    final hasIdentity =
        speakerName.trim().isNotEmpty || relationshipLabel.trim().isNotEmpty;
    if (!hasIdentity) return false;
    final low = contentHint.toLowerCase();
    final trivial =
        low.isEmpty ||
        low.length < 16 ||
        low.contains('günaydın') ||
        low.contains('iyi geceler') ||
        low.contains('tamam') ||
        low.contains('hmm');
    if (trivial && styleConsistency < 0.70 && ownerConfidence < 0.80)
      return false;
    return styleConsistency >= 0.62 || ownerConfidence >= 0.76;
  }
}
