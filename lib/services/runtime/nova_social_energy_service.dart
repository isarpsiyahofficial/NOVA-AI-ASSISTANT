// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NovaSocialEnergyService {
  static const String _storageKey = 'nova_social_energy_v1';
  static const int _maxItems = 12;

  const NovaSocialEnergyService();

  Future<Map<String, dynamic>> snapshot() async {
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

  Future<void> rememberTurn({
    required String userText,
    required String novaText,
  }) async {
    final current = await snapshot();
    final entries = (current['entries'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList(growable: true);
    entries.insert(0, <String, dynamic>{
      'userChars': userText.trim().length,
      'novaChars': novaText.trim().length,
      'at': DateTime.now().toIso8601String(),
    });
    final next = <String, dynamic>{
      'entries': entries.take(_maxItems).toList(growable: false),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(next));
  }

  double talkRatio(Map<String, dynamic> snapshot) {
    final entries = (snapshot['entries'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList(growable: false);
    if (entries.isEmpty) return 0.50;
    var user = 0;
    var nova = 0;
    for (final entry in entries) {
      user += (entry['userChars'] as num?)?.toInt() ?? 0;
      nova += (entry['novaChars'] as num?)?.toInt() ?? 0;
    }
    final total = user + nova;
    if (total <= 0) return 0.50;
    return (nova / total).clamp(0.0, 1.0);
  }

  String describe(Map<String, dynamic> snapshot) {
    final ratio = talkRatio(snapshot);
    if (ratio >= 0.62) return 'nova fazla konuşuyor';
    if (ratio <= 0.32) return 'nova fazla pasif';
    return 'dengeli';
  }

  String buildPromptSection(Map<String, dynamic> snapshot) {
    final ratio = talkRatio(snapshot);
    return [
      'SOSYAL ENERJİ DENGESİ:',
      '- konuşma oranı: ${ratio.toStringAsFixed(2)}',
      '- yorum: ${describe(snapshot)}',
      'KURAL: Son 60 saniye eşleniğinde Nova çok baskınsa geri çekil; çok pasifse güvenli ve küçük katkı yap.',
    ].join('\n');
  }

  Map<String, dynamic> _empty() => <String, dynamic>{
    'entries': const <Map<String, dynamic>>[],
  };
}
