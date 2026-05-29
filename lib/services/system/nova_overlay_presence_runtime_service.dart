// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:math';

class NovaOverlayPresenceState {
  final String title;
  final String status;
  final double breathScale;
  final double glow;
  final double textOpacity;
  final double shellOpacity;
  final double motion;
  final bool showEmotionChip;
  final String emotionLabel;
  final bool touchTransparent;
  final Map<String, dynamic> palette;
  final Map<String, dynamic> metrics;

  const NovaOverlayPresenceState({
    required this.title,
    required this.status,
    required this.breathScale,
    required this.glow,
    required this.textOpacity,
    required this.shellOpacity,
    required this.motion,
    required this.showEmotionChip,
    required this.emotionLabel,
    required this.touchTransparent,
    required this.palette,
    this.metrics = const <String, dynamic>{},
  });
}

class NovaOverlayPresenceRuntimeService {
  const NovaOverlayPresenceRuntimeService();

  NovaOverlayPresenceState buildState({
    required String mode,
    required String emotion,
    required double energy,
    required double speakingIntensity,
    required String assistantName,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) {
    final normalizedMode = _normalize(mode);
    final normalizedEmotion = _normalize(emotion);
    final e = energy.clamp(0, 1).toDouble();
    final s = speakingIntensity.clamp(0, 1).toDouble();
    final profile = _profileFor(
      mode: normalizedMode,
      emotion: normalizedEmotion,
      context: context,
    );
    final breathScale = _clamp(0.90 + profile.breathBase + e * 0.10 + s * 0.14);
    final glow = _clamp(profile.glowBase + e * 0.12 + s * 0.08);
    final textOpacity = _clamp(profile.textBase + _readabilityBoost(context));
    final shellOpacity = _clamp(profile.shellBase + e * 0.10 + s * 0.10);
    final motion = _clamp(profile.motionBase + e * 0.16 + s * 0.18);
    final emotionLabel = _emotionLabel(normalizedEmotion);
    final status = _statusFor(
      mode: normalizedMode,
      emotion: normalizedEmotion,
      context: context,
    );
    final title = assistantName.trim().isEmpty ? 'Nova' : assistantName.trim();
    return NovaOverlayPresenceState(
      title: title,
      status: status,
      breathScale: breathScale,
      glow: glow,
      textOpacity: textOpacity,
      shellOpacity: shellOpacity,
      motion: motion,
      showEmotionChip: emotionLabel != 'Nötr',
      emotionLabel: emotionLabel,
      touchTransparent: true,
      palette: _palette(profile.paletteKey),
      metrics: <String, dynamic>{
        'normalizedMode': normalizedMode,
        'normalizedEmotion': normalizedEmotion,
        'energy': e,
        'speakingIntensity': s,
        'readabilityBoost': _readabilityBoost(context),
        'presencePriority': profile.priority,
      },
    );
  }

  Map<String, dynamic> buildNativePayload(NovaOverlayPresenceState state) {
    return <String, dynamic>{
      'title': state.title,
      'status': state.status,
      'breathScale': state.breathScale,
      'glow': state.glow,
      'textOpacity': state.textOpacity,
      'shellOpacity': state.shellOpacity,
      'motion': state.motion,
      'showEmotionChip': state.showEmotionChip,
      'emotionLabel': state.emotionLabel,
      'touchTransparent': state.touchTransparent,
      'metrics': state.metrics,
      ...state.palette,
    };
  }

  List<Map<String, dynamic>> buildBreathingFrames({
    required String mode,
    required String emotion,
    required double energy,
    required String assistantName,
    int frameCount = 24,
  }) {
    final frames = <Map<String, dynamic>>[];
    for (var i = 0; i < frameCount; i++) {
      final t = i / max(1, frameCount - 1);
      final wave = _breathWave(t, energy: energy, mode: mode);
      final state = buildState(
        mode: mode,
        emotion: emotion,
        energy: energy,
        speakingIntensity: wave,
        assistantName: assistantName,
      );
      frames.add(buildNativePayload(state));
    }
    return frames;
  }

  Map<String, dynamic> buildReadabilityAudit({
    required String mode,
    required String emotion,
    required double energy,
    required String assistantName,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) {
    final state = buildState(
      mode: mode,
      emotion: emotion,
      energy: energy,
      speakingIntensity: 0.0,
      assistantName: assistantName,
      context: context,
    );
    final readable = state.textOpacity >= 0.82 && state.shellOpacity >= 0.48;
    return <String, dynamic>{
      'readable': readable,
      'textOpacity': state.textOpacity,
      'shellOpacity': state.shellOpacity,
      'status': state.status,
      'palette': state.palette,
      'recommendedAction': readable
          ? 'keep'
          : 'increase_text_opacity_and_reduce_cloud_fade',
    };
  }

  String buildPromptSection({
    required String mode,
    required String emotion,
    required double energy,
    required double speakingIntensity,
    required String assistantName,
  }) {
    final state = buildState(
      mode: mode,
      emotion: emotion,
      energy: energy,
      speakingIntensity: speakingIntensity,
      assistantName: assistantName,
    );
    return [
      'EMBODIED OVERLAY:',
      '- başlık: ${state.title}',
      '- durum: ${state.status}',
      '- nefes ölçeği: ${state.breathScale.toStringAsFixed(2)}',
      '- ışıma: ${state.glow.toStringAsFixed(2)}',
      '- metin opaklığı: ${state.textOpacity.toStringAsFixed(2)}',
      '- kabuk opaklığı: ${state.shellOpacity.toStringAsFixed(2)}',
      '- duygu rozeti: ${state.showEmotionChip ? state.emotionLabel : 'kapalı'}',
      'KURAL: overlay şeffaf ve dokunmaya engel olmayan yapıda kalsın; ama yazı okunamayacak kadar silikleşmesin.',
      'KURAL: overlay sesi yalnız dekorla değil; düşünme, dinleme, çağrı, companion ve aciliyet modlarıyla birlikte bedenleştirsin.',
    ].join('\n');
  }

  _OverlayProfile _profileFor({
    required String mode,
    required String emotion,
    required Map<String, dynamic> context,
  }) {
    final urgent =
        context['urgent'] == true ||
        mode.contains('call') ||
        emotion.contains('fear') ||
        emotion.contains('tense');
    if (mode.contains('companion')) {
      return const _OverlayProfile(
        paletteKey: 'companion',
        glowBase: 0.74,
        textBase: 0.92,
        shellBase: 0.60,
        motionBase: 0.54,
        breathBase: 0.08,
        priority: 0.90,
      );
    }
    if (mode.contains('call')) {
      return const _OverlayProfile(
        paletteKey: 'call',
        glowBase: 0.72,
        textBase: 0.94,
        shellBase: 0.58,
        motionBase: 0.52,
        breathBase: 0.07,
        priority: 0.92,
      );
    }
    if (mode.contains('sleep') || mode.contains('night')) {
      return const _OverlayProfile(
        paletteKey: 'sleep',
        glowBase: 0.40,
        textBase: 0.86,
        shellBase: 0.48,
        motionBase: 0.22,
        breathBase: 0.03,
        priority: 0.38,
      );
    }
    if (mode.contains('speaking')) {
      return const _OverlayProfile(
        paletteKey: 'speaking',
        glowBase: 0.84,
        textBase: 0.94,
        shellBase: 0.62,
        motionBase: 0.62,
        breathBase: 0.10,
        priority: 0.86,
      );
    }
    if (mode.contains('curious')) {
      return const _OverlayProfile(
        paletteKey: 'curious',
        glowBase: 0.68,
        textBase: 0.90,
        shellBase: 0.56,
        motionBase: 0.50,
        breathBase: 0.07,
        priority: 0.72,
      );
    }
    if (urgent) {
      return const _OverlayProfile(
        paletteKey: 'urgent',
        glowBase: 0.86,
        textBase: 0.96,
        shellBase: 0.66,
        motionBase: 0.66,
        breathBase: 0.10,
        priority: 0.94,
      );
    }
    return const _OverlayProfile(
      paletteKey: 'listening',
      glowBase: 0.66,
      textBase: 0.90,
      shellBase: 0.56,
      motionBase: 0.40,
      breathBase: 0.06,
      priority: 0.68,
    );
  }

  Map<String, dynamic> _palette(String key) {
    switch (key) {
      case 'companion':
        return const <String, dynamic>{
          'core': '#D1ECFF',
          'glowColor': '#52D1FF',
          'shell': '#8BE8FF',
          'cloud': '#102940',
          'text': '#F7FBFF',
        };
      case 'call':
        return const <String, dynamic>{
          'core': '#D8F8FF',
          'glowColor': '#4FC3F7',
          'shell': '#81D4FA',
          'cloud': '#0E2434',
          'text': '#F8FCFF',
        };
      case 'sleep':
        return const <String, dynamic>{
          'core': '#FFE0B2',
          'glowColor': '#FFB74D',
          'shell': '#FFCC80',
          'cloud': '#162235',
          'text': '#FFFDF8',
        };
      case 'speaking':
        return const <String, dynamic>{
          'core': '#FFF3BF',
          'glowColor': '#FFD54F',
          'shell': '#FFE082',
          'cloud': '#1C2435',
          'text': '#FFFDF2',
        };
      case 'curious':
        return const <String, dynamic>{
          'core': '#E1BEE7',
          'glowColor': '#BA68C8',
          'shell': '#CE93D8',
          'cloud': '#1B1635',
          'text': '#FCF7FF',
        };
      case 'urgent':
        return const <String, dynamic>{
          'core': '#FFCDD2',
          'glowColor': '#EF5350',
          'shell': '#E57373',
          'cloud': '#2D1518',
          'text': '#FFF8F8',
        };
      case 'listening':
      default:
        return const <String, dynamic>{
          'core': '#E0F7FA',
          'glowColor': '#52D1FF',
          'shell': '#80DEEA',
          'cloud': '#102C44',
          'text': '#F7FBFF',
        };
    }
  }

  String _statusFor({
    required String mode,
    required String emotion,
    required Map<String, dynamic> context,
  }) {
    if (mode.contains('companion')) return 'Çağrıda size eşlik ediyor';
    if (mode.contains('call')) return 'Çağrı akışı aktif';
    if (mode.contains('sleep') || mode.contains('night'))
      return 'Sessiz dengede';
    if (mode.contains('speaking')) return 'Konuşuyor';
    if (mode.contains('curious')) return 'Merakla izliyor';
    if (emotion.contains('fear')) return 'Tedirginliği dengeliyor';
    if (emotion.contains('tense') || emotion.contains('angry'))
      return 'Gerilimi dengeliyor';
    if (emotion.contains('warm')) return 'Sıcak bir varlıkla eşlik ediyor';
    if (context['thinking'] == true) return 'Düşünce akışı çalışıyor';
    return 'Dinliyor';
  }

  String _emotionLabel(String emotion) {
    if (emotion.contains('warm') || emotion.contains('love')) return 'Sıcak';
    if (emotion.contains('fear')) return 'Tedirgin';
    if (emotion.contains('tense') || emotion.contains('angry')) return 'Gergin';
    if (emotion.contains('sad')) return 'Hüzünlü';
    if (emotion.contains('curious')) return 'Meraklı';
    return 'Nötr';
  }

  double _readabilityBoost(Map<String, dynamic> context) {
    final lowContrastBackground = context['lowContrastBackground'] == true;
    final callMode = context['callMode'] == true;
    final thinking = context['thinking'] == true;
    var boost = 0.0;
    if (lowContrastBackground) boost += 0.06;
    if (callMode) boost += 0.02;
    if (thinking) boost += 0.02;
    return boost;
  }

  double _breathWave(double t, {required double energy, required String mode}) {
    final modeBias = _normalize(mode).contains('sleep')
        ? 0.03
        : (_normalize(mode).contains('call') ? 0.08 : 0.06);
    final wave = (sin(t * pi * 2) + 1) / 2;
    return _clamp(modeBias + wave * 0.20 + energy.clamp(0, 1) * 0.08);
  }

  String _normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }

  double _clamp(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}

class _OverlayProfile {
  final String paletteKey;
  final double glowBase;
  final double textBase;
  final double shellBase;
  final double motionBase;
  final double breathBase;
  final double priority;

  const _OverlayProfile({
    required this.paletteKey,
    required this.glowBase,
    required this.textBase,
    required this.shellBase,
    required this.motionBase,
    required this.breathBase,
    required this.priority,
  });
}
