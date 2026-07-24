import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova/core/settings/nova_settings.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('NOVA carrier media bridge', () {
    test('carrier settings survive map serialization without losing state', () {
      const settings = NovaSettings(
        carrierBridgeEnabled: true,
        carrierBridgeBaseUrl: 'https://calls.example.test',
        carrierBridgeControlToken: '12345678901234567890123456789012',
      );

      final restored = NovaSettings.fromMap(settings.toMap());

      expect(restored.carrierBridgeEnabled, isTrue);
      expect(restored.carrierBridgeBaseUrl, 'https://calls.example.test');
      expect(
        restored.carrierBridgeControlToken,
        '12345678901234567890123456789012',
      );
    });

    test('serialized preferences explicitly remove the bridge secret', () {
      final service = _read('lib/services/settings/nova_settings_service.dart');
      final tokenStore = _read('lib/core/api/nova_secure_token_store.dart');

      expect(service, contains("'carrierBridgeControlToken': ''"));
      expect(service, contains('carrierBridgeTokenName'));
      expect(tokenStore, contains('readNamed'));
      expect(tokenStore, contains('writeNamed'));
    });

    test('production bridge control is HTTPS and owner-approval gated', () {
      final dart = _read(
        'lib/services/call/nova_carrier_media_bridge_service.dart',
      );
      final control = _read(
        'infra/call-bridge/control_gateway/service.py',
      );

      expect(dart, contains("baseUri.scheme.toLowerCase() != 'https'"));
      expect(dart, contains("'owner_approved': true"));
      expect(dart, contains("path: '/calls/outbound'"));
      expect(dart, contains('Bearer \$token'));
      expect(control, contains('owner_approved=true is required'));
      expect(control, contains('Action": "Originate"'));
      expect(control, contains('NOVA_ASTERISK_AMI_SECRET'));
    });

    test('call media path has real bidirectional PCM and evidence', () {
      final media = _read('infra/call-bridge/media_gateway/service.py');
      final dialplan = _read(
        'infra/call-bridge/asterisk/config/extensions.conf',
      );
      final workflow = _read(
        '.github/workflows/nova-call-bridge-e2e.yml',
      );

      expect(media, contains('transcribe_8k_pcm'));
      expect(media, contains('synthesize_8k_pcm'));
      expect(media, contains('await self.send_pcm(writer, outgoing)'));
      expect(media, contains('incoming_rms'));
      expect(media, contains('outgoing_rms'));
      expect(dialplan, contains('AudioSocket('));
      expect(dialplan, contains('[from-nova-carrier]'));
      expect(workflow, contains('Run real AudioSocket call'));
    });
  });
}
