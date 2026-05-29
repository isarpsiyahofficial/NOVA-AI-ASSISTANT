import 'dart:io';

void main() {
  final file = File('tool/nova_full_native_lib_audit.dart');
  if (!file.existsSync()) {
    stderr.writeln('ERROR: tool/nova_full_native_lib_audit.dart bulunamadÄ±.');
    exit(1);
  }

  final original = file.readAsStringSync();
  final lines = original.split('\n');
  final out = <String>[];
  var changed = 0;

  const safeHitLine =
      "    final hit = RegExp(r'''\\b(aiService\\.process|_novaAiService\\.process|_setupAiService\\.process|mainAiService\\.process|localModelService\\.generate|modelBridge\\.generate|ModelBridge\\.generate|invokeMethod\\([\"']askAI[\"']|AiRequest\\(|systemPrompt)\\b''').firstMatch(text);";

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.contains('final hit = RegExp(') && line.contains('askAI')) {
      out.add(safeHitLine);
      changed++;
      while (i + 1 < lines.length && lines[i + 1].contains('.firstMatch(text)')) {
        i++;
      }
      continue;
    }

    if (line.contains('invokeMethod') && line.contains('askAI') && !line.contains('final hit = RegExp(')) {
      final indent = line.substring(0, line.length - line.trimLeft().length);
      out.add("\${indent}r'''invokeMethod\\([\"']askAI[\"']''',");
      changed++;
      continue;
    }

    out.add(line);
  }

  file.writeAsStringSync(out.join('\n'));

  stdout.writeln('PATCHED tool/nova_full_native_lib_audit.dart askAI regex/string hotfix. changed=\$changed');
  stdout.writeln('Åimdi Ã§alÄ±ÅŸtÄ±r:');
  stdout.writeln('  flutter analyze');
  stdout.writeln('  dart run tool/nova_full_native_lib_audit.dart --build --strict');
}
