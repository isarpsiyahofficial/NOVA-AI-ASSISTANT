// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_turkish_pragmatics_engine_service.dart';
import 'nova_turkish_indirect_request_detector_service.dart';
import 'nova_conversation_act_detector_service.dart';

class NovaSpokenIntentInterpreterService {
  const NovaSpokenIntentInterpreterService();

  static const NovaConversationActDetectorService _actDetector =
      NovaConversationActDetectorService();

  static const NovaTurkishPragmaticsEngineService _pragmatics =
      NovaTurkishPragmaticsEngineService();
  static const NovaTurkishIndirectRequestDetectorService
  _indirectRequestDetector = NovaTurkishIndirectRequestDetectorService();

  static const List<String> _addressPrefixes = <String>[
    'nova',
    'hey nova',
    'merhaba nova',
    'dinle nova',
    'nova bak',
    'nova dinle',
    'nova bir şey diyeceğim',
    'nova sana söylüyorum',
    'nova bir bakar mısın',
    'nova şunu yap',
    'nova canım',
    'nova hazır mısın',
    'nova burada mısın',
    'nova burda mısın',
    'nova burada misin',
    'nova burda misin',
    'nova beni dinle',
    'nova uyan',
    'nova yardım et',
    'nova gelir misin',
  ];

  static const List<String> _continueSpeakingPhrases = <String>[
    'ben anlatırken sen de anlatmaya devam et',
    'dinlerken anlatmaya devam edebilirsin',
    'ben konuşurken konuşmaya devam et',
    'sen de anlatmaya devam et',
  ];

  static const List<String> _deferPhrases = <String>[
    'tamam bekle',
    'bekle halledicem',
    'bekle halledeceğim',
    'bir saniye',
    'şimdilik dursun',
    'sonra halledeceğim',
    'tamam sonra',
    'tamam hallediyorum',
    'bekle çözeceğim',
  ];

  static const List<String> _conversationIndicators = <String>[
    'sohbete katıl',
    'sohbete katil',
    'aramıza katıl',
    'aramiza katil',
    'sen de katıl',
    'sen de katil',
    'izin verirsen',
    'tanışmak isterim',
    'tanismak isterim',
    'ne dersin nova',
    'sen ne dersin',
    'sen de ne düşünüyorsun',
    'sen de ne dusunuyorsun',
    'sohbet edelim',
    'sohbet et',
    'benimle konuş',
    'benimle sohbet',
    'bir şey soracağım',
    'sana bir şey soracağım',
    'sana bir şey diyeceğim',
    'beni dinliyor musun',
    'beni duyuyor musun',
    'biliyor musun',
    'biliyorsun dimi',
    'biliyorsun değil mi',
    'neden sustun',
    'neden cevap vermiyorsun',
    'beni anlıyor musun',
    'beni anladın mı',
    'yardımcı olur musun',
    'konuşabilir misin',
    'benimle biraz konuş',
    'sence',
    'ne düşünüyorsun',
    'nasılsın',
    'orada mısın',
    'burada mısın',
    'hatırlıyor musun',
  ];

  static const List<String> _commandIndicators = <String>[
    'aç',
    'kapat',
    'durdur',
    'başlat',
    'ara',
    'hatırlat',
    'kaydet',
    'sil',
    'söyle',
    'anlat',
    'uykuya al',
    'tamamen uyut',
    'tam güç',
    'pil tasarrufu',
    'overlay',
    'izin',
    'nova',
    'yardım et',
    'hallet',
    'yönet',
    'geç',
    'moduna geç',
    'ayarla',
    'değiştir',
    'seç',
    'başlatır mısın',
    'yardımcı olur musun',
    'bir bakar mısın',
    'benim için',
    'telefonu aç',
    'hoparlöre al',
    'sen konuş',
    'bana ver',
    'şuna söyle',
    'sana bir şey diyeceğim',
    'bakar mısın',
    'ilgilenir misin',
    'şunu yap',
    'şunu da yap',
    'gerekli izinleri aç',
    'komutumu uygula',
    'devral',
    'devret',
    'yardima gel',
    'yardıma gel',
    'buraya gel',
    'cikabilirsin',
    'çıkabilirsin',
    'tercume et',
    'çeviri yap',
    'cevir',
    'çevir',
    'sohbet et',
    'sarki',
    'şarkı',
    'medya',
    'spotify',
    'youtube music',
  ];

