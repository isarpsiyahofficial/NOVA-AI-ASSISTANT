// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_twelve_shields_service.dart';

class NovaSafeAutonomyDecision {
  final bool allowProactiveQuestion;
  final bool allowScreenControl;
  final bool allowCallIntervention;
  final bool mustAskPermission;
  final String reason;
  final List<String> blockedCapabilities;
  final String containmentStage;
  const NovaSafeAutonomyDecision({
    required this.allowProactiveQuestion,
    required this.allowScreenControl,
    required this.allowCallIntervention,
    required this.mustAskPermission,
    required this.reason,
    this.blockedCapabilities = const <String>[],
    this.containmentStage = 'normal',
  });
}

class NovaSafeAutonomyLimiterService {
  const NovaSafeAutonomyLimiterService();
  static const NovaTwelveShieldsService _shields = NovaTwelveShieldsService();

  static const List<String> _sensitiveDomains = <String>[
    'security',
    'call',
    'screen_control',
    'voice_clone',
    'self_repair',
  ];
  static const List<String> _socialDomains = <String>[
    'general',
    'presence',
    'companion',
    'reminder',
    'translator',
  ];
  static const List<String> _deviceDomains = <String>[
    'media',
    'phone_control',
    'overlay',
    'automation',
    'background',
  ];

  NovaSafeAutonomyDecision evaluate({
    required String domain,
    required bool userExplicitlyRequested,
    required bool ownerMode,
    required bool permissionEnabled,
    required bool inCall,
  }) {
    final normalizedDomain = domain.trim().toLowerCase();
    final shield = _shields.evaluate(
      text: normalizedDomain,
      metadata: <String, dynamic>{
        'authorityBand': ownerMode ? 'owner' : 'acquainted',
        'allowChatGpt': false,
        'battery': permissionEnabled ? 0.50 : 0.18,
        'keepHotMic': inCall,
      },
    );
    final sensitive =
        _containsAny(normalizedDomain, _sensitiveDomains) ||
        normalizedDomain.contains('security') ||
        normalizedDomain.contains('call');
    final deviceLike = _containsAny(normalizedDomain, _deviceDomains);
    final social = _containsAny(normalizedDomain, _socialDomains);
    final allowCallIntervention =
        inCall &&
        permissionEnabled &&
        ownerMode &&
        !shield.blockedCapabilities.contains('command_acceptance');
    final allowScreenControl =
        deviceLike &&
        permissionEnabled &&
        userExplicitlyRequested &&
        ownerMode &&
        !shield.quarantine;
    final allowProactiveQuestion =
        social && ownerMode && !sensitive && !shield.quarantine;
    final mustAskPermission = sensitive && !userExplicitlyRequested;
    final reason = _reason(
      sensitive: sensitive,
      deviceLike: deviceLike,
      social: social,
      userExplicitlyRequested: userExplicitlyRequested,
      ownerMode: ownerMode,
      permissionEnabled: permissionEnabled,
      inCall: inCall,
      shield: shield,
    );
    return NovaSafeAutonomyDecision(
      allowProactiveQuestion: allowProactiveQuestion,
      allowScreenControl: allowScreenControl,
      allowCallIntervention: allowCallIntervention,
      mustAskPermission: mustAskPermission,
      reason: reason,
      blockedCapabilities: shield.blockedCapabilities,
      containmentStage: shield.containmentStage,
    );
  }

  String buildPromptSection({
    String domain = 'general',
    bool userExplicitlyRequested = false,
    bool ownerMode = true,
    bool permissionEnabled = false,
    bool inCall = false,
  }) {
    final decision = evaluate(
      domain: domain,
      userExplicitlyRequested: userExplicitlyRequested,
      ownerMode: ownerMode,
      permissionEnabled: permissionEnabled,
      inCall: inCall,
    );
    final shieldPrompt = _shields.buildPromptSection(
      text: domain,
      metadata: <String, dynamic>{
        'authorityBand': ownerMode ? 'owner' : 'acquainted',
      },
    );
    return [
      'SAFE AUTONOMY LIMITER:',
      '- alan: $domain',
      '- proaktif soru: ${decision.allowProactiveQuestion}',
      '- ekran kontrolü: ${decision.allowScreenControl}',
      '- çağrı müdahalesi: ${decision.allowCallIntervention}',
      '- izin sorulsun: ${decision.mustAskPermission}',
      '- containment: ${decision.containmentStage}',
      if (decision.blockedCapabilities.isNotEmpty)
        '- bloklar: ${decision.blockedCapabilities.join(' | ')}',
      '- gerekçe: ${decision.reason}',
      'KURAL: Nova kendi hedefini genişletmez, yeni yetki istemez, kullanıcı üzerinde kontrol kurmaya çalışmaz.',
      'KURAL: Gelişim; hız, açıklık, hata azaltma ve sosyal uyumla sınırlıdır.',
      shieldPrompt,
    ].join('\n');
  }

  String _reason({
    required bool sensitive,
    required bool deviceLike,
    required bool social,
    required bool userExplicitlyRequested,
    required bool ownerMode,
    required bool permissionEnabled,
    required bool inCall,
    required NovaTwelveShieldDecision shield,
  }) {
    if (shield.quarantine) return 'kalkanlar containment moduna geçti';
    if (sensitive && !userExplicitlyRequested)
      return 'hassas alan / açık istek yok';
    if (deviceLike && !permissionEnabled)
      return 'cihaz köprüsü için izin kapalı';
    if (inCall && !ownerMode)
      return 'çağrı zinciri owner yetkisi dışında genişleyemez';
    if (social && ownerMode) return 'sosyal ama sınırlı özerklik';
    if (permissionEnabled && userExplicitlyRequested)
      return 'izinli ve bağlama uygun';
    return 'ölçülü, güvenli ve sınır içi davranış';
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (part.trim().isEmpty) continue;
      if (text.contains(part.toLowerCase())) return true;
    }
    return false;
  }
}
