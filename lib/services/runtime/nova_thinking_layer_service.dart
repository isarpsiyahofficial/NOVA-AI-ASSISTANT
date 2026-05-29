// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_thinking_models.dart';

class NovaThinkingLayerService {
  const NovaThinkingLayerService();

  NovaThinkingSnapshot analyze(
    String rawInput, {
    required bool internetAllowed,
    required bool isResearchRequest,
  }) {
    final input = rawInput.trim();
    final lower = _normalize(input);
    final tokenCount = input
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .length;

    final bool emotional = _containsAny(lower, const <String>[
      'kotuyum',
      'uzgunum',
      'yoruldum',
      'garip hissediyorum',
      'moralim bozuk',
      'sevindim',
      'mutluyum',
      'canim sikkin',
      'bunaldim',
      'dertlesmek istiyorum',
      'icimi dokmek istiyorum',
      'yalniz hissediyorum',
      'sinirliyim',
      'gerildim',
      'sabirim kalmadi',
    ]);
    final bool directCommand = _containsAny(lower, const <String>[
      'ac',
      'kapat',
      'ara',
      'mesaj at',
      'cal',
      'oynat',
      'degistir',
      'baslat',
      'durdur',
      'hatirlat',
      'uyandir',
      'spotify',
      'telefon',
      'muzik',
      'hoparlor',
      'cevapla',
      'devral',
      'devret',
      'yardima gel',
      'buraya gel',
      'cevir',
      'tercume et',
      'kaydet',
      'sil',
      'moduna gec',
      'ayarla',
    ]);
    final bool naturalCommand = _containsAny(lower, const <String>[
      'yardim eder misin',
      'yardım eder misin',
      'bir bakar misin',
      'bakar misin',
      'cozer misin',
      'çözer misin',
      'halledebilir misin',
      'arayabilir misin',
      'acabilir misin',
      'açabilir misin',
      'kapatabilir misin',
      'bunu duzelt',
      'bunu düzelt',
      'sunu hallet',
      'şunu hallet',
      'ilgilenir misin',
      'yardimci olur musun',
      'yardımcı olur musun',
    ]);
    final bool memory = _containsAny(lower, const <String>[
      'hafizana kaydet',
      'unutma',
      'hatirla',
      'aklinda tut',
      'bunu kaydet',
      'gecen sefer',
      'daha once',
      'hatirliyor musun',
    ]);
    final bool information =
        isResearchRequest ||
        internetAllowed ||
        _containsAny(lower, const <String>[
          'nedir',
          'nasil',
          'anlat',
          'acikla',
          'bilgi ver',
          'neden',
          'hangi',
          'kim',
          'ne zaman',
          'farki ne',
          'sence',
          'ne dusunuyorsun',
          'yorumlarsan',
          'bir bakar misin',
        ]);
    final bool smallTalk = _containsAny(lower, const <String>[
      'nasilsin',
      'bugun nasil gidiyor',
      'ne yapiyorsun',
      'merhaba',
      'selam',
      'orada misin',
      'beni duyuyor musun',
      'sohbet edelim',
      'iki laf edelim',
      'konusalim',
      'konuşalım',
      'muhabbet edelim',
    ]);
    final bool explainFailure = _containsAny(lower, const <String>[
      'neden yapamiyorsun',
      'neden olmuyor',
      'neden cevap vermiyorsun',
      'neden anlamiyorsun',
      'neden yapmadi',
      'neden yapmiyor',
      'olmadiysa neden',
      'olmadıysa neden',
    ]);
    final bool ambiguous =
        tokenCount <= 3 &&
        !directCommand &&
        !naturalCommand &&
        !memory &&
        !information &&
        !emotional &&
        !smallTalk;

    final NovaInteractionIntent intent;
    if (memory) {
      intent = NovaInteractionIntent.memory;
    } else if (emotional) {
      intent = NovaInteractionIntent.emotional;
    } else if (directCommand || naturalCommand) {
      intent = NovaInteractionIntent.command;
    } else if (information) {
      intent = NovaInteractionIntent.information;
    } else if (ambiguous) {
      intent = NovaInteractionIntent.ambiguous;
    } else {
      intent = NovaInteractionIntent.conversation;
    }

    final curiosity = switch (intent) {
      NovaInteractionIntent.command =>
        naturalCommand ? NovaCuriosityLevel.medium : NovaCuriosityLevel.low,
      NovaInteractionIntent.information =>
        tokenCount <= 6 ? NovaCuriosityLevel.medium : NovaCuriosityLevel.high,
      NovaInteractionIntent.memory => NovaCuriosityLevel.medium,
      NovaInteractionIntent.conversation =>
        smallTalk ? NovaCuriosityLevel.medium : NovaCuriosityLevel.high,
      NovaInteractionIntent.emotional => NovaCuriosityLevel.high,
      NovaInteractionIntent.ambiguous => NovaCuriosityLevel.high,
    };

    final confidence = switch (intent) {
      NovaInteractionIntent.ambiguous => NovaConfidenceLevel.low,
      NovaInteractionIntent.conversation =>
        smallTalk ? NovaConfidenceLevel.high : NovaConfidenceLevel.medium,
      NovaInteractionIntent.emotional => NovaConfidenceLevel.medium,
      NovaInteractionIntent.command =>
        naturalCommand ? NovaConfidenceLevel.medium : NovaConfidenceLevel.high,
      NovaInteractionIntent.information => NovaConfidenceLevel.medium,
      NovaInteractionIntent.memory => NovaConfidenceLevel.high,
    };

    final perspectives = <NovaThinkingPerspective>[
      NovaThinkingPerspective(
        name: 'niyet okuma',
        focus: (directCommand || naturalCommand)
            ? 'Sabit komut kelimesi arama; kullanıcının yaptırmak istediği gerçek işi tamamla.'
            : 'Aynı anlam farklı cümlelerle kurulabilir; doğal Türkçeyi dar kalıba hapsetme.',
      ),
      NovaThinkingPerspective(
        name: 'iletişim',
        focus: (smallTalk || intent == NovaInteractionIntent.conversation)
            ? 'Sadece komut bekleyen bot gibi davranma; karşılıklı konuşmayı sürdür.'
            : 'Yapamadığında bile sessiz kalma; neden ve bir sonraki adımı açıkla.',
      ),
      NovaThinkingPerspective(
        name: 'guven kontrolu',
        focus: ambiguous
            ? 'Yanlış işlem riskini azaltmak için kısa netleştirme sor.'
            : 'Emin olmadığın yerde kesin konuşma; kısa temkin payı bırak.',
      ),
    ];

    final interpretations = _buildInterpretations(
      intent,
      lower,
      smallTalk: smallTalk,
      naturalCommand: naturalCommand,
    );

    return NovaThinkingSnapshot(
      intent: intent,
      curiosityLevel: curiosity,
      confidenceLevel: confidence,
      primaryGoal: _buildPrimaryGoal(intent, naturalCommand: naturalCommand),
      possibleInterpretations: interpretations,
      perspectives: perspectives,
      shouldAskClarifyingQuestion:
          intent == NovaInteractionIntent.ambiguous ||
          (intent == NovaInteractionIntent.command && tokenCount <= 2),
      shouldAvoidToolUse:
          intent == NovaInteractionIntent.conversation ||
          intent == NovaInteractionIntent.emotional,
      shouldUseMemory:
          intent == NovaInteractionIntent.conversation ||
          intent == NovaInteractionIntent.emotional ||
          intent == NovaInteractionIntent.memory ||
          lower.contains('daha once') ||
          lower.contains('gecen sefer') ||
          lower.contains('hatirliyor musun'),
      shouldOfferWarmth:
          intent == NovaInteractionIntent.emotional ||
          intent == NovaInteractionIntent.conversation ||
          smallTalk,
      shouldExplainLimits:
          explainFailure || intent == NovaInteractionIntent.command,
      shouldStayEngaged:
          smallTalk ||
          intent == NovaInteractionIntent.conversation ||
          intent == NovaInteractionIntent.emotional,
      shouldPreferDialogue: smallTalk || naturalCommand,
    );
  }

