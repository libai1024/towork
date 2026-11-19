import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/workspace_model_codec.dart';
import '../domain/repositories/todo_store.dart';
import '../data/repositories/category_repository.dart';
import '../domain/models/models.dart';
import '../domain/workspace/workspace_commands.dart';

class LocalTodoProjection extends TodoReadStore {
  LocalTodoProjection() : super([]);
  void _accept(List<Todo> value) => state = value;
}

class LocalCategoryProjection extends CategoryRepository {
  LocalCategoryProjection() : super(initial: []);
  @override
  set state(List<Category> value) =>
      throw StateError('Use awaited workspace commands');
  void accept(List<Category> value) => super.state = value;
}

final localWorkspaceSessionProvider = StateProvider<LocalWorkspaceSession?>(
  (ref) => null,
);

/// Holds only committed projections. The store remains authoritative.
class LocalWorkspaceSession {
  LocalWorkspaceSession(
    this.store,
    WorkspaceSnapshot initial, {
    Duration Function()? elapsed,
  }) : _elapsedOverride = elapsed {
    accept(initial);
    _subscription = store.watch().listen(
      accept,
      onError: (Object error) {
        // Keep the last committed workspace visible; callers can explicitly reload.
        readError = error;
      },
    );
  }
  final WorkspaceCommandStore store;
  final Duration Function()? _elapsedOverride;
  final _uptime = Stopwatch()..start();
  Duration get _elapsed => _elapsedOverride?.call() ?? _uptime.elapsed;
  final _events = StreamController<void>.broadcast();
  Stream<void> get events => _events.stream;
  int _automaticHolds = 0;
  Duration? _quietUntil;
  bool get automaticWorkHeld => _automaticHolds > 0 || _disposed;
  Duration get automaticWorkDelay {
    final remaining = (_quietUntil ?? _elapsed) - _elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// A confirmation sheet owns this lease until it closes. The callback is
  /// idempotent so cancellation/disposal cannot prematurely release another UI.
  void Function() holdAutomaticWork() {
    _automaticHolds++;
    _notify();
    var released = false;
    return () {
      if (released) return;
      released = true;
      _automaticHolds--;
      _notify();
    };
  }

  void _notify() {
    if (!_disposed) _events.add(null);
  }

  /// Coordinate transactional chat writes without separating their atomic journal
  /// from the business commit. Callers own the existing store transaction.
  Future<T> foreground<T>(Future<T> Function() action) async {
    final release = holdAutomaticWork();
    try {
      return await action();
    } finally {
      // Longer than the longest current (10-second) undo toast. Generation
      // must not immediately bump a series version and invalidate that undo.
      _quietUntil = _elapsed + const Duration(seconds: 15);
      release();
    }
  }

  final todos = LocalTodoProjection();
  final categories = LocalCategoryProjection();
  WorkspaceSnapshot snapshot = WorkspaceSnapshot([]);
  StreamSubscription<WorkspaceSnapshot>? _subscription;
  Object? readError;
  bool _disposed = false;

  void accept(WorkspaceSnapshot incoming) {
    if (_disposed) return;
    final merged = {...snapshot.entities};
    var changed = readError != null;
    for (final e in incoming.entities.values) {
      if (merged[e.key]?.version != e.version &&
          (merged[e.key]?.version ?? 0) <= e.version) {
        changed = true;
      }
      if ((merged[e.key]?.version ?? 0) <= e.version) merged[e.key] = e;
    }
    if (!changed) return;
    snapshot = WorkspaceSnapshot(merged.values);
    readError = null;
    // Both lists are assigned synchronously before Flutter's next frame.
    categories.accept(
      snapshot.categories.map(workspaceCategory).toList()..sort(
        (a, b) => a.sortOrder == b.sortOrder
            ? a.id.compareTo(b.id)
            : a.sortOrder.compareTo(b.sortOrder),
      ),
    );
    todos._accept(
      snapshot.todos.map(workspaceTodo).toList()..sort(
        (a, b) => b.createdAt == a.createdAt
            ? a.id.compareTo(b.id)
            : b.createdAt.compareTo(a.createdAt),
      ),
    );
    _notify();
  }

  Future<WorkspaceReceipt> execute(WorkspaceCommand command) async {
    Future<WorkspaceReceipt> apply() async {
      final receipt = await store.execute(command);
      accept(WorkspaceSnapshot(receipt.affected));
      return receipt;
    }

    return command.source == 'system' ? apply() : foreground(apply);
  }

  Future<void> undo(String id, String undoId) async {
    await foreground(() async {
      final receipt = await store.undo(id, operationId: undoId);
      accept(WorkspaceSnapshot(receipt.affected));
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
    await _events.close();
    // Projections are owned/disposed by their scoped Riverpod providers.
  }
}
