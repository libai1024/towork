import 'package:towork/domain/repositories/memory_persistence.dart';

/// 内存版 [MemoryPersistence]，镜像 SQLite 实现的暂停/纪元/版本语义，
/// 供记忆页生产模式的 widget 测试使用（不引入数据库）。
class FakeMemoryPersistence implements MemoryPersistence {
  FakeMemoryPersistence({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final _records = <String, PersistedMemory>{};
  int _epoch = 0;
  bool _paused = false;
  int _seq = 0;

  /// 一次性注入失败：下一次变更调用抛出该失败码（用于模拟持久层错误）。
  MemoryPersistenceFailureCode? _nextFailure;
  void failNextWith(MemoryPersistenceFailureCode code) => _nextFailure = code;

  Never _fail(MemoryPersistenceFailureCode code) {
    _nextFailure = null;
    throw MemoryPersistenceFailure(code);
  }

  void _checkInjected() {
    final injected = _nextFailure;
    if (injected != null) _fail(injected);
  }

  String _validatedContent(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 10000 ||
        content.contains('\u0000')) {
      _fail(MemoryPersistenceFailureCode.validation);
    }
    return trimmed;
  }

  String _validatedKind(String kindId) {
    final trimmed = kindId.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 80 ||
        !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(trimmed)) {
      _fail(MemoryPersistenceFailureCode.validation);
    }
    return trimmed;
  }

  @override
  Future<int> epoch() async => _epoch;

  @override
  Future<bool> paused() async => _paused;

  @override
  Future<MemoryPersistenceWrite> remember({
    required String content,
    required String kindId,
    MemoryPersistSource? source,
    String? sourceMessageId,
    String? sourceSessionId,
    String? sourceRecordId,
    double? confidence,
    DateTime? expiresAt,
    int? expectedEpoch,
  }) async {
    _checkInjected();
    final text = _validatedContent(content);
    final kind = _validatedKind(kindId);
    final score = confidence ?? 1;
    if (score < 0 || score > 1 || !score.isFinite) {
      _fail(MemoryPersistenceFailureCode.validation);
    }
    if (_paused) _fail(MemoryPersistenceFailureCode.paused);
    if (expectedEpoch != null && expectedEpoch != _epoch) {
      _fail(MemoryPersistenceFailureCode.epochChanged);
    }
    final now = _clock().toUtc();
    final id = 'fake_mem_${_seq++}';
    _records[id] = PersistedMemory(
      id: id,
      epoch: _epoch,
      kindId: kind,
      content: text,
      source: source ?? MemoryPersistSource.manual,
      sourceMessageId: sourceMessageId,
      sourceSessionId: sourceSessionId,
      sourceRecordId: sourceRecordId,
      confidence: score,
      expiresAt: expiresAt,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );
    return MemoryPersistenceWrite(memoryId: id, version: 1, epoch: _epoch);
  }

  @override
  Future<List<PersistedMemory>> search(String query, {int limit = 20}) async {
    final terms = query
        .split(RegExp(r'\s+'))
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return const [];
    final now = _clock().toUtc();
    int hits(PersistedMemory memory) =>
        terms.where((t) => memory.content.toLowerCase().contains(t)).length;
    final live =
        _records.values
            .where((m) => !m.isDeleted)
            .where((m) => m.expiresAt == null || m.expiresAt!.isAfter(now))
            .where((m) => hits(m) > 0)
            .toList()
          ..sort((a, b) {
            final score = hits(b).compareTo(hits(a));
            return score != 0 ? score : b.updatedAt.compareTo(a.updatedAt);
          });
    return live.take(limit).toList();
  }

  @override
  Future<List<PersistedMemory>> list({bool includeDeleted = false}) async => [
    for (final record in _records.values)
      if (includeDeleted || !record.isDeleted) record,
  ];

  @override
  Future<PersistedMemory> update(
    String id, {
    String? content,
    String? kindId,
    Object? expiresAt = keepMemoryExpiry,
    int? expectedVersion,
  }) async {
    _checkInjected();
    final row = _records[id];
    if (row == null || row.isDeleted) {
      _fail(MemoryPersistenceFailureCode.notFound);
    }
    if (expectedVersion != null && expectedVersion != row.version) {
      _fail(MemoryPersistenceFailureCode.versionConflict);
    }
    if (_paused) _fail(MemoryPersistenceFailureCode.paused);
    final next = PersistedMemory(
      id: id,
      epoch: row.epoch,
      kindId: kindId == null ? row.kindId : _validatedKind(kindId),
      content: content == null ? row.content : _validatedContent(content),
      source: row.source,
      sourceMessageId: row.sourceMessageId,
      sourceSessionId: row.sourceSessionId,
      sourceRecordId: row.sourceRecordId,
      confidence: row.confidence,
      expiresAt: identical(expiresAt, keepMemoryExpiry)
          ? row.expiresAt
          : expiresAt as DateTime?,
      version: row.version + 1,
      createdAt: row.createdAt,
      updatedAt: _clock().toUtc(),
      deletedAt: row.deletedAt,
    );
    _records[id] = next;
    return next;
  }

  @override
  Future<void> delete(String id, {int? expectedVersion}) async {
    _checkInjected();
    final row = _records[id];
    if (row == null || row.isDeleted) {
      _fail(MemoryPersistenceFailureCode.notFound);
    }
    if (expectedVersion != null && expectedVersion != row.version) {
      _fail(MemoryPersistenceFailureCode.versionConflict);
    }
    final now = _clock().toUtc();
    _records[id] = PersistedMemory(
      id: id,
      epoch: row.epoch,
      kindId: row.kindId,
      content: row.content,
      source: row.source,
      sourceMessageId: row.sourceMessageId,
      sourceSessionId: row.sourceSessionId,
      sourceRecordId: row.sourceRecordId,
      confidence: row.confidence,
      expiresAt: row.expiresAt,
      version: row.version + 1,
      createdAt: row.createdAt,
      updatedAt: now,
      deletedAt: now,
    );
    _epoch += 1;
  }

  @override
  Future<void> clearAll({int? expectedEpoch}) async {
    _checkInjected();
    if (expectedEpoch != null && expectedEpoch != _epoch) {
      _fail(MemoryPersistenceFailureCode.epochChanged);
    }
    final now = _clock().toUtc();
    for (final id in _records.keys.toList()) {
      final row = _records[id]!;
      if (row.isDeleted) continue;
      _records[id] = PersistedMemory(
        id: id,
        epoch: row.epoch,
        kindId: row.kindId,
        content: row.content,
        source: row.source,
        sourceMessageId: row.sourceMessageId,
        sourceSessionId: row.sourceSessionId,
        sourceRecordId: row.sourceRecordId,
        confidence: row.confidence,
        expiresAt: row.expiresAt,
        version: row.version + 1,
        createdAt: row.createdAt,
        updatedAt: now,
        deletedAt: now,
      );
    }
    _epoch += 1;
  }

  @override
  Future<void> setPaused(bool value) async {
    _checkInjected();
    if (_paused == value) return;
    _paused = value;
    // 与 SQLite 实现一致：开启暂停推进纪元，关闭不动。
    if (value) _epoch += 1;
  }
}
