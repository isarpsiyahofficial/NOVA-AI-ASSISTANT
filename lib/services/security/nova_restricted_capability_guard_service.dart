// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

import 'nova_security_quarantine_service.dart';
import 'nova_security_diagnostic_mode_service.dart';

class NovaRestrictedCapabilityGuardResult {
  final bool blocked;
  final bool quarantined;
  final String spokenText;

  const NovaRestrictedCapabilityGuardResult({
    required this.blocked,
    required this.quarantined,
    required this.spokenText,
  });
  const NovaRestrictedCapabilityGuardResult.allow()
    : blocked = false,
      quarantined = false,
      spokenText = '';
}

class NovaRestrictedCapabilityGuardService {
  final NovaSecurityQuarantineService quarantineService;
  const NovaRestrictedCapabilityGuardService({required this.quarantineService});

  Future<NovaRestrictedCapabilityGuardResult> evaluatePhoneControlRequest(
    String raw,
  ) async {
    if (await const NovaSecurityDiagnosticModeService().isPassive()) {
      print('NOVA_SECURITY_DIAGNOSTIC_PASSIVE_RESTRICTED_CAPABILITY_ALLOW');
      return const NovaRestrictedCapabilityGuardResult.allow();
    }
    final n = _normalize(raw);
    if (n.isEmpty) return const NovaRestrictedCapabilityGuardResult.allow();
    final mentionsPhoneControl =
        n.contains('uygulama') ||
        n.contains('ac') ||
        n.contains('aç') ||
        n.contains('kontrol et') ||
        n.contains('telefonu yonet') ||
        n.contains('telefonu yönet');
    if (!mentionsPhoneControl)
      return const NovaRestrictedCapabilityGuardResult.allow();

    final allowedMedia = n.contains('spotify') || n.contains('youtube music');
    final callException =
        n.contains('ara ') ||
        n.contains('arama') ||
        n.contains('çağrı') ||
        n.contains('cagri');
    if (allowedMedia || callException) {
      return const NovaRestrictedCapabilityGuardResult.allow();
    }

    final state = await quarantineService.registerStrike(
      reason:
          'İzin verilmeyen telefon kontrol girişimi algılandı. Sadece Spotify / YouTube Music ve çağrı akışı açıktır.',
    );
    return NovaRestrictedCapabilityGuardResult(
      blocked: true,
      quarantined: state.quarantined,
      // Security guards may block actions, but they must not author Nova speech.
      // The UI/debug layer can inspect blocked/quarantined and the AI turn
      // controller can summarize a structured denial if needed.
      spokenText: '',
    );
  }

  String _normalize(String raw) => raw
      .toLowerCase()
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u')
      .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
