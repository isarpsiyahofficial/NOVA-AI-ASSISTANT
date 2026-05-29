// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaKnowledgeDeduplicationService {
  const NovaKnowledgeDeduplicationService();

  static const int _minUsefulLength = 24;
  static const List<String> _blockedFragments = <String>[
    'ipucu 1',
    'ipucu 2',
    'ipucu 3',
    'varyant 1',
    'varyant 2',
    'varyant 3',
    'bilgi satırı 1',
    'bilgi satırı 2',
    'bilgi satırı 3',
    'yerel model anlatımı',
    'kaynak rehberi notu',
  ];

  List<String> sanitizeCorpus(String raw) {
    final lines = raw.split(RegExp(r'\r?\n'));
    final unique = <String>[];
    final seen = <String>{};
    for (final original in lines) {
      final cleaned = cleanLine(original);
      if (cleaned.isEmpty) continue;
      if (!_looksUseful(cleaned)) continue;
      final fp = fingerprint(cleaned);
      if (!seen.add(fp)) continue;
      unique.add(cleaned);
    }
    return unique;
  }

  String cleanLine(String line) {
    var out = line.trim();
    if (out.isEmpty) return '';
    out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
    out = out.replaceAll('•', '-');
    out = out.replaceAll('–', '-');
    out = out.replaceAll('—', '-');
    if (out.length < _minUsefulLength) return '';
    for (final fragment in _blockedFragments) {
      if (out.toLowerCase().contains(fragment)) {
        return '';
      }
    }
    if (RegExp(r'^(.)\1{6,}$', unicode: true).hasMatch(out)) {
      return '';
    }
    return out;
  }

  String fingerprint(String line) {
    final lowered = line.toLowerCase();
    final collapsed = lowered
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü\s]+', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final tokens = collapsed
        .split(' ')
        .where((token) => token.isNotEmpty && !_stopwords.contains(token))
        .toList(growable: false);
    if (tokens.isEmpty) return collapsed;
    final short = tokens.take(18).toList()..sort();
    return short.join('|');
  }

  List<NovaKnowledgeLineCandidate> rankForPrompt({
    required String prompt,
    required String domain,
    required List<String> lines,
    int maxItems = 12,
  }) {
    final tokens = _tokens(prompt);
    final scored = <NovaKnowledgeLineCandidate>[];
    for (final line in lines) {
      double score = 0;
      final lowered = line.toLowerCase();
      for (final token in tokens) {
        if (lowered.contains(token)) {
          score += 2.0;
        }
      }
      score += _domainHeuristic(domain, lowered);
      score += _informativenessBonus(line);
      if (score > 0) {
        scored.add(
          NovaKnowledgeLineCandidate(
            domain: domain,
            text: line,
            score: score,
            signature: fingerprint(line),
          ),
        );
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return _diversify(scored, maxItems: maxItems);
  }

  String sanitizeLine(String line) => cleanLine(line);

  List<NovaKnowledgeLineCandidate> rankLines({
    required String prompt,
    required String domain,
    required List<String> lines,
    int maxItems = 12,
  }) => rankForPrompt(
    prompt: prompt,
    domain: domain,
    lines: lines,
    maxItems: maxItems,
  );

  List<String> dedupe(List<String> lines, {int maxItems = 120}) {
    final cleaned = lines
        .map(cleanLine)
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    final ranked = rankForPrompt(
      prompt: '',
      domain: 'general',
      lines: cleaned,
      maxItems: maxItems,
    );
    return ranked.map((e) => e.text).toList(growable: false);
  }

  String buildPromptSection({
    required String prompt,
    required String domain,
    required List<String> lines,
    int maxItems = 8,
  }) {
    final ranked = rankForPrompt(
      prompt: prompt,
      domain: domain,
      lines: lines,
      maxItems: maxItems,
    );
    final out = <String>[
      '[TEKRARSIZ BİLGİ FİLTRESİ]',
      '- alan: $domain',
      '- giriş satırı: ${lines.length}',
      '- seçilen satır: ${ranked.length}',
      'Kural: Aynı bilgiyi varyant varyant tekrar etme; kısa, net ve farklı blokları kullan.',
    ];
    for (final item in ranked) {
      out.add(item.render());
    }
    return out.join('\n');
  }

  List<NovaKnowledgeLineCandidate> _diversify(
    List<NovaKnowledgeLineCandidate> items, {
    required int maxItems,
  }) {
    final out = <NovaKnowledgeLineCandidate>[];
    final seen = <String>{};
    final seenPrefixes = <String>{};
    for (final item in items) {
      if (!seen.add(item.signature)) continue;
      final prefix = _prefix(item.text);
      if (seenPrefixes.contains(prefix) && out.length > maxItems ~/ 2) {
        continue;
      }
      seenPrefixes.add(prefix);
      out.add(item);
      if (out.length >= maxItems) break;
    }
    return out;
  }

  double _domainHeuristic(String domain, String lowered) {
    switch (domain) {
      case 'cars':
        return _containsAny(lowered, const <String>[
              'car',
              'automobile',
              'sedan',
              'touring',
              'roadster',
              'coupe',
              'suv',
              'wagon',
              'pickup',
              'model',
            ])
            ? 1.3
            : 0.0;
      case 'automotive_mechanics':
        return _containsAny(lowered, const <String>[
              'engine',
              'motor',
              'transmission',
              'gear',
              'gearbox',
              'clutch',
              'ignition',
              'carburetor',
              'battery',
              'radiator',
              'cooling',
              'brake',
              'alternator',
            ])
            ? 1.45
            : 0.0;
      case 'cooking':
        return _containsAny(lowered, const <String>[
              'cook',
              'boil',
              'bake',
              'roast',
              'simmer',
              'oven',
              'ingredients',
              'sauce',
              'broth',
            ])
            ? 1.2
            : 0.0;
      case 'desserts':
        return _containsAny(lowered, const <String>[
              'dessert',
              'pudding',
              'pastry',
              'cream',
              'sugar',
              'chocolate',
              'custard',
              'syrup',
              'cake',
            ])
            ? 1.2
            : 0.0;
      case 'languages':
        return _containsAny(lowered, const <String>[
              'anlam',
              'kullanım',
              'örnek',
              'dil',
              'çeviri',
              'translation',
            ])
            ? 1.1
            : 0.0;
      default:
        return _containsAny(lowered, const <String>[
              'genel',
              'önce',
              'dikkat',
              'not',
              'temel',
            ])
            ? 0.7
            : 0.0;
    }
  }

  double _informativenessBonus(String line) {
    final length = line.length;
    if (length >= 120) return 1.1;
    if (length >= 80) return 0.8;
    if (length >= 50) return 0.4;
    return 0.0;
  }

  String _prefix(String line) {
    final cleaned = line.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9çğıöşü\s]+', unicode: true),
      ' ',
    );
    return cleaned.split(' ').where((e) => e.isNotEmpty).take(6).join(' ');
  }

  bool _containsAny(String text, List<String> items) {
    for (final item in items) {
      if (text.contains(item)) return true;
    }
    return false;
  }

  bool _looksUseful(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('lorem ipsum')) return false;
    if (RegExp(r'^\d+$').hasMatch(lower)) return false;
    if (RegExp(r'^[-–—]+$').hasMatch(lower)) return false;
    final words = lower.split(' ').where((w) => w.isNotEmpty).length;
    return words >= 4;
  }

  List<String> _tokens(String prompt) {
    return prompt
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü\s]+', unicode: true), ' ')
        .split(' ')
        .where((token) => token.length > 1 && !_stopwords.contains(token))
        .toList(growable: false);
  }

  static const Set<String> _stopwords = <String>{
    've',
    'ile',
    'ama',
    'gibi',
    'bir',
    'bu',
    'şu',
    'o',
    'mi',
    'mı',
    'mu',
    'mü',
    'da',
    'de',
    'ise',
    'için',
    'icin',
    'çok',
    'cok',
    'daha',
    'olan',
    'olarak',
    'veya',
    'ya',
    'the',
    'a',
    'an',
    'of',
    'to',
    'in',
    'on',
    'for',
    'is',
    'are',
    'be',
    'by',
    'or',
    'and',
  };
}

class NovaKnowledgeLineCandidate {
  final String domain;
  final String text;
  final double score;
  final String signature;

  const NovaKnowledgeLineCandidate({
    required this.domain,
    required this.text,
    required this.score,
    required this.signature,
  });

  String render() => '- [$domain ${score.toStringAsFixed(2)}] $text';
}
