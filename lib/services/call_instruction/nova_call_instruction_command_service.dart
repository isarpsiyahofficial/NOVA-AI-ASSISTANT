// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

import '../../core/call_instruction/nova_call_instruction.dart';
import '../../core/contacts/contact_role.dart';
import '../../core/contacts/nova_contact.dart';

class NovaCallInstructionParseResult {
  final bool handled;
  final bool success;
  final String spokenText;
  final NovaCallInstructionDraft? draft;

  const NovaCallInstructionParseResult({
    required this.handled,
    required this.success,
    String spokenText = '',
    this.draft,
  }) : spokenText = '';

  const NovaCallInstructionParseResult.unhandled()
    : handled = false,
      success = false,
      spokenText = '',
      draft = null;
}

class NovaCallInstructionCommandService {
  const NovaCallInstructionCommandService();

  NovaCallInstructionParseResult parse({
    required String raw,
    required List<NovaContact> contacts,
  }) {
    final text = raw.trim();
    if (text.isEmpty) return const NovaCallInstructionParseResult.unhandled();
    final n = _normalize(text);
    final wantsCall =
        n.contains(' ara') ||
        n.startsWith('ara ') ||
        n.contains('aramani') ||
        n.contains('aramanı') ||
        n.contains('telefon et') ||
        n.contains('cagri ac') ||
        n.contains('çağrı aç');
    if (!wantsCall) return const NovaCallInstructionParseResult.unhandled();

    final contact = _findContact(text, contacts);
    if (contact == null) {
      return const NovaCallInstructionParseResult(
        handled: true,
        success: false,
        spokenText: '',
      );
    }

    if (!contact.canReceiveAutoCallHandling) {
      return NovaCallInstructionParseResult(
        handled: true,
        success: false,
        spokenText: '',
      );
    }

    final speakerPreferred =
        n.contains('hoparlor') ||
        n.contains('hoparlör') ||
        n.contains('hoparlore al') ||
        n.contains('hoparlöre al');
    final instructionText = _extractInstructionText(text);
    final recurrence = _detectRecurrence(n);
    final scheduledFor = _resolveWhen(n, DateTime.now());
    final type = recurrence == 'daily'
        ? NovaCallInstructionType.recurringDaily
        : scheduledFor.isBefore(DateTime.now().add(const Duration(minutes: 2)))
        ? NovaCallInstructionType.immediate
        : NovaCallInstructionType.scheduledOnce;

    return NovaCallInstructionParseResult(
      handled: true,
      success: true,
      spokenText: '',
      draft: NovaCallInstructionDraft(
        contact: contact,
        instructionText: instructionText,
        speakerPreferred: speakerPreferred,
        type: type,
        scheduledFor: scheduledFor,
        recurrenceLabel: recurrence,
      ),
    );
  }

  NovaContact? _findContact(String raw, List<NovaContact> contacts) {
    final n = _normalize(raw);
    NovaContact? best;
    double bestScore = 0;
    for (final contact in contacts) {
      final name = _normalize(contact.displayName);
      final relationship = _normalize(contact.relationshipLabel);
      final role = _normalize(_roleLabel(contact.role));
      final customRole = _normalize(contact.customRoleLabel ?? '');
      final phone = _normalize(contact.phoneNumber);
      if (name.isEmpty &&
          relationship.isEmpty &&
          customRole.isEmpty &&
          phone.isEmpty) {
        continue;
      }
      double score = 0;
      if (name.isNotEmpty && (n.contains(name) || name.contains(n))) {
        score += (name.length * 2.2);
      }
      for (final token in name.split(' ')) {
        if (token.isNotEmpty && n.contains(token)) score += token.length * 1.8;
      }
      for (final token in relationship.split(' ')) {
        if (token.isNotEmpty && n.contains(token)) score += token.length * 1.2;
      }
      for (final token in customRole.split(' ')) {
        if (token.isNotEmpty && n.contains(token)) score += token.length * 1.3;
      }
      for (final token in role.split(' ')) {
        if (token.isNotEmpty && n.contains(token)) score += token.length * 0.8;
      }
      if (phone.isNotEmpty && n.contains(phone)) score += 4;
      if (contact.isProtectedIdentity) score += 0.6;
      if (contact.canReceiveAutoCallHandling) score += 0.4;
      switch (contact.closenessLevel.trim().toLowerCase()) {
        case 'very_close':
          score += 0.45;
          break;
        case 'close':
          score += 0.25;
          break;
        case 'distant':
          score -= 0.10;
          break;
        default:
          break;
      }
      if (score > bestScore) {
        best = contact;
        bestScore = score;
      }
    }
    return bestScore >= 1.6 ? best : null;
  }

