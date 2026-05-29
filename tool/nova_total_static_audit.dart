
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

  Finding(
    this.severity,
    this.category,
    this.file,
    this.line,
    this.message, {
    this.snippet = '',
    this.recommendation = '',
  });

  Map<String, Object> toJson() => {
        'severity': severity,
        'category': category,
        'file': file,
        'line': line,
        'message': message,
        'snippet': snippet,
        'recommendation': recommendation,
      };
}

class SourceFile {
  final File file;
  final String rel;
  final String text;
  final List<String> lines;
  SourceFile(this.file, this.rel, this.text) : lines = text.split('\n');
}

final findings = <Finding>[];
final files = <SourceFile>[];

bool strict = false;

void main(List<String> args) async {
  strict = args.contains('--strict');
  final root = Directory.current;

  collectFiles(root);
  add('INFO', 'inventory', '.', 0, 'Text files scanned: ${files.length}.');

  scanPresence();
  scanSetupGate();
  scanSingleBrainAuthority();
  scanAiBypasses();
  scanTtsBypasses();
  scanLocalModelTimeouts();
  scanNativeBridge();
  scanNativeTokenStopPropagation();
  scanCancelAndWarmEngine();
  scanInternalPromptLeak();
  scanBrainKernelProbeQuality();
  scanFallbackStaticSpeech();
  scanGemmaQwenModelRouting();
  scanAndroidManifestAndPermissions();
  scanAsrTtsRuntimeChains();
  scanCallCompanionChains();
  scanDashboardAndRuntimeControls();
  scanPatchMarkerNeed();

  writeReports();

  final fail = findings.where((f) => f.severity == 'FAIL').length;
  final warn = findings.where((f) => f.severity == 'WARN').length;
  final ok = findings.where((f) => f.severity == 'OK').length;
  final info = findings.where((f) => f.severity == 'INFO').length;

  stdout.writeln('NOVA_TOTAL_STATIC_AUDIT_DONE');
  stdout.writeln('OK=$ok WARN=$warn FAIL=$fail INFO=$info');
  stdout.writeln('Reports: build/nova_total_static_audit/NOVA_TOTAL_STATIC_AUDIT_REPORT.md');
  stdout.writeln('JSON: build/nova_total_static_audit/nova_total_static_audit_report.json');

  if (strict && fail > 0) {
    exitCode = 1;
  }
}

void collectFiles(Directory root) {
  final includeExt = {
    '.dart', '.kt', '.java', '.xml', '.yaml', '.yml', '.gradle', '.kts',
    '.properties', '.md', '.json', '.txt', '.cpp', '.cc', '.c', '.h', '.hpp',
  };
  for (final ent in root.listSync(recursive: true, followLinks: false)) {
    if (ent is! File) continue;
    final p = ent.path.replaceAll('\\', '/');
    if (p.contains('/.dart_tool/') ||
        p.contains('/build/') ||
        p.contains('/.gradle/') ||
        p.contains('/.idea/') ||
        p.contains('/.git/') ||
        p.contains('/nova_total_static_audit/')) {
      continue;
    }
    final name = ent.uri.pathSegments.isNotEmpty ? ent.uri.pathSegments.last : p;
    final dot = name.lastIndexOf('.');
    final ext = dot >= 0 ? name.substring(dot).toLowerCase() : '';
    if (!includeExt.contains(ext)) continue;
    try {
      final txt = ent.readAsStringSync();
      final rel = pathRel(ent.path, Directory.current.path);
      files.add(SourceFile(ent, rel, txt));
    } catch (_) {}
  }
  files.sort((a, b) => a.rel.compareTo(b.rel));
}

String pathRel(String path, String root) {
  var p = path.replaceAll('\\', '/');
  var r = root.replaceAll('\\', '/');
  if (p.startsWith('$r/')) return p.substring(r.length + 1);
  return p;
}

SourceFile fileEnds(String suffix) {
  suffix = suffix.replaceAll('\\', '/');
  for (final f in files) {
    if (f.rel.replaceAll('\\', '/').endsWith(suffix)) return f;
  }
  return null;
}

List<SourceFile> findFiles(RegExp re) => files.where((f) => re.hasMatch(f.rel)).toList();

