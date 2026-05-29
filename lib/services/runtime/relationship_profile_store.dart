// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/runtime/nova_relationship_profile.dart';
import 'nova_memory_compaction_service.dart';

class RelationshipProfileStore {
  static const NovaMemoryCompactionService _compaction =
      NovaMemoryCompactionService();
  static const String _storageKey = 'nova_relationship_profiles_v2';

  const RelationshipProfileStore();

  Future<Map<String, NovaRelationshipProfile>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return <String, NovaRelationshipProfile>{};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, NovaRelationshipProfile>{};
      final result = <String, NovaRelationshipProfile>{};
      decoded.forEach((key, value) {
        if (value is Map) {
          result[key.toString()] = _compactProfile(
            NovaRelationshipProfile.fromMap(Map<String, dynamic>.from(value)),
          );
        }
      });
      return result;
    } catch (_) {
      return <String, NovaRelationshipProfile>{};
    }
  }

  Future<NovaRelationshipProfile?> getByKey(String speakerKey) async {
    final all = await getAll();
    return all[speakerKey.trim()];
  }

  Future<void> save(NovaRelationshipProfile profile) async {
    if (profile.speakerKey.trim().isEmpty) return;
    final all = Map<String, NovaRelationshipProfile>.of(await getAll());
    all[profile.speakerKey.trim()] = _compactProfile(profile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(all.map((key, value) => MapEntry(key, value.toMap()))),
    );
  }

  NovaRelationshipProfile _compactProfile(NovaRelationshipProfile profile) {
    return profile.copyWith(
      stablePreferences: _compaction.compactStrings(
        profile.stablePreferences,
        limit: 8,
        maxItemLength: 88,
      ),
      sharedAnchors: _compaction.compactStrings(
        profile.sharedAnchors,
        limit: 8,
        maxItemLength: 88,
      ),
      criticalCorrections: _compaction.compactStrings(
        profile.criticalCorrections,
        limit: 6,
        maxItemLength: 88,
      ),
      constitutionPrinciples: _compaction.compactStrings(
        profile.constitutionPrinciples,
        limit: 8,
        maxItemLength: 96,
      ),
      ritualSeeds: _compaction.compactStrings(
        profile.ritualSeeds,
        limit: 6,
        maxItemLength: 72,
      ),
      supportStyle: _compaction.compactSummary(
        profile.supportStyle,
        maxLength: 90,
      ),
      displayName: _compaction.compactSummary(
        profile.displayName,
        maxLength: 40,
      ),
      preferredAddress: _compaction.compactSummary(
        profile.preferredAddress,
        maxLength: 40,
      ),
    );
  }
}
