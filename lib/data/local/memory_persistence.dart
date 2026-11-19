import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/repositories/memory_persistence.dart';
import 'app_database.dart';

/// SQLite implementation of the FC4 memory boundary. Every mutating call runs
/// in one transaction; epoch and pause state live in a singleton row and only
/// ever move forward within a committed transaction.
class SqliteMemoryPersistence implements MemoryPersistence {
  SqliteMemoryPersistence(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final AppDatabase _db;
  final DateTime Function() _clock;
  final Random _random = Random.secure();

  static Never _fail(MemoryPersistenceFailureCode code) =>
      throw MemoryPersistenceFailure(code);

  String _newId() =>
      'mem_${List.generate(24, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

  int _now() => _clock().toUtc().microsecondsSinceEpoch;

  Future<({int epoch, bool paused, int updatedAt})> _state() async {
    final rows = await (_db.select(
      _db.localMemoryState,
    )..where((r) => r.id.equals(1))).get();
    if (rows.isEmpty) return (epoch: 0, paused: false, updatedAt: 0);
    final row = rows.single;
    return (epoch: row.epoch, paused: row.paused, updatedAt: row.updatedAt);
  }

  Future<void> _writeState(int epoch, bool paused, int updatedAt) => _db
      .into(_db.localMemoryState)
      .insertOnConflictUpdate(
        LocalMemoryStateCompanion.insert(
          id: const Value(1),
          epoch: epoch,
          paused: paused,
          updatedAt: updatedAt,
        ),
      );

  @override
  Future<int> epoch() async => (await _state()).epoch;

  @override
  Future<bool> paused() async => (await _state()).paused;

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

  /// Sources must still exist when the write lands; a deleted conversation or
  /// business row cannot author new memories.
  Future<void> _checkSources({
    String? messageId,
    String? sessionId,
    String? recordId,
  }) async {
    if (messageId != null) {
      final turn = await (_db.select(
        _db.chatTurns,
      )..where((r) => r.inputId.equals(messageId))).getSingleOrNull();
      if (turn == null) _fail(MemoryPersistenceFailureCode.validation);
      if (sessionId != null && turn.sessionId != sessionId) {
        _fail(MemoryPersistenceFailureCode.validation);
      }
    } else if (sessionId != null) {
      final conversation =
          await (_db.select(_db.chatConversations)
                ..where((c) => c.id.equals(sessionId) & c.deletedAt.isNull()))
              .getSingleOrNull();
      if (conversation == null) {
        _fail(MemoryPersistenceFailureCode.validation);
      }
    }
    if (recordId != null) {
      final row =
          await (_db.select(_db.workDataRows)
                ..where((r) => r.id.equals(recordId) & r.deletedAt.isNull()))
              .getSingleOrNull();
      if (row == null) _fail(MemoryPersistenceFailureCode.validation);
    }
  }

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
  }) => _db.transaction(() async {
    final origin = source ?? MemoryPersistSource.manual;
    final text = _validatedContent(content);
    final kind = _validatedKind(kindId);
    final score = confidence ?? 1;
    if (score < 0 || score > 1 || !score.isFinite) {
      _fail(MemoryPersistenceFailureCode.validation);
    }
    final state = await _state();
    if (state.paused) _fail(MemoryPersistenceFailureCode.paused);
    if (expectedEpoch != null && expectedEpoch != state.epoch) {
      _fail(MemoryPersistenceFailureCode.epochChanged);
    }
    await _checkSources(
      messageId: sourceMessageId,
      sessionId: sourceSessionId,
      recordId: sourceRecordId,
    );
    final id = _newId();
    final now = _now();
    await _db
        .into(_db.localMemories)
        .insert(
          LocalMemoriesCompanion.insert(
            id: id,
            epoch: state.epoch,
            kindId: kind,
            content: text,
            source: origin.name,
            sourceMessageId: Value(sourceMessageId),
            sourceSessionId: Value(sourceSessionId),
            sourceRecordId: Value(sourceRecordId),
            confidence: score,
            expiresAt: Value(expiresAt?.toUtc().microsecondsSinceEpoch),
            version: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return MemoryPersistenceWrite(memoryId: id, version: 1, epoch: state.epoch);
  });

  PersistedMemory _record(LocalMemory row) => PersistedMemory(
    id: row.id,
    epoch: row.epoch,
    kindId: row.kindId,
    content: row.content,
    source: row.source == 'ai'
        ? MemoryPersistSource.ai
        : MemoryPersistSource.manual,
    sourceMessageId: row.sourceMessageId,
    sourceSessionId: row.sourceSessionId,
    sourceRecordId: row.sourceRecordId,
    confidence: row.confidence,
    expiresAt: row.expiresAt == null
        ? null
        : DateTime.fromMicrosecondsSinceEpoch(row.expiresAt!, isUtc: true),
    version: row.version,
    createdAt: DateTime.fromMicrosecondsSinceEpoch(row.createdAt, isUtc: true),
    updatedAt: DateTime.fromMicrosecondsSinceEpoch(row.updatedAt, isUtc: true),
    deletedAt: row.deletedAt == null
        ? null
        : DateTime.fromMicrosecondsSinceEpoch(row.deletedAt!, isUtc: true),
  );

  @override
  Future<List<PersistedMemory>> list({bool includeDeleted = false}) async {
    final query = _db.select(_db.localMemories)
      ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]);
    if (!includeDeleted) {
      query.where((r) => r.deletedAt.isNull());
    }
    return (await query.get()).map(_record).toList();
  }

  static String _escapeLike(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');

  /// 代词与语气助词。带这些字的二字组合多半是跨词边界切出来的碎片
  /// （「提醒我的」→「醒我」），只会带来误命中。只收不构成常用实词的字。
  static const _stopCharacters = {
    '的',
    '了',
    '我',
    '你',
    '他',
    '她',
    '它',
    '们',
    '吗',
    '呢',
    '吧',
    '啊',
    '么',
    '很',
    '这',
    '那',
  };

  /// 口语里到处都是、对「这条记忆相不相关」没有区分度的二字组合。
  /// 不剔除的话，「帮我」「明天」会把无关记忆带进每一轮对话。
  static const _stopBigrams = {
    '帮我',
    '给我',
    '我的',
    '你的',
    '我们',
    '一下',
    '一个',
    '这个',
    '那个',
    '什么',
    '怎么',
    '今天',
    '明天',
    '后天',
    '昨天',
    '现在',
    '时候',
    '然后',
    '还有',
    '可以',
    '需要',
    '已经',
    '就是',
    '不是',
    '没有',
    '是不',
    '提醒',
    '待办',
    '记得',
    '记住',
    '还记',
    '知道',
    '一条',
    '一些',
    '所有',
    '这些',
    '那些',
    '的话',
    '但是',
    '因为',
    '所以',
    '如果',
    '或者',
    '以及',
    '关于',
    '进行',
    '看看',
    '告诉',
    '我要',
    '我想',
  };

  @override
  Future<List<PersistedMemory>> search(String query, {int limit = 20}) async {
    // Whitespace terms plus CJK bigrams: Chinese queries carry no spaces, so
    // a whole sentence would never substring-match a stored memory.
    final terms = <String>{};
    for (final chunk in query.split(RegExp(r'\s+'))) {
      final trimmed = chunk.trim();
      if (trimmed.isEmpty) continue;
      final runs = RegExp(r'[\u4e00-\u9fff]{2,}')
          .allMatches(trimmed)
          .map((m) => m.group(0)!)
          .toList();
      // 整句几乎不可能原样出现在记忆里；有二字组合时只用组合，
      // 夹在中文里的英文词和型号（iPhone、A320）单独成词。
      if (runs.isEmpty || trimmed.runes.length <= 6) {
        terms.add(trimmed);
      } else {
        terms.addAll(
          RegExp(r'[A-Za-z0-9]{2,}')
              .allMatches(trimmed)
              .map((m) => m.group(0)!),
        );
      }
      for (final run in runs) {
        for (var i = 0; i + 2 <= run.length; i++) {
          final pair = run.substring(i, i + 2);
          if (!_stopBigrams.contains(pair) &&
              !_stopCharacters.contains(pair[0]) &&
              !_stopCharacters.contains(pair[1])) {
            terms.add(pair);
          }
        }
      }
    }
    terms.removeWhere(_stopBigrams.contains);
    if (terms.isEmpty || limit < 1) return const [];
    // 与占位符同源截断：terms 里的 CJK bigram 可能远超 24 个，
    // 多绑参数会让 SQLite 抛 “参数数量不匹配”，拖垮整次发送。
    final bounded = [
      for (final term in terms.take(24)) '%${_escapeLike(term.toLowerCase())}%',
    ];
    const like = "content LIKE ? ESCAPE '\\'";
    // 先按命中的词数排，再按新旧：只沾一个词的旧记忆不该压过多词命中的。
    final score = [
      for (final _ in bounded) '(CASE WHEN $like THEN 1 ELSE 0 END)',
    ].join(' + ');
    final rows = await _db
        .customSelect(
          'SELECT id, epoch, kind_id, content, source, source_message_id, '
          'source_session_id, source_record_id, confidence, expires_at, version, '
          'created_at, updated_at, deleted_at, ($score) AS score '
          'FROM local_memories '
          'WHERE deleted_at IS NULL '
          'AND (expires_at IS NULL OR expires_at > ?) '
          'AND (${[for (final _ in bounded) like].join(' OR ')}) '
          'ORDER BY score DESC, updated_at DESC LIMIT ?',
          variables: [
            for (final term in bounded) Variable.withString(term),
            Variable.withInt(_now()),
            for (final term in bounded) Variable.withString(term),
            Variable.withInt(limit > 50 ? 50 : limit),
          ],
          readsFrom: {_db.localMemories},
        )
        .get();
    return [
      for (final row in rows)
        PersistedMemory(
          id: row.read<String>('id'),
          epoch: row.read<int>('epoch'),
          kindId: row.read<String>('kind_id'),
          content: row.read<String>('content'),
          source: row.read<String>('source') == 'ai'
              ? MemoryPersistSource.ai
              : MemoryPersistSource.manual,
          sourceMessageId: row.readNullable<String>('source_message_id'),
          sourceSessionId: row.readNullable<String>('source_session_id'),
          sourceRecordId: row.readNullable<String>('source_record_id'),
          confidence: row.read<double>('confidence'),
          expiresAt: row.readNullable<int>('expires_at') == null
              ? null
              : DateTime.fromMicrosecondsSinceEpoch(
                  row.read<int>('expires_at'),
                  isUtc: true,
                ),
          version: row.read<int>('version'),
          createdAt: DateTime.fromMicrosecondsSinceEpoch(
            row.read<int>('created_at'),
            isUtc: true,
          ),
          updatedAt: DateTime.fromMicrosecondsSinceEpoch(
            row.read<int>('updated_at'),
            isUtc: true,
          ),
        ),
    ];
  }

  @override
  Future<PersistedMemory> update(
    String id, {
    String? content,
    String? kindId,
    Object? expiresAt = keepMemoryExpiry,
    int? expectedVersion,
  }) => _db.transaction(() async {
    final row = await (_db.select(
      _db.localMemories,
    )..where((r) => r.id.equals(id) & r.deletedAt.isNull())).getSingleOrNull();
    if (row == null) _fail(MemoryPersistenceFailureCode.notFound);
    if (expectedVersion != null && expectedVersion != row.version) {
      _fail(MemoryPersistenceFailureCode.versionConflict);
    }
    final state = await _state();
    if (state.paused) _fail(MemoryPersistenceFailureCode.paused);
    final nextContent = content == null
        ? row.content
        : _validatedContent(content);
    final nextKind = kindId == null ? row.kindId : _validatedKind(kindId);
    final nextExpiry = identical(expiresAt, keepMemoryExpiry)
        ? row.expiresAt
        : (expiresAt as DateTime?)?.toUtc().microsecondsSinceEpoch;
    final updated =
        await (_db.update(
          _db.localMemories,
        )..where((r) => r.id.equals(id) & r.version.equals(row.version))).write(
          LocalMemoriesCompanion(
            content: Value(nextContent),
            kindId: Value(nextKind),
            expiresAt: Value(nextExpiry),
            version: Value(row.version + 1),
            updatedAt: Value(_now()),
          ),
        );
    if (updated != 1) {
      _fail(MemoryPersistenceFailureCode.versionConflict);
    }
    return _record(
      (await (_db.select(
        _db.localMemories,
      )..where((r) => r.id.equals(id))).getSingle()),
    );
  });

  @override
  Future<void> delete(
    String id, {
    int? expectedVersion,
  }) => _db.transaction(() async {
    final row = await (_db.select(
      _db.localMemories,
    )..where((r) => r.id.equals(id) & r.deletedAt.isNull())).getSingleOrNull();
    if (row == null) _fail(MemoryPersistenceFailureCode.notFound);
    if (expectedVersion != null && expectedVersion != row.version) {
      _fail(MemoryPersistenceFailureCode.versionConflict);
    }
    final state = await _state();
    final now = _now();
    final updated =
        await (_db.update(
          _db.localMemories,
        )..where((r) => r.id.equals(id) & r.version.equals(row.version))).write(
          LocalMemoriesCompanion(
            deletedAt: Value(now),
            version: Value(row.version + 1),
            updatedAt: Value(now),
          ),
        );
    if (updated != 1) {
      _fail(MemoryPersistenceFailureCode.versionConflict);
    }
    await _writeState(state.epoch + 1, state.paused, now);
  });

  @override
  Future<void> clearAll({int? expectedEpoch}) => _db.transaction(() async {
    final state = await _state();
    if (expectedEpoch != null && expectedEpoch != state.epoch) {
      _fail(MemoryPersistenceFailureCode.epochChanged);
    }
    final now = _now();
    await _db.customUpdate(
      'UPDATE local_memories SET deleted_at = ?, updated_at = ?, '
      'version = version + 1 WHERE deleted_at IS NULL',
      variables: [Variable.withInt(now), Variable.withInt(now)],
    );
    await _writeState(state.epoch + 1, state.paused, now);
  });

  @override
  Future<void> setPaused(bool value) => _db.transaction(() async {
    final state = await _state();
    if (state.paused == value) return;
    final now = _now();
    // Pausing invalidates in-flight extraction; unpausing keeps the epoch.
    final nextEpoch = value ? state.epoch + 1 : state.epoch;
    await _writeState(nextEpoch, value, now);
  });
}
