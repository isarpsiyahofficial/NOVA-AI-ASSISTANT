// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NovaEmotionalMomentumService {
  static const String _storageKey = 'nova_emotional_momentum_v2';
  static const int _historyLimit = 24;

  const NovaEmotionalMomentumService();

  Future<Map<String, dynamic>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) return _empty();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return _empty();
      return _sanitize(decoded);
    } catch (_) {
      return _empty();
    }
  }

  Future<void> evolve({
    required String dominantEmotion,
    required double intensity,
  }) async {
    final current = await load();
    final history = (current['history'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList(growable: true);

    final now = DateTime.now();
    final normalizedEmotion = dominantEmotion.trim().isEmpty
        ? 'nötr'
        : dominantEmotion.trim();
    final inputIntensity = intensity.clamp(0.0, 1.0);
    final previousIntensity = (current['intensity'] as num?)?.toDouble() ?? 0.0;
    final previousValence = (current['valence'] as num?)?.toDouble() ?? 0.0;
    final previousArousal = (current['arousal'] as num?)?.toDouble() ?? 0.0;
    final previousTrust = (current['trustCarry'] as num?)?.toDouble() ?? 0.0;

    final valence = _valenceFor(normalizedEmotion);
    final arousal = _arousalFor(normalizedEmotion, inputIntensity);
    final decayedIntensity = previousIntensity * 0.72;
    final decayedValence = previousValence * 0.76;
    final decayedArousal = previousArousal * 0.70;
    final trustCarry =
        ((previousTrust * 0.82) + _trustCarryFor(normalizedEmotion) * 0.18)
            .clamp(0.0, 1.0);

    final nextIntensity = (decayedIntensity + (inputIntensity * 0.52)).clamp(
      0.0,
      1.0,
    );
    final nextValence = (decayedValence + (valence * 0.36)).clamp(-1.0, 1.0);
    final nextArousal = (decayedArousal + (arousal * 0.42)).clamp(0.0, 1.0);
    final stability = _stabilityScore(
      nextIntensity,
      nextArousal,
      history.length,
    );

    history.insert(0, <String, dynamic>{
      'emotion': normalizedEmotion,
      'intensity': inputIntensity,
      'valence': valence,
      'arousal': arousal,
      'at': now.toIso8601String(),
    });

    final next = <String, dynamic>{
      'dominantEmotion': normalizedEmotion,
      'intensity': nextIntensity,
      'valence': nextValence,
      'arousal': nextArousal,
      'trustCarry': trustCarry,
      'stability': stability,
      'paceHint': _paceHint(nextArousal, nextIntensity),
      'responseTemperature': _responseTemperature(nextValence, nextArousal),
      'history': history.take(_historyLimit).toList(growable: false),
      'updatedAt': now.toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(next));
  }

  String buildPromptSection(Map<String, dynamic> snapshot) {
    final emotion = (snapshot['dominantEmotion'] as String? ?? 'nötr').trim();
    final intensity = (snapshot['intensity'] as num?)?.toDouble() ?? 0.0;
    final valence = (snapshot['valence'] as num?)?.toDouble() ?? 0.0;
    final arousal = (snapshot['arousal'] as num?)?.toDouble() ?? 0.0;
    final trustCarry = (snapshot['trustCarry'] as num?)?.toDouble() ?? 0.0;
    final stability = (snapshot['stability'] as num?)?.toDouble() ?? 0.0;
    final paceHint = snapshot['paceHint']?.toString() ?? 'denge';
    final temperature =
        snapshot['responseTemperature']?.toString() ?? 'neutral';
    final history =
        (snapshot['history'] as List<dynamic>? ?? const <dynamic>[]).length;
    return [
      'DUYGUSAL MOMENTUM:',
      '- taşınan duygu: $emotion',
      '- kalan yoğunluk: ${intensity.toStringAsFixed(2)}',
      '- valence: ${valence.toStringAsFixed(2)}',
      '- arousal: ${arousal.toStringAsFixed(2)}',
      '- trustCarry: ${trustCarry.toStringAsFixed(2)}',
      '- stability: ${stability.toStringAsFixed(2)}',
      '- paceHint: $paceHint',
      '- responseTemperature: $temperature',
      '- historyDepth: $history',
      'KURAL: Duygu her tur sıfırlanmasın; birkaç tur boyunca yumuşak decay ile taşınsın.',
      'KURAL: Momentum yüksekse tonu bir anda sert şekilde değiştirme.',
      'KURAL: Valence ve arousal birlikte okunmalı; sakin üzüntü ile yüksek gerginlik aynı ritimle cevaplanmamalı.',
    ].join('\n');
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> raw) {
    return <String, dynamic>{
      'dominantEmotion': raw['dominantEmotion']?.toString() ?? 'nötr',
      'intensity': ((raw['intensity'] as num?)?.toDouble() ?? 0.0).clamp(
        0.0,
        1.0,
      ),
      'valence': ((raw['valence'] as num?)?.toDouble() ?? 0.0).clamp(-1.0, 1.0),
      'arousal': ((raw['arousal'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
      'trustCarry': ((raw['trustCarry'] as num?)?.toDouble() ?? 0.0).clamp(
        0.0,
        1.0,
      ),
      'stability': ((raw['stability'] as num?)?.toDouble() ?? 0.0).clamp(
        0.0,
        1.0,
      ),
      'paceHint': raw['paceHint']?.toString() ?? 'denge',
      'responseTemperature':
          raw['responseTemperature']?.toString() ?? 'neutral',
      'history': (raw['history'] as List<dynamic>? ?? const <dynamic>[]),
      'updatedAt':
          raw['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _empty() => <String, dynamic>{
    'dominantEmotion': 'nötr',
    'intensity': 0.0,
    'valence': 0.0,
    'arousal': 0.0,
    'trustCarry': 0.0,
    'stability': 0.0,
    'paceHint': 'denge',
    'responseTemperature': 'neutral',
    'history': const <Map<String, dynamic>>[],
  };

  double _valenceFor(String emotion) {
    final lower = emotion.toLowerCase();
    if (_containsAny(lower, const <String>[
      'mutlu',
      'sevindim',
      'rahat',
      'iyi',
    ]))
      return 0.72;
    if (_containsAny(lower, const <String>['üzgün', 'kırgın', 'moral']))
      return -0.58;
    if (_containsAny(lower, const <String>['gergin', 'kaygı', 'sinir']))
      return -0.46;
    if (_containsAny(lower, const <String>['mahcup', 'utangaç'])) return -0.20;
    return 0.0;
  }

  double _arousalFor(String emotion, double intensity) {
    final lower = emotion.toLowerCase();
    var base = intensity;
    if (_containsAny(lower, const <String>['gergin', 'kaygı', 'sinir', 'acil']))
      base += 0.18;
    if (_containsAny(lower, const <String>['üzgün', 'yorgun', 'mahcup']))
      base -= 0.10;
    return base.clamp(0.0, 1.0);
  }

  double _trustCarryFor(String emotion) {
    final lower = emotion.toLowerCase();
    if (_containsAny(lower, const <String>['güven', 'rahat', 'sevindim']))
      return 0.80;
    if (_containsAny(lower, const <String>['üzgün', 'mahcup'])) return 0.54;
    if (_containsAny(lower, const <String>['gergin', 'sinir'])) return 0.32;
    return 0.46;
  }

  double _stabilityScore(double intensity, double arousal, int historyLength) {
    var score = 0.60;
    score -= intensity * 0.16;
    score -= arousal * 0.20;
    score += (historyLength >= 4 ? 0.06 : 0.0);
    return score.clamp(0.0, 1.0);
  }

  String _paceHint(double arousal, double intensity) {
    if (arousal >= 0.72) return 'kısa_blok_hızlı_tepki';
    if (intensity >= 0.58 && arousal < 0.42) return 'yumuşak_yavaş';
    if (intensity >= 0.58) return 'ölçülü_dikkatli';
    return 'denge';
  }

  String _responseTemperature(double valence, double arousal) {
    if (valence <= -0.40 && arousal >= 0.56) return 'cooling';
    if (valence <= -0.40) return 'gentle';
    if (valence >= 0.42 && arousal >= 0.46) return 'warm_bright';
    if (valence >= 0.42) return 'warm_soft';
    return 'neutral';
  }

  bool _containsAny(String text, List<String> cues) {
    for (final cue in cues) {
      if (text.contains(cue)) return true;
    }
    return false;
  }

  Map<String, dynamic> buildMomentumAudit({
    required double valence,
    required double arousal,
    required double intensity,
    required int historyLength,
  }) {
    return <String, dynamic>{
      'paceHint': _paceHint(arousal, intensity),
      'responseTemperature': _responseTemperature(valence, arousal),
      'stabilityScore': _stabilityScore(valence, arousal, historyLength),
      'needsCooling': valence <= -0.40 && arousal >= 0.56,
      'historyLength': historyLength,
    };
  }

  String describeRegulationStrategy({
    required double valence,
    required double arousal,
  }) {
    if (valence <= -0.40 && arousal >= 0.56)
      return 'önce sakinleştir, sonra anlamayı derinleştir';
    if (valence <= -0.40) return 'yumuşak eşlik ve kısa cümle';
    if (valence >= 0.42 && arousal >= 0.46) return 'enerjiyi taşı ama taşırma';
    return 'dengeyi koru';
  }

  bool shouldPauseBeforeReply({
    required double arousal,
    required bool isInterruption,
  }) {
    if (isInterruption) return false;
    return arousal >= 0.72;
  }
}
