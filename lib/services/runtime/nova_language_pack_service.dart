// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NovaLanguagePack {
  final String code;
  final String displayName;
  final bool removable;
  final String guidance;

  const NovaLanguagePack({
    required this.code,
    required this.displayName,
    required this.removable,
    required this.guidance,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'code': code,
    'displayName': displayName,
    'removable': removable,
    'guidance': guidance,
  };

  factory NovaLanguagePack.fromMap(Map<String, dynamic> map) =>
      NovaLanguagePack(
        code: (map['code'] as String? ?? '').trim(),
        displayName: (map['displayName'] as String? ?? '').trim(),
        removable: map['removable'] as bool? ?? true,
        guidance: (map['guidance'] as String? ?? '').trim(),
      );
}

class NovaLanguagePackService {
  static const String _storageKey = 'nova_language_packs_v2';

  const NovaLanguagePackService();

  static const NovaLanguagePack turkishCore = NovaLanguagePack(
    code: 'tr',
    displayName: 'Türkçe',
    removable: false,
    guidance:
        'Türkçe ana dildir. Doğal konuşma, niyet çözme, duygu-vurgu ayırımı ve yardımcı asistan tonu daima Türkçe çekirdeğe dayanır.',
  );

  static const NovaLanguagePack englishCore = NovaLanguagePack(
    code: 'en',
    displayName: 'English',
    removable: true,
    guidance:
        'İngilizce paketi aktifse Nova çift yönlü çeviri, tercüman modu ve anlık açıklama desteği verebilir.',
  );

  static const NovaLanguagePack arabicCore = NovaLanguagePack(
    code: 'ar',
    displayName: 'العربية',
    removable: true,
    guidance:
        'Arapça paketi aktifse Nova temel karşılıklı çeviri ve kısa açıklama desteği verir.',
  );

  static const NovaLanguagePack frenchCore = NovaLanguagePack(
    code: 'fr',
    displayName: 'Français',
    removable: true,
    guidance:
        'Fransızca paketi aktifse Nova temel karşılıklı çeviri ve kısa açıklama desteği verir.',
  );

  static const NovaLanguagePack russianCore = NovaLanguagePack(
    code: 'ru',
    displayName: 'Русский',
    removable: true,
    guidance:
        'Rusça paketi aktifse Nova temel karşılıklı çeviri ve kısa açıklama desteği verir.',
  );

  static const NovaLanguagePack italianCore = NovaLanguagePack(
    code: 'it',
    displayName: 'Italiano',
    removable: true,
    guidance:
        'İtalyanca paketi aktifse Nova temel karşılıklı çeviri ve kısa açıklama desteği verir.',
  );

  static const Map<String, NovaLanguagePack> _builtIn =
      <String, NovaLanguagePack>{
        'tr': turkishCore,
        'en': englishCore,
        'ar': arabicCore,
        'fr': frenchCore,
        'ru': russianCore,
        'it': italianCore,
      };

  Future<List<NovaLanguagePack>> loadInstalled() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey)?.trim() ?? '';
    if (raw.isEmpty) {
      return const <NovaLanguagePack>[
        turkishCore,
        englishCore,
        arabicCore,
        frenchCore,
        russianCore,
        italianCore,
      ];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <NovaLanguagePack>[
          turkishCore,
          englishCore,
          arabicCore,
          frenchCore,
          russianCore,
          italianCore,
        ];
      }
      final packs = decoded
          .whereType<Map>()
          .map((e) => NovaLanguagePack.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.code.isNotEmpty)
          .toList(growable: true);
      if (packs.every((e) => e.code != 'tr')) {
        packs.insert(0, turkishCore);
      }
      return packs;
    } catch (_) {
      return const <NovaLanguagePack>[
        turkishCore,
        englishCore,
        arabicCore,
        frenchCore,
        russianCore,
        italianCore,
      ];
    }
  }

  Future<void> installByCode(String code) async {
    final normalized = code.trim().toLowerCase();
    final pack = _builtIn[normalized];
    if (pack == null) return;
    final installed = await loadInstalled();
    if (installed.any((e) => e.code == normalized)) return;
    final next = <NovaLanguagePack>[...installed, pack];
    await _save(next);
  }

  Future<void> removeByCode(String code) async {
    final normalized = code.trim().toLowerCase();
    if (normalized == 'tr') return;
    final installed = await loadInstalled();
    final next = installed
        .where((e) => e.code != normalized)
        .toList(growable: false);
    await _save(next);
  }

  String buildInstalledLanguageGuideSync(List<NovaLanguagePack> installed) {
    final buffer = StringBuffer()..writeln('AKTİF DİL PAKETLERİ:');
    for (final pack in installed) {
      buffer
        ..writeln('- ${pack.displayName} (${pack.code})')
        ..writeln('  ${pack.guidance}');
    }
    buffer
      ..writeln('Dil paketi kuralı: Türkçe daima korunur ve silinemez.')
      ..writeln(
        'Çeviride önce anlamı koru, sonra doğal ifadeyi oluştur. Desteklenmeyen dilde kullanıcıyı yönlendir.',
      );
    return buffer.toString();
  }

  Future<void> _save(List<NovaLanguagePack> packs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(packs.map((e) => e.toMap()).toList(growable: false)),
    );
  }
}
