// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Kontrol Paneli'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionCard(
            title: "Yapay Zeka",
            items: [
              "Model Durumu",
              "Hızlı Yanıt Aktif",
              "Öğrenme Sistemi Aktif",
            ],
          ),
          _SectionCard(
            title: "İzinler",
            items: ["Telefon Yönetimi", "Çağrı Kontrolü", "İnternet (ChatGPT)"],
          ),
          _SectionCard(
            title: "Davranış",
            items: ["Şaka Seviyesi", "Konuşma Stili", "Sohbet Seviyesi"],
          ),
          _SectionCard(
            title: "Durum",
            items: ["Aktif Durum", "Gece Rutini", "Durum İptali"],
          ),
          _SectionCard(
            title: "Güvenlik",
            items: ["Yetkili Kullanıcılar", "Ses Tanıma", "Kontrol Koruması"],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _SectionCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...items.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text("• $e"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
