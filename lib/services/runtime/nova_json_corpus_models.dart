// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaJsonCorpusRecord {
  final String id;
  final String domain;
  final String title;
  final String sourceFile;
  final String recordType;
  final String text;
  final int lineCount;
  final List<String> keywords;
  final String dedupHash;

  const NovaJsonCorpusRecord({
    required this.id,
    required this.domain,
    required this.title,
    required this.sourceFile,
    required this.recordType,
    required this.text,
    required this.lineCount,
    required this.keywords,
    required this.dedupHash,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'domain': domain,
    'title': title,
    'source_file': sourceFile,
    'record_type': recordType,
    'text': text,
    'line_count': lineCount,
    'keywords': keywords,
    'dedup_hash': dedupHash,
  };
}

class NovaJsonCorpusDomainSummary {
  final String domain;
  final String sourceFile;
  final int recordCount;
  final bool isJsonMirrored;

  const NovaJsonCorpusDomainSummary({
    required this.domain,
    required this.sourceFile,
    required this.recordCount,
    required this.isJsonMirrored,
  });
}
