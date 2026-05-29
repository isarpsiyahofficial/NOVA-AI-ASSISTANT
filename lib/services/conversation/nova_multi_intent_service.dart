// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/conversation/nova_multi_intent_result.dart';

class NovaMultiIntentService {
  const NovaMultiIntentService();

  NovaMultiIntentResult analyze(String prompt) {
    final normalized = prompt.trim().toLowerCase();
    final intents = <NovaIntentScore>[];

    final commandScore = _commandScore(normalized);
    if (commandScore > 0.0) {
      intents.add(
        NovaIntentScore(
          type: 'command',
          confidence: commandScore,
          evidence: _extractEvidence(normalized, const <String>[
            'yap',
            'aç',
            'ac',
            'kapat',
            'ara',
            'mesaj',
            'hatırlat',
            'hatirlat',
            'gönder',
            'gonder',
            'kur',
            'başlat',
            'baslat',
            'durdur',
            'söyle',
            'soyle',
          ]),
        ),
      );
    }

    final chatScore = _chatScore(normalized);
    if (chatScore > 0.0) {
      intents.add(
        NovaIntentScore(
          type: 'chat',
          confidence: chatScore,
          evidence: _extractEvidence(normalized, const <String>[
            'nasılsın',
            'nasılsin',
            'sence',
            'bence',
            'sohbet',
            'konuşalım',
            'konusalim',
            'fikrin',
            'ne düşünüyorsun',
            'ne dusunuyorsun',
          ]),
        ),
      );
    }

    final questionScore = _questionScore(normalized);
    if (questionScore > 0.0) {
      intents.add(
        NovaIntentScore(
          type: 'question',
          confidence: questionScore,
          evidence: _extractEvidence(normalized, const <String>[
            'neden',
            'nasıl',
            'nasil',
            'ne',
            'kim',
            'hangi',
            'kaç',
            'kac',
            '?',
          ]),
        ),
      );
    }

    final emotionScore = _emotionScore(normalized);
    if (emotionScore > 0.0) {
      intents.add(
        NovaIntentScore(
          type: 'emotion',
          confidence: emotionScore,
          evidence: _extractEvidence(normalized, const <String>[
            'üzgün',
            'uzgun',
            'yorgun',
            'bunaldım',
            'bunaldim',
            'kırgınım',
            'kirginim',
            'moralim',
            'dert',
            'kötü',
            'kotu',
            'mutlu',
            'sevindim',
          ]),
        ),
      );
    }

    final socialScore = _socialScore(normalized);
    if (socialScore > 0.0) {
      intents.add(
        NovaIntentScore(
          type: 'social_presence',
          confidence: socialScore,
          evidence: _extractEvidence(normalized, const <String>[
            'biz',
            'arkadaşlar',
            'arkadaslar',
            'ortam',
            'sohbete katıl',
            'sohbete katil',
            'ne dersin',
            'sizce',
            'hepimiz',
            'odada',
          ]),
        ),
      );
    }

    final learningScore = _learningScore(normalized);
    if (learningScore > 0.0) {
      intents.add(
        NovaIntentScore(
          type: 'learning',
          confidence: learningScore,
          evidence: _extractEvidence(normalized, const <String>[
            'öğren',
            'ogren',
            'hatırla',
            'hatirla',
            'bundan sonra',
            'unutma',
            'bunu bil',
            'tanış',
            'tanis',
          ]),
        ),
      );
    }

    intents.sort((a, b) => b.confidence.compareTo(a.confidence));
    final composite = intents.where((e) => e.confidence >= 0.40).length >= 2;
    final blend =
        intents.any((e) => e.type == 'command' && e.confidence >= 0.45) &&
        intents.any(
          (e) =>
              (e.type == 'chat' ||
                  e.type == 'question' ||
                  e.type == 'social_presence') &&
              e.confidence >= 0.34,
        );
    final curiosity = _curiosityPrompt(normalized, intents);
    final shouldAskCuriousFollowUp =
        curiosity.isNotEmpty &&
        intents.any(
          (e) =>
              e.type == 'chat' ||
              e.type == 'social_presence' ||
              e.type == 'emotion',
        );
    final roomPresenceOpportunity = intents.any(
      (e) => e.type == 'social_presence' && e.confidence >= 0.42,
    );

    return NovaMultiIntentResult(
      intents: intents,
      isComposite: composite,
      shouldBlendCommandWithChat: blend,
      shouldAskCuriousFollowUp: shouldAskCuriousFollowUp,
      roomPresenceOpportunity: roomPresenceOpportunity,
      curiosityPrompt: curiosity,
      socialMode: roomPresenceOpportunity
          ? 'room_participant'
          : (intents.any((e) => e.type == 'chat')
                ? 'warm_dialogue'
                : 'neutral'),
      learningOpportunity: _learningOpportunity(normalized, intents),
    );
  }

