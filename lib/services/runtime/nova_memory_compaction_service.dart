// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaMemoryCompactionService {
  const NovaMemoryCompactionService();

  List<String> compactStrings(
    List<String> values, {
    int limit = 8,
    int maxItemLength = 96,
  }) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in values) {
      final normalized = _normalize(raw, maxItemLength: maxItemLength);
      if (normalized.isEmpty) continue;
      final key = normalized.toLowerCase();
      if (!seen.add(key)) continue;
      out.add(normalized);
      if (out.length >= limit) break;
    }
    return out;
  }

  String compactSummary(String value, {int maxLength = 220}) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= maxLength) return cleaned;
    return cleaned.substring(0, maxLength).trimRight() + '…';
  }

  String compactPreference(String value) =>
      compactSummary(value, maxLength: 90);

  String _normalize(String value, {required int maxItemLength}) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return '';
    if (cleaned.length <= maxItemLength) return cleaned;
    return cleaned.substring(0, maxItemLength).trimRight() + '…';
  }
}
