// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaEmphasisSchedule {
  final List<String> words;
  final bool sparseMode;
  const NovaEmphasisSchedule({required this.words, required this.sparseMode});
  String buildPromptSection() =>
      'VURGU ZAMANLAYICI: sparse=$sparseMode; kelimeler=${words.join(" | ")}';
}

class NovaEmphasisSchedulerService {
  const NovaEmphasisSchedulerService();

  NovaEmphasisSchedule schedule(
    List<String> emphasisWords, {
    required bool shortFormPreferred,
  }) {
    final unique = <String>[];
    for (final word in emphasisWords) {
      final trimmed = word.trim();
      if (trimmed.isEmpty) continue;
      if (!unique.contains(trimmed)) unique.add(trimmed);
    }
    return NovaEmphasisSchedule(
      words: unique.take(shortFormPreferred ? 3 : 5).toList(growable: false),
      sparseMode: true,
    );
  }
}
