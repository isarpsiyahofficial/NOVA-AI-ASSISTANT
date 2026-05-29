// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../services/phone_control/phone_control_guard_service.dart';
import '../../services/phone_control/phone_control_service.dart';
import '../../services/screen_control/screen_observation_permission_service.dart';
import '../../services/permissions/nova_android_permission_bridge_service.dart';

class PhoneAndScreenControlPage extends StatefulWidget {
  final PhoneControlService phoneControlService;
  final PhoneControlGuardService phoneControlGuardService;
  final ScreenObservationPermissionService screenPermissionService;
  final NovaAndroidPermissionBridgeService permissionBridgeService;

  const PhoneAndScreenControlPage({
    super.key,
    required this.phoneControlService,
    required this.phoneControlGuardService,
    required this.screenPermissionService,
    required this.permissionBridgeService,
  });

  @override
  State<PhoneAndScreenControlPage> createState() =>
      _PhoneAndScreenControlPageState();
}

class _PhoneAndScreenControlPageState extends State<PhoneAndScreenControlPage> {
  bool _loading = true;
  bool _saving = false;
  bool _userRespondedToWarning = false;
  String _guardMessage = '';

  bool _overlayEnabled = false;
  bool _accessibilityEnabled = false;
  bool _notificationsEnabled = false;
  bool _micPermissionEnabled = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    await widget.phoneControlService.restore();
    await widget.screenPermissionService.restore();
    await _refreshNativeStatuses();
    await _checkGuard();

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  Future<void> _refreshNativeStatuses() async {
    final overlay = await widget.permissionBridgeService.canDrawOverlays();
    final accessibility = await widget.permissionBridgeService
        .isAccessibilityEnabled();
    final notifications = await widget.permissionBridgeService
        .canPostNotifications();
    final mic = await widget.permissionBridgeService.hasRecordAudioPermission();

    _overlayEnabled = overlay;
    _accessibilityEnabled = accessibility;
    _notificationsEnabled = notifications;
    _micPermissionEnabled = mic;
  }

  Future<void> _checkGuard() async {
    final decision = widget.phoneControlGuardService.evaluate(
      state: widget.phoneControlService.state,
      timeoutMinutes: 60,
      userRespondedToWarning: _userRespondedToWarning,
    );

    if (decision.shouldWarn) {
      _guardMessage = decision.message;
      await widget.phoneControlService.markReminderSent();
      return;
    }

    if (decision.shouldAutoDisable) {
      _guardMessage = decision.message;
      await widget.phoneControlService.disable();
      return;
    }

    _guardMessage = '';
  }

  Future<void> _togglePhoneControl(bool enable) async {
    setState(() {
      _saving = true;
    });

    if (enable) {
      await widget.phoneControlService.enable();
    } else {
      await widget.phoneControlService.disable();
    }

    await _checkGuard();

    if (!mounted) return;

    setState(() {
      _saving = false;
      _userRespondedToWarning = true;
    });
  }

  Future<void> _keepPhoneControlOn() async {
    setState(() {
      _saving = true;
    });

    await widget.phoneControlService.extendSession();
    await _checkGuard();

    if (!mounted) return;

    setState(() {
      _saving = false;
      _userRespondedToWarning = true;
      _guardMessage = 'Telefon yönetimi süresi uzatıldı efendim.';
    });
  }

  Future<void> _toggleScreenObservation(bool enable) async {
    setState(() {
      _saving = true;
    });

    if (enable) {
      await widget.screenPermissionService.enableManual();
    } else {
      await widget.screenPermissionService.disable();
    }

    if (!mounted) return;

    setState(() {
      _saving = false;
    });
  }

  Future<void> _openOverlaySettings() async {
    await widget.permissionBridgeService.openOverlaySettings();
    await _refreshNativeStatuses();
    if (mounted) setState(() {});
  }

  Future<void> _openAccessibilitySettings() async {
    await widget.permissionBridgeService.openAccessibilitySettings();
    await _refreshNativeStatuses();
    if (mounted) setState(() {});
  }

  Future<void> _openNotificationSettings() async {
    await widget.permissionBridgeService.openAppNotificationSettings();
    await _refreshNativeStatuses();
    if (mounted) setState(() {});
  }

  Future<void> _openAppSettings() async {
    await widget.permissionBridgeService.openAppSettings();
    await _refreshNativeStatuses();
    if (mounted) setState(() {});
  }

  Widget _buildNativeRequirementCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Native Yetki Durumu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Overlay'),
              subtitle: Text(_overlayEnabled ? 'Hazır' : 'Kapalı'),
              trailing: FilledButton.tonal(
                onPressed: _openOverlaySettings,
                child: const Text('Aç'),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Accessibility'),
              subtitle: Text(_accessibilityEnabled ? 'Hazır' : 'Kapalı'),
              trailing: FilledButton.tonal(
                onPressed: _openAccessibilitySettings,
                child: const Text('Aç'),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bildirim'),
              subtitle: Text(_notificationsEnabled ? 'Hazır' : 'Kontrol Et'),
              trailing: FilledButton.tonal(
                onPressed: _openNotificationSettings,
                child: const Text('Ayar'),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mikrofon / Uygulama izinleri'),
              subtitle: Text(
                _micPermissionEnabled ? 'Hazır' : 'Eksik olabilir',
              ),
              trailing: FilledButton.tonal(
                onPressed: _openAppSettings,
                child: const Text('Uygulama Ayarı'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Telefon yönetimi ve ekran izleme anahtarları açık olsa bile, native izinler kapalıysa otomasyon / overlay / accessibility zinciri eksik çalışır.',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final phoneEnabled = widget.phoneControlService.isEnabled;
    final screenEnabled = widget.screenPermissionService.isEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telefon ve Ekran Kontrolü'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNativeRequirementCard(),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Telefon Yönetimi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: phoneEnabled,
                    onChanged: _saving ? null : _togglePhoneControl,
                    title: const Text('Telefon yönetimi aktif'),
                    subtitle: const Text(
                      'Yalnızca siz izin verdiğinizde görev yürütür.',
                    ),
                  ),
                  if (_guardMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _guardMessage,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (phoneEnabled)
                      FilledButton.tonal(
                        onPressed: _saving ? null : _keepPhoneControlOn,
                        child: const Text('Açık Kalsın'),
                      ),
                  ],
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
                    'Ekran İzleme / Ekran Yönetme',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: screenEnabled,
                    onChanged: _saving ? null : _toggleScreenObservation,
                    title: const Text('Ekran izleme izni aktif'),
                    subtitle: const Text(
                      'Sadece gerektiğinde açılması önerilir.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bu izin kapalıysa asistan ekran üzerinde işlem yapmadan önce izin ister. '
                    'Telefon cevaplama ve diğer bağımsız fonksiyonlar kendi kurallarına göre çalışmaya devam eder.',
                  ),
                ],
              ),
            ),
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: Text('Ayarlar uygulanıyor...')),
            ),
        ],
      ),
    );
  }
}
