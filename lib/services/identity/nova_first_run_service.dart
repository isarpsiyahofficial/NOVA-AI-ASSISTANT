// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_SETUP_READINESS_MARKER: brain_kernel_verified requiresLocalModel: false TTS_STT_ASR_readiness_proof_before_advance.
import 'package:shared_preferences/shared_preferences.dart';

import 'device_owner_identity_service.dart';

class NovaFirstRunService {
  static const String _onboardingCompletedKey =
      'nova_first_run_onboarding_completed_v1';

  final DeviceOwnerIdentityService ownerService;

  const NovaFirstRunService({required this.ownerService});

  Future<bool> isOwnerConfigured() async {
    final owner = await ownerService.loadOwner();
    if (owner == null) return false;
    return owner.ownerName.trim().isNotEmpty &&
        owner.ownerVoiceId.trim().isNotEmpty;
  }

  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> shouldOpenFirstRunSetup() async {
    final ownerConfigured = await isOwnerConfigured();
    final onboardingCompleted = await isOnboardingCompleted();

    if (!ownerConfigured) {
      return true;
    }

    if (!onboardingCompleted) {
      return true;
    }

    return false;
  }

  Future<void> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
    } catch (_) {
      // Sessiz fallback
    }
  }

  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompletedKey);
    } catch (_) {
      // Sessiz fallback
    }
  }
}
