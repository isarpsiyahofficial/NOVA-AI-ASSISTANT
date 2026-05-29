// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_relationship_profile.dart';
import '../../core/runtime/nova_behavior_decision.dart';

class NovaAnticipatoryCompanionshipService {
  const NovaAnticipatoryCompanionshipService();

  Map<String, dynamic> resolve({
    required NovaRelationshipProfile profile,
    required NovaBehaviorDecision behaviorDecision,
    required String latestPrompt,
    required String contextMode,
    required double talkRatio,
  }) {
    final prompt = latestPrompt.toLowerCase();
    final bool technicalMode =
        contextMode == 'iş modu' ||
        prompt.contains('ayar') ||
        prompt.contains('teknik') ||
        prompt.contains('kod') ||
        prompt.contains('sistem');
    final bool emotionalMode =
        prompt.contains('üzgün') ||
        prompt.contains('yoruldum') ||
        prompt.contains('moral') ||
        prompt.contains('sinir') ||
        prompt.contains('kırgın');
    final bool timePressure =
        prompt.contains('acelem var') || prompt.contains('hızlı');

    String proactiveStyle = 'bekle ve ölçülü kal';
    if (technicalMode || timePressure) {
      proactiveStyle = 'önce kısa özet ver, detay için alan aç';
    } else if (emotionalMode) {
      proactiveStyle = 'çözüm dayatma; önce alan aç ve yumuşak karşıla';
    } else if (profile.trustLevel >= 0.72 && talkRatio < 0.56) {
      proactiveStyle = 'küçük doğal katkı yapılabilir';
    }

    final proactiveBand = behaviorDecision.shouldInitiate && talkRatio < 0.62
        ? 'kontrollü açık'
        : 'düşük yoğunluk';

    return <String, dynamic>{
      'style': proactiveStyle,
      'band': proactiveBand,
      'shouldPreSummarize': technicalMode || timePressure,
      'shouldHoldSpace': emotionalMode,
      'shouldOfferTinyHelp': profile.trustLevel >= 0.64 && !emotionalMode,
    };
  }

  String buildPromptSection(Map<String, dynamic> plan) {
    return [
      'ANTICIPATORY COMPANIONSHIP:',
      '- proaktif bant: ${plan['band']}',
      '- proaktif stil: ${plan['style']}',
      '- önce özet ver: ${plan['shouldPreSummarize'] == true ? 'evet' : 'hayır'}',
      '- duygusal alan aç: ${plan['shouldHoldSpace'] == true ? 'evet' : 'hayır'}',
      '- küçük yardım teklifi uygun: ${plan['shouldOfferTinyHelp'] == true ? 'evet' : 'hayır'}',
      'KURAL: Proaktiflik düşük yoğunlukta, izinli ve zamanlamalı olsun; rastgele atlama yapma.',
    ].join('\n');
  }
}
