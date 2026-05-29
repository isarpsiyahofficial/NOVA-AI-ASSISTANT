// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaSelfRepairCommandParseResult {
  final bool matched;
  final bool wantsRepair;
  final String requestedArea;
  final String message;

  const NovaSelfRepairCommandParseResult({
    required this.matched,
    required this.wantsRepair,
    required this.requestedArea,
    required this.message,
  });
}

class NovaSelfRepairCommandService {
  const NovaSelfRepairCommandService();

  NovaSelfRepairCommandParseResult parse(String input) {
    final text = input.trim();
    final lower = text.toLowerCase();
    final matched = const <String>[
      'kendini onar',
      'onarım başlat',
      'onarım paneli',
      'sorunu onar',
      'tamir et',
      'kendini tamir et',
    ].any(lower.contains);
    if (!matched) {
      return const NovaSelfRepairCommandParseResult(
        matched: false,
        wantsRepair: false,
        requestedArea: '',
        message: 'Self repair komutu algılanmadı.',
      );
    }

    final requestedArea = _extractArea(text);
    return NovaSelfRepairCommandParseResult(
      matched: true,
      wantsRepair: true,
      requestedArea: requestedArea,
      message: requestedArea.isEmpty
          ? 'Genel onarım isteği algılandı.'
          : '$requestedArea alanı için onarım isteği algılandı.',
    );
  }

  String _extractArea(String input) {
    final lower = input.toLowerCase();
    const markers = <String>[
      'şu işlevinde',
      'şu özelliğinde',
      'şu alanda',
      'bu alanda',
      'şu modülde',
      'şu tarafta',
    ];
    for (final marker in markers) {
      final index = lower.indexOf(marker);
      if (index >= 0) {
        final sliced = input.substring(index + marker.length).trim();
        final cleaned = sliced
            .replaceAll(
              RegExp(r'bir problem var', caseSensitive: false, unicode: true),
              '',
            )
            .replaceAll(
              RegExp(r'problem var', caseSensitive: false, unicode: true),
              '',
            )
            .replaceAll(
              RegExp(r'kendini onar', caseSensitive: false, unicode: true),
              '',
            )
            .replaceAll(
              RegExp(r'tamir et', caseSensitive: false, unicode: true),
              '',
            )
            .trim();
        return cleaned;
      }
    }
    return '';
  }
}
