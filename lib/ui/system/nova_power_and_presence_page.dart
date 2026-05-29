// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../services/presence/nova_presence_service.dart';
import '../../core/system/nova_power_mode.dart';
import '../../services/system/nova_power_service.dart';

class NovaPowerAndPresencePage extends StatefulWidget {
  final NovaPowerService powerService;
  final NovaPresenceService presenceService;

  const NovaPowerAndPresencePage({
    super.key,
    required this.powerService,
    required this.presenceService,
  });

  @override
  State<NovaPowerAndPresencePage> createState() =>
      _NovaPowerAndPresencePageState();
}

class _NovaPowerAndPresencePageState extends State<NovaPowerAndPresencePage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    await widget.powerService.restore();
    await widget.presenceService.restore();

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  Future<void> _setFullyShutdown() async {
    await widget.powerService.setFullyShutdown(userInitiated: true);
    widget.presenceService.setStateSafe(NovaPresenceState.fullyOff);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _setFullyOn() async {
    await widget.powerService.setFullyOn(userInitiated: true);
    widget.presenceService.setStateSafe(NovaPresenceState.idle);
    if (!mounted) return;
    setState(() {});
  }

  String _powerLabel() {
    final mode = widget.powerService.mode;
    switch (mode) {
      case NovaPowerMode.fullyOn:
        return 'Tam güç modu';
      case NovaPowerMode.batterySaver:
        return 'Tasarruf modu';
      case NovaPowerMode.limbo:
        return 'Araf modu';
      case NovaPowerMode.passiveSleep:
        return 'Gece modu';
      case NovaPowerMode.fullyShutdown:
        return 'Shutdown modu';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final settings = widget.presenceService.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Güç ve Gösterge'), centerTitle: true),
      body: AnimatedBuilder(
        animation: widget.presenceService,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Asistan Güç Durumu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text('Durum: ${_powerLabel()}'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _setFullyOn,
                        child: const Text('Tam Güç Modu'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          await widget.powerService.setBatterySaver(
                            userInitiated: true,
                          );
                          widget.presenceService.setStateSafe(
                            NovaPresenceState.idle,
                          );
                          if (!mounted) return;
                          setState(() {});
                        },
                        child: const Text('Tasarruf Modu'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          await widget.powerService.setLimbo(
                            userInitiated: true,
                          );
                          widget.presenceService.setStateSafe(
                            NovaPresenceState.sleeping,
                          );
                          if (!mounted) return;
                          setState(() {});
                        },
                        child: const Text('Araf Modu'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          await widget.powerService.setPassiveSleep(
                            userInitiated: true,
                          );
                          widget.presenceService.setStateSafe(
                            NovaPresenceState.sleeping,
                          );
                          if (!mounted) return;
                          setState(() {});
                        },
                        child: const Text('Gece Modu'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _setFullyShutdown,
                        child: const Text('Shutdown Modu'),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<String>(
                        future: widget.powerService.getStartupGreeting(),
                        builder: (context, snapshot) {
                          final greeting =
                              snapshot.data ?? 'Hoş geldin patron.';
                          return Text(
                            'Açıldığında varsayılan karşılama: $greeting',
                          );
                        },
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
                        'Aktiflik Işığı',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: settings.indicatorEnabled,
                        onChanged: (value) {
                          widget.presenceService.setIndicatorEnabled(value);
                        },
                        title: const Text('Gösterge açık'),
                        subtitle: const Text(
                          'Kapatmak asistan davranışını etkilemez, sadece görseli gizler.',
                        ),
                      ),
                      ListTile(
                        title: const Text('Gösterge boyutu'),
                        subtitle: Slider(
                          value: settings.indicatorSize,
                          min: 12,
                          max: 28,
                          divisions: 8,
                          label: settings.indicatorSize.toStringAsFixed(0),
                          onChanged: (value) {
                            widget.presenceService.setIndicatorSize(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
