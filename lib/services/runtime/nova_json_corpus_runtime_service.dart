// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';
import 'dart:io';

import 'nova_json_corpus_models.dart';
import 'nova_knowledge_deduplication_service.dart';

class NovaJsonCorpusRuntimeService {
  const NovaJsonCorpusRuntimeService();

  static const NovaKnowledgeDeduplicationService _dedupe =
      NovaKnowledgeDeduplicationService();

  static String? _installedRootPath;

  static const Map<String, String> _domainFileAliases = <String, String>{
    'general': 'general_life',
    'ultra_support_brain': 'general_life',
    'problem_solving': 'people_understanding',
    'math_advanced': 'physics',
    'biology_advanced': 'human_health',
    'chemistry_advanced': 'physics',
    'numerology_calculations': 'numerology',
    'occultism': 'spiritualism',
    'astrology_calculations': 'astrology',
    'bioenergy': 'spiritualism',
    'reiki': 'spiritualism',
    'physics_formula_applications': 'physics',
    'automotive_catalog': 'cars',
    'automotive_troubleshooting': 'automotive_mechanics',
    'archaeology_advanced': 'turkish_culture',
    'construction_engineering': 'general_life',
    'pvc_aluminum': 'general_life',
    'agriculture_engineering': 'general_life',
    'finance_advanced': 'general_life',
    'crypto_advanced': 'general_life',
  };