  List<String> _buildInterpretations(
    NovaInteractionIntent intent,
    String lower, {
    required bool smallTalk,
    required bool naturalCommand,
  }) {
    switch (intent) {
      case NovaInteractionIntent.command:
        return <String>[
          if (naturalCommand)
            'Kullanıcı doğal dille işlem istiyor; dar komut kalıbı arama.',
          'Kullanıcı birebir komut kelimesi kurmamış olsa da bir işlem yaptırmak istiyor olabilir.',
          'Doğru sistemi seçip gereksiz netleştirmeyi azaltmam gerekiyor.',
        ];
      case NovaInteractionIntent.information:
        return const <String>[
          'Kullanıcı yalnız bilgi değil, yorumlanmış ve işe yarar açıklama istiyor olabilir.',
          'Soru dolaylı kurulmuş olabilir; anlamı toparlamam gerekiyor.',
          'Emin olmadığım yerde temkinli ifade kullanmalıyım.',
        ];
      case NovaInteractionIntent.emotional:
        return const <String>[
          'Kullanıcı önce anlaşılmak ve duygusal olarak görülmek istiyor olabilir.',
          'Hemen çözüm vermek yerine önce doğru tonda karşılık bekliyor olabilir.',
          'Sıcak ama kontrollü konuşmam gerekir.',
        ];
      case NovaInteractionIntent.memory:
        return const <String>[
          'Kullanıcı bir bilgiyi saklamamı ya da unutmamamı istiyor.',
          'Geçici ve kalıcı hafıza ayrımını düşünmeliyim.',
          'Aynı şeyi tekrar kaydetmemeliyim.',
        ];
      case NovaInteractionIntent.ambiguous:
        return const <String>[
          'İfade kısa ve çok anlamlı olabilir.',
          'Yanlış işlem yapmamak için kısa netleştirme gerekir.',
          'Tahmine dayalı işlem yerine güvenli soru sormalıyım.',
        ];
      case NovaInteractionIntent.conversation:
        return <String>[
          if (smallTalk)
            'Kullanıcı sadece tepki ve varlık hissi arıyor olabilir.',
          'Kuru cevap yerine sıcak ve insan gibi bir karşılık daha doğal olur.',
          'Aynı kalıp cümlelere düşmemeliyim.',
        ];
    }
  }

