// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NovaCallStyleLearningProfile {
  final String preferredTone;
  final String pacingHint;
  final String emphasisHint;
  final DateTime updatedAt;

  const NovaCallStyleLearningProfile({
    this.preferredTone = '',
    this.pacingHint = '',
    this.emphasisHint = '',
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'preferredTone': preferredTone,
    'pacingHint': pacingHint,
    'emphasisHint': emphasisHint,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NovaCallStyleLearningProfile.fromMap(Map<String, dynamic> map) =>
      NovaCallStyleLearningProfile(
        preferredTone: (map['preferredTone'] as String? ?? '').trim(),
        pacingHint: (map['pacingHint'] as String? ?? '').trim(),
        emphasisHint: (map['emphasisHint'] as String? ?? '').trim(),
        updatedAt:
            DateTime.tryParse((map['updatedAt'] as String? ?? '').trim()) ??
            DateTime.now(),
      );

  NovaCallStyleLearningProfile copyWith({
    String? preferredTone,
    String? pacingHint,
    String? emphasisHint,
    DateTime? updatedAt,
  }) => NovaCallStyleLearningProfile(
    preferredTone: preferredTone ?? this.preferredTone,
    pacingHint: pacingHint ?? this.pacingHint,
    emphasisHint: emphasisHint ?? this.emphasisHint,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class NovaCallStyleLearningService {
  static const String _storageKey = 'nova_call_style_learning_v1';

  const NovaCallStyleLearningService();

  Future<NovaCallStyleLearningProfile> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return NovaCallStyleLearningProfile(updatedAt: DateTime.now());
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return NovaCallStyleLearningProfile(updatedAt: DateTime.now());
      }
      return NovaCallStyleLearningProfile.fromMap(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return NovaCallStyleLearningProfile(updatedAt: DateTime.now());
    }
  }

  Future<void> rememberHints({
    String preferredTone = '',
    String pacingHint = '',
    String emphasisHint = '',
  }) async {
    final current = await load();
    final next = current.copyWith(
      preferredTone: preferredTone.trim().isEmpty
          ? current.preferredTone
          : preferredTone.trim(),
      pacingHint: pacingHint.trim().isEmpty
          ? current.pacingHint
          : pacingHint.trim(),
      emphasisHint: emphasisHint.trim().isEmpty
          ? current.emphasisHint
          : emphasisHint.trim(),
      updatedAt: DateTime.now(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(next.toMap()));
  }

  Future<String> buildPromptSuffix() async {
    final profile = await load();
    final parts = <String>[];
    if (profile.preferredTone.isNotEmpty)
      parts.add('Ton: ${profile.preferredTone}');
    if (profile.pacingHint.isNotEmpty) parts.add('Akış: ${profile.pacingHint}');
    if (profile.emphasisHint.isNotEmpty)
      parts.add('Vurgu: ${profile.emphasisHint}');
    if (parts.isEmpty) return '';
    return ' Kullanıcının öğrettiği çağrı konuşma ipuçları: ${parts.join(' | ')}.';
  }
}
