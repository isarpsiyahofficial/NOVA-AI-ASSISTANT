// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/identity/known_voice_identity.dart';

class VoiceIdentityRegistryService {
  static const String _storageKey = 'nova_known_voice_identities_v1';
  static const int _maxIdentityCount = 200;

  const VoiceIdentityRegistryService();

  Future<List<KnownVoiceIdentity>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.trim().isEmpty) {
        return const <KnownVoiceIdentity>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <KnownVoiceIdentity>[];
      }

      final items = decoded
          .whereType<Map>()
          .map(
            (e) =>
                KnownVoiceIdentity.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .where((e) => e.id.trim().isNotEmpty && e.voiceId.trim().isNotEmpty)
          .toList(growable: false);

      return _dedupeAndTrim(items);
    } catch (_) {
      return const <KnownVoiceIdentity>[];
    }
  }

  Future<void> _save(List<KnownVoiceIdentity> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final safe = _dedupeAndTrim(items);

      await prefs.setString(
        _storageKey,
        jsonEncode(safe.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {
      // Sessiz fallback
    }
  }

  List<KnownVoiceIdentity> _dedupeAndTrim(List<KnownVoiceIdentity> items) {
    final Map<String, KnownVoiceIdentity> byVoiceId =
        <String, KnownVoiceIdentity>{};
    final Map<String, KnownVoiceIdentity> byId = <String, KnownVoiceIdentity>{};

    for (final item in items) {
      final normalizedVoiceId = item.voiceId.trim();
      final normalizedId = item.id.trim();

      if (normalizedVoiceId.isEmpty || normalizedId.isEmpty) {
        continue;
      }

      final existingByVoice = byVoiceId[normalizedVoiceId];
      if (existingByVoice == null ||
          item.updatedAt.isAfter(existingByVoice.updatedAt)) {
        byVoiceId[normalizedVoiceId] = item;
      }
    }

    for (final item in byVoiceId.values) {
      final existingById = byId[item.id];
      if (existingById == null ||
          item.updatedAt.isAfter(existingById.updatedAt)) {
        byId[item.id] = item;
      }
    }

    final list = byId.values.toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (list.length <= _maxIdentityCount) {
      return list;
    }

    return list.take(_maxIdentityCount).toList(growable: false);
  }

  Future<List<KnownVoiceIdentity>> getAll() async {
    return _load();
  }

  Future<KnownVoiceIdentity?> findByVoiceId(String voiceId) async {
    final text = voiceId.trim();
    if (text.isEmpty) return null;

    final items = await _load();
    for (final item in items) {
      if (item.voiceId.trim() == text) {
        return item;
      }
    }
    return null;
  }

  Future<void> addOrUpdate(KnownVoiceIdentity identity) async {
    final normalizedVoiceId = identity.voiceId.trim();
    final normalizedId = identity.id.trim();

    if (normalizedVoiceId.isEmpty || normalizedId.isEmpty) {
      return;
    }

    final items = await _load();
    bool updated = false;

    final next = items
        .map((item) {
          final sameId = item.id.trim() == normalizedId;
          final sameVoiceId = item.voiceId.trim() == normalizedVoiceId;

          if (sameId || sameVoiceId) {
            updated = true;

            return item.copyWith(
              id: identity.id,
              displayName: identity.displayName,
              relationshipLabel: identity.relationshipLabel,
              voiceId: identity.voiceId,
              isVoiceKnown: identity.isVoiceKnown,
              isAuthorizedToUseNova: identity.isAuthorizedToUseNova,
              canReceiveAutoCallHandling: identity.canReceiveAutoCallHandling,
              introducedByOwner: identity.introducedByOwner,
              createdAt: item.createdAt,
              updatedAt: identity.updatedAt,
            );
          }

          return item;
        })
        .toList(growable: true);

    if (!updated) {
      next.add(identity);
    }

    await _save(next);
  }

  Future<void> remove(String id) async {
    final text = id.trim();
    if (text.isEmpty) return;

    final items = await _load();
    final next = items
        .where((e) => e.id.trim() != text)
        .toList(growable: false);
    await _save(next);
  }

  Future<void> removeByVoiceId(String voiceId) async {
    final text = voiceId.trim();
    if (text.isEmpty) return;

    final items = await _load();
    final next = items
        .where((e) => e.voiceId.trim() != text)
        .toList(growable: false);
    await _save(next);
  }
}
