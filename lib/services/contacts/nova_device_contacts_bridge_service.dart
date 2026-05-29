// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/services.dart';

import '../../core/contacts/device_contact_entry.dart';

class DeviceContactsPermissionStatus {
  final bool granted;
  final bool permanentlyDenied;
  final String message;

  const DeviceContactsPermissionStatus({
    required this.granted,
    required this.permanentlyDenied,
    required this.message,
  });
}

class DeviceContactsFetchResult {
  final bool success;
  final List<DeviceContactEntry> contacts;
  final String message;

  const DeviceContactsFetchResult({
    required this.success,
    required this.contacts,
    required this.message,
  });
}

class NovaDeviceContactsBridgeService {
  static const MethodChannel _channel = MethodChannel(
    'nova/device_contacts_bridge',
  );

  const NovaDeviceContactsBridgeService();

  Future<DeviceContactsPermissionStatus> getPermissionStatus() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'getContactsPermissionStatus',
      );

      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        return DeviceContactsPermissionStatus(
          granted: map['granted'] as bool? ?? false,
          permanentlyDenied: map['permanentlyDenied'] as bool? ?? false,
          message: (map['message'] as String? ?? '').trim(),
        );
      }
    } on PlatformException catch (e) {
      return DeviceContactsPermissionStatus(
        granted: false,
        permanentlyDenied: false,
        message: e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Kişi izni durumu alınamadı.',
      );
    } catch (_) {
      return const DeviceContactsPermissionStatus(
        granted: false,
        permanentlyDenied: false,
        message: 'Kişi izni durumu alınamadı.',
      );
    }

    return const DeviceContactsPermissionStatus(
      granted: false,
      permanentlyDenied: false,
      message: 'Kişi izni durumu alınamadı.',
    );
  }

  Future<DeviceContactsPermissionStatus> requestPermission() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'requestContactsPermission',
      );

      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        return DeviceContactsPermissionStatus(
          granted: map['granted'] as bool? ?? false,
          permanentlyDenied: map['permanentlyDenied'] as bool? ?? false,
          message: (map['message'] as String? ?? '').trim(),
        );
      }
    } on PlatformException catch (e) {
      return DeviceContactsPermissionStatus(
        granted: false,
        permanentlyDenied: false,
        message: e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Kişi izni istenemedi.',
      );
    } catch (_) {
      return const DeviceContactsPermissionStatus(
        granted: false,
        permanentlyDenied: false,
        message: 'Kişi izni istenemedi.',
      );
    }

    return const DeviceContactsPermissionStatus(
      granted: false,
      permanentlyDenied: false,
      message: 'Kişi izni istenemedi.',
    );
  }

  Future<bool> openAppSettings() async {
    try {
      final ok = await _channel.invokeMethod<bool>('openAppSettings');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<DeviceContactsFetchResult> fetchContacts() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('fetchDeviceContacts');

      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final items = ((map['contacts'] as List?) ?? const <dynamic>[])
            .whereType<Map>()
            .map(
              (e) => DeviceContactEntry.fromMap(Map<String, dynamic>.from(e)),
            )
            .where((e) => e.hasUsablePhoneNumber && e.hasUsableDisplayName)
            .toList(growable: false);

        return DeviceContactsFetchResult(
          success: map['success'] as bool? ?? false,
          contacts: items,
          message: (map['message'] as String? ?? '').trim(),
        );
      }
    } on PlatformException catch (e) {
      return DeviceContactsFetchResult(
        success: false,
        contacts: const <DeviceContactEntry>[],
        message: e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Telefon kişileri alınamadı.',
      );
    } catch (_) {
      return const DeviceContactsFetchResult(
        success: false,
        contacts: <DeviceContactEntry>[],
        message: 'Telefon kişileri alınamadı.',
      );
    }

    return const DeviceContactsFetchResult(
      success: false,
      contacts: <DeviceContactEntry>[],
      message: 'Telefon kişileri alınamadı.',
    );
  }
}
