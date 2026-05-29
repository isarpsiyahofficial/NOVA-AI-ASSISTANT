// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NovaAdaptiveInstructionService {
  static const String _persistentKey =
      'nova_adaptive_persistent_instruction_v1';
  static const String _sessionKey = 'nova_adaptive_session_instruction_v1';

  const NovaAdaptiveInstructionService();

  Future<void> setPersistentInstruction(String instruction) async {
    final cleaned = _clean(instruction);
    if (cleaned.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_persistentKey, cleaned);
  }

  Future<void> setSessionInstruction(String instruction) async {
    final cleaned = _clean(instruction);
    if (cleaned.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, cleaned);
  }

  Future<String> getPersistentInstruction() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_persistentKey) ?? '').trim();
  }

  Future<String> getSessionInstruction() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_sessionKey) ?? '').trim();
  }

  Future<void> clearSessionInstruction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_persistentKey);
    await prefs.remove(_sessionKey);
  }

  Future<String> buildPromptSection() async {
    final persistent = await getPersistentInstruction();
    final session = await getSessionInstruction();
    final parts = <String>[];
    if (persistent.isNotEmpty) {
      parts.add(
        'KALICI ÖĞRETİM: Kullanıcı bundan sonra şu davranışı tercih ediyor: $persistent',
      );
    }
    if (session.isNotEmpty) {
      parts.add(
        'BU SEFERLİK ÖĞRETİM: Yalnız mevcut istek için şu çalışma tarzını uygula: $session',
      );
    }
    return parts.join('\n');
  }

  bool looksLikePersistentTeaching(String raw) {
    final n = _normalize(raw);
    return n.contains('bundan sonra') ||
        n.contains('artik boyle yap') ||
        n.contains('artık böyle yap') ||
        n.contains('bundan sonra boyle davran') ||
        n.contains('cagri sistemlerinde degisiklik yapicaz') ||
        n.contains('çağrı sistemlerinde değişiklik yapacağız');
  }

  bool looksLikeSessionTeaching(String raw) {
    final n = _normalize(raw);
    return n.contains('bu seferlik') ||
        n.contains('sadece bu sefer') ||
        n.contains('bu kerelik') ||
        n.contains('simdilik boyle yap') ||
        n.contains('şimdilik böyle yap');
  }

  bool looksLikeTeachingReset(String raw) {
    final n = _normalize(raw);
    return n.contains('ogretilmis sistemi sil') ||
        n.contains('öğretilmiş sistemi sil') ||
        n.contains('varsayilana dondur') ||
        n.contains('varsayılana döndür') ||
        n.contains('ogrenilen davranislari sil') ||
        n.contains('öğrenilen davranışları sil');
  }

  String extractInstructionBody(String raw) {
    var text = raw.trim();
    final lower = _normalize(text);
    for (final marker in const [
      'bundan sonra',
      'bu seferlik',
      'sadece bu sefer',
      'bu kerelik',
      'şimdilik',
      'simdilik',
    ]) {
      final idx = lower.indexOf(_normalize(marker));
      if (idx >= 0) {
        text = text.substring(idx + marker.length).trim();
        break;
      }
    }
    return _clean(text);
  }

  String _clean(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
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
        .replaceAll('ü', 'u');
  }
}
