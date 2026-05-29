// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaVoiceIdentityContinuityService {
  DateTime? _trustedUntil;
  String _speakerId = '';
  String _speakerName = '';

  NovaVoiceIdentityContinuityService();

  bool get hasContinuity =>
      _trustedUntil != null && DateTime.now().isBefore(_trustedUntil!);
  String get speakerId => _speakerId;
  String get speakerName => _speakerName;

  void markTrusted({
    required String speakerId,
    required String speakerName,
    Duration hold = const Duration(hours: 12),
  }) {
    _speakerId = speakerId.trim();
    _speakerName = speakerName.trim();
    _trustedUntil = DateTime.now().add(hold);
  }

  void soften(Duration hold) {
    if (_trustedUntil == null) return;
    _trustedUntil = DateTime.now().add(hold);
  }

  void clear() {
    _trustedUntil = null;
    _speakerId = '';
    _speakerName = '';
  }
}