bool anyText(RegExp re) => files.any((f) => re.hasMatch(f.text));

Iterable<MapEntry<int, String>> linesMatching(SourceFile f, RegExp re) sync* {
  for (var i = 0; i < f.lines.length; i++) {
    if (re.hasMatch(f.lines[i])) yield MapEntry(i + 1, f.lines[i]);
  }
}

void add(
  String sev,
  String cat,
  String file,
  int line,
  String msg, {
  String snippet = '',
  String recommendation = '',
}) {
  findings.add(Finding(sev, cat, file, line, msg, snippet: snippet, recommendation: recommendation));
}

void requireFile(String category, String suffix, String why) {
  final f = fileEnds(suffix);
  if (f == null) {
    add('FAIL', category, suffix, 0, 'Required file not found: $why.');
  } else {
    add('OK', category, f.rel, 0, 'Found required file: $why.');
  }
}

void requireText(String category, String fileSuffix, RegExp pattern, String okMsg, String failMsg, {String recommendation = ''}) {
  final f = fileEnds(fileSuffix);
  if (f == null) {
    add('FAIL', category, fileSuffix, 0, 'File missing for check: $failMsg', recommendation: recommendation);
    return;
  }
  final m = firstMatchLine(f, pattern);
  if (m != null) {
    add('OK', category, f.rel, m.key, okMsg, snippet: m.value.trim());
  } else {
    add('FAIL', category, f.rel, 0, failMsg, recommendation: recommendation);
  }
}

MapEntry<int, String> firstMatchLine(SourceFile f, RegExp re) {
  for (var i = 0; i < f.lines.length; i++) {
    if (re.hasMatch(f.lines[i])) return MapEntry(i + 1, f.lines[i]);
  }
  return null;
}

void scanPresence() {
  requireFile('presence', 'lib/services/local_model/local_model_service.dart', 'Dart local model service');
  requireFile('presence', 'lib/services/runtime/nova_single_brain_authority_service.dart', 'single brain authority service');
  requireFile('presence', 'lib/core/ai/nova_ai_service.dart', 'core AI service');
  requireFile('presence', 'android/app/src/main/kotlin/com/example/nova/MainActivity.kt', 'native MethodChannel bridge');
  requireFile('presence', 'android/app/src/main/kotlin/com/example/nova/ModelBridge.kt', 'native LiteRT/Gemma model bridge');

  final setupFiles = findFiles(RegExp(r'lib/.+setup.+\.dart$', caseSensitive: false));
  if (setupFiles.isEmpty) {
    add('FAIL', 'presence', 'lib/', 0, 'No setup page/service file found by name.');
  } else {
    add('OK', 'presence', setupFiles.map((e) => e.rel).join(', '), 0, 'Setup-related files found: ${setupFiles.length}.');
  }
}

void scanSetupGate() {
  final setupFiles = findFiles(RegExp(r'lib/.+(setup|first_run|onboarding).+\.dart$', caseSensitive: false));
  var hasPrepare = false;
  var hasVerifyKernel = false;
  var hasOpeningMicro = false;
  var hasHardFallback = false;

  for (final f in setupFiles) {
    if (RegExp(r'prepare(LocalModel)?ForBoot|prepareForBoot|model_prepare', caseSensitive: false).hasMatch(f.text)) hasPrepare = true;
    if (RegExp(r'verify(Local)?BrainKernelForBoot|brain_kernel|brainKernel', caseSensitive: false).hasMatch(f.text)) hasVerifyKernel = true;
    if (RegExp(r'opening_micro_inference|setup_voice_opening|setupMicro', caseSensitive: false).hasMatch(f.text)) hasOpeningMicro = true;
    if (RegExp(r'(fallback|static|haz[Ä±i]r metin|default).{0,80}(speak|tts|setup)', caseSensitive: false).hasMatch(f.text)) {
      hasHardFallback = true;
      final m = firstMatchLine(f, RegExp(r'(fallback|static|haz[Ä±i]r metin|default).{0,80}(speak|tts|setup)', caseSensitive: false));
      add('WARN', 'setup_gate', f.rel, m?.key  0, 'Setup file contains possible fallback/static setup speech path.', snippet: m?.value.trim() ?? '', recommendation: 'Setup voice must only advance from SingleBrain/LocalModel modelUsed=true.');
    }
  }

  add(hasPrepare ? 'OK' : 'FAIL', 'setup_gate', 'lib/setup', 0, hasPrepare ? 'Setup has model prepare phase.' : 'Setup prepare phase not found.');
  add(hasVerifyKernel ? 'OK' : 'FAIL', 'setup_gate', 'lib/setup', 0, hasVerifyKernel ? 'Setup references brain kernel verification.' : 'Setup does not clearly reference brain kernel verification.');
  add(hasOpeningMicro ? 'OK' : 'FAIL', 'setup_gate', 'lib/setup', 0, hasOpeningMicro ? 'Setup opening micro-inference path found.' : 'Setup opening micro-inference path not found.');
  if (!hasHardFallback) add('OK', 'setup_gate', 'lib/setup', 0, 'No obvious setup fallback/static speech pattern found.');
}

