// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaTurkishDiscourseMarkerDecision {
  final List<String> markers;
  final bool signalsContinuation;
  final bool signalsRepair;
  final bool signalsHesitation;
  final bool signalsEmphasis;

  const NovaTurkishDiscourseMarkerDecision({
    required this.markers,
    required this.signalsContinuation,
    required this.signalsRepair,
    required this.signalsHesitation,
    required this.signalsEmphasis,
  });

  String buildPromptSection() {
    return 'TÜRKÇE SÖYLEM BELİRTEÇLERİ: ${markers.join(" | ")}; devam=$signalsContinuation; onarım=$signalsRepair; tereddüt=$signalsHesitation; vurgu=$signalsEmphasis';
  }

  bool get signalsTurnHolding => signalsContinuation;
}

class NovaTurkishDiscourseMarkerParserService {
  const NovaTurkishDiscourseMarkerParserService();

  NovaTurkishDiscourseMarkerDecision parse(String raw) {
    final text = raw.toLowerCase();
    final markers = <String>[];
    void add(String value) {
      if (!markers.contains(value)) markers.add(value);
    }

    for (final m in const [
      'ya',
      'hani',
      'işte',
      'şey',
      'yani',
      'aslında',
      'bak',
      'tamam da',
      'neyse',
    ]) {
      if (text.contains(m)) add(m);
    }
    final continuation = markers.any(
      (m) => const ['hani', 'yani', 'işte'].contains(m),
    );
    final repair = markers.any(
      (m) => const ['aslında', 'yani', 'şey'].contains(m),
    );
    final hesitation = markers.any(
      (m) => const ['şey', 'hani', 'yani'].contains(m),
    );
    final emphasis = markers.any(
      (m) => const ['bak', 'tamam da', 'ya'].contains(m),
    );
    return NovaTurkishDiscourseMarkerDecision(
      markers: markers,
      signalsContinuation: continuation,
      signalsRepair: repair,
      signalsHesitation: hesitation,
      signalsEmphasis: emphasis,
    );
  }
}
