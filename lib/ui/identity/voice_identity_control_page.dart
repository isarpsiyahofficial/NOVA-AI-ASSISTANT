// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../core/identity/known_voice_identity.dart';
import '../../services/identity/device_owner_identity_service.dart';
import '../../services/identity/voice_identity_registry_service.dart';
import '../../services/identity/voice_introduction_service.dart';
import '../../services/identity/nova_voice_identity_runtime_service.dart';

class VoiceIdentityControlPage extends StatefulWidget {
  final DeviceOwnerIdentityService ownerService;
  final VoiceIdentityRegistryService registryService;
  final VoiceIntroductionService introductionService;
  final NovaVoiceIdentityRuntimeService? runtimeService;

  const VoiceIdentityControlPage({
    super.key,
    required this.ownerService,
    required this.registryService,
    required this.introductionService,
    this.runtimeService,
  });

  @override
  State<VoiceIdentityControlPage> createState() =>
      _VoiceIdentityControlPageState();
}

enum _VoiceIdentityType { familiar, authorized }

class _VoiceIdentityControlPageState extends State<VoiceIdentityControlPage> {
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerVoiceIdController = TextEditingController();
  final TextEditingController _welcomeTextController = TextEditingController();

  final TextEditingController _personNameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _voiceIdController = TextEditingController();

  List<KnownVoiceIdentity> _items = const <KnownVoiceIdentity>[];
  bool _loading = true;
  bool _saving = false;
  _VoiceIdentityType _identityType = _VoiceIdentityType.familiar;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerVoiceIdController.dispose();
    _welcomeTextController.dispose();
    _personNameController.dispose();
    _relationshipController.dispose();
    _voiceIdController.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final owner = await widget.ownerService.loadOwner();
    final items = await widget.registryService.getAll();

    if (!mounted) return;

    setState(() {
      if (owner != null) {
        _ownerNameController.text = owner.ownerName;
        _ownerVoiceIdController.text = owner.ownerVoiceId;
        _welcomeTextController.text = owner.welcomeBackText;
      }
      _items = items;
      _loading = false;
    });
  }

  Future<void> _saveOwner() async {
    final ownerName = _ownerNameController.text.trim();
    final ownerVoiceId = _ownerVoiceIdController.text.trim();
    final welcomeText = _welcomeTextController.text.trim();

    if (ownerName.isEmpty || ownerVoiceId.isEmpty) return;

    setState(() {
      _saving = true;
    });

    await widget.ownerService.registerOwner(
      ownerName: ownerName,
      ownerVoiceId: ownerVoiceId,
      welcomeBackText: welcomeText.isEmpty ? 'Hoş geldin patron.' : welcomeText,
      proactiveChatAllowed: true,
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
    });
  }

  Future<void> _introducePerson() async {
    final name = _personNameController.text.trim();
    final relationship = _relationshipController.text.trim();
    var voiceId = _voiceIdController.text.trim();

    if (name.isEmpty || relationship.isEmpty) return;

    setState(() {
      _saving = true;
    });

    if (voiceId.isEmpty && widget.runtimeService != null) {
      final generatedVoiceId = _normalizeVoiceId(name, relationship);
      final enroll = await widget.runtimeService!.enrollFromFreshExternalSample(
        voiceId: generatedVoiceId,
        displayName: name,
        maxDurationSeconds: 6,
        outputName: 'nova_identity_$generatedVoiceId',
      );
      if (!enroll.success || enroll.voiceId.trim().isEmpty) {
        if (!mounted) return;
        setState(() {
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enroll.message.trim().isEmpty
                  ? 'Ses kaydı alınamadı.'
                  : enroll.message.trim(),
            ),
          ),
        );
        return;
      }
      voiceId = enroll.voiceId.trim();
    }

    if (voiceId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      return;
    }

    await widget.introductionService.introducePerson(
      displayName: name,
      relationshipLabel: relationship,
      voiceId: voiceId,
      grantNovaPermission: _identityType == _VoiceIdentityType.authorized,
      allowAutoCallHandling: false,
      familiarOnly: _identityType == _VoiceIdentityType.familiar,
    );

    final items = await widget.registryService.getAll();

    if (!mounted) return;

    setState(() {
      _items = items;
      _saving = false;
      _personNameController.clear();
      _relationshipController.clear();
      _voiceIdController.clear();
      _identityType = _VoiceIdentityType.familiar;
    });
  }

  Future<void> _removeIdentity(String id) async {
    setState(() {
      _saving = true;
    });

    await widget.registryService.remove(id);
    final items = await widget.registryService.getAll();

    if (!mounted) return;

    setState(() {
      _items = items;
      _saving = false;
    });
  }

  String _normalizeVoiceId(String name, String relationship) {
    final base = '${name.trim()}_${relationship.trim()}'.toLowerCase();
    return base
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü]+', unicode: true), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ses Kimliği, Tanıdık ve Yetki'),
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
                    'Cihaz Sahibi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ownerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Sahip adı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ownerVoiceIdController,
                    decoration: const InputDecoration(
                      labelText: 'Sahip ses kimliği',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _welcomeTextController,
                    decoration: const InputDecoration(
                      labelText: 'Açılış karşılama metni',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _saveOwner,
                      child: const Text('Sahibi Kaydet'),
                    ),
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
                    'Yetki Ayrımı',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cihaz sahibi en üst yetkiye sahiptir. Yetkili kişiler Novai kullanabilir ama yetki verme/alma sahibi yerine yapamaz. Tanıdık kişiler yalnız tanınır; sohbet edilebilir fakat komut veremez.',
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
                children: [
                  Text(
                    'Kişi Tanıştır',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _personNameController,
                    decoration: const InputDecoration(
                      labelText: 'Kişi adı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _relationshipController,
                    decoration: const InputDecoration(
                      labelText:
                          'İlişki etiketi (örn: Eşiniz Esma / Oğlunuz Hüseyin)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _voiceIdController,
                    decoration: const InputDecoration(
                      labelText:
                          'Ses kimliği (boş bırakırsanız mikrofondan alınır)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<_VoiceIdentityType>(
                    segments: const <ButtonSegment<_VoiceIdentityType>>[
                      ButtonSegment<_VoiceIdentityType>(
                        value: _VoiceIdentityType.familiar,
                        label: Text('Tanıdık'),
                        icon: Icon(Icons.record_voice_over_rounded),
                      ),
                      ButtonSegment<_VoiceIdentityType>(
                        value: _VoiceIdentityType.authorized,
                        label: Text('Yetkili'),
                        icon: Icon(Icons.verified_user_rounded),
                      ),
                    ],
                    selected: <_VoiceIdentityType>{_identityType},
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) return;
                      setState(() {
                        _identityType = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Çağrı yetkisi ses profili ekranından değil, kişiler listesindeki çağrı yetkisi alanından yönetilir.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _introducePerson,
                      child: const Text('Kişiyi Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('İlişki: ${item.relationshipLabel}'),
                    Text(
                      'Ses yetki seviyesi: ${item.isAuthorizedToUseNova ? "Yetkili" : "Tanıdık"}',
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => _removeIdentity(item.id),
                      child: const Text('Sil'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: Text('Ses kimliği verileri kaydediliyor...'),
              ),
            ),
        ],
      ),
    );
  }
}
