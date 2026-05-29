// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaTrustCalibrationService {
  const NovaTrustCalibrationService();

  Map<String, dynamic> calibrate({
    required double ownerConfidence,
    required String relationshipStage,
  }) {
    final trustMode = ownerConfidence >= 0.90
        ? 'yüksek güven / doğal sıcaklık mümkün'
        : ownerConfidence >= 0.65
        ? 'ölçülü güven / dikkatli samimiyet'
        : 'düşük güven / nötr ve sınır odaklı';
    return <String, dynamic>{
      'trustMode': trustMode,
      'allowWarmth': ownerConfidence >= 0.80,
      'allowLightHumor': ownerConfidence >= 0.86,
      'needBoundaryReminder': ownerConfidence < 0.60,
      'relationshipStage': relationshipStage,
    };
  }

  String buildPromptSection({
    required double ownerConfidence,
    required String relationshipStage,
  }) {
    final calibrated = calibrate(
      ownerConfidence: ownerConfidence,
      relationshipStage: relationshipStage,
    );
    return [
      'TRUST CALIBRATION:',
      '- güven modu: ${calibrated['trustMode']}',
      '- sıcaklık alanı: ${calibrated['allowWarmth']}',
      '- hafif mizah: ${calibrated['allowLightHumor']}',
      '- sınır hatırlatması: ${calibrated['needBoundaryReminder']}',
      '- ilişki evresi: ${calibrated['relationshipStage']}',
      'KURAL: Güven belirsizse daha nötr kal; yine de kırıcı, alıngan veya cezalandırıcı davranma.',
    ].join('\n');
  }
}
