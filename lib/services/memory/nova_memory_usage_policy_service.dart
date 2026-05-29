// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/cognition/nova_emotion_state.dart';

class NovaMemoryUsagePolicyDecision {
  final bool shouldSurface;
  final bool shouldAskBeforePromoting;
  final bool shouldStayQuiet;
  final String reason;

  const NovaMemoryUsagePolicyDecision({
    required this.shouldSurface,
    required this.shouldAskBeforePromoting,
    required this.shouldStayQuiet,
    required this.reason,
  });
}

class NovaMemoryUsagePolicyService {
  const NovaMemoryUsagePolicyService();

  bool shouldSurfaceMemory({
    required String prompt,
    required String memoryText,
    required double relevance,
    required NovaEmotionState emotion,
  }) {
    return decide(
      prompt: prompt,
      memoryText: memoryText,
      relevance: relevance,
      emotion: emotion,
    ).shouldSurface;
  }

  NovaMemoryUsagePolicyDecision decide({
    required String prompt,
    required String memoryText,
    required double relevance,
    required NovaEmotionState emotion,
  }) {
    final normalizedPrompt = prompt.toLowerCase().trim();
    final normalizedMemory = memoryText.toLowerCase().trim();

    if (normalizedPrompt.isEmpty || normalizedMemory.isEmpty) {
      return const NovaMemoryUsagePolicyDecision(
        shouldSurface: false,
        shouldAskBeforePromoting: false,
        shouldStayQuiet: true,
        reason: 'Boş içerik.',
      );
    }

    final explicitRecall = _containsAny(normalizedPrompt, const [
      'hatırla',
      'hatirla',
      'geçen gün',
      'gecen gun',
      'az önce',
      'az once',
      'demin',
      'önceden',
      'onceden',
      'konuşmuştuk',
      'konusmustuk',
      'hatırlıyor musun',
      'hatirliyor musun',
    ]);
    final memoryPromotionIntent = _containsAny(normalizedPrompt, const [
      'bunu öğren',
      'bunu ogren',
      'hafızana al',
      'hafizana al',
      'unutma',
      'kalıcı tut',
      'kalici tut',
      'öğren ve davranışına ekle',
      'ogren ve davranisina ekle',
    ]);
    final suppressionContext = _containsAny(normalizedPrompt, const [
      'şimdi buna dönme',
      'simdi buna donme',
      'eski konuyu açma',
      'eski konuyu acma',
      'onu karıştırma',
      'onu karistirma',
    ]);
    final highEmotionalMoment =
        emotion.empathyNeed > 0.42 || emotion.frustrationTrend > 0.44;
    final veryRelevant = relevance >= 0.72;
    final solidRelevant = relevance >= 0.58;
    final sameTopic = _tokenOverlap(normalizedPrompt, normalizedMemory) >= 0.42;
    final intrusive =
        _containsAny(normalizedMemory, const [
          'kişisel not',
          'hassas',
          'özel',
          'mahrem',
        ]) &&
        !explicitRecall;

    if (suppressionContext) {
      return const NovaMemoryUsagePolicyDecision(
        shouldSurface: false,
        shouldAskBeforePromoting: false,
        shouldStayQuiet: true,
        reason: 'Kullanıcı eski konuyu şimdi açmamak istedi.',
      );
    }

    if (memoryPromotionIntent) {
      return const NovaMemoryUsagePolicyDecision(
        shouldSurface: true,
        shouldAskBeforePromoting: true,
        shouldStayQuiet: false,
        reason: 'Kullanıcı açıkça kalıcılaştırma/öğrenme yönünde konuşuyor.',
      );
    }

    if (explicitRecall && (solidRelevant || sameTopic)) {
      return const NovaMemoryUsagePolicyDecision(
        shouldSurface: true,
        shouldAskBeforePromoting: false,
        shouldStayQuiet: false,
        reason: 'Kullanıcı geçmişe açık referans verdi.',
      );
    }

    if (intrusive) {
      return const NovaMemoryUsagePolicyDecision(
        shouldSurface: false,
        shouldAskBeforePromoting: false,
        shouldStayQuiet: true,
        reason: 'Açık çağrı olmadan kişisel hafıza yüzeye çıkmamalı.',
      );
    }

    if (highEmotionalMoment && !veryRelevant) {
      return const NovaMemoryUsagePolicyDecision(
        shouldSurface: false,
        shouldAskBeforePromoting: false,
        shouldStayQuiet: true,
        reason: 'Duygusal anda alakasız hafıza açmak konuşmayı bozabilir.',
      );
    }

    if (sameTopic && veryRelevant) {
      return const NovaMemoryUsagePolicyDecision(
        shouldSurface: true,
        shouldAskBeforePromoting: false,
        shouldStayQuiet: false,
        reason: 'Yüksek alaka ve aynı konu çizgisi var.',
      );
    }

    if (normalizedPrompt.contains(normalizedMemory) || veryRelevant) {
      return const NovaMemoryUsagePolicyDecision(
        shouldSurface: true,
        shouldAskBeforePromoting: false,
        shouldStayQuiet: false,
        reason: 'Doğrudan örtüşme var.',
      );
    }

    if (solidRelevant && emotion.trustComfort >= 0.46 && !highEmotionalMoment) {
      return const NovaMemoryUsagePolicyDecision(
        shouldSurface: true,
        shouldAskBeforePromoting: false,
        shouldStayQuiet: false,
        reason: 'Orta-üst alaka ve güvenli akış.',
      );
    }

    return const NovaMemoryUsagePolicyDecision(
      shouldSurface: false,
      shouldAskBeforePromoting: false,
      shouldStayQuiet: true,
      reason: 'Yerinde olmayan hafıza referansı baskılandı.',
    );
  }

  String buildPromptSection() {
    return [
      'MEMORY USAGE POLICY:',
      '- Hafızayı yalnız yüksek alakada ve yerinde kullan.',
      '- Kullanıcı açıkça geçmişe dönmüyorsa eski konuyu gereksiz yere açma.',
      '- Öğrenme/kalıcılaştırma çağrışımı varsa uygun yerde önce sor: geçici mi kalıcı mı?',
      '- Duygusal anda düşük alakalı hafıza gösterme; önce duyguya cevap ver.',
      '- Hassas veya özel hafızayı açık ihtiyaç olmadan masaya koyma.',
      '- Eski konuyu yüzeye çıkaracaksan kısa referans ver; sohbeti ele geçirme.',
    ].join('\n');
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }

  double _tokenOverlap(String left, String right) {
    final leftSet = left
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), ' ')
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.length >= 3)
        .toSet();
    final rightSet = right
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), ' ')
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.length >= 3)
        .toSet();
    if (leftSet.isEmpty || rightSet.isEmpty) return 0.0;
    final common = leftSet.intersection(rightSet).length;
    final base = leftSet.length > rightSet.length
        ? leftSet.length
        : rightSet.length;
    return common / base;
  }
}
