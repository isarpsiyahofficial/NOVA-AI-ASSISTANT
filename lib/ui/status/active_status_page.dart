// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../services/status/status_service.dart';
import '../../services/status/status_storage_service.dart';

class ActiveStatusPage extends StatefulWidget {
  final StatusService statusService;
  final StatusStorageService storageService;

  const ActiveStatusPage({
    super.key,
    required this.statusService,
    required this.storageService,
  });

  @override
  State<ActiveStatusPage> createState() => _ActiveStatusPageState();
}

class _ActiveStatusPageState extends State<ActiveStatusPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  UserStatusType _selectedType = UserStatusType.sleeping;
  int _selectedDurationHours = 2;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    await widget.storageService.restore(widget.statusService);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _setQuickStatus({
    required UserStatusType type,
    required String label,
    required Duration duration,
    bool setByVoice = false,
  }) async {
    setState(() {
      _isSaving = true;
    });

    widget.statusService.setStatus(
      type: type,
      label: label,
      duration: duration,
      setByVoice: setByVoice,
    );

    await widget.storageService.save(widget.statusService);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _selectedType = type;
      _selectedDurationHours = duration.inHours <= 0 ? 1 : duration.inHours;
    });
  }

  Future<void> _cancelStatus() async {
    setState(() {
      _isSaving = true;
    });

    widget.statusService.cancelCurrentStatus();
    await widget.storageService.save(widget.statusService);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _saveNightRoutine({
    required int startHour,
    required int endHour,
  }) async {
    setState(() {
      _isSaving = true;
    });

    widget.statusService.updateConfig(
      widget.statusService.config.copyWith(
        nightlySleepStartHour: startHour,
        nightlySleepEndHour: endHour,
      ),
    );

    await widget.storageService.save(widget.statusService);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _saveCheckInterval(int hours) async {
    setState(() {
      _isSaving = true;
    });

    widget.statusService.updateConfig(
      widget.statusService.config.copyWith(
        periodicCheckInterval: Duration(hours: hours),
      ),
    );

    await widget.storageService.save(widget.statusService);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });
  }

  String _statusLabel(UserStatusType type) {
    switch (type) {
      case UserStatusType.sleeping:
        return 'Uyuyor';
      case UserStatusType.showering:
        return 'Duşta';
      case UserStatusType.driving:
        return 'Trafikte';
      case UserStatusType.busy:
        return 'Meşgul';
      case UserStatusType.custom:
        return 'Özel';
    }
  }

  String _currentStatusText() {
    final type = widget.statusService.currentStatusType;
    final label = widget.statusService.currentStatusLabel;

    if (type == null || label == null) {
      return 'Aktif özel durum yok.';
    }

    return 'Aktif durum: ${_statusLabel(type)} ($label)';
  }

  Widget _buildQuickStatusButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton(
          onPressed: _isSaving
              ? null
              : () => _setQuickStatus(
                  type: UserStatusType.sleeping,
                  label: 'sleeping',
                  duration: const Duration(hours: 8),
                ),
          child: const Text('8 Saat Uyuyorum'),
        ),
        FilledButton(
          onPressed: _isSaving
              ? null
              : () => _setQuickStatus(
                  type: UserStatusType.showering,
                  label: 'showering',
                  duration: const Duration(minutes: 30),
                ),
          child: const Text('Duştayım'),
        ),
        FilledButton(
          onPressed: _isSaving
              ? null
              : () => _setQuickStatus(
                  type: UserStatusType.driving,
                  label: 'driving',
                  duration: const Duration(hours: 2),
                ),
          child: const Text('Trafikteyim'),
        ),
        FilledButton(
          onPressed: _isSaving
              ? null
              : () => _setQuickStatus(
                  type: UserStatusType.busy,
                  label: 'busy',
                  duration: const Duration(hours: 2),
                ),
          child: const Text('Meşgulüm'),
        ),
      ],
    );
  }

  Widget _buildCustomStatusEditor() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Özel Durum Tanımla',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UserStatusType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Durum tipi',
                border: OutlineInputBorder(),
              ),
              items: UserStatusType.values
                  .map(
                    (type) => DropdownMenuItem<UserStatusType>(
                      value: type,
                      child: Text(_statusLabel(type)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Süre (saat)'),
              subtitle: Slider(
                value: _selectedDurationHours.toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                label: _selectedDurationHours.toString(),
                onChanged: (value) {
                  setState(() {
                    _selectedDurationHours = value.round();
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving
                    ? null
                    : () => _setQuickStatus(
                        type: _selectedType,
                        label: _selectedType.name,
                        duration: Duration(hours: _selectedDurationHours),
                      ),
                child: const Text('Bu Durumu Başlat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNightRoutineCard() {
    final config = widget.statusService.config;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Gece Rutini', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Text('Uyku başlangıcı')),
                DropdownButton<int>(
                  value: config.nightlySleepStartHour,
                  items: List<DropdownMenuItem<int>>.generate(
                    24,
                    (index) => DropdownMenuItem<int>(
                      value: index,
                      child: Text(index.toString().padLeft(2, '0')),
                    ),
                  ),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null) return;
                          _saveNightRoutine(
                            startHour: value,
                            endHour: config.nightlySleepEndHour,
                          );
                        },
                ),
              ],
            ),
            Row(
              children: [
                const Expanded(child: Text('Uyku bitişi')),
                DropdownButton<int>(
                  value: config.nightlySleepEndHour,
                  items: List<DropdownMenuItem<int>>.generate(
                    24,
                    (index) => DropdownMenuItem<int>(
                      value: index,
                      child: Text(index.toString().padLeft(2, '0')),
                    ),
                  ),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null) return;
                          _saveNightRoutine(
                            startHour: config.nightlySleepStartHour,
                            endHour: value,
                          );
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckIntervalCard() {
    final config = widget.statusService.config;
    final currentHours = config.periodicCheckInterval.inHours;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Durum Kontrol Aralığı',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Her $currentHours saatte bir sor'),
              subtitle: Slider(
                value: currentHours.toDouble(),
                min: 1,
                max: 6,
                divisions: 5,
                label: currentHours.toString(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        _saveCheckInterval(value.round());
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool hasActiveStatus = widget.statusService.isAnyStatusActive;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktif Durum Yönetimi'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Geçerli Durum',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(_currentStatusText()),
                  const SizedBox(height: 12),
                  if (hasActiveStatus)
                    FilledButton.tonal(
                      onPressed: _isSaving ? null : _cancelStatus,
                      child: const Text('Durumu İptal Et'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hızlı Durumlar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildQuickStatusButtons(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCustomStatusEditor(),
          const SizedBox(height: 12),
          _buildNightRoutineCard(),
          const SizedBox(height: 12),
          _buildCheckIntervalCard(),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: Text('Durum ayarları kaydediliyor...')),
            ),
        ],
      ),
    );
  }
}

class NovaActiveStatusQuickProfile {
  final String label;
  final Duration duration;
  final String explanation;

  const NovaActiveStatusQuickProfile({
    required this.label,
    required this.duration,
    required this.explanation,
  });
}

extension NovaActiveStatusProfiles on _ActiveStatusPageState {
  List<NovaActiveStatusQuickProfile> buildVoiceFriendlyProfiles() {
    return const <NovaActiveStatusQuickProfile>[
      NovaActiveStatusQuickProfile(
        label: 'Uyuyorum',
        duration: Duration(hours: 2),
        explanation: 'Çağrı yönetimi yumuşak ve koruyucu tona geçer.',
      ),
      NovaActiveStatusQuickProfile(
        label: 'İşteyim',
        duration: Duration(hours: 4),
        explanation: 'Kısa, profesyonel ve gereksiz bölmeyen akışa geçilir.',
      ),
      NovaActiveStatusQuickProfile(
        label: 'Müsait değilim',
        duration: Duration(hours: 1),
        explanation: 'Nova konuşma devralmayı daha erken teklif edebilir.',
      ),
    ];
  }

  String buildStatusGovernanceMemo() {
    final profiles = buildVoiceFriendlyProfiles();
    return <String>[
      'AKTİF DURUM YÖNETİMİ:',
      ...profiles.map(
        (p) => '- ${p.label}: ${p.duration.inHours}s | ${p.explanation}',
      ),
      'Kural: durum değişince dashboard, çağrı ve arka plan zinciri aynı bağlamı paylaşmalıdır.',
    ].join('\n');
  }
}

class NovaStatusAuthorityMemo {
  final String title;
  final List<String> rules;

  const NovaStatusAuthorityMemo({required this.title, required this.rules});

  String render() => <String>[title, ...rules.map((e) => '- $e')].join('\n');
}

extension NovaActiveStatusAuthorityExtension on _ActiveStatusPageState {
  NovaStatusAuthorityMemo buildAuthorityMemo() {
    return const NovaStatusAuthorityMemo(
      title: 'DURUM > YETKİ > ÇAĞRI UYUM MEMOSU',
      rules: <String>[
        'Durum değişikliği çağrı/companion akışına tek kaynak olarak yansır.',
        'Uyku modunda aile ve acil istisnaları daha koruyucu biçimde değerlendirilir.',
        'Aynı durum dashboard ve sesli komut katmanında farklı görünemez.',
        'Owner önceliği ve yetkili ayrımı durum akışını ezmemeli; birlikte çalışmalıdır.',
      ],
    );
  }
}
