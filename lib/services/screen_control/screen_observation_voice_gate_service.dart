// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum ScreenPermissionVoiceDecision { none, enable, deny, disable }

class ScreenObservationVoiceGateService {
  const ScreenObservationVoiceGateService();

  ScreenPermissionVoiceDecision resolve(String input) {
    final text = input.toLowerCase().trim();

    if (text.isEmpty) {
      return ScreenPermissionVoiceDecision.none;
    }

    if (_containsAny(text, const [
      'evet',
      'olur',
      'tamam',
      'aç',
      'yap',
      'aktif et',
      'izin ver',
    ])) {
      return ScreenPermissionVoiceDecision.enable;
    }

    if (_containsAny(text, const [
      'hayır',
      'gerek yok',
      'açma',
      'istemiyorum',
      'şimdilik hayır',
    ])) {
      return ScreenPermissionVoiceDecision.deny;
    }

    if (_containsAny(text, const [
      'kapat',
      'izni kapat',
      'ekran izlemeyi kapat',
      'telefon yönetimini kapat',
    ])) {
      return ScreenPermissionVoiceDecision.disable;
    }

    return ScreenPermissionVoiceDecision.none;
  }

  bool shouldAskPermission({
    required bool permissionEnabled,
    required bool taskNeedsScreenObservation,
  }) {
    return taskNeedsScreenObservation && !permissionEnabled;
  }

  String permissionQuestion() {
    return 'Efendim ekran izleme izni kapalı. Açmak ister misiniz?';
  }

  bool _containsAny(String text, List<String> phrases) {
    for (final phrase in phrases) {
      if (text.contains(phrase)) return true;
    }
    return false;
  }
}
