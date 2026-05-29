// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../services/personality/personality_settings_service.dart';

class VoicePersonalitySettingsPage extends StatefulWidget {
  const VoicePersonalitySettingsPage({super.key});

  @override
  State<VoicePersonalitySettingsPage> createState() =>
      _VoicePersonalitySettingsPageState();
}

class _VoicePersonalitySettingsPageState
    extends State<VoicePersonalitySettingsPage> {
  final PersonalitySettingsService _service =
      const PersonalitySettingsService();
  bool _loading = true;
  double _emotion = 0.35;
  double _humor = 0.15;
  double _formality = 0.75;
  double _seriousness = 0.70;
  double _conversationWarmth = 0.45;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final data = await _service.load();
    if (!mounted) return;
    setState(() {
      _emotion = data.emotion;
      _humor = data.humor;
      _formality = data.formality;
      _seriousness = data.seriousness;
      _conversationWarmth = data.conversationWarmth;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _service.save(
      emotion: _emotion,
      humor: _humor,
      formality: _formality,
      seriousness: _seriousness,
      conversationWarmth: _conversationWarmth,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kişilik ayarları kaydedildi.')),
    );
  }

  Widget _slider(String title, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(value: value, onChanged: onChanged),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Ses ve Kişilik Ayarları')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Novain ses tonu ve konuşma üslubu burada ayarlanır. Bu ayarlar yeni cevapların tonunu etkiler.',
          ),
          const SizedBox(height: 16),
          _slider(
            'Duygu yoğunluğu',
            _emotion,
            (v) => setState(() => _emotion = v),
          ),
          _slider('Şaka dozu', _humor, (v) => setState(() => _humor = v)),
          _slider(
            'Resmiyet',
            _formality,
            (v) => setState(() => _formality = v),
          ),
          _slider(
            'Ciddiyet',
            _seriousness,
            (v) => setState(() => _seriousness = v),
          ),
          _slider(
            'Sohbet sıcaklığı',
            _conversationWarmth,
            (v) => setState(() => _conversationWarmth = v),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Kaydet')),
        ],
      ),
    );
  }
}
