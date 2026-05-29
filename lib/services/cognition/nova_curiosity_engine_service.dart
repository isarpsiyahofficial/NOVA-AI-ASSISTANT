// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/cognition/nova_curiosity_signal.dart';

class NovaCuriosityEngineService {
  const NovaCuriosityEngineService();

  NovaCuriositySignal inspect(String prompt) {
    final normalized = prompt.toLowerCase().trim();

    var score = 8;
    var reason = 'Takip sorusu gerekmiyor.';

    final hasOpenNeed = _containsAny(normalized, const [
      'neden',
      'nasıl',
      'nasil',
      'sence',
      'kararsızım',
      'kararsizim',
      'emin değilim',
      'emin degilim',
      'bilmiyorum',
      'ne dersin',
    ]);
    if (hasOpenNeed) {
      score += 28;
      reason = 'Açık uçlu bir ihtiyaç var.';
    }

    final hasEmotionalWindow = _containsAny(normalized, const [
      'üzgün',
      'uzgun',
      'bunaldım',
      'bunaldim',
      'yorgunum',
      'kafam karışık',
      'kafam karisik',
      'moralim bozuk',
    ]);
    if (hasEmotionalWindow) {
      score += 24;
      reason = 'Duygusal bir açıklık var; nazik takip sorusu doğal olabilir.';
    }

    final hasSocialInvite = _containsAny(normalized, const [
      'sen ne dersin',
      'sence',
      'katıl',
      'katil',
      'sohbete katıl',
      'sohbete katil',
      'tanış',
      'tanis',
      'bizimle',
      'aramıza',
      'aramiza',
    ]);
    if (hasSocialInvite) {
      score += 22;
      reason = 'Konuşmaya davet veya sosyal açıklık seziliyor.';
    }

    final shouldBeQuiet = _containsAny(normalized, const [
      'tamam',
      'oldu',
      'yeter',
      'kapat',
      'sus',
      'bekle',
      'daha fazla sorma',
      'soru sorma',
    ]);
    if (shouldBeQuiet) {
      score -= 40;
      reason = 'Kullanıcı alan istiyor; merak geri çekilmeli.';
    }

    if (_containsAny(normalized, const [
      'devam',
      'yarım kaldı',
      'yarim kaldi',
      'oradan devam',
      'kaldığımız yer',
      'kaldigimiz yer',
    ])) {
      score += 16;
      reason = 'Önceki konuya dönmek için kısa takip yararlı olabilir.';
    }

    score = score.clamp(0, 100);
    return NovaCuriositySignal(prompt: reason, score: score);
  }

  String buildPromptSection(String prompt) {
    final signal = inspect(prompt);
    final curiosityAllowed = signal.score >= 42;
    return [
      'KONTROLLÜ MERAK MOTORU:',
      '- skor: ${signal.score}',
      '- özet: ${signal.prompt}',
      '- merak izni: ${curiosityAllowed ? 'uygun' : 'şimdilik geri planda'}',
      '- kural: Merak doğal, kısa, güvenli ve bağlama hizmet eden bir soru şeklinde çıkmalı.',
      '- kural: Art arda soru yağmuru yapma; aynı turda en fazla bir kısa merak sorusu.',
      '- kural: Komut baskınsa veya kullanıcı kapanış veriyorsa merakı sustur.',
      '- kural: Merak öğrenme amacı taşıyorsa owner izni veya doğal sosyal davet sinyali olmadan ilişki bilgisi kazımaya çalışma.',
    ].join('\n');
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }
}
