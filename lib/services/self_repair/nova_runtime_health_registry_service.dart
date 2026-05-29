// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_runtime_health_issue.dart';
import '../../core/self_repair/nova_runtime_health_snapshot.dart';

class NovaRuntimeHealthRegistryService {
  static final NovaRuntimeHealthRegistryService instance =
      NovaRuntimeHealthRegistryService._();
  NovaRuntimeHealthRegistryService._();

  final List<NovaRuntimeHealthIssue> _issues = <NovaRuntimeHealthIssue>[];

  void publish(NovaRuntimeHealthIssue issue) {
    _issues.removeWhere(
      (e) => e.module == issue.module && e.code == issue.code,
    );
    if (_isHealthyIssue(issue)) {
      _issues.removeWhere((e) => e.module == issue.module);
      return;
    }
    _issues.add(issue);
  }

  bool _isHealthyIssue(NovaRuntimeHealthIssue issue) {
    final joined = '${issue.code.toLowerCase()} ${issue.message.toLowerCase()}';
    const healthyTokens = <String>[
      'healthy',
      'ready',
      'verified',
      'ok',
      'running',
      'available',
      'success',
      'resolved',
      'çalışıyor',
      'calisiyor',
      'hazır',
      'hazir',
      'doğrulandı',
      'dogrulandi',
      'aktif',
    ];
    const brokenTokens = <String>[
      'fail',
      'failed',
      'degraded',
      'blocked',
      'timeout',
      'error',
      'hata',
      'başarısız',
      'basarisiz',
      'engellendi',
    ];
    return healthyTokens.any(joined.contains) &&
        !brokenTokens.any(joined.contains);
  }

  NovaRuntimeHealthSnapshot snapshot() => NovaRuntimeHealthSnapshot(
    createdAt: DateTime.now(),
    issues: List<NovaRuntimeHealthIssue>.unmodifiable(_issues),
  );
}
