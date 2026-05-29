// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:math' as math;

class NovaEmbeddingService {
  static const int dimension = 128;

  const NovaEmbeddingService();

  List<double> embed(String input) {
    final normalized = _normalize(input);
    final vector = List<double>.filled(dimension, 0.0, growable: false);
    if (normalized.isEmpty) return vector;

    final tokenWeights = _tokenWeights(normalized);
    if (tokenWeights.isEmpty) return vector;

    for (final entry in tokenWeights.entries) {
      final token = entry.key;
      final weight = entry.value;
      _accumulate(vector, token, weight * 1.9);

      for (final gram in _charGrams(token)) {
        _accumulate(vector, gram, weight * 0.9);
      }

      final stems = _softStems(token);
      for (final stem in stems) {
        if (stem != token) {
          _accumulate(vector, stem, weight * 0.55);
        }
      }
    }

    _normalizeVector(vector);
    return vector;
  }

  Map<String, double> _tokenWeights(String value) {
    final weights = <String, double>{};
    final tokens = value.split(' ').where((e) => e.trim().isNotEmpty);
    for (final token in tokens) {
      if (token.length < 2) continue;
      final isImportant = !_stopWords.contains(token);
      final base = isImportant ? 1.0 : 0.22;
      final boosted = _boostForIntentToken(token, base);
      weights[token] = (weights[token] ?? 0.0) + boosted;
    }
    return weights;
  }

  double _boostForIntentToken(String token, double value) {
    if (_commandTokens.contains(token)) return value * 1.45;
    if (_memoryTokens.contains(token)) return value * 1.55;
    if (_emotionTokens.contains(token)) return value * 1.35;
    return value;
  }

  List<String> _charGrams(String value) {
    if (value.length <= 3) return <String>[value];
    final out = <String>[];
    for (var size = 3; size <= 4; size++) {
      if (value.length < size) continue;
      for (var i = 0; i <= value.length - size; i++) {
        out.add(value.substring(i, i + size));
      }
    }
    return out;
  }

  List<String> _softStems(String value) {
    final out = <String>{value};
    final suffixes = <String>[
      'leri',
      'ları',
      'lerin',
      'ların',
      'lerden',
      'lardan',
      'lere',
      'lara',
      'leri',
      'ları',
      'den',
      'dan',
      'ten',
      'tan',
      'dir',
      'dır',
      'dur',
      'dür',
      'tir',
      'tır',
      'tur',
      'tür',
      'im',
      'ım',
      'um',
      'üm',
      'sin',
      'sın',
      'sun',
      'sün',
      'iyor',
      'iyorlar',
      'mak',
      'mek',
      'miş',
      'mış',
      'muş',
      'müş',
      'lik',
      'lık',
      'luk',
      'lük',
      'ci',
      'cı',
      'cu',
      'cü',
      'si',
      'sı',
      'su',
      'sü',
      'yi',
      'yı',
      'yu',
      'yü',
      'i',
      'ı',
      'u',
      'ü',
      'e',
      'a',
    ];
    for (final suffix in suffixes) {
      if (value.length - suffix.length < 3) continue;
      if (value.endsWith(suffix)) {
        out.add(value.substring(0, value.length - suffix.length));
      }
    }
    return out.toList(growable: false);
  }

  void _accumulate(List<double> vector, String token, double weight) {
    final hashA = token.hashCode;
    final hashB = Object.hash(token, token.length, 'nova');
    final hashC = Object.hash(token, 'semantic', token.codeUnitAt(0));

    final indexA = hashA.abs() % dimension;
    final indexB = hashB.abs() % dimension;
    final indexC = hashC.abs() % dimension;

    vector[indexA] += ((hashA & 1) == 0 ? 1.0 : -1.0) * weight;
    vector[indexB] += ((hashB & 1) == 0 ? 0.75 : -0.75) * weight;
    vector[indexC] += ((hashC & 1) == 0 ? 0.5 : -0.5) * weight;
  }

  void _normalizeVector(List<double> vector) {
    var norm = 0.0;
    for (final value in vector) {
      norm += value * value;
    }
    if (norm <= 0.0) return;
    final scale = 1.0 / math.sqrt(norm);
    for (var i = 0; i < vector.length; i++) {
      vector[i] = vector[i] * scale;
    }
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

const Set<String> _commandTokens = <String>{
  'ara',
  'aç',
  'ac',
  'kapat',
  'başlat',
  'baslat',
  'durdur',
  'gönder',
  'gonder',
  'hatırlat',
  'hatirlat',
  'uyandır',
  'uyandir',
  'açtır',
  'acilir',
  'çal',
  'cal',
};

const Set<String> _memoryTokens = <String>{
  'hatırla',
  'hatirla',
  'unutma',
  'geçen',
  'onceki',
  'önceki',
  'konu',
  'mesele',
  'kaldığımız',
  'kaldigimiz',
  'devam',
  'geri',
  'dön',
  'don',
};

const Set<String> _emotionTokens = <String>{
  'üzgün',
  'uzgun',
  'sinirli',
  'öfke',
  'ofke',
  'mutlu',
  'rahat',
  'bunaldım',
  'bunaldim',
  'yoruldum',
  'kırıldım',
  'kirildim',
};

const Set<String> _stopWords = <String>{
  've',
  'ile',
  'ama',
  'gibi',
  'için',
  'icin',
  'olan',
  'olanı',
  'olani',
  'bunu',
  'bana',
  'beni',
  'benim',
  'senin',
  'sana',
  'sen',
  'nova',
  'şunu',
  'sunu',
  'böyle',
  'boyle',
  'şöyle',
  'soyle',
  'bir',
  'iki',
  'üç',
  'uc',
  'daha',
  'çok',
  'cok',
  'kadar',
  'göre',
  'gore',
  'sonra',
  'önce',
  'once',
  'mi',
  'mı',
  'mu',
  'mü',
  'bu',
  'şu',
  'su',
  'o',
  'da',
  'de',
  'ki',
  'veya',
  'ya',
  'hem',
};
