import 'package:flutter_test/flutter_test.dart';
import 'package:nova/core/contacts/device_contact_entry.dart';
import 'package:nova/services/actions/nova_contact_call_target_resolver_service.dart';
import 'package:nova/services/contacts/nova_device_contacts_bridge_service.dart';

class _FakeContactsBridge extends NovaDeviceContactsBridgeService {
  final bool granted;
  final List<DeviceContactEntry> contacts;

  const _FakeContactsBridge({
    required this.granted,
    this.contacts = const <DeviceContactEntry>[],
  });

  @override
  Future<DeviceContactsPermissionStatus> getPermissionStatus() async {
    return DeviceContactsPermissionStatus(
      granted: granted,
      permanentlyDenied: false,
      message: granted ? 'OK' : 'Kişiler izni kapalı.',
    );
  }

  @override
  Future<DeviceContactsFetchResult> fetchContacts() async {
    return DeviceContactsFetchResult(
      success: granted,
      contacts: contacts,
      message: granted ? 'OK' : 'Kişiler izni kapalı.',
    );
  }
}

void main() {
  group('Nova local contact call target resolver', () {
    test('resolves Turkish possessive phrase Annemi to Anne', () async {
      final resolver = NovaContactCallTargetResolverService(
        contactsBridge: const _FakeContactsBridge(
          granted: true,
          contacts: <DeviceContactEntry>[
            DeviceContactEntry(
              id: 'anne-1',
              displayName: 'Anne',
              phoneNumber: '+90 555 111 22 33',
            ),
          ],
        ),
      );

      final result = await resolver.resolve('Annemi');

      expect(result.success, isTrue);
      expect(result.fromContacts, isTrue);
      expect(result.displayName, 'Anne');
      expect(result.number, '+905551112233');
    });

    test('accepts a user-spoken direct number without reading contacts', () async {
      final resolver = NovaContactCallTargetResolverService(
        contactsBridge: const _FakeContactsBridge(granted: false),
      );

      final result = await resolver.resolve('+90 (555) 222 33 44');

      expect(result.success, isTrue);
      expect(result.fromContacts, isFalse);
      expect(result.number, '+905552223344');
    });

    test('blocks ambiguous contact matches', () async {
      final resolver = NovaContactCallTargetResolverService(
        contactsBridge: const _FakeContactsBridge(
          granted: true,
          contacts: <DeviceContactEntry>[
            DeviceContactEntry(
              id: 'ahmet-1',
              displayName: 'Ahmet',
              phoneNumber: '05550000001',
            ),
            DeviceContactEntry(
              id: 'ahmet-2',
              displayName: 'Ahmet',
              phoneNumber: '05550000002',
            ),
          ],
        ),
      );

      final result = await resolver.resolve('Ahmet');

      expect(result.success, isFalse);
      expect(result.message, contains('birden fazla'));
    });

    test('does not guess an unknown contact', () async {
      final resolver = NovaContactCallTargetResolverService(
        contactsBridge: const _FakeContactsBridge(
          granted: true,
          contacts: <DeviceContactEntry>[
            DeviceContactEntry(
              id: 'mehmet-1',
              displayName: 'Mehmet',
              phoneNumber: '05550000003',
            ),
          ],
        ),
      );

      final result = await resolver.resolve('Selin');

      expect(result.success, isFalse);
      expect(result.number, isEmpty);
      expect(result.message, contains('bulunamadı'));
    });
  });
}
