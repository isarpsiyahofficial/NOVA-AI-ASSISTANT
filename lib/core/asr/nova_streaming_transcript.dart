class NovaStreamingTranscript {
  final String text;
  final bool isFinal;
  final double confidence;
  final int segmentId;
  final int startMs;
  final int endMs;
  final String locale;
  final String identityAudioPath;

  const NovaStreamingTranscript({
    required this.text,
    required this.isFinal,
    required this.confidence,
    required this.segmentId,
    required this.startMs,
    required this.endMs,
    this.locale = 'tr-TR',
    this.identityAudioPath = '',
  });

  bool get hasText => text.trim().isNotEmpty;
  String get detectedLocale => locale;
  bool get hasIdentityAudioEvidence => identityAudioPath.trim().isNotEmpty;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'text': text,
        'isFinal': isFinal,
        'confidence': confidence,
        'segmentId': segmentId,
        'startMs': startMs,
        'endMs': endMs,
        'locale': locale,
        'identityAudioPath': identityAudioPath,
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
      identityAudioPath:
          (map['identityAudioPath'] as String? ?? '').trim(),
    );
  }
}
