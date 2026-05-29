// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/voice_clone/cloned_voice_profile.dart';
import '../../core/voice_clone/voice_clone_source_type.dart';

class ClonedVoiceLibraryService {
  static const String _storageKey = 'nova_cloned_voice_library_v2';
  static const int _maxVoiceCount = 50;

  const ClonedVoiceLibraryService();

  Future<List<ClonedVoiceProfile>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.trim().isEmpty) {
        return const <ClonedVoiceProfile>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <ClonedVoiceProfile>[];
      }

      final items = decoded
          .whereType<Map>()
          .map(
            (e) =>
                ClonedVoiceProfile.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
          .toList(growable: false);

      return _trim(items);
    } catch (_) {
      return const <ClonedVoiceProfile>[];
    }
  }

  Future<void> _save(List<ClonedVoiceProfile> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final safe = _trim(items);
      await prefs.setString(
        _storageKey,
        jsonEncode(safe.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {
      // Sessiz fallback
    }
  }

  List<ClonedVoiceProfile> _trim(List<ClonedVoiceProfile> items) {
    final list = [...items]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (list.length <= _maxVoiceCount) return list;
    return list.take(_maxVoiceCount).toList(growable: false);
  }

  Future<List<ClonedVoiceProfile>> getAll() async {
    return _load();
  }

  Future<ClonedVoiceProfile?> getActiveVoice() async {
    final items = await _load();
    for (final item in items) {
      if (item.isActiveInUse) return item;
    }
    return null;
  }

  Future<void> addOrUpdate(ClonedVoiceProfile profile) async {
    final items = await _load();
    bool updated = false;

    final next = items
        .map((item) {
          if (item.id == profile.id) {
            updated = true;
            return profile;
          }
          return item;
        })
        .toList(growable: true);

    if (!updated) {
      next.add(profile);
    }

    await _save(next);
  }

  Future<void> addOrUpdateFromProfileId(String profileId) async {
    final now = DateTime.now();

    final profile = ClonedVoiceProfile(
      id: profileId,
      name: 'Klon Ses $profileId',
      sourceType: VoiceCloneSourceType.file,
      sourceReference: '',
      styleInstruction: 'Nova klon sesi',
      noiseReduced: true,
      isFavorite: false,
      isActiveInUse: false,
      createdAt: now,
      updatedAt: now,
    );

    await addOrUpdate(profile);
  }

  Future<void> addOrUpdateFromNativeCloneResult({
    required Map<String, dynamic> nativeResult,
    required VoiceCloneSourceType sourceType,
  }) async {
    final voiceId = (nativeResult['voiceId'] as String? ?? '').trim();
    final voiceName = (nativeResult['voiceName'] as String? ?? '').trim();
    final sourceReference =
        (nativeResult['sourceReference'] as String? ??
                nativeResult['referenceAudio'] as String? ??
                '')
            .trim();
    final styleInstruction = (nativeResult['styleInstruction'] as String? ?? '')
        .trim();

    if (voiceId.isEmpty || voiceName.isEmpty || sourceReference.isEmpty) {
      return;
    }

    final now = DateTime.now();

    final profile = ClonedVoiceProfile(
      id: voiceId,
      name: voiceName,
      sourceType: sourceType,
      sourceReference: sourceReference,
      styleInstruction: styleInstruction,
      noiseReduced: true,
      isFavorite: false,
      isActiveInUse: false,
      createdAt: now,
      updatedAt: now,
    );

    await addOrUpdate(profile);
  }

  Future<void> setFavorite({
    required String id,
    required bool isFavorite,
  }) async {
    final items = await _load();
    final now = DateTime.now();

    final next = items
        .map(
          (item) => item.id == id
              ? item.copyWith(isFavorite: isFavorite, updatedAt: now)
              : item,
        )
        .toList(growable: false);

    await _save(next);
  }

  Future<void> setActiveVoice(String id) async {
    final items = await _load();
    final now = DateTime.now();

    final next = items
        .map(
          (item) => item.copyWith(
            isActiveInUse: item.id == id,
            updatedAt: item.id == id ? now : item.updatedAt,
          ),
        )
        .toList(growable: false);

    await _save(next);
  }

  Future<bool> remove(String id) async {
    final items = await _load();
    final target = items.where((e) => e.id == id).toList(growable: false);

    if (target.isEmpty) return false;
    if (target.first.isActiveInUse) {
      return false;
    }

    final next = items.where((e) => e.id != id).toList(growable: false);
    await _save(next);
    return true;
  }

  Future<int> cleanupNonFavorites() async {
    final items = await _load();

    final kept = items
        .where((item) {
          if (item.isActiveInUse) return true;
          if (item.isFavorite) return true;
          return false;
        })
        .toList(growable: false);

    final removedCount = items.length - kept.length;
    await _save(kept);
    return removedCount;
  }

  Future<int> cleanupRedundantNonFavorites() async {
    final items = await _load();
    final Map<String, ClonedVoiceProfile> latestByMeaning =
        <String, ClonedVoiceProfile>{};

    for (final item in items) {
      final key =
          '${item.name.trim().toLowerCase()}::${item.styleInstruction.trim().toLowerCase()}';
      final existing = latestByMeaning[key];

      if (existing == null || item.updatedAt.isAfter(existing.updatedAt)) {
        latestByMeaning[key] = item;
      }
    }

    final latestSet = latestByMeaning.values.map((e) => e.id).toSet();

    final kept = items
        .where((item) {
          if (item.isActiveInUse) return true;
          if (item.isFavorite) return true;
          if (latestSet.contains(item.id)) return true;
          return false;
        })
        .toList(growable: false);

    final removedCount = items.length - kept.length;
    await _save(kept);
    return removedCount;
  }
}
