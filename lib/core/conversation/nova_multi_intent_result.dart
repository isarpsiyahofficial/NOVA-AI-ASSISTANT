// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaIntentScore {
  final String type;
  final double confidence;
  final String evidence;

  const NovaIntentScore({
    required this.type,
    required this.confidence,
    this.evidence = '',
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'type': type,
    'confidence': confidence.clamp(0.0, 1.0),
    'evidence': evidence,
  };
}

class NovaMultiIntentResult {
  final List<NovaIntentScore> intents;
  final bool isComposite;
  final bool shouldBlendCommandWithChat;
  final bool shouldAskCuriousFollowUp;
  final bool roomPresenceOpportunity;
  final String curiosityPrompt;
  final String socialMode;
  final String learningOpportunity;

  const NovaMultiIntentResult({
    required this.intents,
    this.isComposite = false,
    this.shouldBlendCommandWithChat = false,
    this.shouldAskCuriousFollowUp = false,
    this.roomPresenceOpportunity = false,
    this.curiosityPrompt = '',
    this.socialMode = 'neutral',
    this.learningOpportunity = '',
  });

  List<Map<String, dynamic>> toMaps() =>
      intents.map((e) => e.toMap()).toList(growable: false);

  String buildPromptSection() {
    final lines = <String>[
      'ÇOKLU NİYET ANALİZİ:',
      '- birleşik akış: ${isComposite ? 'evet' : 'hayır'}',
      '- komut + sohbet birlikte yürüsün: ${shouldBlendCommandWithChat ? 'evet' : 'hayır'}',
      '- ortamda ikinci kişi gibi katkı fırsatı: ${roomPresenceOpportunity ? 'evet' : 'hayır'}',
      '- merak odaklı takip sorusu uygun: ${shouldAskCuriousFollowUp ? 'evet' : 'hayır'}',
      '- sosyal mod: $socialMode',
      if (curiosityPrompt.trim().isNotEmpty)
        '- merak kıvılcımı: $curiosityPrompt',
      if (learningOpportunity.trim().isNotEmpty)
        '- öğrenme fırsatı: $learningOpportunity',
    ];
    for (final intent in intents) {
      lines.add(
        '- niyet ${intent.type}: ${(intent.confidence * 100).toStringAsFixed(0)}%'
        '${intent.evidence.trim().isEmpty ? '' : ' | iz: ${intent.evidence.trim()}'}',
      );
    }
    lines.add(
      'YÜRÜTME KURALI: Tek niyet seçme. Eşik üstü niyetleri birleştir; gerekiyorsa aynı cevap içinde hem aksiyon hem sohbet hem de insani takip yürüt.',
    );
    return lines.join('\n');
  }
}