void scanSingleBrainAuthority() {
  requireText(
    'single_brain',
    'lib/services/runtime/nova_single_brain_authority_service.dart',
    RegExp(r'handleInput\s*\(', caseSensitive: false),
    'SingleBrain handleInput found.',
    'SingleBrain handleInput not found.',
  );
  requireText(
    'single_brain',
    'lib/services/runtime/nova_single_brain_authority_service.dart',
    RegExp(r'modelUsed|requireModel|allowed', caseSensitive: false),
    'SingleBrain decision flags found.',
    'SingleBrain decision flags modelUsed/allowed/requireModel not found.',
  );
  requireText(
    'single_brain',
    'lib/services/runtime/nova_single_brain_authority_service.dart',
    RegExp(r'singleBrainAuthority|sourceSystem.*single_brain_authority|aiChainRequired', caseSensitive: false),
    'SingleBrain metadata marker found.',
    'SingleBrain native metadata marker not found.',
    recommendation: 'Native askAI metadata guard needs singleBrainAuthority/sourceSystem markers from Dart.',
  );

  final f = fileEnds('lib/services/runtime/nova_single_brain_authority_service.dart');
  if (f != null) {
    for (final m in linesMatching(f, RegExp(r'SINGLE_BRAIN_FAST_DECISION|CoreProfileHash|NovaCoreProfile|Runtime KatmanÄ±|Runtime Katmani'))) {
      add('FAIL', 'single_brain_prompt_contract', f.rel, m.key, 'Internal decision label/profile text is still present in SingleBrain prompt path.', snippet: m.value.trim(), recommendation: 'Do not feed internal debug/decision labels as model-visible answer format.');
    }
  }
}

void scanAiBypasses() {
  final allowedFiles = [
    'lib/core/ai/nova_ai_service.dart',
    'lib/services/runtime/nova_single_brain_authority_service.dart',
    'tool/',
  ];

  final aiCall = RegExp(r'\b(_?novaAiService|novaAiService|aiService|_setupAiService|NovaAiService\.instance)\.(process|ask|generate|reply|respond)\s*\(', caseSensitive: false);
  var violations = 0;
  for (final f in files.where((x) => x.rel.endsWith('.dart'))) {
    for (final m in linesMatching(f, aiCall)) {
      final allowed = allowedFiles.any((p) => f.rel.startsWith(p) || f.rel.endsWith(p));
      final nearSingleBrain = near(f, m.key - 1, RegExp(r'NovaSingleBrainAuthorityService\.instance\.handleInput|singleBrainAuthority', caseSensitive: false), 18, 18);
      if (!allowed && !nearSingleBrain) {
        violations++;
        add('FAIL', 'ai_bypass', f.rel, m.key, 'Possible direct AI call bypassing SingleBrainAuthority.', snippet: m.value.trim(), recommendation: 'Route normal AI through NovaSingleBrainAuthorityService.handleInput().');
      }
    }
  }
  if (violations == 0) add('OK', 'ai_bypass', 'lib/', 0, 'No obvious direct AI bypass found.');
}

