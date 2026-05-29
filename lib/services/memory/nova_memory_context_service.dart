// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/cognition/nova_emotion_state.dart';
import '../../core/memory/memory_item.dart';
import 'nova_semantic_memory_service.dart';
import 'memory_service.dart' show MemoryService;

class NovaMemoryContextService {
  final MemoryService memoryService;
  final NovaSemanticMemoryService semanticMemoryService;

  const NovaMemoryContextService({
    this.memoryService = const MemoryService(),
    this.semanticMemoryService = const NovaSemanticMemoryService(),
  });

  Future<List<MemoryItem>> selectRelevant(String prompt) async {
    final semantic = await semanticMemoryService.selectRelevant(prompt);
    if (semantic.isNotEmpty) return semantic;

    final all = await memoryService.getAll();
    if (all.isEmpty) return const <MemoryItem>[];

    final normalized = _normalize(prompt);
    final scored = <_ScoredMemory>[];
    for (final item in all) {
      final score = _score(item, normalized);
      if (score > 0) {
        scored.add(_ScoredMemory(item: item, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(4).map((e) => e.item).toList(growable: false);
  }

  Future<String> buildPromptContext(
    List<MemoryItem> memories, {
    List<MemoryItem> semanticMatches = const <MemoryItem>[],
    NovaEmotionState? emotion,
    String latestPrompt = '',
  }) async {
    final normalizedPrompt = latestPrompt.trim();
    final semanticOnly = <MemoryItem>[];
    final memoryIds = memories.map((e) => e.id).toSet();
    for (final item in semanticMatches) {
      if (!memoryIds.contains(item.id)) {
        semanticOnly.add(item);
      }
    }

    if (memories.isEmpty && semanticOnly.isEmpty && emotion == null) {
      return 'İLGİLİ HAFIZA BAĞLAMI: Şu an yüksek ilişkili kayıt bulunamadı.';
    }

    final buffer = StringBuffer()
      ..writeln('İLGİLİ HAFIZA BAĞLAMI:')
      ..writeln(
        '- Kullanıcıyla ilgili yalnız gerçekten ilişkili kayıtları kullan.',
      );

    if (normalizedPrompt.isNotEmpty) {
      buffer.writeln('- Son kullanıcı girdisi: $normalizedPrompt');
    }

    if (emotion != null) {
      buffer.writeln(
        '- Duygu izi: baskın=${emotion.dominantEmotion}, yoğunluk=${emotion.intensity.toStringAsFixed(2)}, denge=${emotion.stability.toStringAsFixed(2)}, yardım ihtiyacı=${emotion.empathyNeed.toStringAsFixed(2)}',
      );
    }

    for (final item in memories) {
      buffer.writeln('- [${item.type.name}] ${item.content}');
    }

    if (semanticOnly.isNotEmpty) {
      buffer.writeln('- Anlamsal eşleşmeler:');
      for (final item in semanticOnly) {
        buffer.writeln('- [${item.type.name}] ${item.content}');
      }
    }

    return buffer.toString().trimRight();
  }

  int _score(MemoryItem item, String normalizedPrompt) {
    final memoryText = _normalize(item.content);
    if (memoryText.isEmpty) return 0;
    if (memoryText == normalizedPrompt) return 120;
    if (normalizedPrompt.contains(memoryText) ||
        memoryText.contains(normalizedPrompt)) {
      return 90;
    }

    final promptWords = normalizedPrompt
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toSet();
    final memoryWords = memoryText
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toSet();
    final overlap = promptWords.intersection(memoryWords).length;
    var score = overlap * 12;
    if (item.type.name == 'permanent') score += 10;
    if (item.type.name == 'contextual') score += 4;
    return score;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _ScoredMemory {
  final MemoryItem item;
  final int score;

  const _ScoredMemory({required this.item, required this.score});
}
