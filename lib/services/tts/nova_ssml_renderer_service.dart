// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/tts/nova_prosody_plan.dart';

class NovaSsmlRendererService {
  const NovaSsmlRendererService();

  String renderPlainSpeech(String text, NovaProsodyPlan plan) {
    var value = text.trim();
    if (value.isEmpty) return value;

    value = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(RegExp(r'([,:;])\s+'), (m) => '${m.group(1)} ')
        .trim();

    if (plan.mediumPauseMs >= 220) {
      value = value.replaceAllMapped(
        RegExp(
          r',\s*(ama|fakat|ancak|çünkü|cunku|yalnız|yalniz|ardından|ardindan|sonra da)\s+',
          caseSensitive: false,
        ),
        (m) => '. ${_upperFirst(m.group(1) ?? '')} ',
      );
    }

    if (plan.shortFormPreferred && value.length > 240) {
      final parts = _novaSplitAfterSentencePunctuation(
        value,
      ).where((e) => e.trim().isNotEmpty).take(2).join(' ').trim();
      value = parts.isEmpty ? value : parts;
    }

    if (plan.emphasis >= 0.10) {
      value = value.replaceAllMapped(
        RegExp(
          r'\b(önce|şimdi|özellikle|dikkat|kritik|net olarak)\b',
          caseSensitive: false,
        ),
        (m) => _upperFirst(m.group(0) ?? ''),
      );
    }

    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _upperFirst(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}

List<String> _novaSplitAfterSentencePunctuation(String text) {
  if (text.trim().isEmpty) return <String>[];
  const marker = '\u0000NOVA_SENTENCE_BREAK\u0000';
  return text
      .replaceAllMapped(RegExp(r'([.!?])\s+'), (m) => '${m.group(1)}$marker')
      .split(marker);
}
