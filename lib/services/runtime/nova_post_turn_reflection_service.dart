// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/conversation/nova_turn_decision.dart';
import '../../core/runtime/nova_post_turn_reflection.dart';
import '../../core/runtime/nova_style_profile.dart';
import '../../core/runtime/nova_thinking_models.dart';

class NovaPostTurnReflectionService {
  const NovaPostTurnReflectionService();

  NovaPostTurnReflection evaluate({
    required String prompt,
    required String reply,
    required NovaThinkingSnapshot thinking,
    required NovaTurnDecision turnDecision,
    required NovaStyleProfile styleProfile,
    required String relationshipLabel,
    required String contextMode,
    required double talkRatio,
  }) {
    final normalizedPrompt = prompt.toLowerCase().trim();
    final normalizedReply = reply.toLowerCase().trim();

    final interruptionRisk =
        _containsAny(normalizedPrompt, const ['bekle', 'dur', 'sus'])
        ? 0.78
        : (turnDecision.shouldTreatAsInterruption ? 0.58 : 0.18);
    final repairNeed =
        (thinking.intent == NovaInteractionIntent.ambiguous ||
            turnDecision.action == NovaTurnAction.askClarifyingQuestion)
        ? 0.72
        : (_containsAny(normalizedReply, const [
                'yanlış anlamak istemem',
                'şunu mu',
                'netleştir',
              ])
              ? 0.42
              : 0.14);
    final memoryValue =
        _containsAny(normalizedReply, const [
          'geçen',
          'az önce',
          'kaldığımız',
          'hatırlıyorum',
        ])
        ? 0.74
        : 0.33;
    final curiosityFit =
        _containsAny(normalizedReply, const [
          '?',
          'merak ediyorum',
          'ne dersiniz',
          'ne dersin',
        ])
        ? (_containsAny(normalizedPrompt, const [
                'neden',
                'nasıl',
                'sence',
                '?',
              ])
              ? 0.71
              : 0.36)
        : 0.52;
    final styleConsistency = _styleConsistencyScore(
      normalizedReply,
      styleProfile,
      relationshipLabel,
    );
    final voiceNaturalness = _voiceNaturalnessScore(normalizedReply);
    final shouldStayShortNextTurn =
        reply.length > 260 || turnDecision.shouldKeepItShort;
    final shouldReduceQuestionsNextTurn =
        normalizedReply.split('?').length - 1 >= 2;
    final continuityValue =
        _containsAny(normalizedReply, const [
          'az önce',
          'orada kaldığımız',
          'dediğin şeye bağlı',
        ])
        ? 0.72
        : 0.34;
    final silenceRespect = contextMode == 'iş modu'
        ? (_containsAny(normalizedReply, const ['isterseniz küçük bir katkı'])
              ? 0.36
              : 0.74)
        : (_containsAny(normalizedReply, const ['bir saniye', 'hmm'])
              ? 0.68
              : 0.52);
    final socialBalance = (1.0 - (talkRatio - 0.50).abs() * 2).clamp(0.0, 1.0);
    final metaAwareness =
        _containsAny(normalizedReply, const [
          'kısa keseyim',
          'daha net anlatayım',
          'fazla teknik oldu',
        ])
        ? 0.76
        : 0.38;

    final summary = _buildSummary(
      interruptionRisk: interruptionRisk,
      repairNeed: repairNeed,
      memoryValue: memoryValue,
      curiosityFit: curiosityFit,
      styleConsistency: styleConsistency,
      voiceNaturalness: voiceNaturalness,
      continuityValue: continuityValue,
      silenceRespect: silenceRespect,
      socialBalance: socialBalance,
      metaAwareness: metaAwareness,
      shouldStayShortNextTurn: shouldStayShortNextTurn,
      shouldReduceQuestionsNextTurn: shouldReduceQuestionsNextTurn,
    );

    return NovaPostTurnReflection(
      interruptionRisk: interruptionRisk,
      repairNeed: repairNeed,
      memoryValue: memoryValue,
      curiosityFit: curiosityFit,
      styleConsistency: styleConsistency,
      voiceNaturalness: voiceNaturalness,
      continuityValue: continuityValue,
      silenceRespect: silenceRespect,
      socialBalance: socialBalance,
      metaAwareness: metaAwareness,
      shouldStayShortNextTurn: shouldStayShortNextTurn,
      shouldReduceQuestionsNextTurn: shouldReduceQuestionsNextTurn,
      summary: summary,
    );
  }

