// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../call_notes/call_note_service.dart';
import '../conversation/nova_conversation_session_service.dart';
import '../memory/memory_service.dart';

class NovaStorageCleanupResult {
  final String message;
  const NovaStorageCleanupResult(this.message);
}

class NovaStorageCleanupService {
  final CallNoteService callNoteService;
  final MemoryService memoryService;
  final NovaConversationSessionService conversationSessionService;

  const NovaStorageCleanupService({
    required this.callNoteService,
    required this.memoryService,
    required this.conversationSessionService,
  });

  Future<NovaStorageCleanupResult> runManualCleanup() async {
    final removedNotes = await callNoteService.cleanupExpired();
    final removedConversation = await conversationSessionService
        .cleanupManual();
    final memories = await memoryService.getAll();

    final storage = await inspectStorage();
    final removedTempBytes = await _cleanupTemporaryDirectory();
    final afterStorage = await inspectStorage();

    return NovaStorageCleanupResult(
      'Genel temizlik tamamlandı efendim. '
      'Çağrı notu temizliği: $removedNotes. '
      'Geçici konuşma temizliği: $removedConversation. '
      'Aktif hafıza kaydı: ${memories.length}. '
      'Geçici cache temizliği: ${_formatBytes(removedTempBytes)}. '
      'Uygulama veri analizi: ${storage.summary}. '
      'Temizlik sonrası: ${afterStorage.summary}.',
    );
  }

  Future<NovaStorageInspection> inspectStorage() async {
    final supportDir = await getApplicationSupportDirectory();
    final documentsDir = await getApplicationDocumentsDirectory();
    final temporaryDir = await getTemporaryDirectory();

    final support = _directorySizeSafe(supportDir);
    final documents = _directorySizeSafe(documentsDir);
    final temporary = _directorySizeSafe(temporaryDir);

    final known = <String, int>{
      'offline_corpus_json': _directorySizeSafe(
        Directory(
          '${supportDir.path}${Platform.pathSeparator}offline_corpus_json',
        ),
      ),
      'nova_models': _directorySizeSafe(
        Directory('${supportDir.path}${Platform.pathSeparator}nova_models'),
      ),
      'nova_tts_assets': _directorySizeSafe(
        Directory('${supportDir.path}${Platform.pathSeparator}nova_tts_assets'),
      ),
      'nova_speaker_models': _directorySizeSafe(
        Directory(
          '${supportDir.path}${Platform.pathSeparator}nova_speaker_models',
        ),
      ),
      'gemma-4-E2B-it.litertlm': _fileSizeSafe(
        File(
          '${supportDir.path}${Platform.pathSeparator}gemma-4-E2B-it.litertlm',
        ),
      ),
      'additional_valid_litertlm_files': _nonPrimaryLitertlmBytes(
        supportDir,
        primaryName: 'gemma-4-E2B-it.litertlm',
      ),
    };

    final totalKnown = known.values.fold<int>(0, (sum, value) => sum + value);

    return NovaStorageInspection(
      supportBytes: support,
      documentsBytes: documents,
      temporaryBytes: temporary,
      knownBytes: known,
      knownTotalBytes: totalKnown,
    );
  }

  Future<int> _cleanupTemporaryDirectory() async {
    try {
      final temp = await getTemporaryDirectory();
      if (!temp.existsSync()) return 0;

      int removed = 0;
      final now = DateTime.now();
      for (final entity in temp.listSync(
        recursive: false,
        followLinks: false,
      )) {
        try {
          final stat = entity.statSync();
          final age = now.difference(stat.modified);
          if (age.inHours < 12) continue;
          final size = _entitySizeSafe(entity);
          if (entity is Directory) {
            entity.deleteSync(recursive: true);
          } else {
            entity.deleteSync();
          }
          removed += size;
        } catch (_) {}
      }
      return removed;
    } catch (_) {
      return 0;
    }
  }

  int _nonPrimaryLitertlmBytes(Directory dir, {required String primaryName}) {
    try {
      if (!dir.existsSync()) return 0;
      int total = 0;
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.isEmpty
            ? entity.path.split(Platform.pathSeparator).last
            : entity.uri.pathSegments.last;
        if (!name.toLowerCase().endsWith('.litertlm')) continue;
        if (name == primaryName) continue;
        total += _fileSizeSafe(entity);
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  int _directorySizeSafe(Directory dir) {
    try {
      if (!dir.existsSync()) return 0;
      int total = 0;
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += _fileSizeSafe(entity);
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  int _entitySizeSafe(FileSystemEntity entity) {
    try {
      if (entity is File) return entity.lengthSync();
      if (entity is Directory) return _directorySizeSafe(entity);
      return 0;
    } catch (_) {
      return 0;
    }
  }

  int _fileSizeSafe(File file) {
    try {
      if (!file.existsSync()) return 0;
      return file.lengthSync();
    } catch (_) {
      return 0;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = <String>['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(value >= 10 || unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }
}

class NovaStorageInspection {
  final int supportBytes;
  final int documentsBytes;
  final int temporaryBytes;
  final Map<String, int> knownBytes;
  final int knownTotalBytes;

  const NovaStorageInspection({
    required this.supportBytes,
    required this.documentsBytes,
    required this.temporaryBytes,
    required this.knownBytes,
    required this.knownTotalBytes,
  });

  String get summary {
    final formattedKnown = knownBytes.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${entry.key}=${_formatStatic(entry.value)}')
        .join(', ');
    return 'support=${_formatStatic(supportBytes)}, '
        'documents=${_formatStatic(documentsBytes)}, '
        'temp=${_formatStatic(temporaryBytes)}, '
        'bilinen büyük kalemler=${formattedKnown.isEmpty ? 'yok' : formattedKnown}.';
  }

  static String _formatStatic(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = <String>['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(value >= 10 || unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }
}
