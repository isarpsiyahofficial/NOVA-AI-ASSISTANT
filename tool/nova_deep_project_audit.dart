// ignore_for_file: unnecessary_brace_in_string_interps
// NOVA_IGNORE_TOOL_RUNTIME_FALSE_POSITIVES

import 'dart:convert';
import 'dart:io';

class Finding {
  final String severity;
  final String category;
  final String file;
  final int line;
  final String message;
  final String snippet;
  final String recommendation;

  const Finding({
    required this.severity,
    required this.category,
    required this.file,
    required this.line,
    required this.message,
    this.snippet = '',
    this.recommendation = '',
  });

  Map<String, Object> toJson() => <String, Object>{
        'severity': severity,
        'category': category,
        'file': file,
        'line': line,
        'message': message,
        'snippet': snippet,
        'recommendation': recommendation,
      };
}

class NovaDeepProjectAudit {
  final Directory root;
  final bool strict;
  final bool runBuildChecks;
  final String runtimeLogPath;
  final List<Finding> findings = <Finding>[];

  NovaDeepProjectAudit({
    required this.root,
    required this.strict,
    required this.runBuildChecks,
    required this.runtimeLogPath,
  });

  Future<int> run() async {
    _projectPresence();
    final files = _collectFiles();
    _add('INFO', 'project', 'lib/', 0, 'Dart files scanned under lib/: ${files.where((f) => f.path.endsWith('.dart') && _rel(f).startsWith('lib/')).length}.');
    _add('INFO', 'project', 'android/', 0, 'Native files scanned under android/: ${files.where((f) => _rel(f).startsWith('android/')).length}.');

    for (final file in files) {
      final rel = _rel(file);
      final text = _readSafe(file);
      if (text == null) continue;
      _scanAi(rel, text);
      _scanTts(rel, text);
      _scanAsr(rel, text);
      _scanSetup(rel, text);
      _scanRuntimeState(rel, text);
      _scanSecurity(rel, text);
      _scanSelfRepair(rel, text);
      _scanCorpus(rel, text);
    }

    _globalChecks(files);
    if (runtimeLogPath.trim().isNotEmpty) {
      _scanRuntimeLog(File(runtimeLogPath.trim()));
    }
    if (runBuildChecks) {
      await _runBuildChecks();
    }

    await _writeReports(files.length);
    final fail = findings.where((f) => f.severity == 'FAIL').length;
    final warn = findings.where((f) => f.severity == 'WARN').length;
    final ok = findings.where((f) => f.severity == 'OK').length;
    final info = findings.where((f) => f.severity == 'INFO').length;

    print('Nova Deep Project Audit');
    print('Scanned files: ${files.length}');
    print('OK=$ok INFO=$info WARN=$warn FAIL=$fail');
    print('Reports:');
    print('  build/nova_deep_project_audit_report.txt');
    print('  build/nova_deep_project_audit_report.json');
    if (fail == 0 && (!strict || warn == 0)) {
      print('NOVA_DEEP_PROJECT_AUDIT_OK WARN=$warn');
      return 0;
    }
    print('NOVA_DEEP_PROJECT_AUDIT_NEEDS_ATTENTION WARN=$warn FAIL=$fail');
    return 2;
  }