void scanTtsBypasses() {
  final ttsCall = RegExp(r'\b(_?ttsService|ttsService|NovaTtsService\.instance|NovaSpeechRuntimeService\.instance)\.(speak|say|synthesize)\s*\(', caseSensitive: false);
  var violations = 0;
  for (final f in files.where((x) => x.rel.endsWith('.dart'))) {
    if (f.rel.endsWith('nova_tts_service.dart') || f.rel.endsWith('nova_speech_runtime_service.dart')) continue;
    for (final m in linesMatching(f, ttsCall)) {
      final block = blockText(f, m.key - 1, 22);
      final authorized = RegExp(r'authoritySource|authorityResponse|singleBrainApproved|allowSecuritySpeech|modelUsed\s*:\s*true', caseSensitive: false).hasMatch(block);
      if (!authorized) {
        violations++;
        add('FAIL', 'tts_bypass', f.rel, m.key, 'Possible direct TTS call without single-brain authority marker.', snippet: m.value.trim(), recommendation: 'Normal Nova speech must require modelUsed=true or explicit authorized security speech.');
      }
    }
  }
  if (violations == 0) add('OK', 'tts_bypass', 'lib/', 0, 'No obvious unauthorized direct TTS call found.');
}

void scanLocalModelTimeouts() {
  final f = fileEnds('lib/services/local_model/local_model_service.dart');
  if (f == null) return;
  final suspicious = RegExp(r'Duration\s*\(\s*seconds\s*:\s*(3[0-9]|4[0-9]|5[0-9])\s*\)|timeoutMs\s*=\s*(3[0-9]000|4[0-9]000|5[0-9]000)|setupMicro.{0,120}(35|45|60)', caseSensitive: false);
  var count = 0;
  for (final m in linesMatching(f, suspicious)) {
    count++;
    add('FAIL', 'timeout_contract', f.rel, m.key, 'Short model timeout candidate found; this can cause local_model_failed_strict before native answer returns.', snippet: m.value.trim(), recommendation: 'Setup micro/brain opening timeout must not be shorter than native timeout; prefer warm-engine + short output over early timeout.');
  }
  if (count == 0) add('OK', 'timeout_contract', f.rel, 0, 'No obvious 35/45/60 second setup model timeout found.');

  if (!RegExp(r'setupMicro|maxOutputTokens|stopOnNewline', caseSensitive: false).hasMatch(f.text)) {
    add('WARN', 'timeout_contract', f.rel, 0, 'No setupMicro/maxOutputTokens/stopOnNewline contract found in LocalModelService.');
  }
}

void scanNativeBridge() {
  final main = fileEnds('android/app/src/main/kotlin/com/example/nova/MainActivity.kt') 
      fileEnds('android/app/src/main/java/com/example/nova/MainActivity.java');
  final bridge = fileEnds('android/app/src/main/kotlin/com/example/nova/ModelBridge.kt') 
      fileEnds('android/app/src/main/java/com/example/nova/ModelBridge.java');

  if (main != null) {
    for (final req in {
      'MethodChannel nova.ai': RegExp(r'MethodChannel\s*\(.+nova\.ai|nova\.ai', caseSensitive: false),
      'askAI method': RegExp(r"""["\']askAI["\']""", caseSensitive: false),
      'prepareLocalModelForBoot': RegExp(r'prepareLocalModelForBoot', caseSensitive: false),
      'verifyLocalBrainKernelForBoot': RegExp(r'verifyLocalBrainKernelForBoot', caseSensitive: false),
      'singleBrain metadata guard': RegExp(r'singleBrainAuthority|singleBrainRequired|aiChainRequired|sourceSystem', caseSensitive: false),
      'NOVA_NATIVE_GENERATE_CALLED log': RegExp(r'NOVA_NATIVE_GENERATE_CALLED', caseSensitive: false),
      'NOVA_RAW_MODEL_OUTPUT log': RegExp(r'NOVA_RAW_MODEL_OUTPUT', caseSensitive: false),
    }.entries) {
      final m = firstMatchLine(main, req.value);
      add(m == null ? 'FAIL' : 'OK', 'native_bridge', main.rel, m?.key ? 0, m == null  '${req.key} missing.' : '${req.key} found.', snippet: m?.value.trim() ?? '');
    }
  }

  if (bridge != null) {
    for (final req in {
      'Engine initialize': RegExp(r'Engine\s*\(|initialize\s*\(', caseSensitive: false),
      'conversation/sendMessage': RegExp(r'createConversation|sendMessage', caseSensitive: false),
      'extract output text': RegExp(r'extract.+Text|raw.*output|messageResult', caseSensitive: false),
    }.entries) {
      final m = firstMatchLine(bridge, req.value);
      add(m == null ? 'FAIL' : 'OK', 'native_bridge', bridge.rel, m?.key ? 0, m == null  '${req.key} missing.' : '${req.key} found.', snippet: m?.value.trim() ?? '');
    }
  }
}