  static void configureInstalledRoot(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      _installedRootPath = null;
      return;
    }
    _installedRootPath = normalized;
  }

  static String? configuredInstalledRoot() {
    final value = _installedRootPath?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  List<String> loadDomainLines(
    String domain, {
    List<String>? fallbackSeedLines,
    String? fallbackCorpus,
  }) {
    final records = buildRecords(domain);
    if (records.isNotEmpty) {
      return _dedupe.dedupe(
        records
            .map((NovaJsonCorpusRecord item) => item.text)
            .toList(growable: false),
      );
    }
    if (fallbackSeedLines != null && fallbackSeedLines.isNotEmpty) {
      return _dedupe.dedupe(fallbackSeedLines);
    }
    if (fallbackCorpus != null && fallbackCorpus.trim().isNotEmpty) {
      return _dedupe.sanitizeCorpus(fallbackCorpus);
    }
    return const <String>[];
  }

  List<NovaJsonCorpusRecord> buildRecords(String domain) {
    final file = _resolveDomainFile(domain);
    if (file == null || !file.existsSync()) {
      return const <NovaJsonCorpusRecord>[];
    }
    final records = <NovaJsonCorpusRecord>[];
    for (final rawLine in file.readAsLinesSync(encoding: utf8)) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }
      try {
        final json = jsonDecode(line);
        if (json is! Map<String, dynamic>) {
          continue;
        }
        final text = (json['text'] ?? json['x'] ?? '').toString().trim();
        if (text.isEmpty) {
          continue;
        }
        final keywordsRaw = json['keywords'];
        final keywords = keywordsRaw is List
            ? keywordsRaw
                  .map((dynamic item) => item.toString())
                  .where((String item) => item.trim().isNotEmpty)
                  .toList(growable: false)
            : <String>[domain];
        records.add(
          NovaJsonCorpusRecord(
            id:
                (json['id'] ??
                        json['i'] ??
                        '$domain-${records.length.toString().padLeft(5, '0')}')
                    .toString(),
            domain: (json['domain'] ?? json['d'] ?? domain).toString(),
            title:
                (json['title'] ??
                        json['t'] ??
                        '$domain satır ${records.length + 1}')
                    .toString(),
            sourceFile:
                (json['source_file'] ?? json['s'] ?? file.uri.pathSegments.last)
                    .toString(),
            recordType: (json['record_type'] ?? json['r'] ?? 'line').toString(),
            text: text,
            lineCount:
                int.tryParse(
                  (json['line_count'] ?? json['l'] ?? _countLines(text))
                      .toString(),
                ) ??
                1,
            keywords: keywords,
            dedupHash: (json['dedup_hash'] ?? json['h'] ?? '').toString(),
          ),
        );
      } catch (_) {
        // Malformed satırları atla.
      }
    }
    return records;
  }

  String buildJsonl(String domain) {
    final file = _resolveDomainFile(domain);
    if (file != null && file.existsSync()) {
      final text = file.readAsStringSync(encoding: utf8);
      return text.endsWith('\n') ? text : '$text\n';
    }
    final buffer = StringBuffer();
    for (final record in buildRecords(domain)) {
      buffer.writeln(jsonEncode(record.toJson()));
    }
    return buffer.toString();
  }

  List<NovaJsonCorpusDomainSummary> buildSummaries() {
    final manifest = _resolveManifestFile();
    if (manifest != null && manifest.existsSync()) {
      try {
        final data = jsonDecode(manifest.readAsStringSync(encoding: utf8));
        final files = data is Map<String, dynamic> ? data['files'] : null;
        if (files is List) {
          return files
              .whereType<Map<String, dynamic>>()
              .map(
                (Map<String, dynamic> item) => NovaJsonCorpusDomainSummary(
                  domain: (item['domain'] ?? '').toString(),
                  sourceFile: (item['output_file'] ?? '').toString(),
                  recordCount:
                      int.tryParse((item['records'] ?? 0).toString()) ?? 0,
                  isJsonMirrored: true,
                ),
              )
              .where(
                (NovaJsonCorpusDomainSummary item) =>
                    item.domain.trim().isNotEmpty,
              )
              .toList(growable: false);
        }
      } catch (_) {
        // Directory scan fallback.
      }
    }

    final root = _resolveCorpusRoot();
    if (root == null || !root.existsSync()) {
      return const <NovaJsonCorpusDomainSummary>[];
    }
    final out = <NovaJsonCorpusDomainSummary>[];
    for (final entity in root.listSync()) {
      if (entity is! File || !entity.path.endsWith('.jsonl')) {
        continue;
      }
      final domain = entity.uri.pathSegments.last.replaceAll('.jsonl', '');
      final count = entity
          .readAsLinesSync(encoding: utf8)
          .where((String line) => line.trim().isNotEmpty)
          .length;
      out.add(
        NovaJsonCorpusDomainSummary(
          domain: domain,
          sourceFile: entity.uri.pathSegments.last,
          recordCount: count,
          isJsonMirrored: true,
        ),
      );
    }
    out.sort((a, b) => a.domain.compareTo(b.domain));
    return out;
  }

  bool hasExactDomainFile(String domain) {
    final root = _resolveCorpusRoot();
    if (root == null) {
      return false;
    }
    final exact = File('${root.path}${Platform.pathSeparator}$domain.jsonl');
    return exact.existsSync();
  }

  String? resolveDomainFilePath(String domain) {
    final file = _resolveDomainFile(domain);
    return file?.path;
  }

  Map<String, dynamic> buildRuntimeDebugState(String domain) {
    final root = _resolveCorpusRoot();
    final exact = hasExactDomainFile(domain);
    final resolvedAlias = _domainFileAliases[domain] ?? domain;
    final resolvedPath = resolveDomainFilePath(domain) ?? '';
    return <String, dynamic>{
      'domain': domain,
      'configuredInstalledRoot': configuredInstalledRoot() ?? '',
      'resolvedRoot': root?.path ?? '',
      'hasExactDomainFile': exact,
      'aliasTarget': resolvedAlias,
      'resolvedPath': resolvedPath,
      'usedAliasFallback': !exact && resolvedPath.isNotEmpty,
    };
  }

  Directory? _resolveCorpusRoot() {
    final configured = configuredInstalledRoot();
    if (configured != null) {
      final configuredDir = Directory(configured);
      if (configuredDir.existsSync()) {
        return configuredDir;
      }
    }

    final cwd = Directory.current;
    final dirNames = <String>['offline_corpus_json', 'offline_corpus_jsonl'];
    final candidates = <Directory>[];
    for (final dirName in dirNames) {
      candidates.addAll(<Directory>[
        Directory(dirName),
        Directory('${cwd.path}${Platform.pathSeparator}$dirName'),
        Directory(
          '${cwd.path}${Platform.pathSeparator}assets${Platform.pathSeparator}$dirName',
        ),
        Directory(
          '${cwd.path}${Platform.pathSeparator}..${Platform.pathSeparator}$dirName',
        ),
        Directory(
          '${cwd.path}${Platform.pathSeparator}..${Platform.pathSeparator}..${Platform.pathSeparator}$dirName',
        ),
        Directory(
          '${cwd.path}${Platform.pathSeparator}..${Platform.pathSeparator}..${Platform.pathSeparator}..${Platform.pathSeparator}$dirName',
        ),
      ]);
    }
    for (final dir in candidates) {
      if (dir.existsSync()) {
        return dir;
      }
    }
    return null;
  }

  File? _resolveDomainFile(String domain) {
    final root = _resolveCorpusRoot();
    if (root == null) {
      return null;
    }
    final exact = File('${root.path}${Platform.pathSeparator}$domain.jsonl');
    if (exact.existsSync()) {
      return exact;
    }
    final resolvedDomain = _domainFileAliases[domain] ?? domain;
    final candidate = File(
      '${root.path}${Platform.pathSeparator}$resolvedDomain.jsonl',
    );
    return candidate.existsSync() ? candidate : null;
  }

  File? _resolveManifestFile() {
    final root = _resolveCorpusRoot();
    if (root == null) {
      return null;
    }
    final candidate = File(
      '${root.path}${Platform.pathSeparator}manifest.json',
    );
    return candidate.existsSync() ? candidate : null;
  }

  int _countLines(String text) => '\n'.allMatches(text).length + 1;
}
