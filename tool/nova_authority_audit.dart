import 'dart:io';

/// Nova authority audit.
///
/// This build-time scanner prevents silent regression back to fragmented AI/TTS
/// paths. Normal speech-producing AI must go through
/// NovaSingleBrainAuthorityService.handleInput(), and normal TTS must carry an
/// explicit authoritySource/authorityResponse/singleBrainApproved marker.
///
/// Usage from project root:
///   dart run tool/nova_authority_audit.dart
///
/// Exit code 1 means an unapproved bypass was found.
void main() {
  final root = Directory.current;
  final dartFiles = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('${Platform.pathSeparator}.dart_tool${Platform.pathSeparator}'))
      .where((f) => !f.path.contains('${Platform.pathSeparator}build${Platform.pathSeparator}'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final violations = <String>[];

  for (final file in dartFiles) {
    final path = file.path.replaceAll('\\', '/');
    final text = file.readAsStringSync();
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNo = i + 1;

      final directAi = RegExp(r'\b(_?novaAiService|aiService|_setupAiService)\.process\s*\(').hasMatch(line);
      if (directAi && !_isAllowedAiLine(path, line, lines, i)) {
        violations.add('$path:$lineNo direct AI bypass: ${line.trim()}');
      }

      final directTts = RegExp(r'\b(widget\.)?(_?ttsService|ttsService)\.speak\s*\(').hasMatch(line);
      if (directTts && !_isAllowedTtsBlock(path, lines, i)) {
        violations.add('$path:$lineNo direct TTS bypass: ${line.trim()}');
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('NOVA_AUTHORITY_AUDIT_OK: no unapproved AI/TTS bypass found.');
    return;
  }

  stderr.writeln('NOVA_AUTHORITY_AUDIT_FAILED: ${violations.length} bypass candidate(s) found.');
  for (final v in violations) {
    stderr.writeln(' - $v');
  }
  exitCode = 1;
}

bool _isAllowedAiLine(String path, String line, List<String> lines, int index) {
  final trimmed = line.trim();
  if (trimmed.startsWith('//')) return true;
  if (trimmed.contains('runAi:')) return true;
  if (_near(lines, index, 'NovaSingleBrainAuthorityService.instance.handleInput', before: 18, after: 18)) return true;
  if (_near(lines, index, 'decisionOnlyClassifier', before: 8, after: 8)) return true;
  // The core service is the implementation endpoint, not a caller.
  if (path.endsWith('/lib/core/ai/nova_ai_service.dart')) return true;
  return false;
}

bool _isAllowedTtsBlock(String path, List<String> lines, int index) {
  if (path.endsWith('/lib/services/tts/nova_tts_service.dart')) return true;
  if (path.endsWith('/lib/services/speech_runtime/nova_speech_runtime_service.dart')) {
    return _near(lines, index, 'NovaSingleBrainAuthorityService.instance.authorizeSpeech', before: 40, after: 8);
  }
  final block = _block(lines, index, maxLines: 18);
  if (block.contains('authoritySource:')) return true;
  if (block.contains('authorityResponse:')) return true;
  if (block.contains('singleBrainApproved:')) return true;
  if (block.contains('allowSecuritySpeech:')) return true;
  return false;
}

String _block(List<String> lines, int index, {required int maxLines}) {
  final buf = StringBuffer();
  for (var i = index; i < lines.length && i < index + maxLines; i++) {
    buf.writeln(lines[i]);
    if (lines[i].contains(');')) break;
  }
  return buf.toString();
}

bool _near(List<String> lines, int index, String needle, {required int before, required int after}) { ? final start = index - before < 0  0 : index - before;
  final end = index + after >= lines.length ? lines.length - 1 : index + after;
  for (var i = start; i <= end; i++) {
    if (lines[i].contains(needle)) return true;
  }
  return false;
}