void scanNativeTokenStopPropagation() {
  final main = fileEnds('android/app/src/main/kotlin/com/example/nova/MainActivity.kt') 
      fileEnds('android/app/src/main/java/com/example/nova/MainActivity.java');
  final bridge = fileEnds('android/app/src/main/kotlin/com/example/nova/ModelBridge.kt') 
      fileEnds('android/app/src/main/java/com/example/nova/ModelBridge.java');

  if (main != null) {
    final max = firstMatchLine(main, RegExp(r'maxOutputTokens', caseSensitive: false));
    final stop = firstMatchLine(main, RegExp(r'stopOnNewline', caseSensitive: false));
    add(max == null ? 'FAIL' : 'OK', 'native_output_limit', main.rel, max?.key ? 0, max == null  'MainActivity does not read/pass maxOutputTokens.' : 'MainActivity references maxOutputTokens.', snippet: max?.value.trim() ?? '');
    add(stop == null ? 'FAIL' : 'OK', 'native_output_limit', main.rel, stop?.key ? 0, stop == null  'MainActivity does not read/pass stopOnNewline.' : 'MainActivity references stopOnNewline.', snippet: stop?.value.trim() ?? '');
  }

  if (bridge != null) {
    final max = firstMatchLine(bridge, RegExp(r'maxOutputTokens', caseSensitive: false));
    final stop = firstMatchLine(bridge, RegExp(r'stopOnNewline', caseSensitive: false));
    add(max == null ? 'FAIL' : 'OK', 'native_output_limit', bridge.rel, max?.key ? 0, max == null  'ModelBridge does not accept/enforce maxOutputTokens.' : 'ModelBridge references maxOutputTokens.', snippet: max?.value.trim() ?? '');
    add(stop == null ? 'FAIL' : 'OK', 'native_output_limit', bridge.rel, stop?.key ? 0, stop == null  'ModelBridge does not accept/enforce stopOnNewline.' : 'ModelBridge references stopOnNewline.', snippet: stop?.value.trim() ?? '');
  }
}

void scanCancelAndWarmEngine() {
  final allNative = files.where((f) => f.rel.endsWith('.kt') || f.rel.endsWith('.java')).toList();
  var cancelLines = 0;
  for (final f in allNative) {
    for (final m in linesMatching(f, RegExp(r'cancelPrevious|ownerPrimaryTurn|cancelGeneration|cachedEngine|close\s*\(|destroy\s*\(', caseSensitive: false))) {
      cancelLines++;
      final isDanger = RegExp(r'cancelPrevious|ownerPrimaryTurn|cancelGeneration|cachedEngine\s*=\s*null|close\s*\(|destroy\s*\(', caseSensitive: false).hasMatch(m.value);
      add(isDanger ? 'WARN' : 'INFO', 'warm_engine_cancel', f.rel, m.key, 'Warm-engine/cancel related line.', snippet: m.value.trim(), recommendation: 'Cancel must not close warm Gemma engine unless active generation must be aborted.');
    }
  }
  if (cancelLines == 0) add('WARN', 'warm_engine_cancel', 'android/', 0, 'No cancel/warm engine policy found; verify engine is cached across turns.');
}

