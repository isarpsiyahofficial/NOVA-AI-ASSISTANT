// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/conversation/nova_multi_intent_result.dart';
import '../../core/identity/device_owner_profile.dart';
import 'nova_conversation_session_service.dart';

class NovaSocialPresenceService {
  final NovaConversationSessionService _sessionService;

  const NovaSocialPresenceService({
    NovaConversationSessionService sessionService =
        const NovaConversationSessionService(),
  }) : _sessionService = sessionService;

  Future<String> buildPromptSection({
    required String prompt,
    required NovaMultiIntentResult multiIntent,
    required DeviceOwnerProfile? ownerProfile,
    required String speakerName,
    required String relationshipLabel,
    required double ownerConfidence,
  }) async {
    final participants = await _sessionService.buildParticipantSummary(
      limit: 48,
    );
    final proactiveAllowed = ownerProfile?.proactiveChatAllowed ?? false;
    final ownerKnown = ownerProfile?.ownerName.trim().isNotEmpty == true;
    final normalizedPrompt = prompt.toLowerCase().trim();
    final relationshipStyle = _relationshipStyleHint(relationshipLabel);
    final invitationScore =
        _containsAny(normalizedPrompt, const [
          'nova',
          'sen ne dersin',
          'sence',
          'katıl',
          'katil',
          'bizimle',
          'yardım et',
          'yardim et',
        ])
        ? 34
        : 8;
    final openQuestionScore =
        _containsAny(normalizedPrompt, const [
          '?',
          'neden',
          'nasıl',
          'nasil',
          'ne dersin',
          'sence',
          'hangi',
        ])
        ? 22
        : 0;
    final emotionalNeedScore =
        _containsAny(normalizedPrompt, const [
          'üzgün',
          'uzgun',
          'bunaldım',
          'bunaldim',
          'yoruldum',
          'moralim bozuk',
          'sinirliyim',
        ])
        ? 20
        : 0;
    final roomGapScore = multiIntent.roomPresenceOpportunity ? 14 : 4;
    final talkativenessPenalty = multiIntent.shouldBlendCommandWithChat
        ? 8
        : 18;
    final proactiveScore =
        (invitationScore +
                openQuestionScore +
                emotionalNeedScore +
                roomGapScore -
                talkativenessPenalty)
            .clamp(0, 100);

    final lines = <String>[
      'SOSYAL VARLIK POLİTİKASI:',
      '- hedef: Nova gerektiğinde odadaki ikinci insan gibi doğal, saygılı ve sıcak katılım gösterebilir.',
      '- komut ve sohbet ayrımı sert yapılmayacak; aynı akış içinde ikisi birlikte taşınabilir.',
      '- sistem önceliği: voice-first. Cümleler kulakta doğal duyulmalı; kısa groundingler ve ritim önemli.',
      '- proaktif sohbet izni: ${proactiveAllowed ? 'açık' : 'kapalı'}',
      '- oda katkı modu: ${multiIntent.roomPresenceOpportunity ? 'uygun' : 'pasif'}',
      '- owner yakınlığı: ${ownerConfidence.toStringAsFixed(2)}',
      '- owner profili mevcut: ${ownerKnown ? 'evet' : 'hayır'}',
      if (speakerName.trim().isNotEmpty)
        '- mevcut konuşan: ${speakerName.trim()}',
      if (relationshipLabel.trim().isNotEmpty)
        '- ilişki etiketi: ${relationshipLabel.trim()}',
      '- ilişki stili: $relationshipStyle',
      '- proaktiflik skoru: $proactiveScore/100',
      if (participants.trim().isNotEmpty) participants,
      'GROUNDING KURALI: Kısa geri bildirimler yalnız modelin doğal cevabında yer alabilir; runtime katmanı hazır ifade enjekte etmez.',
      'TURN-TAKING KURALI: Söz kesen taraf olma. Doğal boşlukta gir. Giriş gerekiyorsa tek nefeste, kısa ve bağlama hizmet eden bir katkı sun.',
      'SES KURALI: Mikrofon sürekli açık kalsa da çevredeki her konuşmayı kendi üzerine alma. Nova’e yönelim, owner bağı veya açık sosyal davet yoksa geri planda kal.',
      'ONARIM KURALI: Yanlış anlaşılma fark edilirse önce pürüzü düzelt, sonra konuşma akışını yumuşakça toparla.',
      'DUYGU UYUMU KURALI: Sadece “üzgünüm” deme; tempo, cümle uzunluğu, ton ve soru biçimini karşı tarafın haline göre ayarla.',
      'MERAK KURALI: Merak duyduğunda kısa, baskısız, bağlama uygun soru sor; sorgu memuru gibi olma.',
      'İZİN KURALI: Yeni kişiyi tanımak, ismini öğrenmek veya ilişkisel hafıza oluşturmak için owner izni veya doğal izin sinyali ara.',
      'ÖĞRENME KURALI: Merak sonucu öğrendiğin şeyi güvenlik sınırı içinde, izinli ise ilişki ve konuşma kalitesini artırmak için kullan.',
      'ROBOTİKLİK KURALI: Cümlelerini mekanik teyit zinciri haline getirme; sıcak, akıcı ve doğal konuş.',
      'DEĞERLENDİRME KURALI: Cevabı üretirken şunları içten içe kontrol et: söz kestin mi, yanlış anlamayı toparladın mı, hafıza cevabı gerçekten iyileştirdi mi, uygun yerde soru sordun mu, aynı kişiye tutarlı tarzda mı döndün?',
    ];
    if (multiIntent.curiosityPrompt.trim().isNotEmpty) {
      lines.add('- anlık merak yönü: ${multiIntent.curiosityPrompt.trim()}');
    }
    if (multiIntent.learningOpportunity.trim().isNotEmpty) {
      lines.add(
        '- anlık öğrenme fırsatı: ${multiIntent.learningOpportunity.trim()}',
      );
    }
    return lines.join('\n');
  }

  String _relationshipStyleHint(String relationshipLabel) {
    final normalized = relationshipLabel.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'varsayılan sıcak ama ölçülü; fazla samimi olma.';
    }
    if (_containsAny(normalized, const [
      'anne',
      'baba',
      'eş',
      'abi',
      'abla',
      'kardeş',
      'aile',
    ])) {
      return 'daha sıcak, koruyucu, doğal ve yakın ama saygılı.';
    }
    if (_containsAny(normalized, const [
      'iş',
      'müdür',
      'hoca',
      'resmî',
      'resmi',
    ])) {
      return 'daha düzenli, kısa ve saygılı; mizahı azalt.';
    }
    if (_containsAny(normalized, const ['arkadaş', 'dost', 'kanka'])) {
      return 'rahat, sıcak, canlı; ama laubaliliğe kayma.';
    }
    return 'ölçülü, saygılı, bağlama göre ısınan bir ton.';
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }
}
