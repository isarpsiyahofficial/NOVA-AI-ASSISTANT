// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/branding/assistant_identity_profile.dart';

class NovaIdentityRuntimeService {
  static const String _prefsKey = 'nova_identity_profile_v1';
  static AssistantIdentityProfile _cached = AssistantIdentityProfile.fallback;
  static bool _loaded = false;

  const NovaIdentityRuntimeService();

  Future<AssistantIdentityProfile> ensureLoaded() async {
    if (_loaded) return _cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _cached = AssistantIdentityProfile.fromMap(
            Map<String, dynamic>.from(decoded),
          );
        }
      }
    } catch (_) {}
    _loaded = true;
    return _cached;
  }

  AssistantIdentityProfile get currentProfile => _cached;
  String get currentDisplayName => _cached.displayName;
  List<String> get knownAliases => List<String>.from(_cached.aliases);
  String get wakeReply => _cached.wakeReply;
  String get listeningReply => _cached.listeningReply;

  Future<AssistantIdentityProfile> renameAssistant({
    required String displayName,
    List<String> additionalAliases = const <String>[],
  }) async {
    await ensureLoaded();
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return _cached;
    final normalizedCurrent = _cached.displayName.trim().toLowerCase();
    final normalizedTarget = trimmed.toLowerCase();
    final aliases = <String>{
      ..._cached.aliases
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty),
      normalizedCurrent,
      normalizedTarget,
      'nova',
      ...additionalAliases
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty),
    };
    final profile = _cached.copyWith(
      displayName: _capitalizeName(trimmed),
      aliases: aliases.toList(growable: false),
    );
    await _persist(profile);
    return profile;
  }

  Future<AssistantIdentityProfile> maybeApplyRenameInstruction(
    String input,
  ) async {
    await ensureLoaded();
    final next = _extractRenameTarget(input);
    if (next == null) return _cached;
    return renameAssistant(
      displayName: next,
      additionalAliases: <String>[_cached.displayName.toLowerCase()],
    );
  }

  bool isAddressedToAssistant(String text, {bool allowEfendim = true}) {
    final normalized = normalize(text);
    if (normalized.isEmpty) return false;
    for (final alias in _cached.aliases) {
      if (alias.isEmpty) continue;
      if (normalized == alias ||
          normalized.startsWith('$alias ') ||
          normalized.contains(' $alias ') ||
          normalized.endsWith(' $alias')) {
        return true;
      }
    }
    return allowEfendim &&
        (normalized.contains(' efendim') ||
            normalized.startsWith('efendim ') ||
            normalized == 'efendim');
  }

  List<String> prefixedPhrases(
    List<String> suffixes, {
    bool includeBareName = true,
  }) {
    final out = <String>{};
    for (final alias in _cached.aliases) {
      final safe = alias.trim();
      if (safe.isEmpty) continue;
      if (includeBareName) out.add(safe);
      for (final suffix in suffixes) {
        final trimmed = suffix.trim();
        if (trimmed.isEmpty) continue;
        out.add('$safe $trimmed');
        out.add('$trimmed $safe');
      }
    }
    return out.toList(growable: false);
  }

  String normalize(String text) => text.trim().toLowerCase();

  String replaceAssistantLabel(String text) {
    var value = text;
    final current = _cached.displayName;
    for (final alias in _cached.aliases) {
      final safeAlias = alias.trim();
      if (safeAlias.isEmpty) continue;
      value = value.replaceAllMapped(
        RegExp('\\b${RegExp.escape(safeAlias)}\\b', caseSensitive: false),
        (_) => current,
      );
    }
    value = value.replaceAllMapped(RegExp(r'\bNova\b'), (_) => current);
    value = value.replaceAllMapped(RegExp(r'\bnova\b'), (_) => current);
    value = value.replaceAllMapped(RegExp(r'\bNova\b'), (_) => current);
    value = value.replaceAllMapped(RegExp(r'\bnova\b'), (_) => current);
    return value;
  }

  String defaultWakeReply() => _cached.wakeReply;
  String defaultListeningReply() => _cached.listeningReply;

  String _capitalizeName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Nova';
    return trimmed
        .split(RegExp(r'\s+'))
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        })
        .join(' ');
  }

  String? _extractRenameTarget(String input) {
    final text = normalize(input);
    if (text.isEmpty) return null;
    final patterns = <RegExp>[
      RegExp(
        r"(?:bundan sonra|artık|simdi|şimdi)\s+(?:adın|ismin|senin adın|senin ismin)\s+(?:olsun|olacak|)\s*([a-zA-ZçğıöşüÇĞİÖŞÜ0-9 _-]{2,32})",
      ),
      RegExp(
        r"(?:bundan sonra|artık|simdi|şimdi)\s+sana\s+([a-zA-ZçğıöşüÇĞİÖŞÜ0-9 _-]{2,32})\s+diye\s+hitap",
      ),
      RegExp(r"(?:adını|ismini)\s+([a-zA-ZçğıöşüÇĞİÖŞÜ0-9 _-]{2,32})\s+yap"),
      RegExp(
        r"(?:senin adin|senin adın|adın|ismin)\s+([a-zA-ZçğıöşüÇĞİÖŞÜ0-9 _-]{2,32})",
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final value = match.group(1)?.trim() ?? '';
        if (value.isNotEmpty && value != 'nova') return value;
      }
    }
    return null;
  }

  Future<void> _persist(AssistantIdentityProfile profile) async {
    _cached = profile;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(profile.toMap()));
    } catch (_) {}
  }
}