  String _extractInstructionText(String raw) {
    final lower = raw.toLowerCase();
    const explicitMarkers = <String>[
      'şunları söyle',
      'sunlari soyle',
      'şunu söyle',
      'sunu soyle',
      'de ki',
      'şunu ilet',
      'sunu ilet',
      'şunu sor',
      'sunu sor',
      'sor ki',
    ];
    for (final marker in explicitMarkers) {
      final idx = lower.indexOf(marker);
      if (idx >= 0) {
        final extracted = raw.substring(idx + marker.length).trim();
        if (extracted.isNotEmpty) {
          return extracted;
        }
      }
    }
    if (lower.contains('nerede olduğunu sor') ||
        lower.contains('nerede oldugunu sor')) {
      return 'Nerede olduğunu sor ve kısa bir not al.';
    }
    if (lower.contains('nasıl olduğunu sor') ||
        lower.contains('nasil oldugunu sor')) {
      return 'Nasıl olduğunu sor ve önemli bir not varsa kaydet.';
    }
    return 'Çağrı notu kullanıcı tarafından verilecek.';
  }

  String _detectRecurrence(String n) {
    if (n.contains('her gun') ||
        n.contains('her gün') ||
        n.contains('her sabah') ||
        n.contains('her aksam') ||
        n.contains('her akşam'))
      return 'daily';
    return '';
  }

  DateTime _resolveWhen(String n, DateTime now) {
    final hourMin = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(n);
    if (_detectRecurrence(n) == 'daily') {
      final defaultHour = n.contains('aksam') || n.contains('akşam') ? 20 : 9;
      final h = hourMin != null
          ? (int.tryParse(hourMin.group(1) ?? '') ?? defaultHour)
          : defaultHour;
      final m = hourMin != null
          ? (int.tryParse(hourMin.group(2) ?? '') ?? 0)
          : 0;
      return DateTime(now.year, now.month, now.day, h, m);
    }
    if (n.contains('1 hafta sonra') || n.contains('bir hafta sonra'))
      return now.add(const Duration(days: 7));
    if (n.contains('3 gun sonra') || n.contains('3 gün sonra'))
      return now.add(const Duration(days: 3));
    if (n.contains('2 gun sonra') || n.contains('2 gün sonra'))
      return now.add(const Duration(days: 2));
    if (n.contains('yarin') || n.contains('yarın')) {
      if (hourMin != null) {
        final h = int.tryParse(hourMin.group(1) ?? '') ?? 9;
        final m = int.tryParse(hourMin.group(2) ?? '') ?? 0;
        return DateTime(now.year, now.month, now.day + 1, h, m);
      }
      return now.add(const Duration(days: 1));
    }
    if (n.contains('simdi') ||
        n.contains('şimdi') ||
        n.contains('hemen') ||
        n.contains('anlik') ||
        n.contains('anlık')) {
      return now;
    }
    if (hourMin != null) {
      final h = int.tryParse(hourMin.group(1) ?? '') ?? now.hour;
      final m = int.tryParse(hourMin.group(2) ?? '') ?? now.minute;
      var dt = DateTime(now.year, now.month, now.day, h, m);
      if (!dt.isAfter(now)) dt = dt.add(const Duration(days: 1));
      return dt;
    }
    return now;
  }

  String _roleLabel(ContactRole role) {
    switch (role) {
      case ContactRole.mother:
        return 'Anne';
      case ContactRole.father:
        return 'Baba';
      case ContactRole.brother:
        return 'Abi Erkek Kardeş';
      case ContactRole.sister:
        return 'Abla Kız Kardeş';
      case ContactRole.spouse:
        return 'Eş';
      case ContactRole.child:
        return 'Çocuk';
      case ContactRole.friend:
        return 'Arkadaş';
      case ContactRole.relative:
        return 'Akraba';
      case ContactRole.custom:
        return 'Özel';
    }
  }

  String _normalize(String raw) => raw
      .toLowerCase()
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u')
      .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