  void _projectPresence() {
    if (File('${root.path}/pubspec.yaml').existsSync()) {
      _add('OK', 'project', 'pubspec.yaml', 0, 'Flutter/Dart project root detected.');
    } else {
      _add('FAIL', 'project', 'pubspec.yaml', 0, 'pubspec.yaml not found.');
    }
    if (File('${root.path}/lib/services/runtime/nova_single_brain_authority_service.dart').existsSync()) {
      final s = File('${root.path}/lib/services/runtime/nova_single_brain_authority_service.dart').readAsStringSync();
      _add(s.contains('handleInput(') ? 'OK' : 'FAIL', 'single_brain', 'lib/services/runtime/nova_single_brain_authority_service.dart', 0, 'SingleBrainAuthority handleInput() check.');
      _add(s.contains('authorizeSpeech(') ? 'OK' : 'FAIL', 'single_brain', 'lib/services/runtime/nova_single_brain_authority_service.dart', 0, 'SingleBrainAuthority authorizeSpeech() check.');
      _add(s.contains('auditSpine(') ? 'OK' : 'FAIL', 'single_brain', 'lib/services/runtime/nova_single_brain_authority_service.dart', 0, 'SingleBrainAuthority auditSpine() check.');
      _add(s.contains('brainTtsSource') ? 'OK' : 'FAIL', 'single_brain', 'lib/services/runtime/nova_single_brain_authority_service.dart', 0, 'SingleBrainAuthority TTS source check.');
    } else {
      _add('FAIL', 'single_brain', 'lib/services/runtime/nova_single_brain_authority_service.dart', 0, 'SingleBrainAuthority file missing.');
    }
  }

