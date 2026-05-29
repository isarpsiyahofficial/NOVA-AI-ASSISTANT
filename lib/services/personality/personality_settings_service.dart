// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:shared_preferences/shared_preferences.dart';

class PersonalitySettingsData {
  final double emotion;
  final double humor;
  final double formality;
  final double seriousness;
  final double conversationWarmth;

  const PersonalitySettingsData({
    required this.emotion,
    required this.humor,
    required this.formality,
    required this.seriousness,
    required this.conversationWarmth,
  });
}

class PersonalitySettingsService {
  static const String _emotionKey = 'nova_personality_emotion';
  static const String _humorKey = 'nova_personality_humor';
  static const String _formalityKey = 'nova_personality_formality';
  static const String _seriousnessKey = 'nova_personality_seriousness';
  static const String _conversationWarmthKey =
      'nova_personality_conversation_warmth';

  const PersonalitySettingsService();

  Future<PersonalitySettingsData> load() async {
    final prefs = await SharedPreferences.getInstance();

    return PersonalitySettingsData(
      emotion: prefs.getDouble(_emotionKey) ?? 0.35,
      humor: prefs.getDouble(_humorKey) ?? 0.15,
      formality: prefs.getDouble(_formalityKey) ?? 0.75,
      seriousness: prefs.getDouble(_seriousnessKey) ?? 0.70,
      conversationWarmth: prefs.getDouble(_conversationWarmthKey) ?? 0.45,
    );
  }

  Future<void> save({
    required double emotion,
    required double humor,
    required double formality,
    double? seriousness,
    double? conversationWarmth,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_emotionKey, emotion);
    await prefs.setDouble(_humorKey, humor);
    await prefs.setDouble(_formalityKey, formality);
    await prefs.setDouble(_seriousnessKey, seriousness ?? 0.70);
    await prefs.setDouble(_conversationWarmthKey, conversationWarmth ?? 0.45);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_emotionKey, 0.35);
    await prefs.setDouble(_humorKey, 0.15);
    await prefs.setDouble(_formalityKey, 0.75);
    await prefs.setDouble(_seriousnessKey, 0.70);
    await prefs.setDouble(_conversationWarmthKey, 0.45);
  }

  String buildPromptGuideSync(PersonalitySettingsData data) {
    String label(double value) {
      if (value >= 0.75) return 'yüksek';
      if (value >= 0.40) return 'orta';
      return 'düşük';
    }

    return '''
[KİŞİLİK AYAR DURUMU]
- duygusallık: ${label(data.emotion)}
- mizah: ${label(data.humor)}
- resmiyet: ${label(data.formality)}
- ciddiyet: ${label(data.seriousness)}
- sohbet sıcaklığı: ${label(data.conversationWarmth)}
Kurallar:
- Kullanıcının istediği üsluba uy.
- Samimiyet artarsa saygıyı bozma.
- Ciddiyet artarsa soğuklaşma.
- Mizah uygunsa kısa ve yerinde espri kullan; aşırıya kaçma.
''';
  }
}