void scanInternalPromptLeak() {
  final leakRe = RegExp(r'SINGLE_BRAIN_FAST_DECISION|CoreProfileHash|NovaCoreProfile|Runtime KatmanÄ±|Runtime Katmani|MODE=|SOURCE=|INPUT=|compressed context|sÄ±kÄ±ÅŸtÄ±rÄ±lmÄ±ÅŸ', caseSensitive: false);
  var count = 0;
  for (final f in files.where((x) => x.rel.endsWith('.dart') || x.rel.endsWith('.kt') || x.rel.endsWith('.java'))) {
    for (final m in linesMatching(f, leakRe)) {
      count++;
      final sev = f.rel.contains('tool/') ? 'INFO' : 'FAIL';
      add(sev, 'internal_prompt_leak', f.rel, m.key, 'Internal/debug prompt token candidate found in runtime source.', snippet: m.value.trim(), recommendation: 'Internal labels must not be model-visible answer style or TTS output.');
    }
  }
  if (count == 0) add('OK', 'internal_prompt_leak', 'lib+android', 0, 'No internal prompt leak tokens found.');
}

void scanBrainKernelProbeQuality() {
  final native = files.where((f) => f.rel.endsWith('.kt') || f.rel.endsWith('.java') || f.rel.endsWith('.dart')).toList();
  var exactHazirim = 0;
  var hasBrainKernel = false;
  for (final f in native) {
    if (RegExp(r'brain_kernel|verifyLocalBrainKernelForBoot', caseSensitive: false).hasMatch(f.text)) hasBrainKernel = true;
    for (final m in linesMatching(f, RegExp(r'Haz[Ä±i]r[Ä±i]m efendim|Hazirim efendim', caseSensitive: false))) {
      exactHazirim++;
      add('WARN', 'brain_kernel_probe', f.rel, m.key, 'Brain kernel probe may be echoing a fixed target phrase.', snippet: m.value.trim(), recommendation: 'Use non-echo liveliness prompt: require a short natural variant, not exact phrase copy.');
    }
  }
  add(hasBrainKernel ? 'OK' : 'FAIL', 'brain_kernel_probe', 'lib+android', 0, hasBrainKernel ? 'Brain kernel proof path exists.' : 'Brain kernel proof path not found.');
  if (exactHazirim == 0) add('OK', 'brain_kernel_probe', 'lib+android', 0, 'No exact "HazÄ±rÄ±m efendim" echo probe found.');
}

void scanFallbackStaticSpeech() {
  final staticRe = RegExp(r'(fallback|static|defaultResponse|hardcoded|haz[Ä±i]r metin|local_model_failed|AI_REQUIRED_BLOCK).{0,160}(speak|tts|response|answer|setup|message)|Yerel model Ã§alÄ±ÅŸÄ±rken beklenmeyen hata oluÅŸtu', caseSensitive: false);
  var count = 0;
  for (final f in files.where((x) => x.rel.endsWith('.dart'))) {
    for (final m in linesMatching(f, staticRe)) {
      count++;
      add('WARN', 'fallback_static_speech', f.rel, m.key, 'Possible fallback/static answer or error-speech path.', snippet: m.value.trim(), recommendation: 'Model failure may show technical UI/log, but must not become Nova personality speech.');
    }
  }
  if (count == 0) add('OK', 'fallback_static_speech', 'lib/', 0, 'No obvious fallback/static speech pattern found.');
}

void scanGemmaQwenModelRouting() {
  var qwen = 0;
  var gemma = 0;
  for (final f in files) {
    for (final m in linesMatching(f, RegExp(r'qwen\.gguf|qwen|Qwen', caseSensitive: false))) {
      qwen++;
      add('WARN', 'model_routing', f.rel, m.key, 'Qwen reference remains.', snippet: m.value.trim(), recommendation: 'If Gemma is active model, confirm this is compatibility-only and not active runtime path.');
    }
    if (RegExp(r'gemma|LiteRT|litert', caseSensitive: false).hasMatch(f.text)) gemma++;
  }
  add(gemma > 0 ? 'OK' : 'FAIL', 'model_routing', '.', 0, gemma > 0 ? 'Gemma/LiteRT references found in source.' : 'No Gemma/LiteRT references found.');
  if (qwen == 0) add('OK', 'model_routing', '.', 0, 'No Qwen reference found.');
}