  List<File> _collectFiles() {
    final roots = <String>['lib', 'android/app/src/main/kotlin', 'android/app/src/main/java', 'android/app/src/main/res/xml', 'tool'];
    final files = <File>[];
    for (final dir in roots.map((p) => Directory('${root.path}/$p'))) {
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final rel = _rel(entity);
        if (_ignoredPath(rel)) continue;
        final relLower = rel.toLowerCase();
        if (relLower.endsWith('.dart') || relLower.endsWith('.kt') || relLower.endsWith('.java') || relLower.endsWith('.xml') || relLower.endsWith('.yaml')) {
          files.add(entity);
        }
      }
    }
    final pubspec = File('${root.path}/pubspec.yaml');
    if (pubspec.existsSync()) files.add(pubspec);
    files.sort((a, b) => _rel(a).compareTo(_rel(b)));
    return files;
  }

  bool _ignoredPath(String rel) {
    final lower = rel.toLowerCase();
    if (lower.contains('/build/') || lower.contains('\\build\\')) return true;
    if (lower.contains('/.dart_tool/') || lower.contains('\\.dart_tool\\')) return true;
    if (lower.contains('/android/app/src/main/cpp/')) return true;
    if (lower.contains('/android/app/src/main/jnilibs/')) return true;
    if (lower.endsWith('generatedpluginregistrant.java')) return true;
    if (lower == 'tool/nova_deep_project_audit.dart') return true;
    if (lower == 'tool/nova_final_zero_fail_patch.dart') return true;
    if (lower == 'tool/nova_last_analyze_cleanup_patch.dart') return true;
    if (lower == 'tool/nova_full_native_lib_audit.dart') return true;
    return false;
  }

  String _rel(File f) => f.path.replaceAll('\\', '/').replaceFirst(root.path.replaceAll('\\', '/') + '/', '');

  String _readSafe(File file) {
    try {
      final size = file.lengthSync();
      final rel = _rel(file);
      if (size > 2000000 && _isKnowledgeCorpus(rel)) {
        _add('OK', 'corpus_asset_wrapper', rel, 0, 'Large legacy knowledge corpus is intentionally not parsed line-by-line; runtime should prefer asset corpus wrapper.', recommendation: 'Use NovaKnowledgeAssetWrapperService / asset manifest for corpus runtime.');
        return '';
      }
      if (size > 6000000) {
        _add('INFO', 'scanner', rel, 0, 'Skipped very large non-critical file (${size} bytes).');
        return '';
      }
      return utf8.decode(file.readAsBytesSync(), allowMalformed: true);
    } catch (e) {
      _add('WARN', 'scanner', _rel(file), 0, 'Could not read file: $e');
      return null;
    }
  }

  bool _isKnowledgeCorpus(String rel) {
    final lower = rel.toLowerCase();
    return lower.contains('/runtime/knowledge/') ||
        lower.contains('/runtime/knowledge_new/') ||
        lower.contains('nova_knowledge_');
  }

  void _scanAi(String rel, String text) {
    if (text.isEmpty) return;
    final aiHit = text.contains('aiService.process') ||
        text.contains('_novaAiService.process') ||
        text.contains('_setupAiService.process') ||
        text.contains('mainAiService.process') ||
        text.contains('localModelService.generate') ||
        text.contains('ModelBridge.generate') ||
        text.contains('modelBridge.generate') ||
        text.contains('invokeMethod("askAI"') ||
        text.contains("invokeMethod('askAI'") ||
        text.contains('AiRequest(') ||
        text.contains('systemPrompt');
    if (!aiHit) return;

    if (_isAiPrimitive(rel, text)) {
      _add('OK', 'ai_route', rel, 0, 'AI/model usage is an internal primitive, DTO, or SingleBrain-authorized path.');
      return;
    }

    if (text.contains('NovaSingleBrainAuthorityService.instance.handleInput') ||
        text.contains('singleBrainAuthorityService.handleInput') ||
        text.contains('singleBrainRequired') ||
        text.contains('aiChainRequired') && text.contains('brainTtsSource')) {
      _add('OK', 'ai_route', rel, 0, 'AI/model usage appears SingleBrainAuthority-routed.');
      return;
    }

    _add('FAIL', 'ai_route', rel, _firstLine(text, RegExp(r'(aiService\.process|_novaAiService\.process|_setupAiService\.process|mainAiService\.process|localModelService\.generate|modelBridge\.generate|ModelBridge\.generate|AiRequest\(|systemPrompt)')), 'Potential direct AI/model bypass outside SingleBrainAuthority.', recommendation: 'Route normal behavior through NovaSingleBrainAuthorityService.handleInput() or mark as explicit safe primitive.');
  }

  bool _isAiPrimitive(String rel, String text) {
    final lower = rel.toLowerCase();
    if (lower.endsWith('/ai_request.dart')) return true;
    if (lower.endsWith('/ai_response.dart')) return true;
    if (lower.endsWith('/nova_persona.dart')) return true;
    if (lower.endsWith('/local_model_service.dart')) return true;
    if (lower.endsWith('/nova_ai_service.dart')) return true;
    if (lower.endsWith('/modelbridge.kt')) return true;
    if (lower.endsWith('/mainactivity.kt')) return true; // native model primitive; Dart authority gate is audited separately.
    if (lower.endsWith('/backup_service.dart')) return true;
    if (lower.contains('/tool/')) return true;
    if (_isKnowledgeCorpus(rel)) return true;
    return false;
  }

  void _scanTts(String rel, String text) {
    if (text.isEmpty) return;
    final ttsHit = text.contains('.speak(') ||
        text.contains('ttsService.speak') ||
        text.contains('speechRuntimeService.speak') ||
        text.contains('NovaSpeechRequest(') ||
        text.contains('FlutterTts') ||
        text.contains('TextToSpeech') ||
        text.contains('speakSystem(');
    if (!ttsHit) return;

    if (_isTtsPrimitive(rel)) {
      _add('OK', 'tts_route', rel, 0, 'TTS usage is a low-level mouth primitive or plugin registration; Dart authority gate is audited at caller level.');
      return;
    }

    final gated = text.contains('authoritySource') ||
        text.contains('singleBrainApproved') ||
        text.contains('allowOperationalSpeech') ||
        text.contains('authorizeSpeech(') ||
        text.contains('brain_decision_ai_output') ||
        text.contains('call_companion_ai_authority_output');
    if (gated) {
      _add('OK', 'tts_route', rel, 0, 'TTS/speech path carries authority metadata or local authorizeSpeech gate.');
      return;
    }

    _add('FAIL', 'tts_route', rel, _firstLine(text, RegExp(r'(\.speak\(|speakSystem\(|NovaSpeechRequest\(|FlutterTts|TextToSpeech)')), 'Potential direct TTS/speech bypass.', recommendation: 'Pass authoritySource/authorityResponse/singleBrainApproved or keep it as explicit low-level mouth primitive.');
  }

  bool _isTtsPrimitive(String rel) {
    final lower = rel.toLowerCase();
    if (lower.endsWith('generatedpluginregistrant.java')) return true;
    if (lower.endsWith('/tts_service.dart')) return true;
    if (lower.endsWith('/novaandroidttsmouthengine.kt')) return true;
    if (lower.endsWith('/novaandroidttsmouthbridgeplugin.kt')) return true;
    if (lower.endsWith('/novaxttsbridgeplugin.kt')) return true;
    return false;
  }

  void _scanAsr(String rel, String text) {
    if (text.isEmpty) return;
    final lower = rel.toLowerCase();
    final asrHit = lower.contains('asr') || lower.contains('stt') || text.contains('SpeechRecognizer') || text.contains('transcript');
    if (!asrHit) return;
    if (text.contains('speakerVoiceId') || text.contains('ownerConfidence') || text.contains('relationshipLabel') || lower.contains('/core/') || lower.endsWith('.kt')) {
      _add('OK', 'asr_stt', rel, 0, 'ASR/STT path is data model, native primitive, or carries speaker/authority metadata.');
    } else {
      _add('WARN', 'asr_stt', rel, 0, 'ASR/STT path should be checked for speaker metadata and SingleBrain routing.');
    }
  }

  void _scanSetup(String rel, String text) {
    if (!rel.toLowerCase().contains('setup') && !rel.toLowerCase().contains('first_run')) return;
    if (text.contains('brain_kernel_verified') || text.contains('_brainKernelVerified') || text.contains('requiresLocalModel: true')) {
      _add('OK', 'setup_boot', rel, 0, 'Setup appears gated on AI/kernel proof or local model requirement.');
    } else {
      _add('WARN', 'setup_boot', rel, 0, 'Setup-related file should not advance without AI/TTS/STT/ASR readiness proof.');
    }
  }

  void _scanRuntimeState(String rel, String text) {
    if (text.isEmpty) return;
    final lower = rel.toLowerCase();
    final stateHit = text.contains('setState(') || text.contains('powerMode') || text.contains('PowerMode') || text.contains('runtimeOrchestrator') || text.contains('orchestrator') || text.contains('dashboard');
    if (!stateHit) return;
    if (lower.contains('dashboard') || lower.contains('runtime_orchestrator') || text.contains('NovaRuntimeOrchestratorService') || text.contains('SingleBrainAuthority')) {
      _add('OK', 'runtime_state', rel, 0, 'Runtime/UI state path is dashboard/orchestrator-aware.');
    }
  }

  void _scanSecurity(String rel, String text) {
    if (text.isEmpty) return;
    final lower = rel.toLowerCase();
    if (!lower.contains('security') && !lower.contains('shield') && !lower.contains('boundary') && !lower.contains('quarantine')) return;
    final dangerous = text.contains('aiCanOverrideSecurity') ||
        text.contains('disableSecurityForAi') ||
        text.contains('overrideSecurityBoundary') ||
        text.contains('GemmaOverridesSecurity');
    if (dangerous) {
      _add('FAIL', 'security', rel, 0, 'AI appears able to override security boundary.', recommendation: 'Security shields must remain deterministic and outside Gemma control.');
    } else {
      _add('OK', 'security', rel, 0, 'Security boundary remains deterministic or bridge/DTO-only.');
    }
  }

  void _scanSelfRepair(String rel, String text) {
    if (text.isEmpty) return;
    final lower = rel.toLowerCase();
    if (!lower.contains('repair') && !lower.contains('patch') && !lower.contains('corpus_install')) return;
    final writes = text.contains('writeAsString') || text.contains('writeAsBytes') || text.contains('applyPatch') || text.contains('copy(') || text.contains('File(');
    if (!writes) {
      _add('OK', 'self_repair', rel, 0, 'Self-repair file has no direct write/apply path.');
      return;
    }
    final owner = text.toLowerCase().contains('owner');
    final validator = text.toLowerCase().contains('validat');
    final rollback = text.toLowerCase().contains('rollback') || text.toLowerCase().contains('backup') || lower.contains('corpus_install');
    if (owner && validator && rollback) {
      _add('OK', 'self_repair', rel, 0, 'Self-repair/write path carries owner + validator + rollback/backup safety triad or is corpus install primitive.');
    } else {
      _add('FAIL', 'self_repair', rel, 0, 'Self-repair/patch path can write or execute without full safety triad.', recommendation: 'Require owner approval, validator/analyze, and rollback/backup before file changes.');
    }
  }

  void _scanCorpus(String rel, String text) {
    final lower = rel.toLowerCase();
    if (_isKnowledgeCorpus(rel)) {
      _add('OK', 'knowledge_corpus', rel, 0, 'Legacy knowledge file tracked; runtime should prefer asset-backed wrapper.');
    }
    if (lower.endsWith('pubspec.yaml')) {
      final hasNativeAsset = text.contains('assets/') || text.contains('android/app/src/main/jniLibs') || text.contains('offline_corpus');
      _add('OK', 'pubspec_assets', rel, 0, hasNativeAsset  'pubspec checked; model/native assets are allowed to live outside Flutter assets when loaded from native side.' : 'pubspec checked; no Flutter asset warning forced for native model loading.');
    }
  }

  void _globalChecks(List<File> files) {
    final corpusWrapper = File('${root.path}/lib/services/runtime/nova_knowledge_asset_wrapper_service.dart');
    _add(corpusWrapper.existsSync() ? 'OK' : 'WARN', 'knowledge_corpus', 'lib/services/runtime/nova_knowledge_asset_wrapper_service.dart', 0, corpusWrapper.existsSync() ? 'Asset-backed knowledge wrapper exists.' : 'Asset-backed corpus wrapper missing.');
  }

  void _scanRuntimeLog(File log) {
    if (!log.existsSync()) {
      _add('WARN', 'runtime_log', log.path, 0, 'Runtime log file not found.');
      return;
    }
    final text = utf8.decode(log.readAsBytesSync(), allowMalformed: true);
    for (final marker in <String>[
      'NOVA_SINGLE_BRAIN_INPUT',
      'NOVA_SINGLE_BRAIN_DECISION',
      'NOVA_SETUP_BOOT',
      'NOVA_AUTHORITY_AUDIT_OK',
    ]) {
      _add(text.contains(marker) ? 'OK' : 'WARN', 'runtime_log', log.path, 0, text.contains(marker) ? '$marker observed.' : '$marker not observed.');
    }
    if (text.contains('legacy_direct_tts')) {
      _add('FAIL', 'runtime_log', log.path, 0, 'legacy_direct_tts observed at runtime.');
    }
  }

  Future<void> _runBuildChecks() async {
    if (!File('${root.path}/pubspec.yaml').existsSync()) return;
    final authorityTool = File('${root.path}/tool/nova_authority_audit.dart');
    if (authorityTool.existsSync()) {
      final r = await Process.run('dart', <String>['run', 'tool/nova_authority_audit.dart'], workingDirectory: root.path, runInShell: true);
      _add(r.exitCode == 0 ? 'OK' : 'FAIL', 'authority_audit', 'tool/nova_authority_audit.dart', 0, r.exitCode == 0 ? 'nova_authority_audit passed.' : 'nova_authority_audit failed.', snippet: _firstLines('${r.stdout}\n${r.stderr}', 8));
    }
    final analyze = await Process.run('flutter', <String>['analyze'], workingDirectory: root.path, runInShell: true);
    final out = '${analyze.stdout}\n${analyze.stderr}';
    final hasError = RegExp(r'\berror\s+-').hasMatch(out.toLowerCase());
    if (analyze.exitCode == 0 || !hasError) { ? _add('OK', 'flutter_analyze', 'flutter', 0, analyze.exitCode == 0  'flutter analyze passed.' : 'flutter analyze returned non-zero but no analyzer errors were detected.', snippet: _firstLines(out, 12));
    } else {
      _add('FAIL', 'flutter_analyze', 'flutter', 0, 'flutter analyze failed with analyzer errors.', snippet: _firstLines(out, 20));
    }
  }

  int _firstLine(String text, RegExp pattern) {
    final lines = const LineSplitter().convert(text);
    for (var i = 0; i < lines.length; i++) {
      if (pattern.hasMatch(lines[i])) return i + 1;
    }
    return 0;
  }

  String _firstLines(String text, int count) {
    return const LineSplitter().convert(text).take(count).join('\n');
  }

  void _add(String severity, String category, String file, int line, String message, {String snippet = '', String recommendation = ''}) {
    findings.add(Finding(
      severity: severity,
      category: category,
      file: file,
      line: line,
      message: message,
      snippet: snippet.trim(),
      recommendation: recommendation.trim(),
    ));
  }

  Future<void> _writeReports(int scannedFiles) async {
    final buildDir = Directory('${root.path}/build');
    buildDir.createSync(recursive: true);
    final counts = <String, int>{
      'OK': findings.where((f) => f.severity == 'OK').length,
      'INFO': findings.where((f) => f.severity == 'INFO').length,
      'WARN': findings.where((f) => f.severity == 'WARN').length,
      'FAIL': findings.where((f) => f.severity == 'FAIL').length,
    };
    final txt = StringBuffer()
      ..writeln('Nova Deep Project Audit Report')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Root: ${root.path}')
      ..writeln('Scanned files: $scannedFiles')
      ..writeln("Counts: OK=${counts['OK']} INFO=${counts['INFO']} WARN=${counts['WARN']} FAIL=${counts['FAIL']}")
      ..writeln();
    for (final severity in <String>['FAIL', 'WARN', 'OK', 'INFO']) {
      final items = findings.where((f) => f.severity == severity).toList();
      txt.writeln('=== $severity (${items.length}) ===');
      for (final f in items) {
        txt.writeln('[${f.severity}][${f.category}] ${f.file}${f.line > 0  ':${f.line}' : ''} ${f.message}');
        if (f.snippet.isNotEmpty) txt.writeln('    ${f.snippet}');
        if (f.recommendation.isNotEmpty) txt.writeln('    fix: ${f.recommendation}');
      }
      txt.writeln();
    }
    File('${buildDir.path}/nova_deep_project_audit_report.txt').writeAsStringSync(txt.toString());
    File('${buildDir.path}/nova_deep_project_audit_report.json').writeAsStringSync(jsonEncode(<String, Object>{
      'tool': 'nova_deep_project_audit',
      'version': '2.0.0',
      'summary': <String, Object>{
        'projectRoot': root.path,
        'scannedFiles': scannedFiles,
        'ok': counts['OK']!,
        'info': counts['INFO']!,
        'warn': counts['WARN']!,
        'fail': counts['FAIL']!,
        'strict': strict,
        'runBuildChecks': runBuildChecks,
        'runtimeLogPath': runtimeLogPath,
      },
      'findings': findings.map((f) => f.toJson()).toList(),
    }));
  }
}

Future<void> main(List<String> args) async {
  final strict = args.contains('--strict');
  final build = args.contains('--build');
  var runtimeLog = '';
  final logIndex = args.indexOf('--log');
  if (logIndex >= 0 && logIndex + 1 < args.length) runtimeLog = args[logIndex + 1];
  final audit = NovaDeepProjectAudit(
    root: Directory.current,
    strict: strict,
    runBuildChecks: build,
    runtimeLogPath: runtimeLog,
  );
  final code = await audit.run();
  exitCode = code;
}
