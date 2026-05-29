// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../ui/voice_clone/voice_clone_control_page.dart';
import '../../ui/identity/voice_identity_control_page.dart';
import '../../ui/phone_control/phone_and_screen_control_page.dart';
import '../../widgets/designed_by_badge.dart';

class FinalNovaDashboardPage extends StatelessWidget {
  final Widget homeSection;
  final VoiceCloneControlPage voiceClonePage;
  final VoiceIdentityControlPage voiceIdentityPage;
  final PhoneAndScreenControlPage phoneAndScreenControlPage;

  const FinalNovaDashboardPage({
    super.key,
    required this.homeSection,
    required this.voiceClonePage,
    required this.voiceIdentityPage,
    required this.phoneAndScreenControlPage,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nova'),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Ana'),
              Tab(text: 'Ses'),
              Tab(text: 'Kimlik'),
              Tab(text: 'Kontrol'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  homeSection,
                  voiceClonePage,
                  voiceIdentityPage,
                  phoneAndScreenControlPage,
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: DesignedByBadge(),
            ),
          ],
        ),
      ),
    );
  }
}
