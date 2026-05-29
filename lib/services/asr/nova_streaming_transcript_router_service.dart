// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.

import '../runtime/nova_turkish_pragmatics_core_service.dart';
import '../runtime/nova_turkish_pragmatics_engine_service.dart';
import '../runtime/nova_turkish_discourse_marker_parser_service.dart';
import '../runtime/nova_conversation_act_detector_service.dart';
import '../runtime/nova_identity_runtime_service.dart';

import '../../core/asr/nova_streaming_asr_event.dart';

class NovaStreamingTranscriptRouteDecision {
  final String route;
  final String normalizedText;

  const NovaStreamingTranscriptRouteDecision({
    required this.route,
    required this.normalizedText,
  });
}

class NovaStreamingTranscriptRouterService {
  const NovaStreamingTranscriptRouterService();

  static const NovaConversationActDetectorService _actDetector =
      NovaConversationActDetectorService();
  static const NovaTurkishPragmaticsCoreService _core =
      NovaTurkishPragmaticsCoreService();
  static const NovaTurkishPragmaticsEngineService _pragmatics =
      NovaTurkishPragmaticsEngineService();
  static const NovaTurkishDiscourseMarkerParserService _markers =
      NovaTurkishDiscourseMarkerParserService();
  static const NovaIdentityRuntimeService _identity =
      NovaIdentityRuntimeService();

  NovaStreamingTranscriptRouteDecision decide(NovaStreamingAsrEvent event) {
    final text = event.transcript.text.trim();
    final normalized = text.toLowerCase();
    final folded = _asciiFold(normalized);
    if (normalized.isEmpty) {
      return const NovaStreamingTranscriptRouteDecision(
        route: 'ignore',
        normalizedText: '',
      );
    }
    if (_containsAny(folded, const [
      'hatirlat',
      'hatirlatir misin',
      'yarin',
      'bugun',
      'alarm kur',
      'beni uyar',
    ])) {
      return NovaStreamingTranscriptRouteDecision(
        route: 'reminder',
        normalizedText: text,
      );
    }
    final act = _actDetector.detect(text);
    final pragmatics = _pragmatics.analyze(text);
    _markers.parse(text);
    _core.analyze(text);
    final addressedToAssistant =
        _identity.isAddressedToAssistant(normalized) ||
        _identity.isAddressedToAssistant(folded) ||
        _containsAny(folded, const [
          'nova',
          'jarviz',
          'carvis',
          'nova',
          'fryday',
          'efendim',
        ]);
    final repairCue =
        act.isRepairCue || _looksLikeRepairOrRuntimeCommand(folded);
    if (repairCue) {
      return NovaStreamingTranscriptRouteDecision(
        route: 'command',
        normalizedText: text,
      );
    }
    if (act.isCommandLike &&
        (addressedToAssistant || pragmatics.hasIndirectRequest)) {
      return NovaStreamingTranscriptRouteDecision(
        route: 'command',
        normalizedText: text,
      );
    }
    if (_containsAny(folded, const [
      'ogren',
      'bundan sonra',
      'bunu boyle yap',
      'sunlari hatirla',
    ])) {
      return NovaStreamingTranscriptRouteDecision(
        route: 'teaching',
        normalizedText: text,
      );
    }
    if (_containsAny(folded, const [
      'ara ',
      ' ara',
      'telefon',
      'cagri',
      'cevapla',
      'devral',
      'hoparlor',
      'mikrofon',
    ])) {
      return NovaStreamingTranscriptRouteDecision(
        route: 'call',
        normalizedText: text,
      );
    }
    if (addressedToAssistant &&
        (act.expectsResponse ||
            act.isSocialCue ||
            act.isEmotionCue ||
            repairCue)) {
      return NovaStreamingTranscriptRouteDecision(
        route: 'conversation',
        normalizedText: text,
      );
    }
    return NovaStreamingTranscriptRouteDecision(
      route: addressedToAssistant ? 'conversation' : 'ambient',
      normalizedText: text,
    );
  }

  bool _containsAny(String text, List<String> needles) {
    for (final needle in needles) {
      final normalizedNeedle = _asciiFold(needle);
      if (normalizedNeedle.isNotEmpty && text.contains(normalizedNeedle))
        return true;
    }
    return false;
  }

  String _asciiFold(String input) {
    return input
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _looksLikeRepairOrRuntimeCommand(String normalized) {
    final text = normalized.trim();
    if (text.isEmpty) return false;
    const repairTokens = <String>[
      'onar',
      'tamir',
      'düzelt',
      'duzelt',
      'çalışmıyor',
      'calismiyor',
      'cevap vermiyor',
      'robotik',
      'sabit metin',
      'fallback',
      'mikrofon',
      'asr',
      'stt',
      'dinleme',
      'beni duymuyor',
      'sesimi algılamıyor',
      'sesimi algilamiyor',
      'overlay',
      'katman görünmüyor',
      'katman gorunmuyor',
      'yerel model',
      'gemma',
      'yavaş',
      'yavas',
      'native inference',
    ];
    return repairTokens.any(text.contains);
  }
}
