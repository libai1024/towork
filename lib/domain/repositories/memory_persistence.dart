/// FC4 memory persistence boundary. SQLite stays authoritative; the store
/// enforces pause and epoch semantics so late extraction tasks can never
/// revive deleted content. (The in-memory demo MemoryStore is a separate type.)
library;

/// [MemoryPersistence.update] 的 expiresAt 保留哨兵：参数缺省时保持库内
/// 现值，显式 DateTime 替换，显式 null 清除。
const Object keepMemoryExpiry = Object();

enum MemoryPersistenceFailureCode {
  paused,
  epochChanged,
  validation,
  notFound,
  versionConflict,
  storage,
}

/// Safe for UI/logs; never carries user text or raw SQLite errors.
class MemoryPersistenceFailure implements Exception {
  const MemoryPersistenceFailure(this.code);
  final MemoryPersistenceFailureCode code;
  @override
  String toString() => 'MemoryPersistenceFailure(${code.name})';
}

enum MemoryPersistSource { manual, ai }

class PersistedMemory {
  const PersistedMemory({
    required this.id,
    required this.epoch,
    required this.kindId,
    required this.content,
    required this.source,
    this.sourceMessageId,
    this.sourceSessionId,
    this.sourceRecordId,
    required this.confidence,
    this.expiresAt,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  final String id, kindId, content;
  final int epoch, version;
  final MemoryPersistSource source;
  final String? sourceMessageId, sourceSessionId, sourceRecordId;
  final double confidence;
  final DateTime? expiresAt;
  final DateTime createdAt, updatedAt;
  final DateTime? deletedAt;
  bool get isDeleted => deletedAt != null;
}

class MemoryPersistenceWrite {
  const MemoryPersistenceWrite({
    required this.memoryId,
    required this.version,
    required this.epoch,
  });
  final String memoryId;
  final int version, epoch;
}

abstract interface class MemoryPersistence {
  Future<int> epoch();
  Future<bool> paused();

  /// Creates one memory. Explicit "remember" is a user intent, but a paused
  /// memory still rejects it with [MemoryPersistenceFailureCode.paused]; an
  /// extraction carrying a stale [expectedEpoch] gets
  /// [MemoryPersistenceFailureCode.epochChanged]. Referenced sources must
  /// still exist when the write lands.
  Future<MemoryPersistenceWrite> remember({
    required String content,
    required String kindId,
    MemoryPersistSource source,
    String? sourceMessageId,
    String? sourceSessionId,
    String? sourceRecordId,
    double confidence,
    DateTime? expiresAt,
    int? expectedEpoch,
  });

  Future<List<PersistedMemory>> list({bool includeDeleted});

  /// Honest keyword (lexical) retrieval over live, unexpired memories:
  /// whitespace terms plus CJK bigrams (minus filler words), OR semantics,
  /// ranked by how many terms hit and then by recency. This is NOT semantic
  /// search; the vector half of the FC4 hybrid target stays open until
  /// embedding passes its feasibility gate.
  Future<List<PersistedMemory>> search(String query, {int limit});

  /// Manual explicit edit with optimistic version check. [expiresAt] follows
  /// keep-sentinel semantics: omitted keeps the stored value, an explicit
  /// DateTime replaces it, and an explicit null clears it.
  Future<PersistedMemory> update(
    String id, {
    String? content,
    String? kindId,
    Object? expiresAt = keepMemoryExpiry,
    int? expectedVersion,
  });

  /// Soft delete advances the epoch, invalidating in-flight extraction tasks.
  Future<void> delete(String id, {int? expectedVersion});

  /// Clears every memory and advances the epoch.
  Future<void> clearAll({int? expectedEpoch});

  /// Pausing advances the epoch; unpausing does not.
  Future<void> setPaused(bool value);
}