void scanAndroidManifestAndPermissions() {
  final manifests = findFiles(RegExp(r'AndroidManifest\.xml$'));
  if (manifests.isEmpty) {
    add('FAIL', 'android_permissions', 'android/', 0, 'AndroidManifest.xml not found.');
    return;
  }
  final text = manifests.map((f) => f.text).join('\n');
  for (final perm in [
    'android.permission.RECORD_AUDIO',
    'android.permission.FOREGROUND_SERVICE',
    'android.permission.FOREGROUND_SERVICE_MICROPHONE',
    'android.permission.WAKE_LOCK',
    'android.permission.MODIFY_AUDIO_SETTINGS',
  ]) {
    add(text.contains(perm) ? 'OK' : 'WARN', 'android_permissions', 'AndroidManifest.xml', 0, text.contains(perm) ? '$perm declared.' : '$perm not declared.');
  }
  if (RegExp(r'android:exported\s*=', caseSensitive: false).hasMatch(text)) {
    add('OK', 'android_permissions', 'AndroidManifest.xml', 0, 'exported attributes are present.');
  } else {
    add('WARN', 'android_permissions', 'AndroidManifest.xml', 0, 'No exported attributes found in manifest scan.');
  }
}

void scanAsrTtsRuntimeChains() {
  final asr = files.where((f) => RegExp(r'asr|stt|speech|listening', caseSensitive: false).hasMatch(f.rel)).toList();
  final tts = files.where((f) => RegExp(r'tts|speech_runtime', caseSensitive: false).hasMatch(f.rel)).toList();
  add(asr.isNotEmpty ? 'OK' : 'WARN', 'asr_tts_chain', 'lib+android', 0, 'ASR/STT/listening files found: ${asr.length}.');
  add(tts.isNotEmpty ? 'OK' : 'WARN', 'asr_tts_chain', 'lib+android', 0, 'TTS/speech runtime files found: ${tts.length}.');

  for (final f in asr) {
    for (final m in linesMatching(f, RegExp(r'ForegroundServiceDidNotStartInTime|startForegroundService|startForeground\s*\(', caseSensitive: false))) {
      add('INFO', 'asr_tts_chain', f.rel, m.key, 'Foreground ASR service related line.', snippet: m.value.trim());
    }
  }
}

void scanCallCompanionChains() {
  final filesFound = files.where((f) => RegExp(r'call|companion|telecom|incall', caseSensitive: false).hasMatch(f.rel)).toList();
  add(filesFound.isNotEmpty ? 'OK' : 'WARN', 'call_companion', 'lib+android', 0, 'Call/companion files found: ${filesFound.length}.');
  for (final f in filesFound.take(80)) {
    final hasMicMute = RegExp(r'mute|microphone|speaker|audioRoute|setAudioRoute', caseSensitive: false).hasMatch(f.text);
    if (hasMicMute) add('INFO', 'call_companion', f.rel, 0, 'Call audio/mic/speaker logic present in file.');
  }
}

void scanDashboardAndRuntimeControls() {
  final dashboards = files.where((f) => RegExp(r'dashboard|control|runtime|orchestrator', caseSensitive: false).hasMatch(f.rel)).toList();
  add(dashboards.isNotEmpty ? 'OK' : 'WARN', 'dashboard_runtime', 'lib/', 0, 'Dashboard/runtime/orchestrator files found: ${dashboards.length}.');

  var directModelUi = 0;
  for (final f in dashboards) {
    for (final m in linesMatching(f, RegExp(r'LocalModelService\.instance\.generate|NovaAiService\.instance|askAI', caseSensitive: false))) {
      directModelUi++;
      add('WARN', 'dashboard_runtime', f.rel, m.key, 'Dashboard/runtime may directly call AI/model.', snippet: m.value.trim(), recommendation: 'Dashboard controls should observe or command SingleBrainAuthority, not bypass it.');
    }
  }
  if (directModelUi == 0) add('OK', 'dashboard_runtime', 'lib/', 0, 'No obvious dashboard direct AI/model bypass found.');
}

void scanPatchMarkerNeed() {
  final marker = RegExp(r'NOVA_PATCH_MARKER|GEMMAPROMPT_REAL_BRAIN_REPAIR_ACTIVE|TOTAL_STATIC_AUDIT', caseSensitive: false);
  final found = files.any((f) => marker.hasMatch(f.text));
  add(found ? 'OK' : 'WARN', 'patch_marker', '.', 0, found ? 'Patch marker found in source.' : 'No runtime patch marker found.', recommendation: 'Add a runtime marker log after important patches so APK/source mismatch is detected instantly.');
}

