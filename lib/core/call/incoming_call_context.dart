// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/contacts/nova_contact.dart';

class IncomingCallContext {
  final String phoneNumber;
  final NovaContact? matchedContact;

  /// Kullanıcı o anda aktif geçici durumda mı
  final bool hasActiveStatus;
  final String? activeStatusLabel;

  /// Nova uyku modunda mı
  final bool novaSleeping;

  /// Çağrı yönetimi özelliği açık mı
  final bool callHandlingEnabled;

  const IncomingCallContext({
    required this.phoneNumber,
    required this.matchedContact,
    required this.hasActiveStatus,
    required this.activeStatusLabel,
    required this.novaSleeping,
    required this.callHandlingEnabled,
  });

  bool get hasKnownContact => matchedContact != null;

  bool get canNovaHandleThisCaller {
    if (matchedContact == null) return false;
    return matchedContact!.allowsCallHandling;
  }

  String get incomingCallerAnnouncement {
    if (matchedContact == null) {
      return 'Bilinmeyen bir numara arıyor efendim.';
    }

    return matchedContact!.incomingCallText;
  }
}
