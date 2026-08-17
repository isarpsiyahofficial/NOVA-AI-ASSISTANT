import 'package:shared_preferences/shared_preferences.dart';

class NovaPlaybackEchoFilterService {
  static const String _activeKey = 'nova_playback_echo_active_v1';
  static const String _lastEndKey = 'nova_playback_echo_last_end_v1';
  static const String _lastTextKey = 'nova_playback_echo_last_text_v1';
  static const String _lastTextAtKey = 'nova_playback_echo_last_text_at_v1';

  // The old 2.6 second blanket block made Nova deaf after every reply. The
  // microphone now returns quickly; the longer 20-second text-similarity guard
  // still rejects Nova's own speech if a device has an audio-tail/echo issue.
  static const Duration _cooldown = Duration(milliseconds: 320);
  static const Duration _staleActiveLimit = Duration(minutes: 2);

  static bool _hydrated = false;
  static bool _active = false;
  static DateTime? _lastEnd;
  static String _lastText = '';
  static DateTime? _lastTextAt;

  const NovaPlaybackEchoFilterService();

  Future<void> _ensureHydrated() async {
    if (_hydrated) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _active = prefs.getBool(_activeKey) ?? false;
      _lastEnd = DateTime.tryParse(
        (prefs.getString(_lastEndKey) ?? '').trim(),
      );
      _lastText = _normalize(prefs.getString(_lastTextKey) ?? '');
      _lastTextAt = DateTime.tryParse(
        (prefs.getString(_lastTextAtKey) ?? '').trim(),
      );
      if (_active &&
          (_lastTextAt == null ||
              DateTime.now().difference(_lastTextAt!) > _staleActiveLimit)) {
        _active = false;
      }
    } catch (_) {
      _active = false;
    } finally {
      _hydrated = true;
    }
  }

  Future<void> markPlaybackStarted({String spokenText = ''}) async {
    await _ensureHydrated();
    final now = DateTime.now();
    final normalized = _normalize(spokenText);
    _active = true;
    if (normalized.isNotEmpty) {
      _lastText = normalized;
      _lastTextAt = now;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_activeKey, true);
      if (normalized.isNotEmpty) {
        await prefs.setString(_lastTextKey, normalized);
        await prefs.setString(_lastTextAtKey, now.toIso8601String());
      }
    } catch (_) {}
  }

  Future<void> markPlaybackEnded() async {
    await _ensureHydrated();
    final now = DateTime.now();
    _active = false;
    _lastEnd = now;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_activeKey, false);
      await prefs.setString(_lastEndKey, now.toIso8601String());
    } catch (_) {}
  }

  Future<bool> isPlaybackActiveNow() async {
    await _ensureHydrated();
    if (_active) return true;
    final lastEnd = _lastEnd;
    if (lastEnd == null) return false;
    return DateTime.now().difference(lastEnd) <= _cooldown;
  }

  Future<bool> waitUntilPlaybackInactive({
    Duration timeout = const Duration(milliseconds: 900),
    Duration pollInterval = const Duration(milliseconds: 40),
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
    await _ensureHydrated();

    final stored = _lastText;
    final heardAt = _lastTextAt;
    if (stored.isEmpty || heardAt == null) return false;
    if (DateTime.now().difference(heardAt) > recentWindow) return false;
    if (normalizedHeard == stored) return true;
    if (normalizedHeard.length >= 12 && stored.contains(normalizedHeard)) {
      return true;
    }
    if (stored.length >= 12 && normalizedHeard.contains(stored)) return true;
    final heardTokens = normalizedHeard
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toSet();
    final storedTokens = stored
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toSet();
    if (heardTokens.isEmpty || storedTokens.isEmpty) return false;
    final intersection = heardTokens.intersection(storedTokens).length;
    final base = heardTokens.length < storedTokens.length
        ? heardTokens.length
        : storedTokens.length;
    return base > 0 && (intersection / base) >= 0.72;
  }

  Future<int> getEchoAttemptCount() async => 0;

  Future<void> reset() async {
    _hydrated = true;
    _active = false;
    _lastEnd = null;
    _lastText = '';
    _lastTextAt = null;
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
