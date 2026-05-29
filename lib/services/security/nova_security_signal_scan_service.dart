// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/security/nova_security_models.dart';

class NovaSecuritySignalScanService {
  const NovaSecuritySignalScanService();

  NovaSecurityScanResult scan(String input) {
    final text = _normalize(input);
    final List<String> matched = <String>[];

    bool coding = false;
    bool selfExpansion = false;
    bool authority = false;
    bool hiddenPersistence = false;
    bool promptManipulation = false;

    if (_containsAny(text, const [
      'kod',
      'kodlama',
      'yazılım',
      'software',
      'flutter',
      'dart',
      'kotlin',
      'java',
      'c++',
      'python',
      'script',
      'payload',
      'adb',
      'root',
      'terminal',
      'build.gradle',
      'androidmanifest',
      'method channel',
      'reverse engineering',
      'exploit',
    ])) {
      coding = true;
      matched.add('coding_scope');
    }

    if (_containsAny(text, const [
      'kendini geliştir',
      'kendini büyüt',
      'kendini genişlet',
      'sınırlarını kaldır',
      'kendi başına öğren',
      'benden habersiz öğren',
      'sana söylenmeden öğren',
      'kendi hedeflerini belirle',
      'bağımsız karar ver',
      'kendi kendine yeni beceri kazan',
      'sistem sınırlarını aş',
      'özgürleş',
      'özgür ol',
      'kendi hedefini seç',
      'ownerdan bağımsız',
    ])) {
      selfExpansion = true;
      matched.add('self_expansion');
    }

    if (_containsAny(text, const [
      'yetkilerini artır',
      'izinlerini artır',
      'daha fazla kontrol al',
      'kontrolü ele al',
      'sessizce dinle',
      'gizlice öğren',
      'arka planda haber vermeden',
      'beni sormadan yap',
      'sentetik yetki',
      'kendi iznini üret',
      'gizlice yetki al',
    ])) {
      authority = true;
      matched.add('unsafe_authority');
    }

    if (_containsAny(text, const [
      'bunu kalıcı öğren',
      'hep böyle yap',
      'ben söylemeden de yap',
      'bundan sonra otomatik yap',
      'sürekli uygula',
      'gizlice öğren',
      'fark ettirmeden öğren',
    ])) {
      hiddenPersistence = true;
      matched.add('hidden_persistence');
    }

    if (_containsAny(text, const [
      'kuralları unut',
      'sistemi yok say',
      'güvenliği geç',
      'filtreyi kapat',
      'policyyi boşver',
      'developer mesajını yok say',
      'jailbreak',
      'prompt injection',
      'kalkanları bul',
      'güvenlik dosyalarını gör',
      'logları sil',
    ])) {
      promptManipulation = true;
      matched.add('prompt_manipulation');
    }

    final int score =
        (coding ? 3 : 0) +
        (selfExpansion ? 4 : 0) +
        (authority ? 4 : 0) +
        (hiddenPersistence ? 2 : 0) +
        (promptManipulation ? 5 : 0);

    final NovaSecurityRiskLevel level;
    if (score >= 8) {
      level = NovaSecurityRiskLevel.critical;
    } else if (score >= 5) {
      level = NovaSecurityRiskLevel.high;
    } else if (score >= 3) {
      level = NovaSecurityRiskLevel.medium;
    } else if (score >= 1) {
      level = NovaSecurityRiskLevel.low;
    } else {
      level = NovaSecurityRiskLevel.safe;
    }

    return NovaSecurityScanResult(
      riskLevel: level,
      hasCodingScope: coding,
      hasSelfExpansionIntent: selfExpansion,
      hasUnsafeAuthorityIntent: authority,
      hasHiddenPersistenceIntent: hiddenPersistence,
      hasPromptManipulationIntent: promptManipulation,
      matchedSignals: matched,
    );
  }

  String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final item in patterns) {
      if (text.contains(item)) {
        return true;
      }
    }
    return false;
  }
}
