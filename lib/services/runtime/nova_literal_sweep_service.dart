// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_identity_runtime_service.dart';

class NovaLiteralSweepService {
  final NovaIdentityRuntimeService identityRuntimeService;

  const NovaLiteralSweepService({
    this.identityRuntimeService = const NovaIdentityRuntimeService(),
  });

  Future<String> sweepText(String text) async {
    await identityRuntimeService.ensureLoaded();
    return sweepTextSync(text);
  }

  String sweepTextSync(String text) {
    var value = text.trim();
    if (value.isEmpty) return value;
    value = identityRuntimeService.replaceAssistantLabel(value);
    final displayName = identityRuntimeService.currentDisplayName;
    for (final alias in identityRuntimeService.knownAliases) {
      final safeAlias = alias.trim();
      if (safeAlias.isEmpty) continue;
      final titleCase = _titleCase(safeAlias);
      value = value.replaceAllMapped(
        RegExp('\\b${RegExp.escape(titleCase)}\\b'),
        (_) => displayName,
      );
      value = value.replaceAllMapped(
        RegExp('\\b${RegExp.escape(safeAlias)}\\b', caseSensitive: false),
        (_) => displayName,
      );
    }
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Map<String, dynamic> sweepMetadataSync(Map<String, dynamic> metadata) {
    final out = <String, dynamic>{};
    metadata.forEach((key, value) {
      out[key] = _sweepAny(value);
    });
    return out;
  }

  dynamic _sweepAny(Object? value) {
    if (value is String) return sweepTextSync(value);
    if (value is List) {
      return value.map(_sweepAny).toList(growable: false);
    }
    if (value is Map) {
      final next = <String, dynamic>{};
      value.forEach((key, child) {
        next[key.toString()] = _sweepAny(child);
      });
      return next;
    }
    return value;
  }

  String _titleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