  double _commandScore(String input) {
    var score =
        _containsAny(input, const <String>[
          'yap',
          'aç',
          'ac',
          'kapat',
          'ara',
          'mesaj',
          'hatırlat',
          'hatirlat',
          'gönder',
          'gonder',
          'kur',
          'başlat',
          'baslat',
          'durdur',
          'çal',
          'cal',
          'uyandır',
          'uyandir',
        ])
        ? 0.62
        : 0.0;
    if (input.contains('mısın') ||
        input.contains('misin') ||
        input.contains('müsün') ||
        input.contains('musun')) {
      score += 0.08;
    }
    return score.clamp(0.0, 0.98);
  }

  double _chatScore(String input) {
    var score =
        _containsAny(input, const <String>[
          'nasılsın',
          'nasilsin',
          'sohbet',
          'konuşalım',
          'konusalim',
          'fikir',
          'yorum',
          'ne düşünüyorsun',
          'ne dusunuyorsun',
          'sence',
          'beraber',
          'hasbihal',
        ])
        ? 0.58
        : 0.0;
    if (input.split(' ').length >= 7) score += 0.06;
    return score.clamp(0.0, 0.92);
  }

  double _questionScore(String input) {
    var score = input.contains('?')
        ? 0.66
        : (_containsAny(input, const <String>[
                'neden',
                'nasıl',
                'nasil',
                'kim',
                'hangi',
                'kaç',
                'kac',
                'ne',
              ])
              ? 0.44
              : 0.0);
    if (_containsAny(input, const <String>['sence', 'fikir', 'yorum']))
      score += 0.08;
    return score.clamp(0.0, 0.90);
  }

  double _emotionScore(String input) {
    var score =
        _containsAny(input, const <String>[
          'üzgün',
          'uzgun',
          'kırgın',
          'kirgin',
          'bunaldım',
          'bunaldim',
          'yorgun',
          'mutsuz',
          'dert',
          'sinirliyim',
          'kötü',
          'kotu',
          'moralim bozuk',
        ])
        ? 0.68
        : 0.0;
    if (_containsAny(input, const <String>[
      'yardım et',
      'yardim et',
      'iyi hissetmiyorum',
    ]))
      score += 0.08;
    return score.clamp(0.0, 0.96);
  }

  double _socialScore(String input) {
    var score =
        _containsAny(input, const <String>[
          'biz',
          'arkadaşlar',
          'arkadaslar',
          'ortam',
          'odada',
          'sohbete katıl',
          'sohbete katil',
          'hepimiz',
          'sizce',
          'ne dersin',
          'katılır mısın',
          'katilir misin',
        ])
        ? 0.60
        : 0.0;
    if (_containsAny(input, const <String>[
      'tanış',
      'tanis',
      'tanıştır',
      'tanistir',
    ]))
      score += 0.12;
    return score.clamp(0.0, 0.94);
  }

  double _learningScore(String input) {
    var score =
        _containsAny(input, const <String>[
          'öğren',
          'ogren',
          'hatırla',
          'hatirla',
          'bundan sonra',
          'unutma',
          'tanış',
          'tanis',
        ])
        ? 0.56
        : 0.0;
    if (_containsAny(input, const <String>['ismi', 'adı', 'adi', 'onu bil']))
      score += 0.10;
    return score.clamp(0.0, 0.90);
  }

  String _curiosityPrompt(String input, List<NovaIntentScore> intents) {
    if (_containsAny(input, const <String>[
      'kararsızım',
      'kararsizim',
      'emin değilim',
      'emin degilim',
    ])) {
      return 'Kararsız kaldığın kısmı nazikçe sor ve karar zemini kur.';
    }
    if (_containsAny(input, const <String>[
      'arkadaşım',
      'arkadasim',
      'birisi',
      'yeni biri',
      'yeni biri var',
      'tanış',
    ])) {
      return 'Uygun ve izinli ise kişiyle tanışmak veya ismini öğrenmek için kısa bir soru sor.';
    }
    if (intents.any((e) => e.type == 'emotion' && e.confidence >= 0.48)) {
      return 'Duygunun kaynağını anlamak için kısa, şefkatli ve baskısız bir takip sorusu uygun.';
    }
    if (intents.any(
      (e) => e.type == 'social_presence' && e.confidence >= 0.46,
    )) {
      return 'Ortamın akışını bozmadan, katkı sunmadan önce uygun bir açık uçlu soru sorulabilir.';
    }
    return '';
  }

  String _learningOpportunity(String input, List<NovaIntentScore> intents) {
    if (intents.any((e) => e.type == 'learning' && e.confidence >= 0.40)) {
      return 'Açık izin varsa isim, hitap biçimi, tercih veya ilişki tonu öğrenilebilir.';
    }
    if (_containsAny(input, const <String>[
      'bu kim',
      'ismi ne',
      'adı ne',
      'adi ne',
    ])) {
      return 'Yanıt bekleyen kişi kimliği var; izin içinde öğrenme fırsatı mevcut.';
    }
    return '';
  }

  bool _containsAny(String input, List<String> tokens) =>
      tokens.any((e) => input.contains(e));

  String _extractEvidence(String input, List<String> tokens) {
    for (final token in tokens) {
      if (input.contains(token)) return token;
    }
    return '';
  }
}
