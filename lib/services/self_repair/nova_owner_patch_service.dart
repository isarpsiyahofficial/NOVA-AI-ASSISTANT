// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/self_repair/nova_owner_patch.dart';

class NovaOwnerPatchService {
  static const String _storageKey = 'nova_owner_patches_v1';

  const NovaOwnerPatchService();

  Future<List<NovaOwnerPatch>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) return const <NovaOwnerPatch>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <NovaOwnerPatch>[];
      return _trim(
        decoded
            .whereType<Map>()
            .map((e) => NovaOwnerPatch.fromMap(Map<String, dynamic>.from(e)))
            .toList(growable: false),
      )..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return const <NovaOwnerPatch>[];
    }
  }

  Future<void> savePatch(NovaOwnerPatch patch) async {
    final items = await getAll();
    final sanitized = _sanitizeTerminalPatch(patch);
    final next = <NovaOwnerPatch>[
      sanitized,
      ...items.where((e) => e.id != patch.id),
    ];
    await _persist(next);
  }

  Future<void> cleanupRetention() async {
    await _persist(await getAll());
  }

  Future<void> _persist(List<NovaOwnerPatch> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_trim(items).map((e) => e.toMap()).toList(growable: false)),
    );
  }

  NovaOwnerPatch _sanitizeTerminalPatch(NovaOwnerPatch patch) {
    final terminal =
        patch.status == NovaOwnerPatchStatus.applied ||
        patch.status == NovaOwnerPatchStatus.rejected;
    if (!terminal) return patch;
    return patch.copyWith(patchText: '', updatedAt: patch.updatedAt);
  }

  List<NovaOwnerPatch> _trim(List<NovaOwnerPatch> items) {
    final now = DateTime.now();
    final kept =
        items
            .where((item) {
              final age = now.difference(item.updatedAt);
              final terminal =
                  item.status == NovaOwnerPatchStatus.applied ||
                  item.status == NovaOwnerPatchStatus.rejected;
              if (terminal) {
                return age.inHours < 24;
              }
              return age.inDays < 7;
            })
            .toList(growable: false)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return kept;
  }
}
