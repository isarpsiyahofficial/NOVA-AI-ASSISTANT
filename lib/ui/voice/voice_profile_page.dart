// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../core/voice/voice_profile.dart';
import '../../services/voice/voice_profile_storage_service.dart';

class VoiceProfilePage extends StatefulWidget {
  final VoiceProfileStorageService storageService;

  const VoiceProfilePage({super.key, required this.storageService});

  @override
  State<VoiceProfilePage> createState() => _VoiceProfilePageState();
}

class _VoiceProfilePageState extends State<VoiceProfilePage> {
  List<VoiceProfile> _profiles = const <VoiceProfile>[];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final profiles = await widget.storageService.loadProfiles();

    if (!mounted) return;

    setState(() {
      _profiles = profiles;
      _isLoading = false;
    });
  }

  Future<void> _runSave(Future<List<VoiceProfile>> Function() action) async {
    setState(() {
      _isSaving = true;
    });

    final updated = await action();

    if (!mounted) return;

    setState(() {
      _profiles = updated;
      _isSaving = false;
    });
  }

  Future<void> _selectProfile(String profileId) async {
    await _runSave(() => widget.storageService.selectProfile(profileId));
  }

  Future<void> _approveProfile(String profileId) async {
    await _runSave(() => widget.storageService.approveProfile(profileId));
  }

  Future<void> _rejectProfile(String profileId) async {
    await _runSave(() => widget.storageService.rejectProfile(profileId));
  }

  VoiceProfile? get _selectedProfile {
    for (final VoiceProfile profile in _profiles) {
      if (profile.isSelected) return profile;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final VoiceProfile? selected = _selectedProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Ses Profilleri'), centerTitle: true),
      body: _isLoading
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
                        Text(
                          'Seçili Ses',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          selected?.name ?? 'Seçili ses yok',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selected?.description ??
                              'Henüz bir ses profili seçilmedi.',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selected?.styleHint ?? '',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Buradan kayıtlı ses profillerini seçebilir, yeni bir sesi '
                      'deneyebilir, “bu olsun” diyerek onaylayabilir veya '
                      '“beğenmedim” mantığıyla önceki kayıtlı seslere dönebilirsiniz. '
                      'Ses değişikliği yalnızca sizin onayınızla kalıcı olur.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._profiles.map(_buildProfileCard),
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(child: Text('Ses profili güncelleniyor...')),
                  ),
              ],
            ),
    );
  }

  Widget _buildProfileCard(VoiceProfile profile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (profile.isSelected) const Chip(label: Text('Aktif')),
                if (profile.isApproved && !profile.isSelected)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Chip(label: Text('Onaylı')),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(profile.description),
            if (profile.styleHint.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ton/Stil: ${profile.styleHint}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => _selectProfile(profile.id),
                  child: const Text('Bu sesi dene'),
                ),
                FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () => _approveProfile(profile.id),
                  child: const Text('Bu olsun'),
                ),
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => _rejectProfile(profile.id),
                  child: const Text('Beğenmedim'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
