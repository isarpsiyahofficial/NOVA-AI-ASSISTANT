// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/voice/voice_profile.dart';
import '../../core/voice/voice_profile_service.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import '../audio_runtime/nova_native_audio_bridge_service.dart';
import '../runtime/nova_runtime_signal_service.dart';

class TtsService {
  final VoiceProfileService voiceProfileService;
  final NovaNativeAudioBridgeService nativeBridge;

  static final FlutterTts _flutterTts = FlutterTts();

  static bool _initialized = false;
  static String _currentLanguage = 'tr-TR';
  static double _currentSpeechRate = 0.60;
  static double _currentPitch = 1.08;
  static Future<void> _operationQueue = Future<void>.value();
  static DateTime? _lastNativeCapabilityCheckAt;
  static bool _lastNativeCapabilityReady = false;
  static bool _lastNativeWarmupAttemptFailed = false;
  static bool _verifiedTurkishPlatformVoiceReady = false;
  static String _verifiedTurkishPlatformVoiceName = '';
  static const String _turkishVoiceCacheKey =
      'nova_verified_turkish_tts_voice_v1';
  static bool _cachedTurkishVoiceApplied = false;
  static const bool _verboseVoiceScanLogging = false;

  const TtsService({
    required this.voiceProfileService,
    required this.nativeBridge,
  });

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _operationQueue = _operationQueue.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (_) {}

    try {
      await _flutterTts.setSharedInstance(true);
    } catch (_) {}

    try {
      await _flutterTts.setQueueMode(0);
    } catch (_) {}

    try {
      await _flutterTts.setLanguage(_currentLanguage);
    } catch (_) {}

    try {
      await _flutterTts.setSpeechRate(_currentSpeechRate);
    } catch (_) {}

    try {
      await _flutterTts.setPitch(_currentPitch);
    } catch (_) {}

    try {
      await _flutterTts.setVolume(1.0);
    } catch (_) {}

