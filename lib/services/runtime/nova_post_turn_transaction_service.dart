// NOVA_SEQUENTIAL_POST_TURN_TRANSACTION_V1
import 'dart:async';

import '../../core/turn/nova_turn_lease.dart';

class NovaPostTurnTransactionResult {
  final bool committed;
  final String reason;
  final int sequence;

  const NovaPostTurnTransactionResult({
    required this.committed,
    required this.reason,
    required this.sequence,
  });
}

class NovaPostTurnTransactionService {
  static final NovaPostTurnTransactionService instance =
      NovaPostTurnTransactionService._();

  Future<void> _tail = Future<void>.value();
  int _sequence = 0;

  NovaPostTurnTransactionService._();

  Future<NovaPostTurnTransactionResult> run({
    required NovaTurnLease? lease,
    required Future<void> Function() transaction,
  }) {
    final completer = _TransactionCompleter();
    final sequence = ++_sequence;
    _tail = _tail.catchError((Object _) {}).then((_) async {
      if (lease == null ||
          !NovaTurnLeaseController.instance.isCurrent(lease)) {
        completer.complete(
          NovaPostTurnTransactionResult(
            committed: false,
            reason: 'stale_or_missing_turn_lease',
            sequence: sequence,
          ),
        );
        return;
      }
      try {
        await transaction();
        final stillCurrent =
            NovaTurnLeaseController.instance.isCurrent(lease);
        completer.complete(
          NovaPostTurnTransactionResult(
            committed: stillCurrent,
            reason: stillCurrent
                ? 'committed_in_order'
                : 'turn_became_stale_after_commit',
            sequence: sequence,
          ),
        );
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}

class _TransactionCompleter {
  final Completer<NovaPostTurnTransactionResult> _delegate =
      Completer<NovaPostTurnTransactionResult>();

  Future<NovaPostTurnTransactionResult> get future => _delegate.future;

  void complete(NovaPostTurnTransactionResult value) {
    if (!_delegate.isCompleted) _delegate.complete(value);
  }

  void completeError(Object error, StackTrace stackTrace) {
    if (!_delegate.isCompleted) _delegate.completeError(error, stackTrace);
  }
}