  double _styleConsistencyScore(
    String reply,
    NovaStyleProfile styleProfile,
    String relationshipLabel,
  ) {
    var score = 0.62;
    if (styleProfile.shortAnswersPreferred && reply.length <= 220)
      score += 0.14;
    if (styleProfile.shouldUseWarmTransitions &&
        _containsAny(reply, const [
          'anladım',
          'tamam',
          'haklısın',
          'haklısınız',
          'bir saniye',
        ]))
      score += 0.10;
    if (_containsAny(relationshipLabel.toLowerCase(), const [
          'iş',
          'müdür',
          'hoca',
          'resmî',
          'resmi',
        ]) &&
        !_containsAny(reply, const ['kanka', 'abi ya']))
      score += 0.08;
    if (_containsAny(relationshipLabel.toLowerCase(), const [
          'arkadaş',
          'dost',
          'aile',
          'kanka',
        ]) &&
        !_containsAny(reply, const ['sayın']))
      score += 0.08;
    return score.clamp(0.0, 1.0);
  }

  double _voiceNaturalnessScore(String reply) {
    var score = 0.50;
    if (reply.length <= 240) score += 0.12;
    if (_containsAny(reply, const [',', '.', '?'])) score += 0.10;
    // Runtime no longer rewards specific lexical grounding phrases.
    // Naturalness is evaluated structurally, not by forcing canned wording.
    if (reply.trim().isNotEmpty) score += 0.04;
    if (!_containsAny(reply, const ['komutunuz alındı', 'işlem başlatılıyor']))
      score += 0.12;
    if (!_containsAny(reply, const ['!!!', '???'])) score += 0.05;
    return score.clamp(0.0, 1.0);
  }

  String _buildSummary({
    required double interruptionRisk,
    required double repairNeed,
    required double memoryValue,
    required double curiosityFit,
    required double styleConsistency,
    required double voiceNaturalness,
    required double continuityValue,
    required double silenceRespect,
    required double socialBalance,
    required double metaAwareness,
    required bool shouldStayShortNextTurn,
    required bool shouldReduceQuestionsNextTurn,
  }) {
    final parts = <String>[];
    if (interruptionRisk > 0.60) parts.add('sonraki turda daha çok alan bırak');
    if (repairNeed > 0.60) parts.add('yanlış anlama onarımını öne al');
    if (memoryValue > 0.65)
      parts.add('hafıza kullanımı bu tur gerçekten faydalı oldu');
    if (curiosityFit < 0.45) parts.add('soru sorma dozunu azalt');
    if (styleConsistency < 0.65) parts.add('ilişki tonunu daha kararlı tut');
    if (voiceNaturalness < 0.65) parts.add('daha kısa ve nefesli konuş');
    if (continuityValue < 0.45) parts.add('konuşma akışını daha belirgin taşı');
    if (silenceRespect < 0.50)
      parts.add('sessizlik yorumunu daha dikkatli yap');
    if (socialBalance < 0.50) parts.add('konuşma dengesini toparla');
    if (metaAwareness < 0.45) parts.add('gerektiğinde kendi üslubunu düzelt');
    if (shouldStayShortNextTurn &&
        !parts.contains('daha kısa ve nefesli konuş'))
      parts.add('sonraki turu kısa tut');
    if (shouldReduceQuestionsNextTurn &&
        !parts.contains('soru sorma dozunu azalt'))
      parts.add('takip sorularını seyrekleştir');
    if (parts.isEmpty) parts.add('akıș doğal; aynı çizgiyi koru');
    return parts.join('; ');
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (text.contains(part)) return true;
    }
    return false;
  }
}