    _initialized = true;
  }

  Future<void> setLanguage(String localeCode) {
    return _enqueue(() async {
      await _ensureInitialized();

      final normalized = _normalizeLocale(localeCode);
      _currentLanguage = normalized;

      try {
        await _flutterTts.setLanguage(normalized);
      } catch (_) {
        _currentLanguage = 'tr-TR';
        try {
          await _flutterTts.setLanguage(_currentLanguage);
        } catch (_) {}
      }

      if (_isTurkishLocale(_currentLanguage)) {
        final cached = await _tryApplyCachedTurkishVoice(
          requireFemaleForTurkish: true,
        );
        if (cached) return;
      }
      await _trySelectBestVoiceForLocale(
        _currentLanguage,
        requireFemaleForTurkish: _isTurkishLocale(_currentLanguage),
      );
    });
  }

  Future<void> setSpeechRate(double value) {
    return _enqueue(() async {
      await _ensureInitialized();

      final normalized = value.clamp(0.54, 0.72);
      _currentSpeechRate = normalized;

      try {
        await _flutterTts.setSpeechRate(normalized);
      } catch (_) {}
    });
  }

  Future<void> setPitch(double value) {
    return _enqueue(() async {
      await _ensureInitialized();

      final normalized = value.clamp(1.00, 1.20);
      _currentPitch = normalized;

      try {
        await _flutterTts.setPitch(normalized);
      } catch (_) {}
    });
  }

  Future<void> stop() {
    return _enqueue(() async {
      await _ensureInitialized();

      try {
        await _flutterTts.stop();
      } catch (_) {}

      try {
        await nativeBridge.stopSherpaTts();
      } catch (_) {}
    });
  }

  Future<void> speakSystem(String text) {
    return _enqueue(() async {
      await _ensureInitialized();

      final prepared = _prepareForSpeech(text);
      if (prepared.isEmpty) {
        throw StateError('Konuşulacak metin boş.');
      }

      if (_isTurkishLocale(_currentLanguage)) {
        final femaleVoiceReady = await _ensureVerifiedTurkishPlatformVoice();
        if (!femaleVoiceReady) {
          throw StateError(
            'Nova için doğrulanmış Türkçe kadın/insancıl ses bulunamadı; erkek/default TTS yasak.',
          );
        }
        debugPrint(
          'NOVA_TTS_ENGINE_SELECTED engine=platform_verified_female mode=system voice=$_verifiedTurkishPlatformVoiceName chars=${prepared.length}',
        );
        await _speakWithPlatformTts(prepared);
        return;
      }

      await _speakWithPlatformTts(prepared);
    });
  }

  Future<void> speak(
    String text, {
    String speakerPath = '',
    bool allowPlatformFallback = true,
  }) {
    return _enqueue(() async {
      await _ensureInitialized();

      final prepared = _prepareForSpeech(text);
      if (prepared.isEmpty) {
        throw StateError('Konuşulacak metin boş.');
      }

      final trimmedSpeakerPath = speakerPath.trim();

      if (_isTurkishLocale(_currentLanguage)) {
        // The DFKI/Sherpa model available in the current mobile package is a
        // single-speaker offline voice and may sound male/robotic on the target
        // device. For normal Nova Turkish speech without an explicit cloned
        // speaker, use only a verified female-like platform Turkish voice. Native
        // Sherpa remains available only when a caller explicitly requests a
        // speakerPath; it is never used as the default Nova mouth.
        if (trimmedSpeakerPath.isEmpty) {
          final femaleVoiceReady = await _ensureVerifiedTurkishPlatformVoice();
          if (!femaleVoiceReady) {
            throw StateError(
              'Nova için doğrulanmış Türkçe kadın/insancıl ses bulunamadı; erkek/default TTS yasak.',
            );
          }
          debugPrint(
            'NOVA_TTS_ENGINE_SELECTED engine=platform_verified_female mode=neuralLocal voice=$_verifiedTurkishPlatformVoiceName chars=${prepared.length}',
          );
          await _speakWithPlatformTts(prepared);
          return;
        }

        try {
          final ready = await _ensureNativeEngineReady(
            preferredModelKey: _preferredModelKeyFromSpeakerPath(
              trimmedSpeakerPath,
            ),
          );
          if (ready) {
            final success = await nativeBridge.speakWithSherpaTts(
              text: prepared,
              language: 'tr',
              speakerPath: _speakerPathForNative(trimmedSpeakerPath),
            );
            if (success) {
              _lastNativeWarmupAttemptFailed = false;
              debugPrint(
                'NOVA_TTS_ENGINE_SELECTED engine=native_sherpa_explicit_speaker speakerPath=$trimmedSpeakerPath chars=${prepared.length}',
              );
              return;
            }
          }
        } catch (e) {
          debugPrint('NOVA_TTS_NATIVE_TURKISH_FAILED error=$e');
          if (!allowPlatformFallback) {
            rethrow;
          }
        }

        if (!allowPlatformFallback) {
          throw StateError(
            'Native Sherpa TTS Türkçe konuşmayı başlatamadı. Platform fallback bu çağrı için kapalı.',
          );
        }

        final femaleVoiceReady = await _ensureVerifiedTurkishPlatformVoice();
        if (!femaleVoiceReady) {
          throw StateError(
            'Nova için doğrulanmış Türkçe kadın/insancıl ses bulunamadı; erkek/default TTS yasak.',
          );
        }
        debugPrint(
          'NOVA_TTS_ENGINE_SELECTED engine=platform_verified_female_after_explicit_native_fail voice=$_verifiedTurkishPlatformVoiceName chars=${prepared.length}',
        );
        await _speakWithPlatformTts(prepared);
        return;
      }

      final shouldUseNaturalEngine = _shouldUseNaturalEngine(
        prepared,
        speakerPath: _speakerPathForNative(trimmedSpeakerPath),
        localeCode: _currentLanguage,
      );

      if (shouldUseNaturalEngine) {
        try {
          final ready = await _ensureNativeEngineReady(
            preferredModelKey: _preferredModelKeyFromSpeakerPath(
              trimmedSpeakerPath,
            ),
          );

          if (ready) {
            final success = await nativeBridge.speakWithSherpaTts(
              text: prepared,
              language: _currentLanguage.startsWith('tr') ? 'tr' : 'en',
              speakerPath: _speakerPathForNative(trimmedSpeakerPath),
            );

            if (success) {
              _lastNativeWarmupAttemptFailed = false;
              return;
            }
          }

          if (!allowPlatformFallback) {
            throw StateError('Native Sherpa TTS konuşmayı başlatamadı.');
          }
        } catch (e) {
          debugPrint('Nova native TTS fallback: $e');
          if (!allowPlatformFallback) {
            rethrow;
          }
        }
      }

      await _speakWithPlatformTts(prepared);
    });
  }

  bool _shouldUseNaturalEngine(
    String text, {
    String speakerPath = '',
    String localeCode = 'tr-TR',
  }) {
    final explicitSpeaker = speakerPath.trim().isNotEmpty;
    if (explicitSpeaker) {
      return true;
    }

    // Turkish is the main spoken language for Nova. Prefer the local neural
    // engine when it is available so prosody and emotional style are not lost
    // to the flat platform fallback.
    if (_isTurkishLocale(localeCode)) {
      return true;
    }

    final cleaned = text.trim().toLowerCase();
    final isLong = cleaned.length >= 24;
    final hasDialogueTone =
        cleaned.contains('?') ||
        cleaned.contains('!') ||
        cleaned.contains(',') ||
        cleaned.contains(';') ||
        cleaned.contains(':');

    return isLong || hasDialogueTone;
  }

  bool _isTurkishLocale(String localeCode) {
    return _normalizeLocale(localeCode).toLowerCase().startsWith('tr');
  }

  Future<bool> _ensureNativeEngineReady({String preferredModelKey = ''}) async {
    final now = DateTime.now();
    final recentCheck =
        _lastNativeCapabilityCheckAt != null &&
        now.difference(_lastNativeCapabilityCheckAt!) <
            const Duration(minutes: 2);

    if (recentCheck && _lastNativeCapabilityReady) {
      return true;
    }

    // Setup sırasında tek bir erken warmup hatasını iki dakika cachelemek,
    // yerel Sherpa TTS hattını kilitliyor ve sistemin platform/erkek sese
    // sapmış gibi davranmasına yol açabiliyordu. Başarısızlık sadece kayıt
    // altına alınır; sonraki konuşma denemesi native hattı yeniden dener.

    try {
      final capabilities = await nativeBridge.getSherpaTtsCapabilities();
      final availableModels =
          (capabilities['availableModels'] as List?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      final hasAnyModel = availableModels.isNotEmpty;
      final assetReady = capabilities['assetReady'] == true;
      final capabilityMessage = capabilities['message']?.toString() ?? '';
      var ready = capabilities['ready'] == true;
      debugPrint(
        'NOVA_TTS_NATIVE_CAPABILITY ready=$ready assetReady=$assetReady '
        'models=${availableModels.join(',')} message=$capabilityMessage',
      );

      if (!ready && hasAnyModel) {
        ready = await nativeBridge.warmupSherpaTts(
          preferredModelKey: preferredModelKey,
        );
      }

      _lastNativeCapabilityCheckAt = now;
      _lastNativeCapabilityReady = ready;
      _lastNativeWarmupAttemptFailed = !ready;
      return ready;
    } catch (_) {
      _lastNativeCapabilityCheckAt = now;
      _lastNativeCapabilityReady = false;
      _lastNativeWarmupAttemptFailed = true;
      return false;
    }
  }

  String _preferredModelKeyFromSpeakerPath(String speakerPath) {
    return 'dfki';
  }

  String _speakerPathForNative(String speakerPath) {
    final trimmed = speakerPath.trim();
    if (trimmed.isNotEmpty) return trimmed;
    if (_isTurkishLocale(_currentLanguage)) return 'dfki';
    return trimmed;
  }

  Future<bool> prewarmPreferredTurkishVoice() async {
    await _ensureInitialized();
    await setLanguage('tr-TR');
    _lastNativeWarmupAttemptFailed = false;
    final femaleVoiceReady = await _ensureVerifiedTurkishPlatformVoice();
    debugPrint(
      'NOVA_TTS_PREWARM_VERIFIED_FEMALE ready=$femaleVoiceReady voice=$_verifiedTurkishPlatformVoiceName',
    );
    return femaleVoiceReady;
  }

  Future<bool> _ensureVerifiedTurkishPlatformVoice() async {
    await _ensureInitialized();
    if (_verifiedTurkishPlatformVoiceReady &&
        _verifiedTurkishPlatformVoiceName.trim().isNotEmpty &&
        _isFemaleLikeVoiceName(_verifiedTurkishPlatformVoiceName) &&
        !_isMaleLikeVoiceName(_verifiedTurkishPlatformVoiceName) &&
        !_isDefaultOrRoboticVoiceName(_verifiedTurkishPlatformVoiceName)) {
      return true;
    }
    final cached = await _tryApplyCachedTurkishVoice(
      requireFemaleForTurkish: true,
    );
    if (cached) return true;
    _verifiedTurkishPlatformVoiceReady = false;
    _verifiedTurkishPlatformVoiceName = '';

    final selected = await _trySelectBestVoiceForLocale(
      'tr-TR',
      requireFemaleForTurkish: true,
    );
    _verifiedTurkishPlatformVoiceReady = selected;
    return selected;
  }

  Future<void> _speakWithPlatformTts(String prepared) async {
    final chunks = _splitIntoChunks(prepared);
    for (final chunk in chunks) {
      if (chunk.trim().isEmpty) continue;
      await _applyDynamicProsody(chunk);
      final result = await _flutterTts.speak(chunk);
      debugPrint(
        'NOVA_TTS_PLATFORM_CHUNK_RESULT result=$result chars=${chunk.length} voice=$_verifiedTurkishPlatformVoiceName',
      );
      if (result != null && result != 1) {
        throw StateError('Sistem TTS konuşmayı başlatamadı.');
      }
    }
    try {
      await _flutterTts.setSpeechRate(_currentSpeechRate);
      await _flutterTts.setPitch(_currentPitch);
    } catch (_) {}
  }

  Future<void> _applyDynamicProsody(String text) async {
    final lowered = text.toLowerCase();

    double rate = _currentSpeechRate;
    double pitch = _currentPitch;

    if (lowered.contains('?')) {
      rate = (rate * 0.94).clamp(0.54, 0.70);
      pitch = (pitch * 1.04).clamp(1.00, 1.20);
    } else if (lowered.contains('!')) {
      rate = (rate * 0.98).clamp(0.54, 0.70);
      pitch = (pitch * 1.05).clamp(1.00, 1.20);
    } else if (lowered.contains(',') ||
        lowered.contains(';') ||
        lowered.contains(':')) {
      rate = (rate * 0.97).clamp(0.54, 0.70);
    }

    if (lowered.contains('efendim') || lowered.contains('patron')) {
      rate = (rate * 0.98).clamp(0.54, 0.70);
      pitch = (pitch * 1.02).clamp(1.00, 1.18);
    }

    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (_) {}

    try {
      await _flutterTts.setPitch(pitch);
    } catch (_) {}
  }

  Future<bool> _tryApplyCachedTurkishVoice({
    bool requireFemaleForTurkish = false,
  }) async {
    try {
      if (_cachedTurkishVoiceApplied &&
          _verifiedTurkishPlatformVoiceReady &&
          _verifiedTurkishPlatformVoiceName.trim().isNotEmpty) {
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_turkishVoiceCacheKey)?.trim() ?? '';
      if (raw.isEmpty) return false;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;
      final voice = decoded.map<String, String>(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
      final name = (voice['name'] ?? '').toLowerCase().trim();
      final locale = (voice['locale'] ?? voice['language'] ?? '')
          .toLowerCase()
          .replaceAll('_', '-');
      if (name.isEmpty ||
          (!locale.startsWith('tr') && !name.contains('tr-tr'))) {
        await prefs.remove(_turkishVoiceCacheKey);
        return false;
      }

      final acceptedFemale =
          _isFemaleLikeVoiceName(name) &&
          !_isMaleLikeVoiceName(name) &&
          !_isKnownBadTurkishVoiceName(name) &&
          !_isDefaultOrRoboticVoiceName(name);
      if (requireFemaleForTurkish && !acceptedFemale) {
        await prefs.remove(_turkishVoiceCacheKey);
        return false;
      }

      await _flutterTts.setVoice(voice);
      _verifiedTurkishPlatformVoiceReady =
          acceptedFemale || !requireFemaleForTurkish;
      _verifiedTurkishPlatformVoiceName = name;
      _cachedTurkishVoiceApplied = true;
      debugPrint('NOVA_TTS_VOICE_CACHE_HIT selected=$name locale=$locale');
      return _verifiedTurkishPlatformVoiceReady;
    } catch (error) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_turkishVoiceCacheKey);
      } catch (_) {}
      debugPrint(
        'NOVA_TTS_VOICE_CACHE_REJECT type=${error.runtimeType} error=$error',
      );
      _cachedTurkishVoiceApplied = false;
      _verifiedTurkishPlatformVoiceReady = false;
      _verifiedTurkishPlatformVoiceName = '';
      return false;
    }
  }

  Future<void> _cacheVerifiedTurkishVoice(Map<String, dynamic> voice) async {
    try {
      final normalized = voice.map<String, String>(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
      final name = (normalized['name'] ?? '').toLowerCase().trim();
      if (name.isEmpty ||
          !_isFemaleLikeVoiceName(name) ||
          _isMaleLikeVoiceName(name) ||
          _isKnownBadTurkishVoiceName(name) ||
          _isDefaultOrRoboticVoiceName(name)) {
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_turkishVoiceCacheKey, jsonEncode(normalized));
      _cachedTurkishVoiceApplied = true;
      _verifiedTurkishPlatformVoiceReady = true;
      _verifiedTurkishPlatformVoiceName = name;
      debugPrint('NOVA_TTS_VOICE_CACHE_SAVE selected=$name');
    } catch (error) {
      debugPrint(
        'NOVA_TTS_VOICE_CACHE_SAVE_ERROR type=${error.runtimeType} error=$error',
      );
    }
  }

  Future<bool> _trySelectBestVoiceForLocale(
    String localeCode, {
    bool requireFemaleForTurkish = false,
  }) async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices is! List) return false;

      final normalizedLocale = localeCode.toLowerCase().replaceAll('_', '-');
      final languageCode = normalizedLocale.split('-').first;
      final turkish = _isTurkishLocale(localeCode);

      final femaleCandidates = <Map<String, dynamic>>[];
      final neutralCandidates = <Map<String, dynamic>>[];
      int rejectedMale = 0;
      int rejectedDefault = 0;
      int rejectedUnknownTurkish = 0;
      Map<String, dynamic>? selected;
      num bestScore = -99999;

      for (final item in voices) {
        if (item is! Map) continue;

        final voice = Map<String, dynamic>.from(item);
        final locale = (voice['locale'] as String? ?? '')
            .toLowerCase()
            .replaceAll('_', '-');
        final name = (voice['name'] as String? ?? '').toLowerCase();
        if (name.trim().isEmpty) continue;
        final qualityRaw = voice['quality'];
        final latencyRaw = voice['latency'];
        final networkRaw =
            voice['network_required'] ?? voice['networkConnectionRequired'];
        final quality = qualityRaw is num
            ? qualityRaw
            : (num.tryParse(qualityRaw?.toString() ?? '') ?? 0);
        final latency = latencyRaw is num
            ? latencyRaw
            : (num.tryParse(latencyRaw?.toString() ?? '') ?? 500);
        final requiresNetwork =
            networkRaw == true ||
            networkRaw?.toString().toLowerCase() == 'true';
        final isMaleLike = _isMaleLikeVoiceName(name);
        final isKnownBadTurkish = turkish && _isKnownBadTurkishVoiceName(name);
        final isBlockedDefault = _isDefaultOrRoboticVoiceName(name);
        final isFemaleLike = _isFemaleLikeVoiceName(name);

        if (turkish && (isMaleLike || isKnownBadTurkish)) {
          rejectedMale += 1;
          if (_verboseVoiceScanLogging)
            debugPrint(
              'NOVA_TTS_VOICE_REJECTED selected=$name reason=male_or_known_bad_turkish',
            );
          continue;
        }
        if (turkish && isBlockedDefault) {
          rejectedDefault += 1;
          if (_verboseVoiceScanLogging)
            debugPrint(
              'NOVA_TTS_VOICE_REJECTED selected=$name reason=default_or_robotic',
            );
          continue;
        }
        if (turkish && requireFemaleForTurkish && !isFemaleLike) {
          rejectedUnknownTurkish += 1;
          if (_verboseVoiceScanLogging)
            debugPrint(
              'NOVA_TTS_VOICE_REJECTED selected=$name reason=turkish_female_not_verified',
            );
          continue;
        }

        num score = 0;
        if (locale == normalizedLocale) score += 1000;
        if (locale.startsWith(languageCode)) score += 400;
        if (name.contains('google')) score += 120;
        if (isFemaleLike) score += 700;
        if (name.contains('dfki')) score += 240;
        score += quality;
        score -= latency / 10;
        if (requiresNetwork) score -= 60;

        if (turkish) {
          if (name.contains('tr-tr') ||
              name.contains('turkish') ||
              name.contains('turk'))
            score += 180;
          if (name.contains('seda') ||
              name.contains('selin') ||
              name.contains('zeynep') ||
              name.contains('ofg') ||
              name.contains('efu') ||
              name.contains('fem'))
            score += 520;
          if (name.contains('network')) score += 40;
        }

        final scored = <String, dynamic>{...voice, '__score': score};
        if (isFemaleLike) {
          femaleCandidates.add(scored);
        } else {
          neutralCandidates.add(scored);
        }
        if (score > bestScore) {
          bestScore = score;
          selected = voice;
        }
      }

      if (turkish && femaleCandidates.isNotEmpty) {
        femaleCandidates.sort(
          (a, b) => ((b['__score'] as num?) ?? 0).compareTo(
            (a['__score'] as num?) ?? 0,
          ),
        );
        selected = Map<String, dynamic>.from(femaleCandidates.first)
          ..remove('__score');
      } else if (!turkish && selected == null && neutralCandidates.isNotEmpty) {
        neutralCandidates.sort(
          (a, b) => ((b['__score'] as num?) ?? 0).compareTo(
            (a['__score'] as num?) ?? 0,
          ),
        );
        selected = Map<String, dynamic>.from(neutralCandidates.first)
          ..remove('__score');
      }

      if (turkish && requireFemaleForTurkish && selected == null) {
        _verifiedTurkishPlatformVoiceReady = false;
        _verifiedTurkishPlatformVoiceName = '';
        unawaited(
          NovaRuntimeSignalService.instance.record(
            kind: NovaRuntimeSignalKind.tts,
            level: NovaRuntimeSignalLevel.error,
            code: 'tts_turkish_female_voice_missing',
            message:
                'Doğrulanmış Türkçe kadın TTS sesi bulunamadı; erkek/neutral ses kullanılmadı.',
            technicalDetails:
                'femaleCandidates=${femaleCandidates.length} neutralCandidates=${neutralCandidates.length} rejectedMale=$rejectedMale rejectedDefault=$rejectedDefault rejectedUnknownTurkish=$rejectedUnknownTurkish',
            diagnosticCandidate: true,
            metadata: <String, dynamic>{
              'femaleCandidates': femaleCandidates.length,
              'neutralCandidates': neutralCandidates.length,
              'rejectedMale': rejectedMale,
              'rejectedDefault': rejectedDefault,
              'rejectedUnknownTurkish': rejectedUnknownTurkish,
            },
          ),
        );
        debugPrint(
          'NOVA_TTS_TURKISH_FEMALE_MISSING female=${femaleCandidates.length} neutral=${neutralCandidates.length} rejectedMale=$rejectedMale rejectedDefault=$rejectedDefault rejectedUnknown=$rejectedUnknownTurkish',
        );
        return false;
      }

      if (selected != null && selected.isNotEmpty) {
        debugPrint(
          "NOVA_TTS_VOICE_CANDIDATE selected=${selected['name']} locale=${selected['locale']} requireFemaleForTurkish=$requireFemaleForTurkish",
        );
        final selectedName = (selected['name'] as String? ?? '').toLowerCase();
        final selectedMale =
            _isMaleLikeVoiceName(selectedName) ||
            _isKnownBadTurkishVoiceName(selectedName);
        final selectedDefaultOrRobotic = _isDefaultOrRoboticVoiceName(
          selectedName,
        );
        final acceptedFemale =
            _isFemaleLikeVoiceName(selectedName) &&
            !selectedMale &&
            !selectedDefaultOrRobotic;
        if (turkish && requireFemaleForTurkish && !acceptedFemale) {
          _verifiedTurkishPlatformVoiceReady = false;
          _verifiedTurkishPlatformVoiceName = '';
          unawaited(
            NovaRuntimeSignalService.instance.record(
              kind: NovaRuntimeSignalKind.tts,
              level: NovaRuntimeSignalLevel.error,
              code: 'tts_turkish_female_voice_not_verified',
              message:
                  'Türkçe kadın TTS sesi doğrulanamadı; erkek/default/robotik ses engellendi.',
              technicalDetails:
                  'selected=$selectedName male=$selectedMale defaultOrRobotic=$selectedDefaultOrRobotic acceptedFemale=$acceptedFemale',
              diagnosticCandidate: true,
            ),
          );
          debugPrint(
            "NOVA_TTS_VOICE_REJECTED selected=$selectedName reason=turkish_female_required",
          );
          return false;
        }
        await _flutterTts.setVoice(
          Map<String, String>.from(
            selected.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ),
          ),
        );
        if (turkish) {
          _verifiedTurkishPlatformVoiceReady = acceptedFemale;
          _verifiedTurkishPlatformVoiceName = acceptedFemale
              ? selectedName
              : '';
          if (acceptedFemale) {
            await _cacheVerifiedTurkishVoice(selected);
          }
          debugPrint(
            acceptedFemale
                ? "NOVA_TTS_VOICE_ACCEPTED_FEMALE selected=$selectedName"
                : "NOVA_TTS_VOICE_REJECTED selected=$selectedName reason=unspecified_gender_not_cached",
          );
        }
        return !turkish || acceptedFemale;
      }
      return false;
    } catch (error) {
      debugPrint(
        'NOVA_TTS_VOICE_SELECT_ERROR type=${error.runtimeType} error=$error',
      );
      return false;
    }
  }

  bool _isMaleLikeVoiceName(String name) {
    final lower = name.toLowerCase();
    final explicitMaleToken = RegExp(
      r'(^|[^a-z])male([^a-z]|$)',
    ).hasMatch(lower);
    return explicitMaleToken ||
        lower.contains('erkek') ||
        lower.contains('adam') ||
        lower.contains('fahrettin') ||
        lower.contains('fettah') ||
        lower.contains('bariton') ||
        lower.contains('tr-tr-x-tmc');
  }

  bool _isKnownBadTurkishVoiceName(String name) {
    final lower = name.toLowerCase();
    return lower.contains('tr-tr-x-tmc') ||
        lower.contains('tmc-network') ||
        lower.contains('tmc-local');
  }

  bool _isDefaultOrRoboticVoiceName(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return true;

    final normalized = lower
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll('.', ' ');

    return normalized.contains('default') ||
        normalized.contains('robot') ||
        normalized.contains('robotic') ||
        normalized.contains('synth') ||
        normalized.contains('synthetic') ||
        normalized.contains('espeak') ||
        normalized.contains('pico') ||
        normalized.contains('flite') ||
        normalized.contains('tts') ||
        normalized.contains('google tr tr local') ||
        normalized.contains('system voice') ||
        normalized.contains('unknown') ||
        normalized.contains('generic');
  }

  bool _isFemaleLikeVoiceName(String name) {
    final lower = name.toLowerCase();
    return lower.contains('female') ||
        lower.contains('woman') ||
        lower.contains('kadın') ||
        lower.contains('kadin') ||
        lower.contains('seda') ||
        lower.contains('selin') ||
        lower.contains('zeynep') ||
        lower.contains('tr-tr-x-ofg') ||
        lower.contains('ofg') ||
        lower.contains('tr-tr-x-efu') ||
        lower.contains('efu') ||
        lower.contains('tr-tr-x-fem') ||
        lower.contains('fem');
  }

  String _normalizeLocale(String localeCode) {
    final raw = localeCode.trim();
    if (raw.isEmpty) return 'tr-TR';

    final normalized = raw.replaceAll('_', '-');
    final lowered = normalized.toLowerCase();

    if (lowered.startsWith('tr')) {
      return 'tr-TR';
    }
    if (lowered.startsWith('en')) {
      return 'en-US';
    }

    return normalized;
  }

  String _prepareForSpeech(String text) {
    var value = text.trim();
    if (value.isEmpty) return '';

    value = value.replaceAll('\n', ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ');
    value = value.replaceAll('“', '');
    value = value.replaceAll('”', '');
    value = value.replaceAll(' - ', ', ');
    value = value.replaceAll(' sn ', ' saniye ');
    value = value.replaceAll(' dk ', ' dakika ');
    value = value.replaceAll(RegExp(r'\bya\b', caseSensitive: false), ' ya');
    value = value.replaceAll(RegExp(r'\bsey\b', caseSensitive: false), ' şey');
    value = value.replaceAll(RegExp(r'\bbi\b', caseSensitive: false), ' bir');
    value = value.replaceAll(
      RegExp(r'\bnolur\b', caseSensitive: false),
      ' ne olur',
    );
    while (value.contains('..')) {
      value = value.replaceAll('..', '.');
    }
    value = value.replaceAll('?.', '?');
    value = value.replaceAll('!.', '!');
    value = value
        .replaceAllMapped(RegExp(r'([.!?])(?=\S)'), (m) => '${m.group(1)} ')
        .replaceAllMapped(RegExp(r'([,:;])(?=\S)'), (m) => '${m.group(1)} ')
        .replaceAll('…', '. ')
        .trim();

    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (!value.endsWith('.') && !value.endsWith('!') && !value.endsWith('?')) {
      value = '$value.';
    }

    return value;
  }

  List<String> _splitIntoChunks(String text) {
    if (text.length <= 320) {
      return <String>[text];
    }

    final sentences = _novaSplitAfterSentencePunctuation(text);
    final chunks = <String>[];
    final buffer = StringBuffer();

    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) continue;

      final candidate = buffer.isEmpty
          ? trimmed
          : '${buffer.toString().trim()} $trimmed';

      if (candidate.length > 320 && buffer.isNotEmpty) {
        chunks.add(buffer.toString().trim());
        buffer.clear();
        buffer.write(trimmed);
      } else {
        if (buffer.isNotEmpty) {
          buffer.write(' ');
        }
        buffer.write(trimmed);
      }
    }

    if (buffer.isNotEmpty) {
      chunks.add(buffer.toString().trim());
    }

    return chunks.isEmpty ? <String>[text] : chunks;
  }

  Future<VoiceProfile?> resolveVoiceProfile(String voiceProfileId) async {
    final all = await voiceProfileService.getAllProfiles();
    for (final item in all) {
      if (item.id == voiceProfileId) {
        return item;
      }
    }
    return null;
  }
}

List<String> _novaSplitAfterSentencePunctuation(String text) {
  if (text.trim().isEmpty) return <String>[];
  const marker = '\u0000NOVA_SENTENCE_BREAK\u0000';
  return text
      .replaceAllMapped(RegExp(r'([.!?])\s+'), (m) => '${m.group(1)}$marker')
      .split(marker);
}
