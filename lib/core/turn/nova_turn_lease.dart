// NOVA_TURN_LEASE_V1
import 'dart:math';

class NovaTurnLease {
  final String id;
  final String sessionId;
  final int sequence;
  final int issuedAtEpochMs;
  final int expiresAtEpochMs;

  const NovaTurnLease({
    required this.id,
    required this.sessionId,
    required this.sequence,
    required this.issuedAtEpochMs,
    required this.expiresAtEpochMs,
  });

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch >= expiresAtEpochMs;

  Map<String, dynamic> toAuditMap() => <String, dynamic>{
        'id': id,
        'sessionId': sessionId,
        'sequence': sequence,
        'issuedAtEpochMs': issuedAtEpochMs,
        'expiresAtEpochMs': expiresAtEpochMs,
        'expired': isExpired,
      };
}

class NovaTurnLeaseController {
  static final NovaTurnLeaseController instance = NovaTurnLeaseController._();

  final Random _random = Random.secure();
  NovaTurnLease? _current;
  int _sequence = 0;

  NovaTurnLeaseController._();

  NovaTurnLease? get current => _current;

  NovaTurnLease begin({
    required String sessionId,
    Duration lifetime = const Duration(minutes: 2),
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final sequence = ++_sequence;
    final entropy = List<int>.generate(18, (_) => _random.nextInt(256))
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    final lease = NovaTurnLease(
      id: 'nova_turn_${now}_${sequence}_$entropy',
      sessionId: sessionId.trim().isEmpty ? 'unknown_session' : sessionId.trim(),
      sequence: sequence,
      issuedAtEpochMs: now,
      expiresAtEpochMs: now + lifetime.inMilliseconds,
    );
    _current = lease;
    return lease;
  }

  bool isCurrent(NovaTurnLease? lease) {
    final current = _current;
    if (lease == null || current == null) return false;
    if (lease.isExpired || current.isExpired) return false;
    return identical(lease, current) ||
        (lease.id == current.id &&
            lease.sequence == current.sequence &&
            lease.sessionId == current.sessionId);
  }

  bool isCurrentId(String leaseId) {
    final current = _current;
    return current != null &&
        !current.isExpired &&
        leaseId.trim().isNotEmpty &&
        current.id == leaseId.trim();
  }

  void invalidate([NovaTurnLease? lease]) {
    final current = _current;
    if (current == null) return;
    if (lease == null || lease.id == current.id) {
      _current = null;
    }
  }
}
