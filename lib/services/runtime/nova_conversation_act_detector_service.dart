// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaConversationActDecision {
  final String primaryAct;
  final List<String> acts;
  final bool expectsResponse;
  final bool isCommandLike;
  final bool isSocialCue;
  final bool isEmotionCue;
  final bool isRepairCue;
  final bool isBackchannelLike;
  final bool shouldKeepListening;
  final double confidence;

  const NovaConversationActDecision({
    required this.primaryAct,
    required this.acts,
    required this.expectsResponse,
    required this.isCommandLike,
    required this.isSocialCue,
    required this.isEmotionCue,
    required this.isRepairCue,
    required this.isBackchannelLike,
    required this.shouldKeepListening,
    required this.confidence,
  });

  String buildPromptSection() {
    return 'KONUŞMA EYLEMİ ALGILAMA: ana=$primaryAct; türler=${acts.join(' | ')}; cevapBekliyor=$expectsResponse; komutBenzeri=$isCommandLike; sosyalİpucu=$isSocialCue; duyguİpucu=$isEmotionCue; onarımİpucu=$isRepairCue; backchannelBenzeri=$isBackchannelLike; dinlemeSürsün=$shouldKeepListening; güven=${confidence.toStringAsFixed(2)}';
  }
}

class NovaConversationActDetectorService {
  const NovaConversationActDetectorService();

  NovaConversationActDecision detect(String raw) {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) {
      return const NovaConversationActDecision(
        primaryAct: 'silence',
        acts: <String>['silence'],
        expectsResponse: false,
        isCommandLike: false,
        isSocialCue: false,
        isEmotionCue: false,
        isRepairCue: false,
        isBackchannelLike: false,
        shouldKeepListening: true,
        confidence: 0.18,
      );
    }

    final acts = <String>[];
    bool expectsResponse = false;
    bool isCommandLike = false;
    bool isSocialCue = false;
    bool isEmotionCue = false;
    bool isRepairCue = false;
    bool isBackchannelLike = false;
    bool shouldKeepListening = false;

    final words = normalized.split(' ').where((e) => e.isNotEmpty).toList();
    final hasQuestion =
        normalized.contains('?') ||
        normalized.contains(' mi ') ||
        normalized.endsWith(' mi') ||
        normalized.contains(' mısın') ||
        normalized.contains(' misin') ||
        normalized.contains(' musun') ||
        normalized.contains(' müsün') ||
        normalized.contains(' neden ') ||
        normalized.contains(' niye ') ||
        normalized.contains(' nasıl ') ||
        normalized.contains(' ne ') ||
        normalized.contains(' kim ') ||
        normalized.contains(' hangi ');
    final commandish = _containsAny(normalized, const [
      'aç',
      'kapat',
      'başlat',
      'durdur',
      'ara',
      'hatırlat',
      'kaydet',
      'sil',
      'değiştir',
      'ayarla',
      'göster',
      'anlat',
      'devral',
      'devret',
      'çevir',
      'yardım et',
      'yap',
      'hallet',
      'bakar mısın',
      'ilgilenir misin',
    ]);
    final emotionish = _containsAny(normalized, const [
      'canım sıkkın',
      'moralim bozuk',
      'üzgünüm',
      'üzgün hissediyorum',
      'gerildim',
      'sinirlendim',
      'yoruldum',
      'kırıldım',
      'sevindim',
      'mutluyum',
      'heyecanlıyım',
      'stresliyim',
      'bunaldım',
      'iyi hissetmiyorum',
    ]);
    final repairish = _containsAny(normalized, const [
      'anlamadım',
      'yanlış anladın',
      'yanlış oldu',
      'öyle demedim',
      'şunu demek istedim',
      'dur bir dakika',
      'dur bunu düzelt',
      'az önce dediğini anlamadım',
      'tekrar eder misin',
    ]);
    final backchannelish =
        _containsAny(normalized, const [
          'hmm',
          'hı hı',
          'evet',
          'tamam',
          'anladım',
          'haklısın',
          'devam et',
          'sürdür',
        ]) &&
        words.length <= 4;
    final socialish = _containsAny(normalized, const [
      'nasılsın',
      'orada mısın',
      'burada mısın',
      'beni duyuyor musun',
      'ne düşünüyorsun',
      'sence',
      'sohbet edelim',
      'benimle konuş',
      'bir şey soracağım',
      'bir şey diyeceğim',
      'hatırlıyor musun',
      'az önce dediğim',
      'neyi konuşuyorduk',
      'kaldığımız yer',
    ]);
    final thinkingish = _containsAny(normalized, const [
      'bence',
      'şöyle düşünüyorum',
      'sanırım',
      'galiba',
      'emin değilim',
      'nasıl desem',
      'bir ihtimal',
      'iki ihtimal',
    ]);

    if (commandish) {
      acts.add('command');
      isCommandLike = true;
      expectsResponse = true;
    }
    if (emotionish) {
      acts.add('emotion');
      isEmotionCue = true;
      expectsResponse = true;
    }
    if (repairish) {
      acts.add('repair');
      isRepairCue = true;
      expectsResponse = true;
      shouldKeepListening = true;
    }
    if (socialish) {
      acts.add('social');
      isSocialCue = true;
      expectsResponse = true;
    }
    if (backchannelish) {
      acts.add('backchannel');
      isBackchannelLike = true;
      expectsResponse = false;
      shouldKeepListening = true;
    }
    if (thinkingish) {
      acts.add('thinking_out_loud');
      expectsResponse = expectsResponse || hasQuestion || words.length >= 5;
    }
    if (hasQuestion && !acts.contains('question')) {
      acts.add('question');
      expectsResponse = true;
    }
    if (acts.isEmpty && words.length >= 4) {
      acts.add('conversation');
      expectsResponse =
          hasQuestion || socialish || emotionish || words.length >= 7;
      shouldKeepListening = !expectsResponse;
    }
    if (acts.isEmpty) {
      acts.add('acknowledgement');
      expectsResponse = false;
      shouldKeepListening = true;
    }

    final primary = acts.first;
    final confidence = isCommandLike
        ? 0.88
        : isRepairCue
        ? 0.82
        : isEmotionCue
        ? 0.78
        : isSocialCue
        ? 0.76
        : hasQuestion
        ? 0.74
        : isBackchannelLike
        ? 0.68
        : 0.61;

    return NovaConversationActDecision(
      primaryAct: primary,
      acts: acts,
      expectsResponse: expectsResponse,
      isCommandLike: isCommandLike,
      isSocialCue: isSocialCue,
      isEmotionCue: isEmotionCue,
      isRepairCue: isRepairCue,
      isBackchannelLike: isBackchannelLike,
      shouldKeepListening: shouldKeepListening,
      confidence: confidence,
    );
  }

  bool _containsAny(String normalized, List<String> needles) {
    for (final needle in needles) {
      if (normalized.contains(needle)) return true;
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
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^a-z0-9\s?]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
