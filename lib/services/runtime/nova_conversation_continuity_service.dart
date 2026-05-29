// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NovaConversationContinuityService {
  static const String _storageKey = 'nova_conversation_continuity_v1';
  static const int _maxTurns = 10;

  const NovaConversationContinuityService();

  Future<Map<String, dynamic>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) return _empty();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return _empty();
      return decoded;
    } catch (_) {
      return _empty();
    }
  }

  Future<void> rememberExchange({
    required String userText,
    required String novaReply,
  }) async {
    final current = await load();
    final turns = (current['turns'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList(growable: true);
    turns.insert(0, <String, dynamic>{
      'user': userText.trim(),
      'nova': novaReply.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    final highlights = _extractHighlights(userText, novaReply);
    final openQuestion = _extractOpenQuestion(userText, novaReply);

    final next = <String, dynamic>{
      'turns': turns.take(_maxTurns).toList(growable: false),
      'highlights': highlights,
      'openQuestion': openQuestion,
      'lastUserText': userText.trim(),
      'lastNovaReply': novaReply.trim(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(next));
  }

  String buildPromptSection(Map<String, dynamic> snapshot) {
    final highlights =
        (snapshot['highlights'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .join(' | ');
    final openQuestion = (snapshot['openQuestion'] as String? ?? '').trim();
    final lastUser = (snapshot['lastUserText'] as String? ?? '').trim();
    final lastNova = (snapshot['lastNovaReply'] as String? ?? '').trim();

    return [
      'KONUŞMA SÜREKLİLİĞİ:',
      '- son kullanıcı izi: ${lastUser.isEmpty ? 'yok' : lastUser}',
      '- son Nova izi: ${lastNova.isEmpty ? 'yok' : lastNova}',
      '- önemli vurgular: ${highlights.isEmpty ? 'yok' : highlights}',
      '- açık kalan soru: ${openQuestion.isEmpty ? 'yok' : openQuestion}',
      'KURAL: Mesaj → cevap kırığını bırakma; yarım kalan konu varsa uygun yerde taşı.',
      'KURAL: “az önce dediğin”, “orada kaldığımız yer” gibi doğal süreklilik işaretlerini sadece gerçekten bağ varsa kullan.',
    ].join('\n');
  }

  Map<String, dynamic> _empty() => <String, dynamic>{
    'turns': const <Map<String, dynamic>>[],
    'highlights': const <String>[],
    'openQuestion': '',
    'lastUserText': '',
    'lastNovaReply': '',
  };

  List<String> _extractHighlights(String userText, String reply) {
    final text = '${userText.trim()} ${reply.trim()}';
    final parts = text
        .split(RegExp(r'[.!?]'))
        .map((e) => e.trim())
        .where((e) => e.split(RegExp(r'\s+')).length >= 4)
        .take(3)
        .toList(growable: false);
    return parts;
  }

  String _extractOpenQuestion(String userText, String reply) {
    if (userText.trim().endsWith('?')) return userText.trim();
    final candidate = _novaSplitAfterSentencePunctuation(reply)
        .map((e) => e.trim())
        .where((e) => e.endsWith('?'))
        .firstWhere((_) => true, orElse: () => '');
    return candidate;
  }
}

List<String> _novaSplitAfterSentencePunctuation(String text) {
  if (text.trim().isEmpty) return <String>[];
  const marker = '\u0000NOVA_SENTENCE_BREAK\u0000';
  return text
      .replaceAllMapped(RegExp(r'([.!?])\s+'), (m) => '${m.group(1)}$marker')
      .split(marker);
}
