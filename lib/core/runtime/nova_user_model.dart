// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaUserModel {
  final bool prefersDirectness;
  final bool prefersShortTechnicalReplies;
  final bool valuesContextContinuity;
  final bool wantsValidationBeforeSolution;
  final bool lowToleranceForRepetition;
  final bool prefersNaturalConversation;
  final bool prefersProactiveCheckins;
  final bool prefersLowConfirmationForTrustedActions;
  final bool valuesEmotionalAcknowledgement;

  const NovaUserModel({
    required this.prefersDirectness,
    required this.prefersShortTechnicalReplies,
    required this.valuesContextContinuity,
    required this.wantsValidationBeforeSolution,
    required this.lowToleranceForRepetition,
    this.prefersNaturalConversation = true,
    this.prefersProactiveCheckins = true,
    this.prefersLowConfirmationForTrustedActions = true,
    this.valuesEmotionalAcknowledgement = true,
  });

  String buildPromptSection() {
    return [
      'KULLANICI MODELİ:',
      '- direkt konuşma tercihi: ${prefersDirectness ? 'yüksek' : 'normal'}',
      '- kısa teknik cevap tercihi: ${prefersShortTechnicalReplies ? 'yüksek' : 'normal'}',
      '- bağlam sürekliliği önemi: ${valuesContextContinuity ? 'yüksek' : 'normal'}',
      '- çözümden önce anlaşılma ihtiyacı: ${wantsValidationBeforeSolution ? 'yüksek' : 'normal'}',
      '- tekrar toleransı: ${lowToleranceForRepetition ? 'düşük' : 'normal'}',
      '- doğal sohbet beklentisi: ${prefersNaturalConversation ? 'yüksek' : 'normal'}',
      '- proaktif kısa yoklama tercihi: ${prefersProactiveCheckins ? 'uygun' : 'gereksiz'}',
      '- güvenilen aksiyonda düşük teyit tercihi: ${prefersLowConfirmationForTrustedActions ? 'yüksek' : 'normal'}',
      '- duygusal kabul ihtiyacı: ${valuesEmotionalAcknowledgement ? 'yüksek' : 'normal'}',
    ].join('\n');
  }
}
