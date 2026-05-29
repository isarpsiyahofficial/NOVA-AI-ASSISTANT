// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../core/navigation/nova_page_key.dart';
import '../../services/navigation/dashboard_navigation_service.dart';
import '../call/call_contact_control_page.dart';
import '../settings/settings_control_page.dart';
import '../status/active_status_page.dart';
import '../voice/voice_profile_page.dart';

class NovaDashboardHubPage extends StatefulWidget {
  final DashboardNavigationService navigationService;
  final Widget mainDashboardPage;
  final SettingsControlPage settingsPage;
  final VoiceProfilePage voiceProfilePage;
  final CallContactControlPage callContactControlPage;
  final ActiveStatusPage activeStatusPage;

  const NovaDashboardHubPage({
    super.key,
    required this.navigationService,
    required this.mainDashboardPage,
    required this.settingsPage,
    required this.voiceProfilePage,
    required this.callContactControlPage,
    required this.activeStatusPage,
  });

  @override
  State<NovaDashboardHubPage> createState() => _NovaDashboardHubPageState();
}

class _NovaDashboardHubPageState extends State<NovaDashboardHubPage> {
  int get _index {
    switch (widget.navigationService.current) {
      case NovaPageKey.mainDashboard:
        return 0;
      case NovaPageKey.settings:
        return 1;
      case NovaPageKey.voiceProfiles:
        return 2;
      case NovaPageKey.callContacts:
        return 3;
      case NovaPageKey.activeStatus:
        return 4;
    }
  }

  void _onTap(int index) {
    final page = NovaPageKey.values[index];
    setState(() {
      widget.navigationService.goTo(page);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      widget.mainDashboardPage,
      widget.settingsPage,
      widget.voiceProfilePage,
      widget.callContactControlPage,
      widget.activeStatusPage,
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Panel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Ayarlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.record_voice_over_outlined),
            label: 'Ses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call_outlined),
            label: 'Kişiler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined),
            label: 'Durum',
          ),
        ],
      ),
    );
  }
}
