import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('Nova runtime integrity contracts', () {
    test('normal turns use the shared humanized NovaAiService', () {
      final source = _read('lib/core/turn/nova_core_turn_controller.dart');

      expect(source, contains('runAi: sharedAi.process'));
      expect(source, contains("'usedSharedNovaAiService': true"));
      expect(source, isNot(contains('runAi: apiService.send')));
      expect(source, isNot(contains('runAi: ApiService')));
    });

    test('runtime graph rejects a second NovaAiService decision root', () {
      final source = _read(
        'lib/services/runtime/nova_runtime_graph_service.dart',
      );

      expect(source, contains('NOVA_RUNTIME_GRAPH_DUPLICATE_AI_REJECTED'));
      expect(
        source,
        contains('A second NovaAiService decision root was created'),
      );
      expect(source, contains('NovaAiService get sharedAiOrThrow'));
    });

    test('STT uses embedded streaming ASR without snapshot fallback', () {
      final source = _read('lib/services/stt/nova_speech_to_text_service.dart');

      expect(source, contains('NOVA_STREAMING_ASR_NO_FALLBACK_V1'));
      expect(source, contains('streamingAsrRuntimeService.events.listen'));
      expect(source, isNot(contains('decodeStreamingSnapshot(')));
      expect(
        source,
        isNot(contains('Platform SpeechRecognizer fallback kullanıldı')),
      );
    });

    test('ASR ownership transfer stops the native engine first', () {
      final source = _read(
        'lib/services/asr/nova_streaming_asr_runtime_service.dart',
      );

      expect(
        source,
        contains('NOVA_ASR_SINGLE_SESSION_OWNER_GUARD_V4_EXPLICIT_TRANSFER'),
      );
      expect(source, contains('await bridgeService.stop();'));
      expect(source, contains("code: 'streaming_asr_owner_transferred'"));
      expect(source, contains("'nativeStoppedBeforeTransfer': true"));
    });

    test('ambient ASR route is never forced back into conversation', () {
      final source = _read(
        'lib/services/asr/nova_streaming_asr_runtime_service.dart',
      );

      expect(source, contains('final forceEligibleRoute ='));
      expect(source, contains("routeDecision.route == 'call'"));
      expect(source, isNot(contains("routeDecision.route != 'ignore'")));
      expect(source, contains("effectiveRoute == 'ambient'"));
    });

    test('TTS resumes ASR without a fixed post-speech delay', () {
      final source = _read('lib/services/tts/nova_tts_service.dart');

      expect(source, contains('NOVA_TTS_LOW_LATENCY_HANDOFF_V1'));
      expect(source, isNot(contains('Duration(milliseconds: 550)')));
      final playbackEnd = source.indexOf(
        'await playbackGuardService.markPlaybackEnded();',
      );
      final clearBuffer = source.indexOf(
        'await streamingAsrBridgeService.clearBuffer();',
        playbackEnd,
      );
      final resume = source.indexOf(
        'await streamingAsrBridgeService.resume();',
        clearBuffer,
      );
      expect(playbackEnd, greaterThanOrEqualTo(0));
      expect(clearBuffer, greaterThan(playbackEnd));
      expect(resume, greaterThan(clearBuffer));
    });

    test('playback echo cooldown stays short and uses in-memory state', () {
      final source = _read(
        'lib/services/audio_runtime/nova_playback_echo_filter_service.dart',
      );

      expect(source, contains('Duration(milliseconds: 320)'));
      expect(source, contains('static bool _active = false;'));
      expect(source, contains('static String _lastText'));
      expect(source, isNot(contains('Duration(milliseconds: 2600)')));
    });

    test('native ASR bridge never invokes Android SpeechRecognizer fallback', () {
      final source = _read(
        'android/app/src/main/kotlin/com/example/nova/NovaNativeAudioBridgePlugin.kt',
      );

      expect(source, contains('usedPlatformSpeechRecognizerFallback" to false'));
      expect(source, isNot(contains('NovaSpeechRecognizerHelper(')));
      expect(source, isNot(contains('fallbackToPlatformRecognizer')));
    });

    test('ambient phrases cannot become new reminder or call commands', () {
      final source = _read(
        'lib/services/asr/nova_streaming_transcript_router_service.dart',
      );

      expect(source, contains('NOVA_ADDRESS_FIRST_ROUTING_V1'));
      final ambientGate = source.indexOf('if (!addressedToAssistant)');
      final reminderRoute = source.indexOf("route: 'reminder'");
      final callRoute = source.indexOf("route: 'call'");
      expect(ambientGate, greaterThanOrEqualTo(0));
      expect(reminderRoute, greaterThan(ambientGate));
      expect(callRoute, greaterThan(ambientGate));
    });

    test('voice clone cannot report reference-file copying as a real clone', () {
      final source = _read(
        'android/app/src/main/kotlin/com/example/nova/NovaCloneEngineAdapter.kt',
      );

      expect(source, contains('realCloneEngineRequired'));
      expect(source, contains('referenceOnlyFallbackUsed" to false'));
      expect(source, isNot(contains('createReferenceFallback')));
      expect(source, isNot(contains('Referans ses profili oluşturuldu')));
    });
  });
}
