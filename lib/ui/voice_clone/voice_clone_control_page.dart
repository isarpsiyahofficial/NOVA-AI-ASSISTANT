// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../core/voice_clone/cloned_voice_profile.dart';
import '../../services/voice_clone/cloned_voice_library_service.dart';
import '../../services/voice_clone/turkish_expressive_voice_service.dart';
import '../../services/voice_clone/voice_clone_cleanup_service.dart';
import '../../services/voice_clone/voice_clone_runtime_control_service.dart';
import '../../services/voice_clone/voice_clone_service.dart';
import '../../services/voice_clone/voice_clone_settings_service.dart';

class VoiceCloneControlPage extends StatefulWidget {
  final VoiceCloneSettingsService settingsService;
  final ClonedVoiceLibraryService libraryService;
  final TurkishExpressiveVoiceService expressiveVoiceService;
  final VoiceCloneCleanupService cleanupService;
  final VoiceCloneRuntimeControlService runtimeControlService;
  final VoiceCloneService cloneService;

  const VoiceCloneControlPage({
    super.key,
    required this.settingsService,
    required this.libraryService,
    required this.expressiveVoiceService,
    required this.cleanupService,
    required this.runtimeControlService,
    required this.cloneService,
  });

  @override
  State<VoiceCloneControlPage> createState() => _VoiceCloneControlPageState();
}

class _VoiceCloneControlPageState extends State<VoiceCloneControlPage> {
  List<ClonedVoiceProfile> _voices = const <ClonedVoiceProfile>[];
  String _status = 'Ses klonlama sistemi hazır efendim.';
  bool _loading = true;
  bool _captureRunning = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final voices = await widget.libraryService.getAll();
    if (!mounted) return;
    setState(() {
      _voices = voices;
      _loading = false;
    });
  }

  Future<void> _cleanup() async {
    final removed = await widget.cleanupService.cleanup(
      rawInput: 'gereksiz ses klonlarını temizle',
    );
    await _refresh();
    if (!mounted) return;
    setState(
      () => _status = removed > 0
          ? '$removed klon kayıt temizlendi efendim.'
          : 'Temizlenecek gereksiz klon bulunamadı efendim.',
    );
  }

  Future<void> _activate(String id) async {
    await widget.libraryService.setActiveVoice(id);
    await _refresh();
    if (!mounted) return;
    setState(() => _status = 'Seçili klon ses aktif edildi efendim.');
  }

  Future<void> _favorite(String id, bool value) async {
    await widget.libraryService.setFavorite(id: id, isFavorite: value);
    await _refresh();
  }

  Future<void> _remove(String id) async {
    final ok = await widget.libraryService.remove(id);
    await _refresh();
    if (!mounted) return;
    setState(
      () => _status = ok
          ? 'Klon ses kaldırıldı efendim.'
          : 'Aktif klon ses silinemez efendim.',
    );
  }

  Future<void> _startExternalCapture() async {
    if (_captureRunning) return;
    setState(() {
      _captureRunning = true;
      _status = 'Dış sesten klon örneği alınıyor efendim.';
    });
    final result = await widget.cloneService.startExternalCloneCapture();
    await _refresh();
    if (!mounted) return;
    setState(() {
      _captureRunning = false;
      _status = result;
    });
  }

  Future<void> _startInternalCapture() async {
    if (_captureRunning) return;
    setState(() {
      _captureRunning = true;
      _status = 'Telefon içi sesten klon örneği alınıyor efendim.';
    });
    final result = await widget.cloneService.startInternalCloneCapture();
    await _refresh();
    if (!mounted) return;
    setState(() {
      _captureRunning = false;
      _status = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0E3),
      appBar: AppBar(title: const Text('Ses Klonlama Sistemi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Durum',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(_status),
                        const SizedBox(height: 8),
                        Text(
                          'Aktif runtime: ${widget.runtimeControlService.state.message}',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton(
                              onPressed: _refresh,
                              child: const Text('Yenile'),
                            ),
                            FilledButton.tonal(
                              onPressed: _captureRunning
                                  ? null
                                  : _startExternalCapture,
                              child: Text(
                                _captureRunning
                                    ? 'İşleniyor...'
                                    : 'Dış Sesten Klon Al',
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: _captureRunning
                                  ? null
                                  : _startInternalCapture,
                              child: Text(
                                _captureRunning
                                    ? 'İşleniyor...'
                                    : 'Telefon Sesinden Klon Al',
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _cleanup,
                              child: const Text('Gereksiz Klonları Temizle'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_voices.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Henüz kayıtlı klon ses bulunmuyor.'),
                    ),
                  ),
                ..._voices.map(
                  (voice) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voice.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text('Kaynak: ${voice.sourceType.name}'),
                          Text(
                            'Aktif: ${voice.isActiveInUse ? 'Evet' : 'Hayır'}',
                          ),
                          Text(
                            'Favori: ${voice.isFavorite ? 'Evet' : 'Hayır'}',
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton(
                                onPressed: voice.isActiveInUse
                                    ? null
                                    : () => _activate(voice.id),
                                child: const Text('Aktif Yap'),
                              ),
                              OutlinedButton(
                                onPressed: () =>
                                    _favorite(voice.id, !voice.isFavorite),
                                child: Text(
                                  voice.isFavorite
                                      ? 'Favoriden Çıkar'
                                      : 'Favori Yap',
                                ),
                              ),
                              TextButton(
                                onPressed: voice.isActiveInUse
                                    ? null
                                    : () => _remove(voice.id),
                                child: const Text('Sil'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