  bool shouldKeepDefaultGreeting(String raw) {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) return true;
    const patterns = <String>[
      'kalsın',
      'aynen kalsın',
      'öyle kalsın',
      'aynı kalsın',
      'değişmesin',
      'varsayılan kalsın',
      'hoş geldin patron kalsın',
      'hoş geldin patron olarak kalsın',
      'hoş geldin patron olsun',
      'aynı olsun',
    ];
    return patterns.any(normalized.contains);
  }

  bool isContinueSpeakingOverride(String raw) {
    final normalized = _normalize(raw);
    return _continueSpeakingPhrases.any(normalized.contains);
  }

  bool isDeferral(String raw) {
    final normalized = _normalize(raw);
    return _deferPhrases.any(normalized.contains);
  }

  NovaConversationActDecision classify(String raw) {
    return _actDetector.detect(raw);
  }

  bool shouldAnswerWithoutExplicitCommand(String raw) {
    final decision = classify(raw);
    final pragmatics = _pragmatics.analyze(raw);
    final indirect = _indirectRequestDetector.detect(raw);
    return !decision.isCommandLike &&
        (decision.expectsResponse ||
            indirect.detected ||
            pragmatics.hasIndirectRequest) &&
        (decision.isSocialCue ||
            decision.isEmotionCue ||
            decision.isRepairCue ||
            decision.primaryAct == 'question' ||
            decision.primaryAct == 'conversation' ||
            pragmatics.hasImpliedDisagreement ||
            pragmatics.hasIndirectRequest);
  }

  String extractSetupResponseMeaning(String raw) {
    final normalized = normalizeMeaning(raw)
        .replaceFirst(
          RegExp(
            r'^(yani|şey|sey|ee|hmm|ıı|ii|tamam|peki|efendim|olur|olur oyle|olur öyle)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\b(nova|abi|abla|reis)\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized;
  }

  bool isDirectCommand(String raw) {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) return false;
    if (_addressPrefixes.any((e) => normalized.startsWith(e))) return true;
    final hasQuestion = normalized.endsWith('?');
    final indicatorHit = _commandIndicators.any(normalized.contains);
    if (indicatorHit && normalized.split(' ').length <= 24) return true;
    if (normalized.contains('benim icin') || normalized.contains('benim için'))
      return true;
    if (normalized.startsWith('beni ') || normalized.startsWith('novai ')) {
      return true;
    }
    if (hasQuestion &&
        (normalized.contains('nova') || normalized.contains('misin'))) {
      return true;
    }
    return false;
  }

  bool isNaturalConversationForNova(String raw) {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) return false;
    if (_conversationIndicators.any(normalized.contains)) {
      return true;
    }
    if (isLikelyAddressedToNova(raw) && normalized.split(' ').length >= 3) {
      return true;
    }
    if (normalized.endsWith('?') && normalized.contains('nova')) {
      return true;
    }
    final words = normalized
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    final hasSecondPersonTone =
        normalized.contains(' sen ') ||
        normalized.startsWith('sen ') ||
        normalized.contains(' sana ') ||
        normalized.contains(' senin ') ||
        normalized.contains(' misin') ||
        normalized.contains(' mısın') ||
        normalized.contains(' musun') ||
        normalized.contains(' miyim') ||
        normalized.contains(' ne dusunuyorsun') ||
        normalized.contains(' ne düşünüyorsun');
    final hasGroupOrInvitationTone =
        normalized.contains('biz ') ||
        normalized.contains('aramıza') ||
        normalized.contains('aramiza') ||
        normalized.contains('sohbete') ||
        normalized.contains('katıl') ||
        normalized.contains('katil') ||
        normalized.contains('izin verirsen') ||
        normalized.contains('tanış') ||
        normalized.contains('tanis') ||
        normalized.contains('sen de');
    if (words.length >= 4 &&
        (hasSecondPersonTone || hasGroupOrInvitationTone)) {
      return true;
    }
    if (words.length >= 7 && normalized.contains('?')) {
      return true;
    }
    final decision = _actDetector.detect(raw);
    return decision.expectsResponse && !decision.isCommandLike;
  }

  String stripAddressPrefix(String raw) {
    String normalizedRaw = raw.trim();
    final lower = _normalize(normalizedRaw);
    for (final prefix in _addressPrefixes) {
      if (lower.startsWith(prefix)) {
        normalizedRaw = normalizedRaw.substring(prefix.length).trim();
        break;
      }
    }
    return normalizedRaw.trim();
  }

  String normalizeMeaning(String raw) {
    return stripAddressPrefix(raw)
        .replaceFirst(RegExp(r'^(olarak|diye)\s+', caseSensitive: false), '')
        .trim();
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
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^a-z0-9\s?]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool isLikelyAddressedToNova(String raw) {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) return false;
    if (_addressPrefixes.any((e) => normalized.startsWith(e))) return true;
    return normalized.contains(' nova ') || normalized.endsWith(' nova');
  }
}
