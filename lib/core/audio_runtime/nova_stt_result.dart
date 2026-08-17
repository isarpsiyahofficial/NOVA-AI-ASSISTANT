class NovaSttResult {
  final bool success;
  final String recognizedText;
  final String detectedLocale;
  final String message;
  final bool voiceIdentityChecked;
  final bool ownerMatched;
  final String speakerVoiceId;
  final String speakerName;
  final double ownerConfidence;
  final String relationshipLabel;
  final String identityAudioPath;
  final String nativeActionToken;

  const NovaSttResult({
    required this.success,
    required this.recognizedText,
    required this.detectedLocale,
    required this.message,
    this.voiceIdentityChecked = false,
    this.ownerMatched = false,
    this.speakerVoiceId = '',
    this.speakerName = '',
    this.ownerConfidence = 0.0,
    this.relationshipLabel = 'unknown',
    this.identityAudioPath = '',
    this.nativeActionToken = '',
  });

  const NovaSttResult.empty()
      : success = false,
        recognizedText = '',
        detectedLocale = 'tr-TR',
        message = 'Herhangi bir metin algılanamadı.',
        voiceIdentityChecked = false,
        ownerMatched = false,
        speakerVoiceId = '',
        speakerName = '',
        ownerConfidence = 0.0,
        relationshipLabel = 'unknown',
        identityAudioPath = '',
        nativeActionToken = '';
}
