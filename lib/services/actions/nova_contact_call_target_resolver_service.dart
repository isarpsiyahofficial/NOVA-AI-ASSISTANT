// NOVA_LOCAL_CONTACT_CALL_TARGET_RESOLVER_V1
import '../../core/contacts/device_contact_entry.dart';
import '../contacts/nova_device_contacts_bridge_service.dart';

class NovaContactCallTargetResolution {
  final bool success;
  final String number;
  final String displayName;
  final bool fromContacts;
  final String message;

  const NovaContactCallTargetResolution({
    required this.success,
    this.number = '',
    this.displayName = '',
    this.fromContacts = false,
    required this.message,
  });
}

class NovaContactCallTargetResolverService {
  final NovaDeviceContactsBridgeService contactsBridge;

  const NovaContactCallTargetResolverService({
    this.contactsBridge = const NovaDeviceContactsBridgeService(),
  });

  Future<NovaContactCallTargetResolution> resolve(String rawTarget) async {
    final target = rawTarget.trim();
    if (target.isEmpty) {
      return const NovaContactCallTargetResolution(
        success: false,
        message: 'Aranacak kişi veya telefon numarası belirtilmedi.',
      );
    }

    final directNumber = normalizeDialNumber(target);
    if (directNumber.isNotEmpty) {
      return NovaContactCallTargetResolution(
        success: true,
        number: directNumber,
        displayName: directNumber,
        fromContacts: false,
        message: 'Kullanıcının söylediği telefon numarası çözüldü.',
      );
    }

    final permission = await contactsBridge.getPermissionStatus();
    if (!permission.granted) {
      return NovaContactCallTargetResolution(
        success: false,
        message: permission.message.trim().isNotEmpty
            ? permission.message.trim()
            : 'Kişiyi aramak için rehber okuma izni verilmemiş.',
      );
    }

    final fetched = await contactsBridge.fetchContacts();
    if (!fetched.success) {
      return NovaContactCallTargetResolution(
        success: false,
        message: fetched.message.trim().isNotEmpty
            ? fetched.message.trim()
            : 'Telefon rehberi okunamadı.',
      );
    }

    final queryVariants = _queryVariants(target);
    final exact = _uniqueUsableMatches(
      fetched.contacts.where(
        (contact) => queryVariants.contains(_normalizeName(contact.displayName)),
      ),
    );
    if (exact.length == 1) return _resolvedContact(exact.single);
    if (exact.length > 1) {
      return NovaContactCallTargetResolution(
        success: false,
        message:
            'Rehberde “$target” için birden fazla numara bulundu. Hangi kişiyi arayacağınızı netleştirin.',
      );
    }

    final prefix = _uniqueUsableMatches(
      fetched.contacts.where((contact) {
        final normalizedName = _normalizeName(contact.displayName);
        return queryVariants.any(
          (query) => normalizedName.startsWith(query) || query.startsWith(normalizedName),
        );
      }),
    );
    if (prefix.length == 1) return _resolvedContact(prefix.single);
    if (prefix.length > 1) {
      return NovaContactCallTargetResolution(
        success: false,
        message:
            'Rehberde “$target” sözüyle eşleşen birden fazla kişi var. Tam kişi adını söyleyin.',
      );
    }

    final contains = _uniqueUsableMatches(
      fetched.contacts.where((contact) {
        final normalizedName = _normalizeName(contact.displayName);
        return queryVariants.any(
          (query) => query.length >= 3 && normalizedName.contains(query),
        );
      }),
    );
    if (contains.length == 1) return _resolvedContact(contains.single);
    if (contains.length > 1) {
      return NovaContactCallTargetResolution(
        success: false,
        message:
            'Rehberde “$target” için birden fazla olası kişi bulundu. Tam adı söyleyin.',
      );
    }

    return NovaContactCallTargetResolution(
      success: false,
      message: 'Rehberde “$target” adına ait tek ve güvenilir bir kişi bulunamadı.',
    );
  }

  NovaContactCallTargetResolution _resolvedContact(DeviceContactEntry contact) {
    final number = normalizeDialNumber(contact.phoneNumber);
    if (number.isEmpty) {
      return NovaContactCallTargetResolution(
        success: false,
        message: '${contact.displayName} kişisinin kullanılabilir telefon numarası yok.',
      );
    }
    return NovaContactCallTargetResolution(
      success: true,
      number: number,
      displayName: contact.displayName.trim(),
      fromContacts: true,
      message: '${contact.displayName} kişisi yerel rehberden tek eşleşmeyle çözüldü.',
    );
  }

  List<DeviceContactEntry> _uniqueUsableMatches(
    Iterable<DeviceContactEntry> contacts,
  ) {
    final byNumber = <String, DeviceContactEntry>{};
    for (final contact in contacts) {
      final number = normalizeDialNumber(contact.phoneNumber);
      if (number.isEmpty) continue;
      byNumber.putIfAbsent(number, () => contact);
    }
    return byNumber.values.toList(growable: false);
  }

  Set<String> _queryVariants(String raw) {
    final base = _normalizeName(raw);
    final variants = <String>{if (base.isNotEmpty) base};
    var current = base;

    for (final suffix in const <String>['yi', 'yı', 'yu', 'yü', 'i', 'ı', 'u', 'ü']) {
      if (current.length > suffix.length + 2 && current.endsWith(suffix)) {
        current = current.substring(0, current.length - suffix.length);
        variants.add(current);
        break;
      }
    }

    for (final suffix in const <String>['im', 'ım', 'um', 'üm', 'm']) {
      if (current.length > suffix.length + 2 && current.endsWith(suffix)) {
        variants.add(current.substring(0, current.length - suffix.length));
        break;
      }
    }

    return variants.where((value) => value.length >= 2).toSet();
  }

  String _normalizeName(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String normalizeDialNumber(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 15) return '';
    return hasPlus ? '+$digits' : digits;
  }
}
