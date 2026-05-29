import 'package:shared_preferences/shared_preferences.dart';

class NovaPlaybackEchoFilterService {
  static const String _activeKey = 'nova_playback_echo_active_v1';
  static const String _lastEndKey = 'nova_playback_echo_last_end_v1';
  static const String _lastTextKey = 'nova_playback_echo_last_text_v1';
  static const String _lastTextAtKey = 'nova_playback_echo_last_text_at_v1';
  static const Duration _cooldown = Duration(milliseconds: 2600);

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
      final lastEnd = DateTime.tryParse(raw);
      if (lastEnd == null) return false;
      return DateTime.now().difference(lastEnd) <= _cooldown;
    } catch (_) {
      return false;
    }
  }

  Future<bool> waitUntilPlaybackInactive({
    Duration timeout = const Duration(milliseconds: 1800),
    Duration pollInterval = const Duration(milliseconds: 150),
  }) async {
    final endAt = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endAt)) {
      if (!await isPlaybackActiveNow()) return true;
      await Future<void>.delayed(pollInterval);
    }
    return !await isPlaybackActiveNow();
  }

  Future<void> registerEchoAttempt() async {}

  Future<bool> isLikelyOwnSpeech(
    String heardText, {
    Duration recentWindow = const Duration(seconds: 20),
  }) async {
    final normalizedHeard = _normalize(heardText);
    if (normalizedHeard.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = _normalize(prefs.getString(_lastTextKey) ?? '');
      final heardAt = DateTime.tryParse(
        (prefs.getString(_lastTextAtKey) ?? '').trim(),
      );
      if (stored.isEmpty || heardAt == null) return false;
      if (DateTime.now().difference(heardAt) > recentWindow) return false;
      if (normalizedHeard == stored) return true;
      if (normalizedHeard.length >= 12 && stored.contains(normalizedHeard)) {
        return true;
      }
      if (stored.length >= 12 && normalizedHeard.contains(stored)) return true;
      final heardTokens = normalizedHeard.split(' ').where((e) => e.isNotEmpty).toSet();
      final storedTokens = stored.split(' ').where((e) => e.isNotEmpty).toSet();
      if (heardTokens.isEmpty || storedTokens.isEmpty) return false;
      final intersection = heardTokens.intersection(storedTokens).length;
      final base = heardTokens.length < storedTokens.length
          ? heardTokens.length
          : storedTokens.length;
      return base > 0 && (intersection / base) >= 0.72;
    } catch (_) {
      return false;
    }
  }

  Future<int> getEchoAttemptCount() async => 0;

  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeKey);
      await prefs.remove(_lastEndKey);
      await prefs.remove(_lastTextKey);
      await prefs.remove(_lastTextAtKey);
    } catch (_) {}
  }

  String _normalize(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
