// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/phone_control/phone_control_state.dart';

class PhoneControlGuardDecision {
  final bool shouldWarn;
  final bool shouldAutoDisable;
  final String message;

  const PhoneControlGuardDecision({
    required this.shouldWarn,
    required this.shouldAutoDisable,
    required this.message,
  });
}

class PhoneControlGuardService {
  const PhoneControlGuardService();

  PhoneControlGuardDecision evaluate({
    required PhoneControlState state,
    required int timeoutMinutes,
    required bool userRespondedToWarning,
  }) {
    if (!state.enabled || state.enabledAt == null) {
      return const PhoneControlGuardDecision(
        shouldWarn: false,
        shouldAutoDisable: false,
        message: '',
      );
    }

    final elapsed = DateTime.now().difference(state.enabledAt!);
    if (elapsed.inMinutes < timeoutMinutes) {
      return const PhoneControlGuardDecision(
        shouldWarn: false,
        shouldAutoDisable: false,
        message: '',
      );
    }

    if (!userRespondedToWarning) {
      return const PhoneControlGuardDecision(
        shouldWarn: true,
        shouldAutoDisable: false,
        message:
            'Efendim telefon yönetimini açık unuttunuz. Kapatmak ister misiniz?',
      );
    }

    return const PhoneControlGuardDecision(
      shouldWarn: false,
      shouldAutoDisable: true,
      message: 'Telefon yönetimi güvenlik gereği otomatik kapatıldı efendim.',
    );
  }
}
