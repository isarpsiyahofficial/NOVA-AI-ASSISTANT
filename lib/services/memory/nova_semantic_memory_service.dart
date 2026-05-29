// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:math' as math;

import '../../core/memory/nova_semantic_memory_record.dart';
import '../../core/memory/memory_item.dart';
import '../../core/memory/memory_types.dart';
import 'nova_embedding_service.dart';
import 'nova_faiss_bridge_service.dart';
import 'memory_service.dart';

class NovaSemanticMemoryService {
  final MemoryService memoryService;
  final NovaEmbeddingService embeddingService;
  final NovaFaissBridgeService bridgeService;

  const NovaSemanticMemoryService({
    this.memoryService = const MemoryService(),
    this.embeddingService = const NovaEmbeddingService(),
    this.bridgeService = const NovaFaissBridgeService(),
  });

  Future<List<MemoryItem>> search(String prompt, {int limit = 4}) {
    return selectRelevant(prompt, limit: limit);
  }

  Future<List<MemoryItem>> selectRelevant(
    String prompt, {
    int limit = 4,
  }) async {
    final cleanedPrompt = prompt.trim();
    if (cleanedPrompt.isEmpty) return const <MemoryItem>[];

    final all = await memoryService.getAll();
    if (all.isEmpty) return const <MemoryItem>[];

    final available = await bridgeService.isAvailable();
    if (!available) return const <MemoryItem>[];

    final created = await bridgeService.createIndex(
      dimension: NovaEmbeddingService.dimension,
      useCosine: true,
    );
    if (!created) return const <MemoryItem>[];

    final records = <NovaSemanticMemoryRecord>[];
    final payload = <Map<String, Object?>>[];
    for (var i = 0; i < all.length; i++) {
      final item = all[i];
      final numericId = i + 1;
      records.add(
        NovaSemanticMemoryRecord(
          numericId: numericId,
          sourceId: item.id,
          type: item.type.name,
          content: item.content,
          createdAt: item.createdAt,
        ),
      );
      payload.add(<String, Object?>{
        'id': numericId,
        'vector': embeddingService.embed(item.content),
      });
    }

    await bridgeService.replaceAll(payload);
    final results = await bridgeService.search(
      query: embeddingService.embed(cleanedPrompt),
      k: limit * 4,
    );
    if (results.isEmpty) return const <MemoryItem>[];

    final byNumericId = {
      for (final record in records) record.numericId: record,
    };
    final bySourceId = {for (final item in all) item.id: item};

    final scoredItems = <MapEntry<MemoryItem, double>>[];
    final seen = <String>{};
    for (final match in results) {
      final score = (match['score'] as num?)?.toDouble() ?? 0.0;
      if (!_isScoreRelevant(cleanedPrompt, score)) continue;

      final rawId = match['id'];
      final numericId = rawId is int ? rawId : int.tryParse('$rawId');
      if (numericId == null) continue;
      final record = byNumericId[numericId];
      if (record == null) continue;
      final item = bySourceId[record.sourceId];
      if (item == null) continue;
      if (!_isContentRelevant(cleanedPrompt, item.content)) continue;
      if (!seen.add(item.id)) continue;
      final lexical = _lexicalRelevance(cleanedPrompt, item.content);
      final recency = _recencyBoost(item.createdAt);
      final finalScore = score + lexical + recency;
      scoredItems.add(MapEntry(item, finalScore));
    }

    scoredItems.sort((a, b) => b.value.compareTo(a.value));
    return scoredItems.take(limit).map((e) => e.key).toList(growable: false);
  }

