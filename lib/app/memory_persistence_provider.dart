import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/memory_persistence.dart';
import '../domain/models/memory.dart';
import '../domain/repositories/memory_persistence.dart';
import 'local_database_provider.dart';
import 'local_workspace_session.dart';
import 'providers.dart';

/// Null in demo mode; production memory lives in SQLite via v11 persistence.
final memoryPersistenceProvider = FutureProvider<MemoryPersistence?>((
  ref,
) async {
  final session = ref.watch(localWorkspaceSessionProvider);
  if (session == null) return null;
  final db = await ref.watch(localDatabaseProvider.future);
  return SqliteMemoryPersistence(db);
});

/// Production memory state over [MemoryPersistence]. The demo page keeps its
/// in-memory store; this controller exposes awaits so failures surface to the
/// caller instead of silently reverting the list.
class MemoryVaultController extends StateNotifier<List<MemoryEntry>> {
  MemoryVaultController(this._persistence) : super(const []);
  final MemoryPersistence _persistence;

  final _versions = <String, int>{};
  int _epoch = 0;

  static String _kindId(MemoryEntry entry) =>
      entry.customTypeId ?? entry.type.name;

  MemoryEntry _entry(PersistedMemory record) {
    final kind = MemoryKind.builtIn
        .where((k) => k.id == record.kindId)
        .firstOrNull;
    return MemoryEntry(
      id: record.id,
      content: record.content,
      type: kind?.semanticType ?? MemoryType.fact,
      customTypeId: kind == null ? record.kindId : null,
      source: record.source == MemoryPersistSource.ai
          ? MemorySource.ai
          : MemorySource.manual,
      sourceSessionId: record.sourceSessionId,
      confidence: record.confidence,
      expiresAt: record.expiresAt,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  Future<void> load() async {
    final records = await _persistence.list();
    _versions
      ..clear()
      ..addAll({for (final r in records) r.id: r.version});
    _epoch = await _persistence.epoch();
    state = [for (final r in records) _entry(r)];
  }

  int? versionOf(String id) => _versions[id];
  int get epoch => _epoch;

  Future<MemoryEntry> addManual({
    required String content,
    required MemoryType type,
    String? customTypeId,
    DateTime? expiresAt,
  }) async {
    final kindId = customTypeId ?? type.name;
    final write = await _persistence.remember(
      content: content,
      kindId: kindId,
      expiresAt: expiresAt,
    );
    await load();
    return state.firstWhere((e) => e.id == write.memoryId);
  }

  Future<void> updateEntry(MemoryEntry entry) async {
    await _persistence.update(
      entry.id,
      content: entry.content,
      kindId: _kindId(entry),
      expiresAt: entry.expiresAt,
      expectedVersion: _versions[entry.id],
    );
    await load();
  }

  /// Production undo re-remembers the content under a new id; epoch guards in
  /// the persistence layer keep this from reviving cleared content.
  Future<void> remove(String id) async {
    await _persistence.delete(id, expectedVersion: _versions[id]);
    await load();
  }

  Future<int> clearAll() async {
    final count = state.length;
    await _persistence.clearAll();
    await load();
    return count;
  }

  Future<void> setPaused(bool value) => _persistence.setPaused(value);
  Future<bool> paused() => _persistence.paused();
}

/// Null in demo mode — the page then keeps the in-memory repository.
final memoryVaultProvider = FutureProvider<MemoryVaultController?>((ref) async {
  final persistence = ref.watch(memoryPersistenceProvider).valueOrNull;
  if (persistence == null) return null;
  final controller = MemoryVaultController(persistence);
  ref.onDispose(controller.dispose);
  final session = ref.watch(localWorkspaceSessionProvider);
  final subscription = session?.events.listen((_) => controller.load());
  ref.onDispose(() => subscription?.cancel());
  await controller.load();
  return controller;
});

/// Production pause state for the page switch; demo keeps the preference.
final memoryPausedViewProvider = FutureProvider<bool>((ref) async {
  final persistence = ref.watch(memoryPersistenceProvider).valueOrNull;
  if (persistence == null) return ref.watch(memoryPausedProvider);
  return persistence.paused();
});
