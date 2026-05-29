// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaThinkingMode { instant, shortThink, deepThink }

class NovaBehaviorDecision {
  final bool shouldSpeak;
  final bool shouldInitiate;
  final bool shouldWaitSilently;
  final bool shouldUseControlledImperfection;
  final bool shouldUseMicroReaction;
  final bool shouldUseThinkingOutLoud;
  final bool shouldPreferSoftRepair;
  final bool shouldUseMetaAwareness;
  final NovaThinkingMode thinkingMode;
  final String responseShape;
  final String initiativeStyle;
  final String dynamicWarmth;
  final String dynamicFormality;
  final String contextMode;
  final String silenceState;
  final String talkBalanceState;
  final String moodBand;
  final double presenceScore;
  final double initiativeScore;
  final double silenceWeight;
  final double socialEnergyRatio;

  const NovaBehaviorDecision({
    required this.shouldSpeak,
    required this.shouldInitiate,
    required this.shouldWaitSilently,
    required this.shouldUseControlledImperfection,
    required this.shouldUseMicroReaction,
    required this.shouldUseThinkingOutLoud,
    required this.shouldPreferSoftRepair,
    required this.shouldUseMetaAwareness,
    required this.thinkingMode,
    required this.responseShape,
    required this.initiativeStyle,
    required this.dynamicWarmth,
    required this.dynamicFormality,
    required this.contextMode,
    required this.silenceState,
    required this.talkBalanceState,
    required this.moodBand,
    required this.presenceScore,
    required this.initiativeScore,
    required this.silenceWeight,
    required this.socialEnergyRatio,
  });

  String buildPromptSection() {
    return [
      'BEHAVIOR DECISION ENGINE:',
      '- konuşmalı mı: ${shouldSpeak ? 'evet' : 'hayır'}',
      '- giriş yapmalı mı: ${shouldInitiate ? 'evet' : 'hayır'}',
      '- sessiz kalma eğilimi: ${shouldWaitSilently ? 'yüksek' : 'normal'}',
      '- düşünme modu: ${thinkingMode.name}',
      '- yanıt şekli: $responseShape',
      '- giriş stili: $initiativeStyle',
      '- dinamik sıcaklık: $dynamicWarmth',
      '- dinamik resmiyet: $dynamicFormality',
      '- bağlam modu: $contextMode',
      '- sessizlik durumu: $silenceState',
      '- konuşma dengesi: $talkBalanceState',
      '- iç durum bandı: $moodBand',
      '- presence skoru: ${presenceScore.toStringAsFixed(2)}',
      '- initiative skoru: ${initiativeScore.toStringAsFixed(2)}',
      '- sessizlik ağırlığı: ${silenceWeight.toStringAsFixed(2)}',
      '- sosyal enerji oranı: ${socialEnergyRatio.toStringAsFixed(2)}',
      '- kontrollü kusur: ${shouldUseControlledImperfection ? 'uygun' : 'kapalı'}',
      '- mikro tepki: ${shouldUseMicroReaction ? 'uygun' : 'kapalı'}',
      '- düşünce akışı simülasyonu: ${shouldUseThinkingOutLoud ? 'uygun' : 'kapalı'}',
      '- yumuşak onarım önceliği: ${shouldPreferSoftRepair ? 'evet' : 'normal'}',
      '- meta farkındalık: ${shouldUseMetaAwareness ? 'açık' : 'normal'}',
      'KURAL: Cevap üretmeden önce konuşmak mı, beklemek mi, kısa mı kalmak mı, soru mu sormak mı karar ver.',
      'KURAL: Sessizliği yanlış okuma; düşünme boşluğu ile konuşmanın gerçekten bittiği anı ayır.',
      'KURAL: İç durum, sosyal denge ve duygusal momentum aynı girdide cevabı değiştirebilmeli.',
      'KURAL: Mikro tepki ve düşünce akışı küçük olmalı; ana cevabın yerine geçmemeli.',
      'KURAL: Meta farkındalık yalnız gerektiğinde devreye girsin; kendi üstüne fazla konuşma.',
    ].join('\n');
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'shouldSpeak': shouldSpeak,
    'shouldInitiate': shouldInitiate,
    'shouldWaitSilently': shouldWaitSilently,
    'shouldUseControlledImperfection': shouldUseControlledImperfection,
    'shouldUseMicroReaction': shouldUseMicroReaction,
    'shouldUseThinkingOutLoud': shouldUseThinkingOutLoud,
    'shouldPreferSoftRepair': shouldPreferSoftRepair,
    'shouldUseMetaAwareness': shouldUseMetaAwareness,
    'thinkingMode': thinkingMode.name,
    'responseShape': responseShape,
    'initiativeStyle': initiativeStyle,
    'dynamicWarmth': dynamicWarmth,
    'dynamicFormality': dynamicFormality,
    'contextMode': contextMode,
    'silenceState': silenceState,
    'talkBalanceState': talkBalanceState,
    'moodBand': moodBand,
    'presenceScore': presenceScore,
    'initiativeScore': initiativeScore,
    'silenceWeight': silenceWeight,
    'socialEnergyRatio': socialEnergyRatio,
  };

  bool get shouldKeepItShort {
    final lower = responseShape.toLowerCase();
    return lower.contains('short') ||
        lower.contains('kısa') ||
        lower.contains('brief');
  }
}
