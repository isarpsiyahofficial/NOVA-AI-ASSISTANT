// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/services.dart';

class NovaFaissBridgeService {
  static const MethodChannel _channel = MethodChannel('nova/faiss_bridge');

  const NovaFaissBridgeService();

  Future<bool> isAvailable() async {
    final value = await _channel.invokeMethod<bool>('isAvailable');
    return value ?? false;
  }

  Future<bool> createIndex({
    required int dimension,
    bool useCosine = true,
  }) async {
    final map = await _channel.invokeMapMethod<String, dynamic>(
      'createIndex',
      <String, dynamic>{'dimension': dimension, 'useCosine': useCosine},
    );
    return map?['success'] == true;
  }

  Future<void> replaceAll(List<Map<String, Object?>> items) async {
    await _channel.invokeMethod('replaceAll', <String, dynamic>{
      'items': items,
    });
  }

  Future<List<Map<String, dynamic>>> search({
    required List<double> query,
    required int k,
  }) async {
    final raw = await _channel.invokeMethod<List<dynamic>>(
      'search',
      <String, dynamic>{'query': query, 'k': k},
    );
    if (raw == null) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }
}
