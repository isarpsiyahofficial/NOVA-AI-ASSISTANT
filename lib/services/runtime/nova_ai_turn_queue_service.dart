// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// GEMMA95952_SELF_REPAIR_V4: queue repair exposes only bounded in-memory stale queue clearing; no file/native/script capability.
import 'dart:async';
import 'dart:collection';

class NovaAiTurnQueueService {
  static final NovaAiTurnQueueService instance =
      NovaAiTurnQueueService._internal(maxParallelTurns: 1);

  final int maxParallelTurns;
  final Queue<_QueuedAiTurn<dynamic>> _queue = Queue<_QueuedAiTurn<dynamic>>();
  int _running = 0;
  int _repairEpoch = 0;

  NovaAiTurnQueueService._internal({required this.maxParallelTurns});

  int get runningCount => _running;
  int get waitingCount => _queue.length;
  int get repairEpoch => _repairEpoch;
  bool get hasCapacity => _running < maxParallelTurns;

  Future<T> run<T>({
    required String label,
    required Future<T> Function() task,
  }) {
    final completer = Completer<T>();
    _queue.add(
      _QueuedAiTurn<T>(
        label: label.trim().isEmpty ? 'ai_turn' : label.trim(),
        task: task,
        completer: completer,
        enqueuedAt: DateTime.now(),
        epoch: _repairEpoch,
      ),
    );
    _drain();
    return completer.future;
  }

  int clearWaitingStale({String reason = 'self_repair_queue_stale_policy'}) {
    if (_queue.isEmpty) return 0;
    final cleared = _queue.length;
    _repairEpoch += 1;
    while (_queue.isNotEmpty) {
      final item = _queue.removeFirst();
      if (!item.completer.isCompleted) {
        item.completer.completeError(
          StateError('AI turn queue temizlendi: $reason'),
        );
      }
    }
    return cleared;
  }

  void _drain() {
    while (_running < maxParallelTurns && _queue.isNotEmpty) {
      final item = _queue.removeFirst();
      if (item.epoch < _repairEpoch) {
        if (!item.completer.isCompleted) {
          item.completer.completeError(
            StateError('Stale AI turn repair epoch nedeniyle düşürüldü.'),
          );
        }
        continue;
      }
      _running += 1;
      unawaited(_execute(item));
    }
  }

  Future<void> _execute<T>(_QueuedAiTurn<T> item) async {
    try {
      if (item.epoch < _repairEpoch) {
        if (!item.completer.isCompleted) {
          item.completer.completeError(
            StateError('Stale AI turn execution öncesi düşürüldü.'),
          );
        }
        return;
      }
      final result = await item.task();
      if (!item.completer.isCompleted) {
        item.completer.complete(result);
      }
    } catch (error, stackTrace) {
      if (!item.completer.isCompleted) {
        item.completer.completeError(error, stackTrace);
      }
    } finally {
      _running = (_running - 1).clamp(0, maxParallelTurns).toInt();
      _drain();
    }
  }
}

class _QueuedAiTurn<T> {
  final String label;
  final Future<T> Function() task;
  final Completer<T> completer;
  final DateTime enqueuedAt;
  final int epoch;

  const _QueuedAiTurn({
    required this.label,
    required this.task,
    required this.completer,
    required this.enqueuedAt,
    required this.epoch,
  });
}
