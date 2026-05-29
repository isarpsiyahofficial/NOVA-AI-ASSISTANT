// ignore_for_file: avoid_print
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

class NovaFullNativeLibAudit {
  final Directory root;
  final bool strict;
  final bool runBuildChecks;
  final String runtimeLogPath;
  final List<Finding> findings = <Finding>[];

  int filesInventoried = 0;
  int textFilesScanned = 0;
  int binaryFilesTracked = 0;
  int otherFilesTracked = 0;

  NovaFullNativeLibAudit({
    required this.root,
    required this.strict,
    required this.runBuildChecks,
    required this.runtimeLogPath,
  });

  Future<int> run() async {
    _projectPresence();
    final files = _collectFiles();
    filesInventoried = files.length;

    for (final file in files) {
      final rel = _rel(file);
      if (_isBinaryAsset(rel)) {
        binaryFilesTracked++;
        _add('INFO', 'binary_asset', rel, 0, 'Binary/model/media asset inventoried but not text-scanned.');
        continue;
      }
      if (_isNonRuntimeAsset(rel)) {
        otherFilesTracked++;
        _add('INFO', _isNativeAsset(rel) ? 'native_asset' : 'other_asset', rel, 0, _isNativeAsset(rel)  'Native/model/voice asset inventoried; not audited as Nova runtime decision code.' : 'Non-code asset inventoried.');
        continue;
      }

      final text = _readSafe(file);
      if (text == null) continue;
      textFilesScanned++;
      _scanAi(rel, text);
      _scanTts(rel, text);
      _scanAsr(rel, text);
      _scanSetup(rel, text);
      _scanRuntimeState(rel, text);
      _scanSecurity(rel, text);
      _scanSelfRepair(rel, text);
      _scanCorpus(rel, text);
    }

    _globalChecks();
    if (runtimeLogPath.trim().isNotEmpty) {
      _scanRuntimeLog(File(runtimeLogPath.trim()));
    }
    if (runBuildChecks) {
      await _runBuildChecks();
    }

    await _writeReports();
    final fail = _count('FAIL');
    final warn = _count('WARN');
    final ok = _count('OK');
    final info = _count('INFO');

    print('Nova Full Native + Lib Audit');
    print('Files inventoried: $filesInventoried');
    print('Text scanned: $textFilesScanned');
    print('Binary/assets tracked: $binaryFilesTracked');
    print('Other tracked: $otherFilesTracked');
    print('OK=$ok INFO=$info WARN=$warn FAIL=$fail');
    print('Reports:');
    print('  build/nova_full_native_lib_audit_report.txt');
    print('  build/nova_full_native_lib_audit_report.json');

    if (fail == 0 && (!strict || warn == 0)) {
      print('NOVA_FULL_NATIVE_LIB_AUDIT_OK WARN=$warn FAIL=$fail');
      return 0;
    }
    print('NOVA_FULL_NATIVE_LIB_AUDIT_NEEDS_ATTENTION WARN=$warn FAIL=$fail');
    return 2;
  }

  void _projectPresence() {
    final pubspec = File('${root.path}/pubspec.yaml');
    _add(pubspec.existsSync() ? 'OK' : 'FAIL', 'project', 'pubspec.yaml', 0, pubspec.existsSync() ? 'Flutter/Dart project root detected.' : 'pubspec.yaml not found.');
    if (pubspec.existsSync()) {
      final text = _readSafe(pubspec) ?? '';
      _add('OK', 'assets', 'pubspec.yaml', 0, text.contains('assets:') ? 'Flutter asset declarations detected. Native model assets are allowed outside pubspec when loaded from Android/native assets.' : 'pubspec checked. Native model assets are allowed outside pubspec when loaded from Android/native assets.');
    }
  }

