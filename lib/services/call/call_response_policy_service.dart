// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/contacts/nova_contact.dart';

class CallResponsePolicyService {
  const CallResponsePolicyService();

  String buildDefaultConversationOpening({
    required NovaContact? contact,
    required String? activeStatusLabel,
  }) {
    if (activeStatusLabel == 'sleeping') {
      return 'Ben Nova. İbrahim şu an uyuyor. İsterseniz not bırakabilirsiniz.';
    }

    if (activeStatusLabel == 'driving') {
      return 'Ben Nova. İbrahim şu an araç kullanıyor. Acilse bana söyleyebilirsiniz.';
    }

    if (activeStatusLabel == 'showering') {
      return 'Ben Nova. İbrahim şu an telefona bakamıyor. İsterseniz not bırakabilirsiniz.';
    }

    if (activeStatusLabel == 'busy') {
      return 'Ben Nova. İbrahim şu an büyük ihtimalle müsait değil. İsterseniz not bırakabilirsiniz.';
    }

    if (contact != null) {
      final relation = contact.relationshipSpeech;
      final name = contact.displayName.trim().isEmpty
          ? 'İbrahim'
          : contact.displayName.trim();
      return '$relation İbrahim şu an müsait değil. Ben Nova. Hoş geldiniz $name. Dilerseniz not bırakabilir, acilse uyandırmamı isteyebilir ya da kısa bir sohbet başlatabilirsiniz.';
    }

    return 'Ben Nova. Şu an onun yerine ben açtım. İsterseniz not bırakabilirsiniz.';
  }

  String buildUnauthorizedUseResponse(String ownerName) {
    return '$ownerName izni olmadan bunu yapamam. Sözlü izin vermesi gerekiyor.';
  }

  String buildUrgencyQuestion() {
    return 'Bu konu acil mi efendim? Gerekirse hemen iletebilirim.';
  }
}
