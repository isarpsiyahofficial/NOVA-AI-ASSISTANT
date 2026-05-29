// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaSpokenQualityEvalTrDecision {
  final bool soundsTooTexty;
  final bool hasHealthyPauses;
  final bool supportsDiscourseMarkers;
  final String styleVerdict;
  final double humanLikenessScore;
  final List<String> observations;
  final List<String> fixes;

  const NovaSpokenQualityEvalTrDecision({
    required this.soundsTooTexty,
    required this.hasHealthyPauses,
    required this.supportsDiscourseMarkers,
    required this.styleVerdict,
    required this.humanLikenessScore,
    required this.observations,
    required this.fixes,
  });

  String buildPromptSection() => <String>[
    'KONUŞMA KALİTESİ TR:',
    '- fazlaYazı=$soundsTooTexty',
    '- sağlıklıDurak=$hasHealthyPauses',
    '- söylemDesteği=$supportsDiscourseMarkers',
    '- insanBenzerliği=${humanLikenessScore.toStringAsFixed(2)}',
    '- yorum=$styleVerdict',
    if (observations.isNotEmpty) '- gözlem: ${observations.join(' | ')}',
    if (fixes.isNotEmpty) '- düzeltme: ${fixes.join(' | ')}',
  ].join('\n');
}

class NovaSpokenQualityEvalTrService {
  const NovaSpokenQualityEvalTrService();

  NovaSpokenQualityEvalTrDecision evaluate(String text) {
    final lower = text.toLowerCase();
    final texty =
        lower.contains('bu bağlamda') ||
        lower.contains('bununla birlikte') ||
        lower.contains('ifade etmek gerekirse');
    final healthyPauses =
        text.contains('.') ||
        text.contains(',') ||
        text.contains(';') ||
        text.contains('...');
    final discourse = [
      'şey',
      'hani',
      'tamam da',
      'yani',
      'aslında',
    ].any(lower.contains);
    final observations = <String>[];
    final fixes = <String>[];
    if (texty) {
      observations.add('yazı dili ağır basıyor');
      fixes.add('bağlaç yoğunluğunu azalt');
      fixes.add('daha kısa cümleler kur');
    } else {
      observations.add('konuşma-benzer akış korunuyor');
    }
    if (healthyPauses) {
      observations.add('durak yapısı okunabilir');
    } else {
      fixes.add('durak ve nefes işaretleri ekle');
    }
    if (discourse) {
      observations.add('söylem belirteçleri mevcut');
    } else {
      fixes.add('bağlama uygunsa hafif söylem belirteci kullanılabilir');
    }
    final verdict = texty
        ? 'fazla yazı gibi, konuşma kırılmalı'
        : (healthyPauses ? 'konuşma-benzer akış iyi' : 'durak desteği zayıf');
    final score = _score(
      texty: texty,
      healthyPauses: healthyPauses,
      discourse: discourse,
    );
    return NovaSpokenQualityEvalTrDecision(
      soundsTooTexty: texty,
      hasHealthyPauses: healthyPauses,
      supportsDiscourseMarkers: discourse,
      styleVerdict: verdict,
      humanLikenessScore: score,
      observations: observations,
      fixes: fixes,
    );
  }

  double _score({
    required bool texty,
    required bool healthyPauses,
    required bool discourse,
  }) {
    var out = 0.35;
    if (!texty) out += 0.30;
    if (healthyPauses) out += 0.20;
    if (discourse) out += 0.15;
    return out.clamp(0.0, 1.0);
  }
}
