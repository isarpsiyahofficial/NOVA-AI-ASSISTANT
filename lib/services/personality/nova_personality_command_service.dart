// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'personality_settings_service.dart';

class NovaPersonalityCommandResult {
  final bool handled;
  final String spokenText;

  const NovaPersonalityCommandResult({
    required this.handled,
    String spokenText = '',
  }) : spokenText = '';

  const NovaPersonalityCommandResult.unhandled()
    : handled = false,
      spokenText = '';
}

class NovaPersonalityCommandService {
  final PersonalitySettingsService settingsService;

  const NovaPersonalityCommandService({required this.settingsService});

  Future<NovaPersonalityCommandResult> tryHandle(String input) async {
    final text = input.trim().toLowerCase();
    if (text.isEmpty) return const NovaPersonalityCommandResult.unhandled();

    final current = await settingsService.load();

    if (text.contains('şaka dozun hangi seviyede') ||
        text.contains('şaka dozun ne')) {
      return NovaPersonalityCommandResult(
        handled: true,
        spokenText: '',
      );
    }

    if (text.contains('şaka dozunu azalt')) {
      final next = (current.humor - 0.15).clamp(0.0, 1.0);
      await settingsService.save(
        emotion: current.emotion,
        humor: next,
        formality: current.formality,
        seriousness: current.seriousness,
        conversationWarmth: current.conversationWarmth,
      );
      return const NovaPersonalityCommandResult(
        handled: true,
        spokenText: '',
      );
    }

    if (text.contains('daha ciddi ol') || text.contains('ciddi konuş')) {
      final nextSerious = (current.seriousness + 0.2).clamp(0.0, 1.0);
      final nextFormality = (current.formality + 0.15).clamp(0.0, 1.0);
      await settingsService.save(
        emotion: current.emotion,
        humor: (current.humor - 0.1).clamp(0.0, 1.0),
        formality: nextFormality,
        seriousness: nextSerious,
        conversationWarmth: current.conversationWarmth,
      );
      return const NovaPersonalityCommandResult(
        handled: true,
        spokenText: '',
      );
    }

    if (text.contains('arkadaş gibi davran') || text.contains('samimi ol')) {
      await settingsService.save(
        emotion: (current.emotion + 0.1).clamp(0.0, 1.0),
        humor: (current.humor + 0.1).clamp(0.0, 1.0),
        formality: (current.formality - 0.25).clamp(0.0, 1.0),
        seriousness: (current.seriousness - 0.1).clamp(0.0, 1.0),
        conversationWarmth: (current.conversationWarmth + 0.2).clamp(0.0, 1.0),
      );
      return const NovaPersonalityCommandResult(
        handled: true,
        spokenText: '',
      );
    }

    if (text.contains('sohbet seviyeni yükselt')) {
      await settingsService.save(
        emotion: (current.emotion + 0.1).clamp(0.0, 1.0),
        humor: current.humor,
        formality: current.formality,
        seriousness: current.seriousness,
        conversationWarmth: (current.conversationWarmth + 0.15).clamp(0.0, 1.0),
      );
      return const NovaPersonalityCommandResult(
        handled: true,
        spokenText: '',
      );
    }

    if (text.contains('sohbet seviyeni alçalt')) {
      await settingsService.save(
        emotion: current.emotion,
        humor: current.humor,
        formality: (current.formality + 0.1).clamp(0.0, 1.0),
        seriousness: (current.seriousness + 0.1).clamp(0.0, 1.0),
        conversationWarmth: (current.conversationWarmth - 0.15).clamp(0.0, 1.0),
      );
      return const NovaPersonalityCommandResult(
        handled: true,
        spokenText: '',
      );
    }

    return const NovaPersonalityCommandResult.unhandled();
  }

  String _labelFor(double value) {
    if (value >= 0.75) return 'yüksek';
    if (value >= 0.4) return 'orta';
    return 'düşük';
  }
}
