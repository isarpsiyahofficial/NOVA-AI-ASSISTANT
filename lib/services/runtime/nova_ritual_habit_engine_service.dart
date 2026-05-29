// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_relationship_profile.dart';

class NovaRitualHabitEngineService {
  const NovaRitualHabitEngineService();

  List<String> resolveRituals({
    required NovaRelationshipProfile profile,
    required String latestPrompt,
    required String contextMode,
  }) {
    final rituals = <String>[];
    if (profile.preferredAddress.trim().isNotEmpty &&
        profile.preferredAddress.toLowerCase() != 'doğal hitap') {
      rituals.add('uygun olduğunda ${profile.preferredAddress} çizgisini koru');
    }
    if (profile.warmth >= 0.72 && contextMode != 'iş modu') {
      rituals.add('sohbete küçük sıcak geçişlerle gir');
    }
    if (profile.formality >= 0.70 || contextMode == 'iş modu') {
      rituals.add('teknik/iş anlarında önce özet sonra detay ritüelini koru');
    }
    for (final seed in profile.ritualSeeds) {
      if (!rituals.any((e) => e.toLowerCase() == seed.toLowerCase())) {
        rituals.add(seed);
      }
    }
    if (latestPrompt.toLowerCase().contains('geçen sefer')) {
      rituals.add('uygunsa ortak geçmişe hafif referans ver');
    }
    return rituals.take(6).toList(growable: false);
  }

  String buildPromptSection(List<String> rituals) {
    return [
      'RİTÜEL VE ORTAK ALIŞKANLIK MOTORU:',
      if (rituals.isEmpty)
        '- bu kişi için henüz yerleşik ritüel yok; yapay tekrar üretme',
      for (final ritual in rituals) '- $ritual',
      'KURAL: Ritüeller hafif olsun; her cevapta yapay tekrar haline gelmesin.',
    ].join('\n');
  }
}
