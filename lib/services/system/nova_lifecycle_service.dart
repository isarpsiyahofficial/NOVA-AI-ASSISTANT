// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

import '../runtime/nova_identity_runtime_service.dart';

enum NovaMode { active, passive }

class NovaLifecycleDecision {
  final bool shouldWake;
  final bool shouldSleepAfterResponse;
  final bool shouldIgnoreInput;

  const NovaLifecycleDecision({
    required this.shouldWake,
    required this.shouldSleepAfterResponse,
    required this.shouldIgnoreInput,
  });
}

class NovaLifecycleService {
  final NovaIdentityRuntimeService identityRuntimeService;
  NovaMode _mode = NovaMode.active;

  NovaLifecycleService({NovaIdentityRuntimeService? identityRuntimeService})
    : identityRuntimeService =
          identityRuntimeService ?? const NovaIdentityRuntimeService();

  NovaMode get mode => _mode;

  bool get isSleeping => _mode == NovaMode.passive;
  bool get isAwake => _mode == NovaMode.active;

  void sleep() {
    _mode = NovaMode.passive;
  }

  void wake() {
    _mode = NovaMode.active;
  }

  bool shouldWakeFromInput(String input) {
    final text = identityRuntimeService.normalize(input);
    if (text.isEmpty) return false;
    final phrases = identityRuntimeService.prefixedPhrases(const <String>[
      'burda mısın',
      'burada mısın',
      'uyan',
      'beni dinle',
      'aktif ol',
      'göreve dön',
    ]);
    return phrases.any(text.contains);
  }

  bool shouldSleepAfterResponse(String input) {
    final text = identityRuntimeService.normalize(input);
    if (text.isEmpty) return false;
    final phrases = identityRuntimeService.prefixedPhrases(const <String>[
      'gidebilirsin',
      'beklemeye geç',
      'pasife dön',
      'uykuya dön',
      'sus',
      'dinlemeyi azalt',
    ]);
    return text.contains(
          'şimdilik bu kadar ${identityRuntimeService.currentDisplayName.toLowerCase()}',
        ) ||
        phrases.any(text.contains);
  }

  bool shouldProcessInput(String input) {
    if (!isSleeping) return true;
    return shouldWakeFromInput(input);
  }

  NovaLifecycleDecision evaluateInput(String input) {
    final text = input.trim();

    if (text.isEmpty) {
      return const NovaLifecycleDecision(
        shouldWake: false,
        shouldSleepAfterResponse: false,
        shouldIgnoreInput: true,
      );
    }

    final wake = shouldWakeFromInput(text);
    final sleepAfter = shouldSleepAfterResponse(text);

    if (isSleeping && !wake) {
      return const NovaLifecycleDecision(
        shouldWake: false,
        shouldSleepAfterResponse: false,
        shouldIgnoreInput: true,
      );
    }

    return NovaLifecycleDecision(
      shouldWake: wake,
      shouldSleepAfterResponse: sleepAfter,
      shouldIgnoreInput: false,
    );
  }
}
