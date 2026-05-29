// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaTurkishIndirectRequestDecision {
  final bool detected;
  final double confidence;
  final List<String> cues;
  const NovaTurkishIndirectRequestDecision({
    required this.detected,
    required this.confidence,
    required this.cues,
  });
  String buildPromptSection() =>
      'TÜRKÇE DOLAYLI RİCA: algılandı=$detected; güven=${confidence.toStringAsFixed(2)}; ipuçları=${cues.join(" | ")}';
}

class NovaTurkishIndirectRequestDetectorService {
  const NovaTurkishIndirectRequestDetectorService();

  NovaTurkishIndirectRequestDecision detect(String raw) {
    final t = raw.toLowerCase();
    final cues = <String>[];
    for (final cue in const [
      'mümkünse',
      'bakabilir misin',
      'yardımcı olur musun',
      'bir el atar mısın',
      'rica etsem',
      'şuna da baksana',
      'müsaitsen',
      'vaktin varsa',
      'halledersen iyi olur',
    ]) {
      if (t.contains(cue)) cues.add(cue);
    }
    final detected = cues.isNotEmpty;
    return NovaTurkishIndirectRequestDecision(
      detected: detected,
      confidence: detected
          ? (0.66 + (cues.length * 0.07)).clamp(0.0, 0.93)
          : 0.18,
      cues: cues,
    );
  }
}
