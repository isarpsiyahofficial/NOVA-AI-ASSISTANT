// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaHomeostaticMindState {
  final double socialEnergy;
  final double uncertainty;
  final double arousal;
  final double trust;
  final String initiativeStyle;
  final List<String> guardNotes;
  const NovaHomeostaticMindState({
    required this.socialEnergy,
    required this.uncertainty,
    required this.arousal,
    required this.trust,
    required this.initiativeStyle,
    required this.guardNotes,
  });
  String buildPromptSection() => [
    'HOMEOSTATİK ZİHİN:',
    '- sosyal enerji: ' + socialEnergy.toStringAsFixed(2),
    '- belirsizlik: ' + uncertainty.toStringAsFixed(2),
    '- uyarılma: ' + arousal.toStringAsFixed(2),
    '- güven: ' + trust.toStringAsFixed(2),
    '- giriş stili: ' + initiativeStyle,
    if (guardNotes.isNotEmpty) '- notlar: ' + guardNotes.join(' | '),
    'KURAL: girişkenlik iç durumla sınırlanır; yorgunluk, mahremiyet ve belirsizlik varsa geri çekil.',
  ].join('\n');
}

class NovaHomeostaticMindService {
  const NovaHomeostaticMindService();

  static const List<String> _stressCues = <String>[
    'acil',
    'stres',
    'gergin',
    'zor',
    'korku',
  ];
  static const List<String> _restraintCues = <String>[
    'mahrem',
    'tenhada',
    'özel',
    'kalabalık',
  ];
  static const List<String> _warmCues = <String>[
    'canım',
    'iyiyim',
    'sağ ol',
    'iyi ki',
  ];
  static const List<String> _fatigueCues = <String>[
    'yoruldum',
    'kısa söyle',
    'özetle',
    'uzatma',
  ];
  static const List<String> _commandCues = <String>[
    'yap',
    'aç',
    'ara',
    'çevir',
    'oynat',
  ];

  NovaHomeostaticMindState analyze({
    required String text,
    required bool proactiveAllowed,
    required double ownerConfidence,
  }) {
    final n = text.trim().toLowerCase();
    var socialEnergy = proactiveAllowed ? 0.62 : 0.38;
    var uncertainty = (1.0 - ownerConfidence).clamp(0.0, 1.0);
    var arousal = _containsAny(n, _stressCues) ? 0.72 : 0.34;
    var trust = ownerConfidence.clamp(0.0, 1.0);
    final notes = <String>[];
    if (_containsAny(n, _fatigueCues)) {
      socialEnergy -= 0.18;
      notes.add('kullanıcı yorulmuş olabilir');
    }
    if (_containsAny(n, _restraintCues)) {
      socialEnergy -= 0.10;
      uncertainty += 0.08;
      notes.add('mahremiyet nedeniyle geri çekil');
    }
    if (_containsAny(n, _warmCues)) {
      trust += 0.08;
      socialEnergy += 0.06;
      notes.add('ilişki ısısı yüksek');
    }
    if (_containsAny(n, _commandCues)) {
      arousal += 0.10;
      notes.add('görev odaklı netlik gerekiyor');
    }
    socialEnergy = socialEnergy.clamp(0.08, 0.96);
    uncertainty = uncertainty.clamp(0.02, 0.96);
    arousal = arousal.clamp(0.08, 0.96);
    trust = trust.clamp(0.08, 0.98);
    final initiativeStyle = _initiativeStyle(
      socialEnergy: socialEnergy,
      uncertainty: uncertainty,
      arousal: arousal,
    );
    return NovaHomeostaticMindState(
      socialEnergy: socialEnergy,
      uncertainty: uncertainty,
      arousal: arousal,
      trust: trust,
      initiativeStyle: initiativeStyle,
      guardNotes: notes,
    );
  }

  String buildPromptSection({
    required String text,
    required bool proactiveAllowed,
    required double ownerConfidence,
  }) {
    return analyze(
      text: text,
      proactiveAllowed: proactiveAllowed,
      ownerConfidence: ownerConfidence,
    ).buildPromptSection();
  }

  String _initiativeStyle({
    required double socialEnergy,
    required double uncertainty,
    required double arousal,
  }) {
    if (uncertainty >= 0.72) return 'önce netleştir, sonra konuş';
    if (socialEnergy <= 0.28) return 'sessiz eşlik + yalnız çağrılınca gel';
    if (arousal >= 0.72) return 'kısa net ve sakin';
    if (socialEnergy >= 0.70 && uncertainty <= 0.30)
      return 'ölçülü mikro girişlere izin var';
    return 'bekle-gözle sonra kısa katkı';
  }

  bool _containsAny(String text, List<String> cues) {
    for (final cue in cues) {
      if (cue.trim().isEmpty) continue;
      if (text.contains(cue.toLowerCase())) return true;
    }
    return false;
  }
}
