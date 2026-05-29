// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaSelfRepairSecurityService {
  const NovaSelfRepairSecurityService();

  static const List<String> _blockedCodeFragments = <String>[
    'class ',
    'import',
    'void main',
    'methodchannel',
    'package:',
    'flutter',
    'kotlin',
    'java',
    'dart:',
    'security_bridge',
    'killswitch',
    'containment',
    'ownerrecovery',
    'androidmanifest',
    'bootguard',
    'devicepolicymanager',
  ];

  static const List<String> _safeSignalPrefixes = <String>[
    'overlay_',
    'background_',
    'stt_',
    'tts_',
    'api_',
    'local_model_',
    'authorization_',
    'voice_identity_',
    'speech_',
    'setup_',
    'brain_kernel_',
    'streaming_asr_',
  ];

  static const List<String> _allowedTargetAreas = <String>[
    'speech_understanding',
    'speech_response',
    'speech_and_understanding',
    'voice_understanding',
    'voice_response',
  ];

  bool canStoreProblemCodeSnippet(String input) {
    final text = input.trim();
    if (text.isEmpty || text.length > 2200) return false;
    final lower = text.toLowerCase();
    for (final token in _blockedCodeFragments) {
      if (lower.contains(token)) {
        return false;
      }
    }
    return true;
  }

  bool canSelfHealSignalCode(String code) {
    final value = code.trim().toLowerCase();
    if (value.isEmpty || value.length > 120) return false;
    return _safeSignalPrefixes.any(value.startsWith);
  }

  bool canAnnounceIssueNaturally(String message) {
    final text = message.trim();
    if (text.isEmpty || text.length > 280) return false;
    final lower = text.toLowerCase();
    return !_blockedCodeFragments.any(lower.contains);
  }

  bool canExposeTargetArea(String targetArea) {
    final value = targetArea.trim().toLowerCase();
    return _allowedTargetAreas.contains(value);
  }

  bool shouldBlockBlindPatchFragment(String fragment) {
    final lower = fragment.trim().toLowerCase();
    if (lower.isEmpty || lower.length > 4000) return true;
    return _blockedCodeFragments.any(lower.contains);
  }

  List<String> buildOwnerOnlyRules() {
    return const <String>[
      'blind patch sadece owner tarafından seçilen dar hedef alanda çalışır',
      'güvenlik dosyaları, kill zinciri ve policy bridge self repair kapsamı dışındadır',
      'nova scope büyütemez, yeni dosya isteyemez, gizli alan göremez',
      'başarısız onarım dürüstçe raporlanır, sessizce düzeldi denmez',
    ];
  }
}
