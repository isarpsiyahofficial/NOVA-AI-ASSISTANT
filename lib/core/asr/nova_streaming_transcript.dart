// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaStreamingTranscript {
  final String text;
  final bool isFinal;
  final double confidence;
  final int segmentId;
  final int startMs;
  final int endMs;
  final String locale;

  const NovaStreamingTranscript({
    required this.text,
    required this.isFinal,
    required this.confidence,
    required this.segmentId,
    required this.startMs,
    required this.endMs,
    this.locale = 'tr-TR',
  });

  bool get hasText => text.trim().isNotEmpty;
  String get detectedLocale => locale;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'text': text,
    'isFinal': isFinal,
    'confidence': confidence,
    'segmentId': segmentId,
    'startMs': startMs,
    'endMs': endMs,
    'locale': locale,
  };

  factory NovaStreamingTranscript.fromMap(Map<String, dynamic> map) {
    return NovaStreamingTranscript(
      text: (map['text'] as String? ?? '').trim(),
      isFinal: map['isFinal'] as bool? ?? false,
      confidence: (map['confidence'] as num? ?? 0.0).toDouble(),
      segmentId: map['segmentId'] as int? ?? 0,
      startMs: map['startMs'] as int? ?? 0,
      endMs: map['endMs'] as int? ?? 0,
      locale: (map['locale'] as String? ?? 'tr-TR').trim(),
    );
  }
}