bool near(SourceFile f, int index, RegExp re, int before, int after) {
  final start = (index - before).clamp(0, f.lines.length - 1).toInt();
  final end = (index + after).clamp(0, f.lines.length - 1).toInt();
  for (var i = start; i <= end; i++) {
    if (re.hasMatch(f.lines[i])) return true;
  }
  return false;
}

String blockText(SourceFile f, int index, int maxLines) {
  final b = StringBuffer();
  for (var i = index; i < f.lines.length && i < index + maxLines; i++) {
    b.writeln(f.lines[i]);
    if (f.lines[i].contains(');')) break;
  }
  return b.toString();
}

void writeReports() {
  final out = Directory('build/nova_total_static_audit');
  if (out.existsSync()) out.deleteSync(recursive: true);
  out.createSync(recursive: true);

  final byCat = <String, List<Finding>>{};
  for (final f in findings) {
    byCat.putIfAbsent(f.category, () => <Finding>[]).add(f);
  }

  final fail = findings.where((f) => f.severity == 'FAIL').length;
  final warn = findings.where((f) => f.severity == 'WARN').length;
  final ok = findings.where((f) => f.severity == 'OK').length;
  final info = findings.where((f) => f.severity == 'INFO').length;

  final md = StringBuffer();
  md.writeln('# NOVA TOTAL STATIC AUDIT');
  md.writeln();
  md.writeln('Build/run yapÄ±lmadÄ±. Bu rapor sadece kaynak kod taramasÄ±dÄ±r.');
  md.writeln();
  md.writeln('## Summary');
  md.writeln();
  md.writeln('- OK: $ok');
  md.writeln('- WARN: $warn');
  md.writeln('- FAIL: $fail');
  md.writeln('- INFO: $info');
  md.writeln('- Files scanned: ${files.length}');
  md.writeln();

  final priority = findings.where((f) => f.severity == 'FAIL' || f.severity == 'WARN').toList();
  md.writeln('## Priority Findings');
  md.writeln();
  if (priority.isEmpty) {
    md.writeln('No FAIL/WARN findings.');
  } else {
    for (final f in priority.take(250)) {
      md.writeln('- **${f.severity} [${f.category}]** `${f.file}:${f.line}` â€” ${f.message}');
      final safeSnippet = f.snippet.trim().replaceAll('`', "'");
      if (safeSnippet.isNotEmpty) md.writeln('  - `$safeSnippet`');
      if (f.recommendation.trim().isNotEmpty) md.writeln('  - Fix: ${f.recommendation}');
    }
  }

  md.writeln();
  md.writeln('## By System');
  for (final e in byCat.entries) {
    md.writeln();
    md.writeln('### ${e.key}');
    for (final f in e.value) {
      md.writeln('- ${f.severity} `${f.file}:${f.line}` ${f.message}');
      final safeSnippet = f.snippet.trim().replaceAll('`', "'");
      if (safeSnippet.isNotEmpty) md.writeln('  - `$safeSnippet`');
      if (f.recommendation.trim().isNotEmpty) md.writeln('  - Fix: ${f.recommendation}');
    }
  }

  File('${out.path}/NOVA_TOTAL_STATIC_AUDIT_REPORT.md').writeAsStringSync(md.toString());

  final json = {
    'summary': {
      'ok': ok,
      'warn': warn,
      'fail': fail,
      'info': info,
      'filesScanned': files.length,
    },
    'findings': findings.map((f) => f.toJson()).toList(),
  };
  File('${out.path}/nova_total_static_audit_report.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));

  for (final e in byCat.entries) {
    final safe = e.key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final buf = StringBuffer();
    for (final f in e.value) {
      buf.writeln('${f.severity} ${f.file}:${f.line} ${f.message}');
      if (f.snippet.trim().isNotEmpty) buf.writeln('  ${f.snippet.trim()}');
      if (f.recommendation.trim().isNotEmpty) buf.writeln('  FIX: ${f.recommendation}');
      buf.writeln();
    }
    File('${out.path}/system_$safe.txt').writeAsStringSync(buf.toString());
  }
}
