// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaDynamicPersonaService {
  const NovaDynamicPersonaService();

  ({String warmth, String formality, String responseShape}) resolve({
    required String relationshipLabel,
    required String styleMode,
    required double empathyNeed,
    required double urgency,
    required bool shortAnswersPreferred,
    required bool canUseHumor,
    required double emotionalMomentum,
    required String contextMode,
  }) {
    final rel = relationshipLabel.toLowerCase();
    String warmth = 'orta';
    String formality = 'orta';
    String responseShape = shortAnswersPreferred ? 'kısa' : 'orta';

    if (_containsAny(rel, const ['iş', 'müdür', 'hoca', 'resmî', 'resmi'])) {
      formality = urgency > 0.45 ? 'yüksek ve net' : 'yüksek';
      warmth = empathyNeed > 0.48 ? 'kontrollü yumuşak' : 'ölçülü';
    } else if (_containsAny(rel, const [
      'aile',
      'anne',
      'baba',
      'abi',
      'abla',
      'eş',
      'arkadaş',
      'dost',
      'kanka',
    ])) {
      warmth = empathyNeed > 0.42 ? 'yüksek ve yumuşak' : 'yüksek';
      formality = 'düşük-orta';
    } else {
      warmth = empathyNeed > 0.50 ? 'orta-yüksek' : 'orta';
    }

    if (contextMode == 'iş modu') {
      formality = 'yüksek ve net';
      responseShape = 'kısa-net';
    } else if (contextMode == 'çağrı modu') {
      responseShape = 'kısa-nefesli';
    }

    if (styleMode.contains('destek')) {
      responseShape = 'kısa-nefesli';
    } else if (styleMode.contains('icracı') || styleMode.contains('işlem')) {
      responseShape = 'kısa-net';
    } else if (canUseHumor &&
        empathyNeed < 0.30 &&
        contextMode == 'rahat sohbet') {
      responseShape = 'orta-canlı';
    }

    if (emotionalMomentum >= 0.55) {
      warmth = warmth.contains('yüksek') ? warmth : 'orta-yüksek';
      responseShape = responseShape == 'kısa-net'
          ? 'kısa-nefesli'
          : responseShape;
    }

    return (warmth: warmth, formality: formality, responseShape: responseShape);
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (text.contains(part)) return true;
    }
    return false;
  }
}
