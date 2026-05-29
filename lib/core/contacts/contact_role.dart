// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum ContactRole {
  mother,
  father,
  brother,
  sister,
  spouse,
  child,
  friend,
  relative,
  custom,
}

extension ContactRoleX on ContactRole {
  String get key {
    switch (this) {
      case ContactRole.mother:
        return 'mother';
      case ContactRole.father:
        return 'father';
      case ContactRole.brother:
        return 'brother';
      case ContactRole.sister:
        return 'sister';
      case ContactRole.spouse:
        return 'spouse';
      case ContactRole.child:
        return 'child';
      case ContactRole.friend:
        return 'friend';
      case ContactRole.relative:
        return 'relative';
      case ContactRole.custom:
        return 'custom';
    }
  }

  String get label {
    switch (this) {
      case ContactRole.mother:
        return 'Anne';
      case ContactRole.father:
        return 'Baba';
      case ContactRole.brother:
        return 'Abi/Erkek Kardeş';
      case ContactRole.sister:
        return 'Abla/Kız Kardeş';
      case ContactRole.spouse:
        return 'Eş';
      case ContactRole.child:
        return 'Çocuk';
      case ContactRole.friend:
        return 'Arkadaş';
      case ContactRole.relative:
        return 'Akraba';
      case ContactRole.custom:
        return 'Özel';
    }
  }

  String buildIncomingCallText(String displayName) {
    switch (this) {
      case ContactRole.mother:
        return 'Anneniz arıyor.';
      case ContactRole.father:
        return 'Babanız arıyor.';
      case ContactRole.brother:
        return 'Erkek kardeşiniz arıyor.';
      case ContactRole.sister:
        return 'Kız kardeşiniz arıyor.';
      case ContactRole.spouse:
        return 'Eşiniz arıyor.';
      case ContactRole.child:
        return 'Çocuğunuz arıyor.';
      case ContactRole.friend:
        return 'Arkadaşınız $displayName arıyor.';
      case ContactRole.relative:
        return 'Yakınınız $displayName arıyor.';
      case ContactRole.custom:
        return '$displayName isimli kişi arıyor efendim.';
    }
  }
}
