// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

class SettingsControlPanel extends StatelessWidget {
  final double emotionLevel;
  final double humorLevel;
  final double formalityLevel;
  final ValueChanged<double>? onEmotionChanged;
  final ValueChanged<double>? onHumorChanged;
  final ValueChanged<double>? onFormalityChanged;
  const SettingsControlPanel({
    super.key,
    this.emotionLevel = 0.35,
    this.humorLevel = 0.15,
    this.formalityLevel = 0.75,
    this.onEmotionChanged,
    this.onHumorChanged,
    this.onFormalityChanged,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Slider(value: emotionLevel, min: 0, max: 1, onChanged: onEmotionChanged),
      Slider(value: humorLevel, min: 0, max: 1, onChanged: onHumorChanged),
      Slider(
        value: formalityLevel,
        min: 0,
        max: 1,
        onChanged: onFormalityChanged,
      ),
    ],
  );
}