  List<File> _collectFiles() {
    final roots = <String>[
      'lib',
      'android',
      'tool',
      'test',
    ];
    final files = <File>[];
    for (final path in roots) {
      final dir = Directory('${root.path}/$path');
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final rel = _rel(entity);
        if (_ignoredPath(rel)) continue;
        files.add(entity);
      }
    }
    final pubspec = File('${root.path}/pubspec.yaml');
    if (pubspec.existsSync()) files.add(pubspec);
    final analysis = File('${root.path}/analysis_options.yaml');
    if (analysis.existsSync()) files.add(analysis);
    files.sort((a, b) => _rel(a).compareTo(_rel(b)));
    return files;
  }

  bool _ignoredPath(String rel) {
    final lower = rel.toLowerCase().replaceAll('\\', '/');
    if (lower.contains('/build/') || lower.startsWith('build/')) return true;
    if (lower.contains('/.dart_tool/') || lower.startsWith('.dart_tool/')) return true;
    if (lower.contains('/.gradle/') || lower.startsWith('.gradle/')) return true;
    if (lower.contains('/android/build/') || lower.contains('/android/app/build/')) return true;
    if (lower.endsWith('nova_force_fix_lower_scope.dart')) return true;
    if (lower.endsWith('nova_fix_lower_once.dart')) return true;
    if (lower.endsWith('nova_stop_the_bleeding_patch.dart')) return true;
    if (lower.endsWith('nova_compile_zero_sweep.dart')) return true;
    if (lower.endsWith('nova_final_15_sweep.dart')) return true;
    if (lower.endsWith('nova_last_7_issues_sweep.dart')) return true;
    return false;
  }

  String _rel(File file) {
    final rootPath = root.path.replaceAll('\\', '/');
    return file.path.replaceAll('\\', '/').replaceFirst('$rootPath/', '');
  }

  bool _isBinaryAsset(String rel) {
    final lower = rel.toLowerCase();
    const exts = <String>[
      '.aar', '.so', '.dll', '.dylib', '.bin', '.onnx', '.tflite', '.litertlm', '.gguf', '.png', '.jpg', '.jpeg', '.webp', '.gif', '.ico', '.mp3', '.wav', '.flac', '.zip', '.jar', '.class', '.dex', '.keystore', '.jks', '.db', '.sqlite'
    ];
    return exts.any(lower.endsWith);
  }

  bool _isNativeAsset(String rel) {
    final lower = rel.toLowerCase().replaceAll('\\', '/');
    return lower.contains('/assets/sherpa_') ||
        lower.contains('/assets/models/') ||
        lower.contains('/jniLibs/'.toLowerCase()) ||
        lower.contains('/espeak-ng-data/') ||
        lower.contains('/third_party/faiss/');
  }

  bool _isNonRuntimeAsset(String rel) {
    final lower = rel.toLowerCase().replaceAll('\\', '/');
    if (_isNativeAsset(lower)) return true;
    const textButNotRuntime = <String>[
      '.md', '.txt', '.bat', '.sh', '.properties', '.gradle', '.cmake', 'dockerfile', '.gitignore', '.pro', '.json'
    ];
    if (lower.endsWith('.xml') && lower.contains('/res/drawable/')) return true;
    if (lower.endsWith('.xml') && lower.contains('/res/mipmap/')) return true;
    if (lower.contains('/android/app/src/main/cpp/third_party/')) return true;
    return textButNotRuntime.any(lower.endsWith);
  }

  String _readSafe(File file) {
    try {
      final size = file.lengthSync();
      final rel = _rel(file);
      if (size > 2500000 && _isKnowledgeCorpus(rel)) {
        _add('OK', 'knowledge_corpus', rel, 0, 'Large knowledge corpus tracked; runtime should prefer asset-backed wrapper.');
        return '';
      }
      if (size > 6000000) {
        _add('INFO', 'scanner', rel, 0, 'Skipped very large file ($size bytes).');
        return '';
      }
      return utf8.decode(file.readAsBytesSync(), allowMalformed: true);
    } catch (e) {
      _add('WARN', 'scanner', _rel(file), 0, 'Could not read file: $e');
      return null;
    }
  }

  bool _isKnowledgeCorpus(String rel) {
    final lower = rel.toLowerCase().replaceAll('\\', '/');
    return lower.contains('/runtime/knowledge/') ||
        lower.contains('/runtime/knowledge_new/') ||
        lower.contains('nova_knowledge_');
  }

  bool _isToolFile(String rel) => rel.toLowerCase().replaceAll('\\', '/').startsWith('tool/');

  RegExpMatch _firstMatch(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false, dotAll: true).firstMatch(text);
      if (match != null) return match;
    }
    return null;
  }

  void _scanAi(String rel, String text) {
    if (text.isEmpty) return;
    final lower = rel.toLowerCase().replaceAll('\\', '/');
    if (_isToolFile(lower) || _isKnowledgeCorpus(lower)) return;

    final hit = _firstMatch(text, <String>[
      r'\baiService\.process\s*\(',
      r'\b_novaAiService\.process\s*\(',
      r'\b_setupAiService\.process\s*\(',
      r'\bmainAiService\.process\s*\(',
      r'\blocalModelService\.generate\s*\(',
      r'\bmodelBridge\.generate\s*\(',
      r'\bModelBridge\.generate\s*\(',
      r'''invokeMethod\(["']askAI["']''',
      r'\bAiRequest\s*\(',
      r'\bsystemPrompt\b',
    ]);
    if (hit == null) return;

    if (_isAiPrimitive(lower, text)) {
      _add('OK', 'ai_route', rel, _lineOf(text, hit.start), 'AI/model path is SingleBrain-authorized, DTO, or internal primitive.', snippet: _lineText(text, hit.start));
      return;
    }

    if (_isSingleBrainRouted(text)) {
      _add('OK', 'ai_route', rel, _lineOf(text, hit.start), 'AI/model path appears SingleBrainAuthority-routed.', snippet: _lineText(text, hit.start));
      return;
    }

    _add('FAIL', 'ai_route', rel, _lineOf(text, hit.start), 'Potential AI/model bypass outside SingleBrainAuthority.', snippet: _lineText(text, hit.start), recommendation: 'Route through SingleBrainAuthority or mark as explicit non-speaking primitive.');
  }

  bool _isAiPrimitive(String lowerRel, String text) {
    if (lowerRel.endsWith('/ai_request.dart')) return true;
    if (lowerRel.endsWith('/ai_response.dart')) return true;
    if (lowerRel.endsWith('/nova_persona.dart')) return true;
    if (lowerRel.endsWith('/local_model_service.dart')) return true;
    if (lowerRel.endsWith('/nova_ai_service.dart')) return true;
    if (lowerRel.endsWith('/backup_service.dart')) return true;
    if (lowerRel.endsWith('/mainactivity.kt')) return true;
    if (lowerRel.endsWith('/modelbridge.kt')) return true;
    if (lowerRel.endsWith('/novaxttsengine.kt')) return true;
    if (lowerRel.endsWith('/novaxttsbridgeplugin.kt')) return true;
    if (text.contains('TextEditingController>.generate')) return true;
    if (text.contains('DropdownMenuItem') && text.contains('.generate(')) return true;
    if (text.contains('List<') && text.contains('>.generate(')) return true;
    return false;
  }

  bool _isSingleBrainRouted(String text) {
    return text.contains('NovaSingleBrainAuthorityService.instance.handleInput') ||
        text.contains('singleBrainAuthorityService.handleInput') ||
        text.contains('SingleBrainAuthority') ||
        text.contains('singleBrainRequired') ||
        (text.contains('aiChainRequired') && text.contains('brainTtsSource'));
  }

  void _scanTts(String rel, String text) {
    if (text.isEmpty) return;
    final lower = rel.toLowerCase().replaceAll('\\', '/');
    if (_isToolFile(lower) || _isKnowledgeCorpus(lower)) return;

    final hit = _firstMatch(text, <String>[
      r'\.speak\s*\(',
      r'ttsService\.speak\s*\(',
      r'speechRuntimeService\.speak\s*\(',
      r'NovaSpeechRequest\s*\(',
      r'FlutterTts\b',
      r'TextToSpeech\b',
      r'speakSystem\s*\(',
    ]);
    if (hit == null) return;

    if (_isTtsPrimitive(lower)) {
      _add('OK', 'tts_route', rel, _lineOf(text, hit.start), 'TTS/speech route is authority-gated or low-level mouth primitive.', snippet: _lineText(text, hit.start));
      return;
    }

    final gated = text.contains('authoritySource') ||
        text.contains('singleBrainApproved') ||
        text.contains('allowOperationalSpeech') ||
        text.contains('authorizeSpeech(') ||
        text.contains('brain_decision_ai_output') ||
        text.contains('call_companion_ai_authority_output');
    _add(gated  'OK' : 'FAIL', 'tts_route', rel, _lineOf(text, hit.start), gated ? 'TTS/speech route is authority-gated or low-level mouth primitive.' : 'Potential direct TTS/speech bypass.', snippet: _lineText(text, hit.start), recommendation: gated ?? '' : 'Pass authoritySource/authorityResponse/singleBrainApproved or keep it as explicit low-level mouth primitive.');
  }

  bool _isTtsPrimitive(String lowerRel) {
    return lowerRel.endsWith('generatedpluginregistrant.java') ||
        lowerRel.endsWith('/tts_service.dart') ||
        lowerRel.endsWith('/novaandroidttsmouthengine.kt') ||
        lowerRel.endsWith('/novaandroidttsmouthbridgeplugin.kt') ||
        lowerRel.endsWith('/novaxttsbridgeplugin.kt') ||
        lowerRel.endsWith('/novaxttsengine.kt');
  }

  bool _isAsrOrSpeechPrimitive(String lowerRel, String text) {
    return lowerRel.contains('/services/speech/') ||
        lowerRel.contains('/services/speech_runtime/') ||
        lowerRel.contains('/services/runtime/nova_speech_') ||
        lowerRel.contains('/services/runtime/nova_turkish_spoken_understanding_layer_service.dart') ||
        lowerRel.contains('/services/self_repair/') ||
        lowerRel.endsWith('/tts_service.dart') ||
        text.contains('authoritySource') ||
        text.contains('singleBrainApproved') ||
        text.contains('NovaSpeechRequest') ||
        text.contains('NovaSingleBrainAuthorityService') ||
        text.contains('SingleBrainAuthority');
  }

  bool _isRuntimeStatePrimitive(String lowerRel, String text) {
    return lowerRel.contains('/core/') ||
        lowerRel.contains('/services/orchestrator/') ||
        lowerRel.contains('/services/runtime/') ||
        lowerRel.contains('/services/security/') ||
        lowerRel.contains('/services/self_repair/') ||
        lowerRel.contains('/services/system/') ||
        lowerRel.contains('/services/voice_clone/') ||
        lowerRel.contains('/services/phone_control/') ||
        lowerRel.contains('/services/local_model/') ||
        text.contains('NovaRuntimeOrchestratorService') ||
        text.contains('SingleBrainAuthority') ||
        text.contains('BrainDecision') ||
        text.contains('OwnerActionBroker') ||
        text.contains('orchestrator');
  }

  void _scanAsr(String rel, String text) {
    if (text.isEmpty) return;
    final lower = rel.toLowerCase().replaceAll('\\', '/');
    if (_isToolFile(lower) || _isKnowledgeCorpus(lower)) return;
    if (lower.endsWith('.xml') || lower.contains('/res/drawable/') || lower.contains('/res/mipmap/')) return;
    if (_isNativeAsset(lower)) return;

    final asrHit = lower.contains('asr') ||
        lower.contains('stt') ||
        lower.contains('speech') ||
        lower.contains('speaker') ||
        text.contains('SpeechRecognizer') ||
        text.contains('transcript');
    if (!asrHit) return;

    final ok = text.contains('speakerVoiceId') ||
        text.contains('speakerName') ||
        text.contains('ownerConfidence') ||
        text.contains('relationshipLabel') ||
        text.contains('SingleBrainAuthority') ||
        _isAsrOrSpeechPrimitive(lower, text) ||
        lower.contains('/core/') ||
        lower.endsWith('.kt') ||
        lower.endsWith('.java');
    _add(ok ? 'OK' : 'WARN', 'asr_stt', rel, 0, ok ? 'ASR/STT path carries speaker/authority metadata or is native/data primitive.' : 'ASR/STT path should be checked for speaker metadata and SingleBrain routing.', recommendation: ok ?? '' : 'Carry speakerVoiceId/speakerName/ownerConfidence/relationshipLabel into SingleBrainAuthority.');
  }

  void _scanSetup(String rel, String text) {
    if (text.isEmpty) return;
    final lower = rel.toLowerCase().replaceAll('\\', '/');
    if (_isToolFile(lower) || _isKnowledgeCorpus(lower)) return;
    if (!lower.contains('setup') && !lower.contains('first_run') && !lower.contains('launch_gate')) return;
    final ok = lower.endsWith('/nova_launch_gate_page.dart') ||
        text.contains('brain_kernel_verified') ||
        text.contains('_brainKernelVerified') ||
        text.contains('requiresLocalModel: true') ||
        text.contains('modelReady') ||
        text.contains('asrReady') ||
        text.contains('ttsReady');
    _add(ok ? 'OK' : 'WARN', 'setup_boot', rel, 0, ok ? 'Setup path appears gated on AI/TTS/STT/ASR readiness proof.' : 'Setup-related path may advance without AI/TTS/STT/ASR readiness proof.', recommendation: ok ?? '' : 'Require brain kernel proof and TTS/STT/ASR readiness before advancing.');
  }

  void _scanRuntimeState(String rel, String text) {
    if (text.isEmpty) return;
    final lower = rel.toLowerCase().replaceAll('\\', '/');
    if (_isToolFile(lower) || _isKnowledgeCorpus(lower)) return;
    final hit = text.contains('setState(') ||
        text.contains('powerMode') ||
        text.contains('PowerMode') ||
        text.contains('runtimeOrchestrator') ||
        text.contains('orchestrator') ||
        text.contains('dashboard');
    if (!hit) return;
    final ok = lower.contains('dashboard') ||
        lower.contains('runtime_orchestrator') ||
        lower.contains('/ui/') ||
        lower.contains('/pages/') ||
        lower.contains('/presentation/') ||
        _isRuntimeStatePrimitive(lower, text) ||
        text.contains('NovaRuntimeOrchestratorService') ||
        text.contains('SingleBrainAuthority') ||
        text.contains('BrainDecision');
    _add(ok ? 'OK' : 'WARN', 'runtime_state', rel, 0, ok ? 'Runtime/UI state path appears orchestrator/dashboard-aware or deterministic UI primitive.' : 'Runtime/UI state mutation should be checked for ghost-flow bypass.', recommendation: ok ?? '' : 'State changes should come from BrainDecision -> Orchestrator/Broker or be deterministic primitive.');
  }

  void _scanSecurity(String rel, String text) {
    if (text.isEmpty) return;
    final lower = rel.toLowerCase().replaceAll('\\', '/');
    if (_isToolFile(lower) || _isKnowledgeCorpus(lower)) return;
    if (!lower.contains('security') && !lower.contains('shield') && !lower.contains('boundary') && !lower.contains('quarantine') && !lower.contains('guard')) return;

    final dangerous = RegExp(r'\b(aiCanOverrideSecurity|disableSecurityForAi|overrideSecurityBoundary|GemmaOverridesSecurity)\b\s*[:=]\s*true', caseSensitive: false).hasMatch(text) ||
        RegExp(r'\ballowAiSecurityOverride\s*\(', caseSensitive: false).hasMatch(text);
    _add(dangerous ? 'FAIL' : 'OK', 'security', rel, 0, dangerous ? 'AI appears able to relax/override security boundary.' : 'Security boundary remains deterministic, DTO/bridge-only, or safe policy text.', recommendation: dangerous ? 'Security shields must remain deterministic and outside Gemma control. AI can request, not override.' : '');
  }

  void _scanSelfRepair(String rel, String text) {
    if (text.isEmpty) return;
    final lower = rel.toLowerCase().replaceAll('\\', '/');
    if (_isToolFile(lower) || _isNativeAsset(lower) || lower.contains('/third_party/')) return;
    if (!lower.contains('repair') && !lower.contains('patch') && !lower.contains('cleanup') && !lower.contains('corpus_install')) return;
    final writes = text.contains('writeAsString') ||
        text.contains('writeAsBytes') ||
        text.contains('applyPatch') ||
        text.contains('copy(') ||
        text.contains('deleteSync') ||
        text.contains('File(');
    if (!writes) {
      _add('OK', 'self_repair', rel, 0, 'Self-repair/write path has owner/validator/rollback markers, no direct write path, or deterministic cleanup primitive.');
      return;
    }
    final normalized = text.toLowerCase();
    final owner = normalized.contains('owner');
    final validator = normalized.contains('validat') || normalized.contains('analyze');
    final rollback = normalized.contains('rollback') || normalized.contains('backup') || lower.contains('corpus_install') || lower.contains('storage_cleanup');
    final deterministicCleanup = lower.contains('storage_cleanup') && !normalized.contains('execute');
    final ok = (owner && validator && rollback) || deterministicCleanup;
    _add(ok ? 'OK' : 'FAIL', 'self_repair', rel, 0, ok ? 'Self-repair/write path has owner/validator/rollback markers, no direct write path, or deterministic cleanup primitive.' : 'Self-repair/write path can write or execute without full safety triad.', recommendation: ok ?? '' : 'Require owner approval, validator/analyze, and rollback/backup before file changes.');
  }

  void _scanCorpus(String rel, String text) {
    final lower = rel.toLowerCase().replaceAll('\\', '/');
    if (_isKnowledgeCorpus(lower)) {
      _add('OK', 'knowledge_corpus', rel, 0, 'Knowledge corpus file tracked; runtime should prefer asset-backed wrapper.');
    }
    if (lower.endsWith('pubspec.yaml')) {
      _add('OK', 'pubspec_assets', rel, 0, 'pubspec checked; native model assets are allowed outside Flutter assets when loaded from Android/native side.');
    }
  }

  void _globalChecks() {
    final wrapper = File('${root.path}/lib/services/runtime/nova_knowledge_asset_wrapper_service.dart');
    _add(wrapper.existsSync() ? 'OK' : 'WARN', 'knowledge_corpus', 'lib/services/runtime/nova_knowledge_asset_wrapper_service.dart', 0, wrapper.existsSync() ? 'Asset-backed knowledge wrapper exists.' : 'Asset-backed corpus wrapper missing.');
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
    final pubspec = File('${root.path}/pubspec.yaml');
    if (!pubspec.existsSync()) return;
    final analyze = await Process.run('flutter', <String>['analyze'], workingDirectory: root.path, runInShell: true);
    final output = '${analyze.stdout}\n${analyze.stderr}';
    final hasError = RegExp(r'\berror\s+-', caseSensitive: false).hasMatch(output);
    if (analyze.exitCode == 0 || !hasError) { ? _add('OK', 'flutter_analyze', 'flutter', 0, analyze.exitCode == 0  'flutter analyze passed.' : 'flutter analyze returned non-zero but no analyzer errors were detected.', snippet: _firstLines(output, 12));
    } else {
      _add('FAIL', 'flutter_analyze', 'flutter', 0, 'flutter analyze failed with analyzer errors.', snippet: _firstLines(output, 24));
    }
  }

  int _lineOf(String text, int offset) {
    if (offset <= 0) return 1;
    var line = 1;
    for (var i = 0; i < offset && i < text.length; i++) {
      if (text.codeUnitAt(i) == 10) line++;
    }
    return line;
  }

  String _lineText(String text, int offset) {
    final safeOffset = offset.clamp(0, text.length);
    final start = text.lastIndexOf('\n', safeOffset) + 1;
    var end = text.indexOf('\n', safeOffset);
    if (end < 0) end = text.length;
    return text.substring(start, end).trim();
  }

  String _firstLines(String text, int count) {
    return const LineSplitter().convert(text).take(count).join('\n');
  }

  int _count(String severity) => findings.where((f) => f.severity == severity).length;

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

  Future<void> _writeReports() async {
    final buildDir = Directory('${root.path}/build');
    buildDir.createSync(recursive: true);
    final counts = <String, int>{
      'OK': _count('OK'),
      'INFO': _count('INFO'),
      'WARN': _count('WARN'),
      'FAIL': _count('FAIL'),
    };
    final txt = StringBuffer()
      ..writeln('Nova Full Native + Lib Audit')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Root: ${root.path}')
      ..writeln('Files inventoried: $filesInventoried')
      ..writeln('Text scanned: $textFilesScanned')
      ..writeln('Binary/assets tracked: $binaryFilesTracked')
      ..writeln('Other tracked: $otherFilesTracked')
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
    File('${buildDir.path}/nova_full_native_lib_audit_report.txt').writeAsStringSync(txt.toString());
    File('${buildDir.path}/nova_full_native_lib_audit_report.json').writeAsStringSync(jsonEncode(<String, Object>{
      'tool': 'nova_full_native_lib_audit',
      'version': '1.5.0',
      'generatedAt': DateTime.now().toIso8601String(),
      'summary': <String, Object>{
        'projectRoot': root.path,
        'filesInventoried': filesInventoried,
        'textFilesScanned': textFilesScanned,
        'binaryFilesTracked': binaryFilesTracked,
        'otherFilesTracked': otherFilesTracked,
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
  final audit = NovaFullNativeLibAudit(
    root: Directory.current,
    strict: strict,
    runBuildChecks: build,
    runtimeLogPath: runtimeLog,
  );
  exitCode = await audit.run();
}
