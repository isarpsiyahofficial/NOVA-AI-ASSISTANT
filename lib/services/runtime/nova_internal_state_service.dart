// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/runtime/nova_internal_state.dart';
import '../../core/runtime/nova_thinking_models.dart';

class NovaInternalStateService {
  static const String _storageKey = 'nova_internal_state_v2';

  const NovaInternalStateService();

  Future<NovaInternalState> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return NovaInternalState.initial();
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return NovaInternalState.initial();
      }
      return NovaInternalState.fromMap(decoded);
    } catch (_) {
      return NovaInternalState.initial();
    }
  }

  Future<NovaInternalState> evolveForInput(
    NovaThinkingSnapshot snapshot,
  ) async {
    final current = await load();
    final nextTurnCount = current.sessionTurnCount + 1;
    final next = current.copyWith(
      energyLevel: _clamp(
        current.energyLevel +
            (snapshot.intent == NovaInteractionIntent.emotional
                ? -0.02
                : 0.006) -
            (nextTurnCount >= 8 ? 0.006 : 0.0),
      ),
      focusLevel: _clamp(
        current.focusLevel +
            (snapshot.intent == NovaInteractionIntent.command ? 0.03 : 0.0) -
            (snapshot.intent == NovaInteractionIntent.conversation
                ? 0.004
                : 0.0),
      ),
      socialOpenness: _clamp(
        current.socialOpenness +
            (snapshot.shouldOfferWarmth ? 0.03 : -0.004) -
            (snapshot.intent == NovaInteractionIntent.command ? 0.012 : 0.0),
      ),
      fatigueLevel: _clamp(
        current.fatigueLevel +
            0.012 +
            (snapshot.intent == NovaInteractionIntent.emotional ? 0.008 : 0.0),
      ),
      conversationDrive: _clamp(
        current.conversationDrive +
            (snapshot.shouldOfferWarmth ? 0.035 : -0.01),
      ),
      ownerCloseness: _clamp(
        current.ownerCloseness +
            (snapshot.intent == NovaInteractionIntent.conversation ? 0.01 : 0),
      ),
      speakingRegister: snapshot.intent == NovaInteractionIntent.command
          ? 'precise_owner'
          : snapshot.intent == NovaInteractionIntent.emotional
          ? 'warm_owner'
          : snapshot.intent == NovaInteractionIntent.ambiguous
          ? 'careful_owner'
          : current.speakingRegister,
      sessionTurnCount: nextTurnCount,
    );
    await _save(next);
    return next;
  }

  Future<void> registerOpenLoop(String text) async {
    final current = await load();
    final loops = <String>[
      text.trim(),
      ...current.lastOpenLoops,
    ].where((e) => e.isNotEmpty).take(5).toList(growable: false);
    await _save(current.copyWith(lastOpenLoops: loops));
  }

  Future<void> applyReplyOutcome({
    required String reply,
    required bool wasLong,
    required bool hadRepair,
  }) async {
    final current = await load();
    final next = current.copyWith(
      focusLevel: _clamp(current.focusLevel + (wasLong ? -0.015 : 0.01)),
      socialOpenness: _clamp(
        current.socialOpenness + (hadRepair ? -0.01 : 0.008),
      ),
      fatigueLevel: _clamp(current.fatigueLevel + (wasLong ? 0.02 : 0.008)),
      conversationDrive: _clamp(
        current.conversationDrive + (wasLong ? -0.012 : 0.006),
      ),
    );
    await _save(next);
  }

  Future<void> _save(NovaInternalState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toMap()));
  }

  double _clamp(double value) {
    if (value < 0.0) return 0.0;
    if (value > 1.0) return 1.0;
    return value;
  }
}
