// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/contacts/contact_role.dart';
import '../../core/contacts/device_contact_entry.dart';
import '../../core/contacts/nova_contact.dart';
import '../../core/contacts/phone_number_normalizer.dart';
import 'nova_device_contacts_bridge_service.dart';

class NovaContactSyncResult {
  final List<NovaContact> contacts;
  final String message;

  const NovaContactSyncResult({required this.contacts, required this.message});
}

class NovaContactService {
  static const String _storageKey = 'nova_contacts_v1';

  const NovaContactService();

  Future<List<NovaContact>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) return const <NovaContact>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <NovaContact>[];
      return decoded
          .whereType<Map>()
          .map((e) => NovaContact.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <NovaContact>[];
    }
  }

  Future<void> _save(List<NovaContact> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(items.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {}
  }

  Future<List<NovaContact>> loadContacts() async => _load();

  Future<List<DeviceContactEntry>> fetchSelectableDeviceContacts() async {
    const bridge = NovaDeviceContactsBridgeService();
    final permission = await bridge.getPermissionStatus();
    final effectivePermission = permission.granted
        ? permission
        : await bridge.requestPermission();

    if (!effectivePermission.granted) {
      return const <DeviceContactEntry>[];
    }

    final fetched = await bridge.fetchContacts();
    if (!fetched.success || fetched.contacts.isEmpty) {
      return const <DeviceContactEntry>[];
    }

    return fetched.contacts;
  }

  Future<NovaContactSyncResult> mergeSelectedDeviceContacts(
    List<DeviceContactEntry> selectedEntries,
  ) async {
    final existing = await _load();
    if (selectedEntries.isEmpty) {
      return NovaContactSyncResult(
        contacts: existing,
        message: 'Seçili kişi bulunmadığı için rehber değişikliği yapılmadı.',
      );
    }

    final Map<String, NovaContact> byPhone = <String, NovaContact>{
      for (final item in existing)
        PhoneNumberNormalizer.normalize(item.phoneNumber): item,
    };

    final List<NovaContact> merged = <NovaContact>[];
    for (final entry in selectedEntries) {
      final normalized = PhoneNumberNormalizer.normalize(entry.phoneNumber);
      if (normalized.isEmpty) continue;
      final current = byPhone[normalized];
      merged.add(
        NovaContact(
          id:
              current?.id ??
              (entry.id.trim().isEmpty ? normalized : entry.id.trim()),
          displayName: entry.displayName.trim(),
          phoneNumber: entry.phoneNumber.trim(),
          role: current?.role ?? _inferRole(entry.displayName),
          customRoleLabel: current?.customRoleLabel,
          isVoiceKnown: current?.isVoiceKnown ?? false,
          relationshipLabel:
              current?.relationshipLabel ??
              _inferRelationshipLabel(entry.displayName),
          closenessLevel: current?.closenessLevel ?? 'normal',
          isAuthorizedToUseNova: current?.isAuthorizedToUseNova ?? false,
          canReceiveAutoCallHandling:
              current?.canReceiveAutoCallHandling ?? false,
          linkedVoiceId: current?.linkedVoiceId ?? '',
          persistentOwnerMessage: current?.persistentOwnerMessage ?? '',
          callOpeningInstruction: current?.callOpeningInstruction ?? '',
          expectedCallerQuestions: current?.expectedCallerQuestions ?? '',
          allowedResponseScope: current?.allowedResponseScope ?? '',
          blockedResponseScope: current?.blockedResponseScope ?? '',
          emergencyInstruction: current?.emergencyInstruction ?? '',
          whiteLieInstruction: current?.whiteLieInstruction ?? '',
          quickReplyInstruction: current?.quickReplyInstruction ?? '',
          callOpeningInstructionMode:
              current?.callOpeningInstructionMode ??
              ContactInstructionMode.customInstruction,
          expectedCallerQuestionsMode:
              current?.expectedCallerQuestionsMode ??
              ContactInstructionMode.customInstruction,
          allowedResponseScopeMode:
              current?.allowedResponseScopeMode ??
              ContactInstructionMode.customInstruction,
          blockedResponseScopeMode:
              current?.blockedResponseScopeMode ??
              ContactInstructionMode.customInstruction,
          emergencyInstructionMode:
              current?.emergencyInstructionMode ??
              ContactInstructionMode.customInstruction,
          whiteLieInstructionMode:
              current?.whiteLieInstructionMode ??
              ContactInstructionMode.customInstruction,
          quickReplyInstructionMode:
              current?.quickReplyInstructionMode ??
              ContactInstructionMode.customInstruction,
          allowEmergencyWake: current?.allowEmergencyWake ?? false,
          autoTakeNotes: current?.autoTakeNotes ?? false,
          allowNightAutoCall: current?.allowNightAutoCall ?? false,
          preferSpeakerMode: current?.preferSpeakerMode ?? true,
          allowNovaSmallTalk: current?.allowNovaSmallTalk ?? true,
          isProtectedIdentity: current?.isProtectedIdentity ?? false,
        ),
      );
    }

    final untouched = existing
        .where((item) {
          final normalized = PhoneNumberNormalizer.normalize(item.phoneNumber);
          return merged.every(
            (e) => PhoneNumberNormalizer.normalize(e.phoneNumber) != normalized,
          );
        })
        .toList(growable: false);

    final next = <NovaContact>[...merged, ...untouched];
    await _save(next);
    return NovaContactSyncResult(
      contacts: next,
      message:
          '${merged.length} seçili rehber kişisi eklendi ya da güncellendi.',
    );
  }

  Future<NovaContactSyncResult> syncFromDeviceContacts() async {
    final existing = await _load();
    const bridge = NovaDeviceContactsBridgeService();
    final permission = await bridge.getPermissionStatus();
    final effectivePermission = permission.granted
        ? permission
        : await bridge.requestPermission();

    if (!effectivePermission.granted) {
      return NovaContactSyncResult(
        contacts: existing,
        message: effectivePermission.message.trim().isEmpty
            ? 'Rehber izni verilmediği için mevcut kişi havuzu korundu.'
            : effectivePermission.message.trim(),
      );
    }

    final fetched = await bridge.fetchContacts();
    if (!fetched.success || fetched.contacts.isEmpty) {
      return NovaContactSyncResult(
        contacts: existing,
        message: fetched.message.trim().isEmpty
            ? 'Telefon rehberinde alınabilir kişi bulunamadı; mevcut kişi havuzu korundu.'
            : fetched.message.trim(),
      );
    }

    final Map<String, NovaContact> byPhone = <String, NovaContact>{
      for (final item in existing)
        PhoneNumberNormalizer.normalize(item.phoneNumber): item,
    };

    final List<NovaContact> merged = <NovaContact>[];
    for (final entry in fetched.contacts) {
      final normalized = PhoneNumberNormalizer.normalize(entry.phoneNumber);
      if (normalized.isEmpty) continue;
      final current = byPhone[normalized];
      merged.add(
        NovaContact(
          id:
              current?.id ??
              (entry.id.trim().isEmpty ? normalized : entry.id.trim()),
          displayName: entry.displayName.trim(),
          phoneNumber: entry.phoneNumber.trim(),
          role: current?.role ?? _inferRole(entry.displayName),
          customRoleLabel: current?.customRoleLabel,
          isVoiceKnown: current?.isVoiceKnown ?? false,
          relationshipLabel:
              current?.relationshipLabel ??
              _inferRelationshipLabel(entry.displayName),
          closenessLevel: current?.closenessLevel ?? 'normal',
          isAuthorizedToUseNova: current?.isAuthorizedToUseNova ?? false,
          canReceiveAutoCallHandling:
              current?.canReceiveAutoCallHandling ?? false,
          linkedVoiceId: current?.linkedVoiceId ?? '',
          persistentOwnerMessage: current?.persistentOwnerMessage ?? '',
          callOpeningInstruction: current?.callOpeningInstruction ?? '',
          expectedCallerQuestions: current?.expectedCallerQuestions ?? '',
          allowedResponseScope: current?.allowedResponseScope ?? '',
          blockedResponseScope: current?.blockedResponseScope ?? '',
          emergencyInstruction: current?.emergencyInstruction ?? '',
          whiteLieInstruction: current?.whiteLieInstruction ?? '',
          quickReplyInstruction: current?.quickReplyInstruction ?? '',
          callOpeningInstructionMode:
              current?.callOpeningInstructionMode ??
              ContactInstructionMode.customInstruction,
          expectedCallerQuestionsMode:
              current?.expectedCallerQuestionsMode ??
              ContactInstructionMode.customInstruction,
          allowedResponseScopeMode:
              current?.allowedResponseScopeMode ??
              ContactInstructionMode.customInstruction,
          blockedResponseScopeMode:
              current?.blockedResponseScopeMode ??
              ContactInstructionMode.customInstruction,
          emergencyInstructionMode:
              current?.emergencyInstructionMode ??
              ContactInstructionMode.customInstruction,
          whiteLieInstructionMode:
              current?.whiteLieInstructionMode ??
              ContactInstructionMode.customInstruction,
          quickReplyInstructionMode:
              current?.quickReplyInstructionMode ??
              ContactInstructionMode.customInstruction,
          allowEmergencyWake: current?.allowEmergencyWake ?? false,
          autoTakeNotes: current?.autoTakeNotes ?? false,
          preferSpeakerMode: current?.preferSpeakerMode ?? true,
          allowNovaSmallTalk: current?.allowNovaSmallTalk ?? true,
          isProtectedIdentity: current?.isProtectedIdentity ?? false,
        ),
      );
    }

    final Set<String> syncedPhones = merged
        .map((e) => PhoneNumberNormalizer.normalize(e.phoneNumber))
        .where((e) => e.isNotEmpty)
        .toSet();
    final preservedManualOnly = existing
        .where(
          (e) => !syncedPhones.contains(
            PhoneNumberNormalizer.normalize(e.phoneNumber),
          ),
        )
        .toList(growable: false);

    final next = <NovaContact>[...merged, ...preservedManualOnly];
    await _save(next);
    return NovaContactSyncResult(
      contacts: next,
      message:
          '${merged.length} rehber kişisi alındı, ${preservedManualOnly.length} mevcut özel kayıt korundu.',
    );
  }

  Future<List<NovaContact>> addContact(NovaContact contact) async {
    final items = await _load();
    final next = <NovaContact>[
      contact,
      ...items.where((e) => e.id != contact.id),
    ];
    await _save(next);
    return next;
  }

  Future<List<NovaContact>> updateContact(NovaContact contact) async {
    final items = await _load();
    final next = items
        .map((e) {
          if (e.id != contact.id) return e;
          if (e.isProtectedIdentity) {
            return contact.copyWith(
              isProtectedIdentity: true,
              isAuthorizedToUseNova: true,
            );
          }
          return contact;
        })
        .toList(growable: false);
    await _save(next);
    return next;
  }

  Future<List<NovaContact>> removeContact(String id) async {
    final items = await _load();
    final next = items
        .where((e) => e.id != id || e.isProtectedIdentity)
        .toList(growable: false);
    await _save(next);
    return next;
  }

  Future<NovaContact?> findByLinkedVoiceId(String voiceId) async {
    final id = voiceId.trim();
    if (id.isEmpty) return null;
    final items = await _load();
    for (final item in items) {
      if (item.linkedVoiceId == id) return item;
    }
    return null;
  }

  Future<NovaContact?> findByPhoneNumber(String phoneNumber) async {
    final normalized = PhoneNumberNormalizer.normalize(phoneNumber);
    if (normalized.isEmpty) return null;
    final items = await _load();
    for (final item in items) {
      if (PhoneNumberNormalizer.normalize(item.phoneNumber) == normalized) {
        return item;
      }
    }
    return null;
  }

  Future<List<NovaContact>> grantNovaAuthority(
    String id, {
    bool callHandling = false,
  }) async {
    final items = await _load();
    final updated = items
        .map((e) {
          if (e.id != id) return e;
          return e.copyWith(
            isAuthorizedToUseNova: true,
            canReceiveAutoCallHandling: callHandling
                ? true
                : e.canReceiveAutoCallHandling,
          );
        })
        .toList(growable: false);
    await _save(updated);
    return updated;
  }

  Future<List<NovaContact>> revokeNovaAuthority(String id) async {
    final items = await _load();
    final updated = items
        .map((e) {
          if (e.id != id) return e;
          if (e.isProtectedIdentity)
            return e.copyWith(isAuthorizedToUseNova: true);
          return e.copyWith(isAuthorizedToUseNova: false);
        })
        .toList(growable: false);
    await _save(updated);
    return updated;
  }

  Future<List<NovaContact>> setCallHandlingAuthority(
    String id,
    bool enabled,
  ) async {
    final items = await _load();
    final updated = items
        .map((e) {
          if (e.id != id) return e;
          return e.copyWith(canReceiveAutoCallHandling: enabled);
        })
        .toList(growable: false);
    await _save(updated);
    return updated;
  }

  ContactRole _inferRole(String displayName) {
    final normalized = displayName.trim().toLowerCase();
    if (normalized.isEmpty) return ContactRole.friend;
    if (_containsAny(normalized, const ['anne', 'annem', 'mama']))
      return ContactRole.mother;
    if (_containsAny(normalized, const ['baba', 'babam', 'peder']))
      return ContactRole.father;
    if (_containsAny(normalized, const [
      'eş',
      'es',
      'eşim',
      'esim',
      'karım',
      'karim',
      'kocam',
      'hanım',
      'hanim',
      'kalbim',
      'aşkım',
      'askim',
      'sevgilim',
      'hayatım',
      'hayatim',
      'canım',
      'canim',
    ]))
      return ContactRole.spouse;
    if (_containsAny(normalized, const [
      'abi',
      'erkek kardeş',
      'erkek kardes',
      'ağabey',
      'agabey',
      'kardesim',
    ]))
      return ContactRole.brother;
    if (_containsAny(normalized, const ['abla', 'kız kardeş', 'kiz kardes']))
      return ContactRole.sister;
    if (_containsAny(normalized, const [
      'oğlum',
      'oglum',
      'kızım',
      'kizim',
      'çocuk',
      'cocuk',
    ]))
      return ContactRole.child;
    if (_containsAny(normalized, const [
      'amca',
      'hala',
      'teyze',
      'dayı',
      'dayi',
      'kuzen',
    ]))
      return ContactRole.relative;
    return ContactRole.friend;
  }

  String _inferRelationshipLabel(String displayName) {
    final role = _inferRole(displayName);
    switch (role) {
      case ContactRole.mother:
        return 'anne';
      case ContactRole.father:
        return 'baba';
      case ContactRole.brother:
        return 'abi';
      case ContactRole.sister:
        return 'abla';
      case ContactRole.spouse:
        return 'eş';
      case ContactRole.child:
        return 'çocuk';
      case ContactRole.relative:
        return 'akraba';
      case ContactRole.friend:
      case ContactRole.custom:
        return '';
    }
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }
}
