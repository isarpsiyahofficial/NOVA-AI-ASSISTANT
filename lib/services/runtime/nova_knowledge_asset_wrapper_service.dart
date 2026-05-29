// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/services.dart';

/// Bridges legacy generated Dart corpus hints to the asset-backed corpus.
/// Runtime retrieval must prefer pubspec-declared assets/native asset corpus.
class NovaKnowledgeAssetWrapperService {
  const NovaKnowledgeAssetWrapperService();

  static const String manifestAssetPath =
      'assets/offline_corpus_json/manifest.json';

  Future<String> loadManifestSafe() async {
    try {
      return await rootBundle.loadString(manifestAssetPath);
    } catch (_) {
      return '{}';
    }
  }

  Future<String> loadDomainAssetSafe(String assetPath) async {
    final normalized = assetPath.trim();
    if (normalized.isEmpty || normalized.contains('..')) return '';
    try {
      return await rootBundle.loadString(normalized);
    } catch (_) {
      return '';
    }
  }

  bool shouldPreferAssetCorpus(String legacyPath) {
    final lower = legacyPath.toLowerCase();
    return lower.contains('nova_knowledge_') ||
        lower.contains('generated_dart_corpus') ||
        lower.contains('offline_corpus_json');
  }
}
