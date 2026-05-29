// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/services.dart';

import '../../core/contacts/phone_number_normalizer.dart';

class NovaCallStateSnapshot {
  final bool inCall;
  final String? activeNumber;
  final String state;
  final bool isRinging;
  final bool isActiveCall;
  final bool canAnswer;
  final bool canDisconnect;
  final bool canMute;
  final bool isMuted;
  final bool isSpeakerOn;

  const NovaCallStateSnapshot({
    required this.inCall,
    required this.activeNumber,
    required this.state,
    required this.isRinging,
    required this.isActiveCall,
    required this.canAnswer,
    required this.canDisconnect,
    required this.canMute,
    required this.isMuted,
    required this.isSpeakerOn,
  });

  factory NovaCallStateSnapshot.fromMap(Map<String, dynamic> map) {
    final rawNumber = (map['number'] as String?)?.trim();
    final normalized = rawNumber == null || rawNumber.isEmpty
        ? null
        : PhoneNumberNormalizer.normalize(rawNumber);

    final rawState = (map['state'] as String? ?? 'idle').trim().toLowerCase();

    final ringing = map['isRinging'] as bool? ?? rawState == 'ringing';
    final activeCall =
        map['isActiveCall'] as bool? ??
        rawState == 'active' ||
            rawState == 'connecting' ||
            rawState == 'dialing' ||
            rawState == 'holding';

    final inCallValue = map['inCall'] as bool? ?? (ringing || activeCall);

    return NovaCallStateSnapshot(
      inCall: inCallValue,
      activeNumber: (normalized == null || normalized.isEmpty)
          ? null
          : normalized,
      state: rawState,
      isRinging: ringing,
      isActiveCall: activeCall,
      canAnswer: map['canAnswer'] as bool? ?? ringing,
      canDisconnect: map['canDisconnect'] as bool? ?? inCallValue,
      canMute: map['canMute'] as bool? ?? activeCall,
      isMuted: map['isMuted'] as bool? ?? false,
      isSpeakerOn: map['isSpeakerOn'] as bool? ?? false,
    );
  }

  factory NovaCallStateSnapshot.idle() {
    return const NovaCallStateSnapshot(
      inCall: false,
      activeNumber: null,
      state: 'idle',
      isRinging: false,
      isActiveCall: false,
      canAnswer: false,
      canDisconnect: false,
      canMute: false,
      isMuted: false,
      isSpeakerOn: false,
    );
  }

  bool get hasActiveNumber =>
      activeNumber != null && activeNumber!.trim().isNotEmpty;

  String get normalizedActiveNumber => activeNumber?.trim() ?? '';
}

class NovaCallStateService {
  static const MethodChannel _channel = MethodChannel('nova/call_state');

  const NovaCallStateService();

  Future<NovaCallStateSnapshot> getSnapshot() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('getCallState');

      if (raw is Map) {
        return NovaCallStateSnapshot.fromMap(Map<String, dynamic>.from(raw));
      }
    } on PlatformException {
      // Sessiz fallback
    } catch (_) {
      // Sessiz fallback
    }

    return NovaCallStateSnapshot.idle();
  }

  Future<bool> isInCall() async {
    final snapshot = await getSnapshot();
    return snapshot.inCall;
  }

  Future<String?> getActiveNumber() async {
    final snapshot = await getSnapshot();
    return snapshot.activeNumber;
  }
}