  Future<void> remember({
    required String topicKey,
    required String summary,
    List<String> tags = const <String>[],
    double importance = 0.56,
  }) async {
    final cleanedSummary = summary.trim();
    if (cleanedSummary.isEmpty) return;
    if (_shouldSkipStorage(cleanedSummary)) return;

    final cleanedTopic = topicKey.trim();
    final normalizedTags = tags
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final buffer = StringBuffer();
    if (cleanedTopic.isNotEmpty) {
      buffer.write('[konu:$cleanedTopic] ');
    }
    buffer.write(cleanedSummary);
    if (normalizedTags.isNotEmpty) {
      buffer.write(' | etiketler: ${normalizedTags.join(', ')}');
    }
    buffer.write(' | önem: ${importance.toStringAsFixed(2)}');
    final candidate = buffer.toString();

    final existing = await memoryService.getAll();
    final now = DateTime.now();
    final normalizedCandidate = _normalizeForDuplicateCheck(candidate);
    for (final item in existing.take(80)) {
      final age = now.difference(item.createdAt);
      final normalizedExisting = _normalizeForDuplicateCheck(item.content);
      final overlap = _tokenOverlap(
        _keywords(normalizedCandidate),
        _keywords(normalizedExisting),
      );
      final exactlySame = normalizedExisting == normalizedCandidate;
      final veryClose = overlap >= 0.86;
      if ((exactlySame || veryClose) && age <= const Duration(days: 3)) {
        return;
      }
    }

    final type = importance >= 0.84
        ? MemoryType.permanent
        : MemoryType.contextual;
    final ttl = type == MemoryType.permanent
        ? null
        : (importance >= 0.68
              ? const Duration(days: 7)
              : const Duration(days: 3));
    await memoryService.add(type: type, content: candidate, ttl: ttl);
  }

  bool _isScoreRelevant(String prompt, double score) {
    final shortPrompt = prompt.split(' ').length <= 3;
    final threshold = shortPrompt ? 0.16 : 0.10;
    return score >= threshold;
  }

  bool _isContentRelevant(String prompt, String content) {
    final promptWords = _keywords(prompt);
    if (promptWords.isEmpty) return false;
    final contentWords = _keywords(content);
    if (contentWords.isEmpty) return false;
    final overlap = promptWords.intersection(contentWords).length;
    if (overlap >= 2) return true;
    if (overlap == 1 && promptWords.length <= 3) return true;
    final similarity = _tokenOverlap(promptWords, contentWords);
    return similarity >= 0.34;
  }

  Set<String> _keywords(String value) {
    final normalized = value.toLowerCase();
    return normalized
        .split(RegExp(r'''[\s,.;:!?()\[\]{}"'`“”‘’/\\|<>+=*~#%@^&_-]+'''))
        .map((e) => e.trim())
        .where((e) => e.length >= 2)
        .where((e) => !_noiseWords.contains(e))
        .toSet();
  }

  double _tokenOverlap(Set<String> left, Set<String> right) {
    if (left.isEmpty || right.isEmpty) return 0.0;
    final common = left.intersection(right).length;
    final base = left.length > right.length ? left.length : right.length;
    return common / base;
  }

  double _lexicalRelevance(String prompt, String content) {
    final promptWords = _keywords(prompt);
    final contentWords = _keywords(content);
    if (promptWords.isEmpty || contentWords.isEmpty) return 0.0;
    final overlap = promptWords.intersection(contentWords).length;
    final base = math.max(promptWords.length, contentWords.length);
    return (overlap / base).clamp(0.0, 1.0) * 0.45;
  }

  double _recencyBoost(DateTime createdAt) {
    final age = DateTime.now().difference(createdAt);
    if (age <= const Duration(hours: 6)) return 0.18;
    if (age <= const Duration(days: 1)) return 0.12;
    if (age <= const Duration(days: 3)) return 0.08;
    if (age <= const Duration(days: 7)) return 0.04;
    return 0.0;
  }

  bool _shouldSkipStorage(String text) {
    final normalized = text.toLowerCase();
    if (normalized.length < 12) return true;
    if (normalized.contains('tamam efendim') && normalized.length < 50)
      return true;
    if (normalized.contains('buyurun efendim') && normalized.length < 50)
      return true;
    if (normalized.contains('komutunuz alındı') && normalized.length < 64)
      return true;
    if (normalized.contains('sizi dinliyorum') && normalized.length < 72)
      return true;
    if (normalized.contains('durum raporu efendim') && normalized.length < 120)
      return true;
    return false;
  }

  String _normalizeForDuplicateCheck(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

const Set<String> _noiseWords = <String>{
  'nova',
  'efendim',
  'bunu',
  'şunu',
  'sunu',
  'beni',
  'bana',
  'için',
  'icin',
  'ile',
  'gibi',
  'olan',
  've',
  'ama',
  'daha',
  'sonra',
  'önce',
  'once',
};
