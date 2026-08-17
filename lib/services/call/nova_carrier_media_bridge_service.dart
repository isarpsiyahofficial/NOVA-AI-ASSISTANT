// NOVA_CARRIER_MEDIA_BRIDGE_CONTROL_V2
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/settings/nova_settings.dart';

class NovaCarrierBridgeResult {
  final bool success;
  final int statusCode;
  final String message;
  final Map<String, dynamic> data;

  const NovaCarrierBridgeResult({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data = const <String, dynamic>{},
  });
}

class NovaCarrierMediaBridgeService {
  final Duration timeout;

  const NovaCarrierMediaBridgeService({
    this.timeout = const Duration(seconds: 12),
  });

  Future<NovaCarrierBridgeResult> health(NovaSettings settings) {
    return _request(settings, method: 'GET', path: '/health');
  }

  Future<NovaCarrierBridgeResult> latestSession(NovaSettings settings) {
    return _request(settings, method: 'GET', path: '/sessions/latest');
  }

  Future<NovaCarrierBridgeResult> syncContactPolicy({
    required NovaSettings settings,
    required String phoneNumber,
    required String contactName,
    String greeting = '',
    List<String> allowedTopics = const <String>[],
    List<String> forbiddenTopics = const <String>[],
    bool ownerApproved = false,
  }) {
    return _request(
      settings,
      method: 'POST',
      path: '/policies',
      requireControlToken: true,
      body: <String, dynamic>{
        'phone_number': phoneNumber.trim(),
        'contact_name': contactName.trim(),
        'greeting': greeting.trim(),
        'allowed_topics': allowedTopics,
        'forbidden_topics': forbiddenTopics,
        'owner_approved': ownerApproved,
      },
    );
  }

  Future<NovaCarrierBridgeResult> startOwnerApprovedOutboundCall({
    required NovaSettings settings,
    required String phoneNumber,
    required String contactName,
    String greeting = '',
    List<String> allowedTopics = const <String>[],
    List<String> forbiddenTopics = const <String>[],
  }) {
    return _request(
      settings,
      method: 'POST',
      path: '/calls/outbound',
      requireControlToken: true,
      body: <String, dynamic>{
        'to': phoneNumber.trim(),
        'owner_approved': true,
        'contact_name': contactName.trim(),
        'greeting': greeting.trim(),
        'allowed_topics': allowedTopics,
        'forbidden_topics': forbiddenTopics,
      },
    );
  }

  Future<NovaCarrierBridgeResult> _request(
    NovaSettings settings, {
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool requireControlToken = false,
  }) async {
    if (!settings.carrierBridgeEnabled) {
      return const NovaCarrierBridgeResult(
        success: false,
        statusCode: 0,
        message: 'Carrier medya köprüsü ayarlarda kapalı.',
      );
    }
    final baseUri = Uri.tryParse(settings.carrierBridgeBaseUrl.trim());
    if (baseUri == null || !baseUri.hasScheme || baseUri.host.isEmpty) {
      return const NovaCarrierBridgeResult(
        success: false,
        statusCode: 0,
        message: 'Carrier medya köprüsü adresi geçersiz.',
      );
    }
    final localDebugHost = <String>{
      'localhost',
      '127.0.0.1',
      '10.0.2.2',
    }.contains(baseUri.host.toLowerCase());
    if (baseUri.scheme.toLowerCase() != 'https' &&
        !(kDebugMode && localDebugHost)) {
      return const NovaCarrierBridgeResult(
        success: false,
        statusCode: 0,
        message: 'Üretim carrier köprüsü yalnız HTTPS üzerinden kullanılabilir.',
      );
    }
    final token = settings.carrierBridgeControlToken.trim();
    if (requireControlToken && token.length < 24) {
      return const NovaCarrierBridgeResult(
        success: false,
        statusCode: 0,
        message: 'Carrier kontrol anahtarı eksik veya çok kısa.',
      );
    }

    final normalizedBasePath =
        baseUri.path.replaceFirst(RegExp(r'/+$'), '');
    final uri = baseUri.replace(
      path: '$normalizedBasePath$path',
      query: null,
      fragment: null,
    );
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      late final HttpClientRequest request;
      if (method == 'POST') {
        request = await client.postUrl(uri).timeout(timeout);
      } else if (method == 'GET') {
        request = await client.getUrl(uri).timeout(timeout);
      } else {
        throw UnsupportedError('Unsupported bridge method: $method');
      }
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(timeout);
      final raw = await utf8.decodeStream(response).timeout(timeout);
      Map<String, dynamic> data = const <String, dynamic>{};
      if (raw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) data = Map<String, dynamic>.from(decoded);
        } catch (_) {
          final end = raw.length > 500 ? 500 : raw.length;
          data = <String, dynamic>{'raw': raw.substring(0, end)};
        }
      }
      final success = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['error'] == null;
      return NovaCarrierBridgeResult(
        success: success,
        statusCode: response.statusCode,
        message: success
            ? data['message']?.toString().trim().isNotEmpty == true
                ? data['message'].toString().trim()
                : 'Carrier medya köprüsü yanıt verdi.'
            : data['error']?.toString().trim().isNotEmpty == true
                ? data['error'].toString().trim()
                : 'Carrier medya köprüsü HTTP ${response.statusCode} hatası verdi.',
        data: data,
      );
    } on SocketException catch (error) {
      return NovaCarrierBridgeResult(
        success: false,
        statusCode: 0,
        message: 'Carrier medya köprüsüne bağlanılamadı: ${error.message}',
      );
    } on TimeoutException {
      return const NovaCarrierBridgeResult(
        success: false,
        statusCode: 0,
        message: 'Carrier medya köprüsü zamanında yanıt vermedi.',
      );
    } catch (error) {
      return NovaCarrierBridgeResult(
        success: false,
        statusCode: 0,
        message: 'Carrier medya köprüsü isteği başarısız: $error',
      );
    } finally {
      client.close(force: true);
    }
  }
}
