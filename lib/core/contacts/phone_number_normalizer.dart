// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class PhoneNumberNormalizer {
  const PhoneNumberNormalizer._();

  static String normalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final buffer = StringBuffer();
    var hasPlus = false;

    for (var i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];
      if (char == '+' && !hasPlus && buffer.isEmpty) {
        hasPlus = true;
        buffer.write(char);
        continue;
      }

      final code = char.codeUnitAt(0);
      if (code >= 48 && code <= 57) {
        buffer.write(char);
      }
    }

    var normalized = buffer.toString();
    if (normalized.startsWith('00')) {
      normalized = '+${normalized.substring(2)}';
    }

    if (normalized.startsWith('+90') && normalized.length == 13) {
      return normalized;
    }

    if (normalized.length == 10) {
      return '+90$normalized';
    }

    if (normalized.length == 11 && normalized.startsWith('0')) {
      return '+90${normalized.substring(1)}';
    }

    return normalized;
  }

  static bool looselyMatches(String a, String b) {
    final left = normalize(a);
    final right = normalize(b);

    if (left.isEmpty || right.isEmpty) return false;
    if (left == right) return true;

    final leftDigits = left.replaceAll(RegExp(r'[^0-9]'), '');
    final rightDigits = right.replaceAll(RegExp(r'[^0-9]'), '');

    if (leftDigits == rightDigits) return true;

    if (leftDigits.length >= 10 && rightDigits.length >= 10) {
      return leftDigits.substring(leftDigits.length - 10) ==
          rightDigits.substring(rightDigits.length - 10);
    }

    return false;
  }
}
