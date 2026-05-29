// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:async';

import '../../core/self_repair/nova_runtime_health_snapshot.dart';
import 'nova_runtime_health_registry_service.dart';

class NovaModuleProbeStreamService {
  final _controller = StreamController<NovaRuntimeHealthSnapshot>.broadcast();

  NovaModuleProbeStreamService();

  Stream<NovaRuntimeHealthSnapshot> get stream => _controller.stream;

  void publishNow() {
    _controller.add(NovaRuntimeHealthRegistryService.instance.snapshot());
  }

  Future<void> dispose() => _controller.close();
}
