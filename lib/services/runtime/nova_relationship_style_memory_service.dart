// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaRelationshipStyleMemoryService {
  const NovaRelationshipStyleMemoryService();

  String buildPromptSection({
    required String speakerName,
    required String relationshipLabel,
    required Map<String, dynamic> understanding,
    required Map<String, dynamic> emotion,
  }) {
    final normalizedRelationship = relationshipLabel.trim().toLowerCase();
    final explicitQuestion =
        understanding['explicitQuestion'] as bool? ?? false;
    final primaryIntent = understanding['primaryIntent'] as String? ?? 'sohbet';
    final emotionalNeed = (emotion['empathyNeed'] as num?)?.toDouble() ?? 0.0;

    final warmth = _resolveWarmth(normalizedRelationship, emotionalNeed);
    final formality = _resolveFormality(normalizedRelationship);
    final humor = _resolveHumor(normalizedRelationship, primaryIntent);
    final questionTolerance = explicitQuestion
        ? 'yüksek'
        : _resolveQuestionTolerance(normalizedRelationship, emotionalNeed);
    final length = _resolveLengthPreference(
      normalizedRelationship,
      primaryIntent,
      emotionalNeed,
    );
    final address = _resolveAddress(normalizedRelationship, speakerName);

    return [
      'İLİŞKİ TARZI BELLEĞİ:',
      '- konuşan: ${speakerName.trim().isEmpty ? 'bilinmiyor' : speakerName.trim()}',
      '- ilişki etiketi: ${relationshipLabel.trim().isEmpty ? 'varsayılan' : relationshipLabel.trim()}',
      '- hitap önerisi: $address',
      '- sıcaklık: $warmth',
      '- resmiyet: $formality',
      '- mizah toleransı: $humor',
      '- soru toleransı: $questionTolerance',
      '- açıklama uzunluğu: $length',
      'KURAL: Hafıza burada sadece etiket değil; hitap, cümle boyu, mizah, soru sıklığı ve destek tonunu gerçekten değiştirmeli.',
      'KURAL: Aynı kişiye her turda bambaşka bir tonla dönme; doğal varyasyon olsun ama karakter kayması olmasın.',
      'KURAL: Aile/çok yakın ilişkide sıcaklık artabilir; iş/resmî ilişkide düzen ve saygı korunur; belirsiz ilişkide ölçülü sıcaklık kullanılır.',
    ].join('\n');
  }

  String _resolveWarmth(String relationship, double emotionalNeed) {
    if (_containsAny(relationship, const [
      'anne',
      'baba',
      'eş',
      'abi',
      'abla',
      'kardeş',
      'aile',
      'dost',
      'arkadaş',
      'kanka',
    ])) {
      return emotionalNeed > 0.45 ? 'yüksek ve yumuşak' : 'yüksek ama ölçülü';
    }
    if (_containsAny(relationship, const [
      'iş',
      'müdür',
      'hoca',
      'resmî',
      'resmi',
    ])) {
      return emotionalNeed > 0.45 ? 'orta ve kontrollü destekleyici' : 'orta';
    }
    return emotionalNeed > 0.45 ? 'orta-yüksek, destekleyici' : 'orta';
  }

  String _resolveFormality(String relationship) {
    if (_containsAny(relationship, const [
      'iş',
      'müdür',
      'hoca',
      'resmî',
      'resmi',
    ]))
      return 'yüksek';
    if (_containsAny(relationship, const [
      'anne',
      'baba',
      'eş',
      'abi',
      'abla',
      'kardeş',
      'aile',
      'arkadaş',
      'dost',
      'kanka',
    ]))
      return 'düşük-orta';
    return 'orta';
  }

  String _resolveHumor(String relationship, String primaryIntent) {
    if (primaryIntent == 'duygusal') return 'düşük';
    if (_containsAny(relationship, const ['arkadaş', 'dost', 'kanka']))
      return 'orta-yüksek';
    if (_containsAny(relationship, const [
      'iş',
      'müdür',
      'hoca',
      'resmî',
      'resmi',
    ]))
      return 'düşük';
    return 'orta';
  }

  String _resolveQuestionTolerance(String relationship, double emotionalNeed) {
    if (emotionalNeed > 0.55) return 'düşük-orta; kısa ve nazik soru';
    if (_containsAny(relationship, const [
      'iş',
      'müdür',
      'hoca',
      'resmî',
      'resmi',
    ]))
      return 'orta';
    if (_containsAny(relationship, const ['arkadaş', 'dost', 'kanka', 'aile']))
      return 'orta-yüksek';
    return 'orta';
  }

  String _resolveLengthPreference(
    String relationship,
    String primaryIntent,
    double emotionalNeed,
  ) {
    if (primaryIntent == 'eylem') return 'kısa';
    if (emotionalNeed > 0.45) return 'kısa-orta, nefesli';
    if (_containsAny(relationship, const [
      'iş',
      'müdür',
      'hoca',
      'resmî',
      'resmi',
    ]))
      return 'kısa-orta';
    return 'orta';
  }

  String _resolveAddress(String relationship, String speakerName) {
    if (speakerName.trim().isNotEmpty &&
        _containsAny(relationship, const [
          'iş',
          'müdür',
          'hoca',
          'resmî',
          'resmi',
        ])) {
      return '${speakerName.trim()} için saygılı hitap';
    }
    if (speakerName.trim().isNotEmpty &&
        _containsAny(relationship, const [
          'anne',
          'baba',
          'eş',
          'abi',
          'abla',
          'kardeş',
          'arkadaş',
          'dost',
          'kanka',
        ])) {
      return '${speakerName.trim()} için sıcak hitap';
    }
    return 'bağlama uygun, aşırıya kaçmayan doğal hitap';
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (text.contains(part)) return true;
    }
    return false;
  }
}
