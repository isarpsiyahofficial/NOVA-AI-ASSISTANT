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

    test('unused Android SpeechRecognizer authority files stay removed', () {
      expect(
        File(
          'android/app/src/main/kotlin/com/example/nova/NovaSpeechRecognizerHelper.kt',
        ).existsSync(),
        isFalse,
      );
      expect(
        File(
          'android/app/src/main/kotlin/com/example/nova/NovaSpeechSessionManager.kt',
        ).existsSync(),
        isFalse,
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

    test('native ASR pause and stop release the microphone gate', () {
      final bridge = _read(
        'android/app/src/main/kotlin/com/example/nova/asr/NovaStreamingAsrBridgePlugin.kt',
      );
      final service = _read(
        'android/app/src/main/kotlin/com/example/nova/asr/NovaAsrForegroundService.kt',
      );

      final pauseCase = bridge.indexOf('"pauseStreamingAsr"');
      final pauseGateStop = bridge.indexOf('stopVoiceGate()', pauseCase);
      final resumeCase = bridge.indexOf('"resumeStreamingAsr"');
      final resumeGateStart = bridge.indexOf('startVoiceGate()', resumeCase);
      final stopCase = bridge.indexOf('"stopStreamingAsr"');
      final stopGateStop = bridge.indexOf('stopVoiceGate()', stopCase);

      expect(pauseCase, greaterThanOrEqualTo(0));
      expect(pauseGateStop, greaterThan(pauseCase));
      expect(resumeGateStart, greaterThan(resumeCase));
      expect(stopGateStop, greaterThan(stopCase));
      expect(service, contains('return START_NOT_STICKY'));
      expect(service, contains('NovaStreamingVoiceGate.stop()'));
    });

    test('microphone gate uses packaged Silero VAD as speech authority', () {
      final gate = _read(
        'android/app/src/main/kotlin/com/example/nova/NovaStreamingVoiceGate.kt',
      );

      expect(gate, contains('import com.k2fsa.sherpa.onnx.Vad'));
      expect(gate, contains('private const val FRAME_SAMPLES = 512'));
      expect(gate, contains('activeVad.acceptWaveform(floatFrame)'));
      expect(gate, contains('activeVad.isSpeechDetected()'));
      expect(gate, contains('fun takeCompletedSpeechPcm('));
      expect(gate, contains('vadEngine" to "sherpa_onnx_silero_vad'));
      expect(gate, isNot(contains('rms >= openThreshold')));
      expect(gate, isNot(contains('speechOpenCounter >= 3')));
    });

    test('Whisper decodes each VAD segment once and throttles partials', () {
      final engine = _read(
        'android/app/src/main/kotlin/com/example/nova/asr/NovaStreamingAsrEngine.kt',
      );

      expect(engine, contains('NovaStreamingVoiceGate.takeCompletedSpeechPcm(28)'));
      expect(engine, contains('decodeFinalSegment(completed, onEvent)'));
      expect(engine, contains('PARTIAL_DECODE_INTERVAL_MS = 2_800L'));
      expect(
        engine,
        contains('decodePolicy" to "silero_segment_once_partial_throttled'),
      );
      final loopStart = engine.indexOf('private fun startContinuousLoop(');
      final warmupStart = engine.indexOf('private fun warmupRecognizer(');
      final loop = engine.substring(loopStart, warmupStart);
      expect(loop, isNot(contains('decodeStreamingSnapshot(')));
      expect(loop, isNot(contains('Thread.sleep(1500')));
    });

    test('heavy native ASR operations run on one worker thread', () {
      final bridge = _read(
        'android/app/src/main/kotlin/com/example/nova/asr/NovaStreamingAsrBridgePlugin.kt',
      );

      expect(bridge, contains('Executors.newSingleThreadExecutor'));
      expect(bridge, contains('NovaAsrNativeWorker'));
      expect(bridge, contains('"initializeStreamingAsr" -> runAsync'));
      expect(bridge, contains('"startStreamingAsr" ->'));
      expect(bridge, contains('runAsync(result) { startRuntime(foreground) }'));
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

      expect(
        source,
        contains('NOVA_TTS_LOW_LATENCY_HANDOFF_V2_SHERPA_PRIMARY'),
      );
      expect(source, isNot(contains('Duration(milliseconds: 550)')));
      final playbackEnd = source.indexOf(
        'await playbackGuardService.markPlaybackEnded();',
      );
      final clearBuffer = source.indexOf(
        'await streamingAsrBridgeService.clearBuffer();',
        playbackEnd,
      );
      final resume = source.indexOf(
        'await NovaStreamingAsrRuntimeService.resumeAfterPlayback(',
        clearBuffer,
      );
      expect(playbackEnd, greaterThanOrEqualTo(0));
      expect(clearBuffer, greaterThan(playbackEnd));
      expect(resume, greaterThan(clearBuffer));
    });

    test('normal Nova speech explicitly selects offline sherpa profile', () {
      final source = _read('lib/services/tts/nova_tts_service.dart');
      expect(source, contains("speakerPath: 'sherpa_default'"));
      expect(
        source,
        contains(
          'enginePolicy=sherpa_offline_primary_platform_explicit_fallback',
        ),
      );
    });

    test('native mouth is a real sherpa OfflineTts engine', () {
      final engine = _read(
        'android/app/src/main/kotlin/com/example/nova/NovaXttsEngine.kt',
      );
      final bridge = _read(
        'android/app/src/main/kotlin/com/example/nova/NovaXttsBridgePlugin.kt',
      );

      expect(engine, contains('import com.k2fsa.sherpa.onnx.OfflineTts'));
      expect(engine, contains('OfflineTtsVitsModelConfig'));
      expect(engine, contains('activeEngine.generate('));
      expect(engine, contains('AudioTrack.Builder()'));
      expect(engine, isNot(contains('NovaAndroidTtsMouthEngine.speak(')));
      expect(bridge, contains('NovaSherpaTtsWarmup'));
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

    test('launch gate cannot bypass verified first-run setup', () {
      final launch = _read('lib/ui/launch/nova_launch_gate_page.dart');
      final setup = _read(
        'lib/ui/onboarding/nova_first_run_setup_v2_page.dart',
      );

      expect(launch, contains('NOVA_LAUNCH_GATE_VERIFIED_SETUP_V2'));
      expect(launch, contains('NovaFirstRunSetupV2Page('));
      expect(launch, isNot(contains('_buildDashboard(setupRequired: true)')));
      expect(setup, contains('enrollVoiceprintFromFile('));
      expect(setup, contains('identifyVoiceFromFile('));
      final enroll = setup.indexOf('enrollVoiceprintFromFile(');
      final identify = setup.indexOf('identifyVoiceFromFile(');
      final complete = setup.indexOf('markOnboardingCompleted()');
      expect(enroll, greaterThanOrEqualTo(0));
      expect(identify, greaterThan(enroll));
      expect(complete, greaterThan(identify));
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


    test('active launch dashboard creates typed authority and a current turn lease', () {
      final launch = _read('lib/ui/launch/nova_launch_gate_page.dart');
      final dashboard = _read('lib/ui/dashboard/dashboard_page.dart');
      final hotpath = _read(
        'lib/services/runtime/nova_hotpath_owner_service.dart',
      );

      expect(launch, contains("import '../dashboard/dashboard_page.dart';"));
      expect(launch, contains('return DashboardPage('));
      expect(dashboard, contains('NovaTurnLeaseController.instance.begin('));
      expect(dashboard, contains('_typedAuthorityForPrompt('));
      expect(dashboard, contains('authority: turnAuthority'));
      expect(dashboard, contains('lease: turnLease'));
      expect(hotpath, contains('authority: aiRequest.authority'));
      expect(hotpath, contains('lease: aiRequest.lease'));
      expect(
        hotpath,
        contains("aiRequest.metadata['allowLegacyRuntimeBroker'] == true"),
      );
    });

    test('voice transcript and owner proof come from the same captured PCM segment', () {
      final dashboard = _read('lib/ui/dashboard/dashboard_page.dart');
      final stt = _read('lib/services/stt/nova_speech_to_text_service.dart');

      expect(dashboard, contains('widget.sttService.transcribe('));
      expect(dashboard, contains("'nativeActionToken': sttResult.nativeActionToken"));
      expect(stt, contains('identifyVoiceFromFile('));
      expect(stt, contains('nativeActionToken: matchedOwner'));
    });

    test('CI never labels a debug-signed APK as a production release', () {
      final gradle = _read('android/app/build.gradle.kts');
      final tecnoWorkflow = _read(
        '.github/workflows/nova-tecno-arm64-apk.yml',
      );
      final runtimeWorkflow = _read(
        '.github/workflows/nova-runtime-integrity.yml',
      );

      expect(
        gradle,
        isNot(contains('signingConfig = signingConfigs.getByName("debug")')),
      );
      expect(tecnoWorkflow, contains('NOVA-TECNO-ARM64-INTERNAL-TEST'));
      expect(tecnoWorkflow, contains('flutter build apk --debug'));
      expect(tecnoWorkflow, isNot(contains('NOVA-TECNO-ARM64-RELEASE')));
      expect(runtimeWorkflow, isNot(contains('flutter build apk --release')));
    });
  });
}
