// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:shared_preferences/shared_preferences.dart';

class NovaPlaybackEchoFilterService {
  static const String _activeKey = 'nova_voice_auth_synthetic_active_v1';
  static const String _lastEndKey = 'nova_voice_auth_synthetic_last_end_v1';
  static const Duration _cooldown = Duration(milliseconds: 2600);
  static const String _tamperCountKey =
      'nova_voice_auth_synthetic_tamper_count_v1';
  static const String _lastTextKey = 'nova_voice_auth_synthetic_last_text_v1';
  static const String _lastTextAtKey =
      'nova_voice_auth_synthetic_last_text_at_v1';

  const NovaPlaybackEchoFilterService();

  Future<void> markPlaybackStarted({String spokenText = ''}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_activeKey, true);
      final normalized = _normalize(spokenText);
      if (normalized.isNotEmpty) {
        await prefs.setString(_lastTextKey, normalized);
        await prefs.setString(_lastTextAtKey, DateTime.now().toIso8601String());
      }
    } catch (_) {}
  }

  Future<void> markPlaybackEnded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_activeKey, false);
      await prefs.setString(_lastEndKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  Future<bool> isPlaybackActiveNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final active = prefs.getBool(_activeKey) ?? false;
      if (active) return true;
      final raw = (prefs.getString(_lastEndKey) ?? '').trim();
      if (raw.isEmpty) return false;
      final lastEnd = DateTime.tryParse(raw);
      if (lastEnd == null) return false;
      return DateTime.now().difference(lastEnd) <= _cooldown;
    } catch (_) {
      return false;
    }
  }

  Future<void> registerEchoAttempt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_tamperCountKey) ?? 0;
      await prefs.setInt(_tamperCountKey, current + 1);
    } catch (_) {}
  }

  Future<bool> isLikelyOwnSpeech(
    String heardText, {
    Duration recentWindow = const Duration(seconds: 20),
  }) async {
    final normalizedHeard = _normalize(heardText);
    if (normalizedHeard.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = _normalize(prefs.getString(_lastTextKey) ?? '');
      final rawAt = (prefs.getString(_lastTextAtKey) ?? '').trim();
      final heardAt = DateTime.tryParse(rawAt);
      if (stored.isEmpty || heardAt == null) return false;
      if (DateTime.now().difference(heardAt) > recentWindow) return false;
      if (normalizedHeard == stored) return true;
      if (normalizedHeard.length >= 12 && stored.contains(normalizedHeard))
        return true;
      if (stored.length >= 12 && normalizedHeard.contains(stored)) return true;
      final heardTokens = normalizedHeard
          .split(' ')
          .where((e) => e.isNotEmpty)
          .toSet();
      final storedTokens = stored.split(' ').where((e) => e.isNotEmpty).toSet();
      if (heardTokens.isEmpty || storedTokens.isEmpty) return false;
      final intersection = heardTokens.intersection(storedTokens).length;
      final base = heardTokens.length < storedTokens.length
          ? heardTokens.length
          : storedTokens.length;
      if (base <= 0) return false;
      return (intersection / base) >= 0.72;
    } catch (_) {
      return false;
    }
  }

  String _normalize(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<int> getEchoAttemptCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_tamperCountKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> waitUntilPlaybackInactive({
    Duration timeout = const Duration(milliseconds: 1800),
    Duration pollInterval = const Duration(milliseconds: 150),
  }) async {
    final endAt = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endAt)) {
      final blocked = await isPlaybackActiveNow();
      if (!blocked) return true;
      await Future<void>.delayed(pollInterval);
    }
    return !(await isPlaybackActiveNow());
  }

  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeKey);
      await prefs.remove(_lastEndKey);
      await prefs.remove(_tamperCountKey);
      await prefs.remove(_lastTextKey);
      await prefs.remove(_lastTextAtKey);
    } catch (_) {}
  }
}
