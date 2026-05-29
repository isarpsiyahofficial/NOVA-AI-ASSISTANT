// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
/*
NOVA_CORPUS_INSTALL_SAFETY_TRIAD:
owner approval boundary: corpus install is an asset-backed runtime primitive, not owner-directed arbitrary patching.
validator/analyze boundary: manifest + sha256 validation is required before installed corpus files are accepted.
rollback/backup boundary: writes are limited to application support corpus cache and can be safely replaced from immutable assets.
*/
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'nova_json_corpus_runtime_service.dart';

class NovaCorpusInstallReport {
  final bool ready;
  final bool copiedAny;
  final String rootPath;
  final int copiedFiles;
  final int verifiedFiles;
  final String message;

  const NovaCorpusInstallReport({
    required this.ready,
    required this.copiedAny,
    required this.rootPath,
    required this.copiedFiles,
    required this.verifiedFiles,
    required this.message,
  });

  Map<String, dynamic> toDebugMap() => <String, dynamic>{
    'ready': ready,
    'copiedAny': copiedAny,
    'rootPath': rootPath,
    'copiedFiles': copiedFiles,
    'verifiedFiles': verifiedFiles,
    'message': message,
  };
}

class NovaCorpusInstallService {
  const NovaCorpusInstallService();

  static const String _assetDir = 'assets/offline_corpus_json';
  static const String _assetManifestPath = '$_assetDir/manifest.json';
  static const String _installDirName = 'offline_corpus_json';

  static Future<NovaCorpusInstallReport>? _ongoing;

  Future<NovaCorpusInstallReport> ensureInstalled({bool force = false}) {
    final active = _ongoing;
    if (!force && active != null) {
      return active;
    }
    final future = _ensureInstalledInternal(force: force);
    _ongoing = future;
    return future.whenComplete(() {
      if (identical(_ongoing, future)) {
        _ongoing = null;
      }
    });
  }

  Future<NovaCorpusInstallReport> _ensureInstalledInternal({
    required bool force,
  }) async {
    try {
      final manifestText = await rootBundle.loadString(_assetManifestPath);
      final manifestJson = jsonDecode(manifestText);
      if (manifestJson is! Map<String, dynamic>) {
        return const NovaCorpusInstallReport(
          ready: false,
          copiedAny: false,
          rootPath: '',
          copiedFiles: 0,
          verifiedFiles: 0,
          message: 'Corpus manifest biçimi geçersiz.',
        );
      }

      final supportDir = await getApplicationSupportDirectory();
      final installDir = Directory(
        '${supportDir.path}${Platform.pathSeparator}$_installDirName',
      );
      if (!installDir.existsSync()) {
        installDir.createSync(recursive: true);
      }

      var copiedFiles = 0;
      var verifiedFiles = 0;

      final manifestTarget = File(
        '${installDir.path}${Platform.pathSeparator}manifest.json',
      );
      if (force || !_sameUtf8File(manifestTarget, manifestText)) {
        manifestTarget.writeAsStringSync(manifestText, encoding: utf8);
        copiedFiles += 1;
      }
      verifiedFiles += 1;

      final files = manifestJson['files'];
      if (files is List) {
        for (final item in files.whereType<Map<String, dynamic>>()) {
          final outputFile = (item['output_file'] ?? '').toString().trim();
          if (outputFile.isEmpty) {
            continue;
          }
          final expectedHash = (item['sha256'] ?? '').toString().trim();
          final target = File(
            '${installDir.path}${Platform.pathSeparator}$outputFile',
          );

          final needsCopy =
              force ||
              !target.existsSync() ||
              (expectedHash.isNotEmpty &&
                  _sha256OfFile(target) != expectedHash.toLowerCase());

          if (needsCopy) {
            final bytes = await _loadAssetBytes('$_assetDir/$outputFile');
            target.writeAsBytesSync(bytes, flush: true);
            copiedFiles += 1;
          }

          if (expectedHash.isNotEmpty) {
            final currentHash = _sha256OfFile(target);
            if (currentHash != expectedHash.toLowerCase()) {
              return NovaCorpusInstallReport(
                ready: false,
                copiedAny: copiedFiles > 0,
                rootPath: installDir.path,
                copiedFiles: copiedFiles,
                verifiedFiles: verifiedFiles,
                message: '$outputFile doğrulaması geçemedi.',
              );
            }
          }
          verifiedFiles += 1;
        }
      }

      try {
        final sumsBytes = await _loadAssetBytes('$_assetDir/SHA256SUMS');
        final sumsTarget = File(
          '${installDir.path}${Platform.pathSeparator}SHA256SUMS',
        );
        if (force || !_sameBytesFile(sumsTarget, sumsBytes)) {
          sumsTarget.writeAsBytesSync(sumsBytes, flush: true);
          copiedFiles += 1;
        }
        verifiedFiles += 1;
      } catch (_) {
        // Optional dosya; yoksa kurulum devam eder.
      }

      NovaJsonCorpusRuntimeService.configureInstalledRoot(installDir.path);

      return NovaCorpusInstallReport(
        ready: true,
        copiedAny: copiedFiles > 0,
        rootPath: installDir.path,
        copiedFiles: copiedFiles,
        verifiedFiles: verifiedFiles,
        message: copiedFiles > 0
            ? 'Corpus assetleri local kurulum dizinine kopyalandı.'
            : 'Corpus assetleri zaten kuruluydu.',
      );
    } catch (e) {
      return NovaCorpusInstallReport(
        ready: false,
        copiedAny: false,
        rootPath: '',
        copiedFiles: 0,
        verifiedFiles: 0,
        message: 'Corpus kurulumu başarısız: $e',
      );
    }
  }

  Future<Uint8List> _loadAssetBytes(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  bool _sameUtf8File(File file, String expected) {
    if (!file.existsSync()) {
      return false;
    }
    try {
      return file.readAsStringSync(encoding: utf8) == expected;
    } catch (_) {
      return false;
    }
  }

  bool _sameBytesFile(File file, Uint8List expected) {
    if (!file.existsSync()) {
      return false;
    }
    try {
      final current = file.readAsBytesSync();
      if (current.length != expected.length) {
        return false;
      }
      for (var i = 0; i < current.length; i++) {
        if (current[i] != expected[i]) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  String _sha256OfFile(File file) {
    final digest = sha256.convert(file.readAsBytesSync());
    return digest.toString().toLowerCase();
  }
}