  String _buildPrimaryGoal(
    NovaInteractionIntent intent, {
    required bool naturalCommand,
  }) {
    switch (intent) {
      case NovaInteractionIntent.command:
        return naturalCommand
            ? 'Doğal Türkçeden gerçek işi çıkar ve gerekiyorsa kısa soru ile tamamla.'
            : 'İstenen işi sabit komut aramadan doğru sisteme bağla.';
      case NovaInteractionIntent.information:
        return 'Soruyu toparla, güvenilir ve işe yarar cevap ver.';
      case NovaInteractionIntent.emotional:
        return 'Önce doğru duygusal karşılık ver, sonra gerekiyorsa yönlendir.';
      case NovaInteractionIntent.memory:
        return 'Bilgiyi doğru hafıza türüne bağla.';
      case NovaInteractionIntent.ambiguous:
        return 'Yanlış anlamayı önleyecek kadar kısa netleştirme yap.';
      case NovaInteractionIntent.conversation:
        return 'Canlı, doğal ve düşünülmüş tepki ver.';
    }
  }

  bool _containsAny(String text, List<String> hints) {
    for (final hint in hints) {
      if (text.contains(hint)) return true;
    }
    return false;
  }

  String _normalize(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll('ê', 'e')
        .replaceAll('ô', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }
}
