// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_system_issue.dart';
import 'nova_capability_catalog_service.dart';
import 'nova_self_diagnostic_service.dart';

class NovaDebugModeResult {
  final List<NovaSystemIssue> issues;
  final List<NovaCapabilityCatalogItem> capabilities;
  final String message;
  const NovaDebugModeResult({
    required this.issues,
    required this.capabilities,
    required this.message,
  });
}

class NovaDebugModeService {
  final NovaSelfDiagnosticService diagnosticService;
  final NovaCapabilityCatalogService capabilityCatalogService;
  const NovaDebugModeService({
    required this.diagnosticService,
    required this.capabilityCatalogService,
  });

  Future<NovaDebugModeResult> runDeepDebug() async {
    final issues = await diagnosticService.diagnose();
    final capabilities = await capabilityCatalogService.loadSafeCatalog();
    final unhealthy = capabilities.where((e) => !e.healthy).length;
    final healthyCount = capabilities.length - unhealthy;
    final msg = issues.isEmpty
        ? 'Hata ayıklama tamamlandı efendim. ${capabilities.length} sistem alanı tarandı, $healthyCount alan sağlıklı görünüyor.'
        : 'Hata ayıklama tamamlandı efendim. ${issues.length} aktif sorun bulundu; ${capabilities.length} sistem alanının $unhealthy tanesi dikkat istiyor.';
    return NovaDebugModeResult(
      issues: issues,
      capabilities: capabilities,
      message: msg,
    );
  }

  bool looksLikeDebugCommand(String input) {
    final t = input.toLowerCase().trim();
    const patterns = <String>[
      'hata ayıkla',
      'debug modu',
      'detaylı tara',
      'sistemi tara',
      'sorunları tara',
      'derin analiz yap',
      'hata tespiti yap',
      'arıza tara',
      'kontrol taraması yap',
      'sistemi incele',
      'sorun bul',
      'tanı koy',
      'diagnostic başlat',
    ];
    return patterns.any(t.contains);
  }
}
