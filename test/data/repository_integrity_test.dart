import 'package:flutter/material.dart' show Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:towork/app/providers.dart'
    show reportListProvider, todoListProvider;
import 'package:towork/data/repositories/category_repository.dart';
import 'package:towork/data/repositories/chat_repository.dart';
import 'package:towork/data/repositories/data_table_repository.dart';
import 'package:towork/data/repositories/memory_repository.dart';
import 'package:towork/data/repositories/quota_repository.dart';
import 'package:towork/data/repositories/report_repository.dart';
import 'package:towork/data/repositories/todo_repository.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/domain/repositories/data_table_bundle.dart';
import 'package:towork/domain/repositories/repository_error.dart';

final _now = DateTime(2026, 9, 23, 12);
final _rejected = isA<RepositoryException>();

DataTableRepository _tableRepo() => DataTableRepository(
  clock: () => _now,
  initial: DataTableBundle(
    tables: [
      for (final id in ['a', 'b'])
        DataTableDef(
          id: id,
          name: id,
          columns: [
            DataColumnDef(name: 'name', type: 'text'),
            DataColumnDef(name: 'amount', type: 'number'),
          ],
          createdAt: _now,
        ),
    ],
    rows: [
      for (final id in ['a', 'b'])
        DataRow(
          id: 'row_$id',
          tableId: id,
          values: {'name': id, 'amount': '1'},
          updatedAt: _now,
        ),
    ],
    logs: [],
  ),
);

PendingRowChange _update(
  String id, {
  String rowId = 'row_a',
  String field = 'amount',
  String oldValue = '1',
  String newValue = '2',
}) => PendingRowChange(
  id: id,
  action: DataChangeAction.update,
  rowId: rowId,
  rowLabel: rowId,
  fields: [
    PendingFieldChange(field: field, oldValue: oldValue, newValue: newValue),
  ],
);

PendingAiBatch _batch(
  DataTableRepository repo,
  List<PendingRowChange> changes,
) => repo.pushPendingBatch(
  tableId: 'a',
  reason: '测试变更',
  sourceLabel: '测试来源',
  changes: changes,
);

Report _generate(ReportRepository repo, String label) => repo.startGeneration(
  periodStart: _now.subtract(const Duration(days: 7)),
  periodEnd: _now,
  type: ReportType.weekly,
  periodLabel: label,
  categories: [],
);

void main() {
  test('AI deletion requires its complete current snapshot', () {
    final repo = _tableRepo();
    addTearDown(repo.dispose);
    final batch = _batch(repo, [
      PendingRowChange(
        id: 'delete',
        action: DataChangeAction.delete,
        rowId: 'row_a',
        rowLabel: 'a',
        fields: [const PendingFieldChange(field: 'amount', oldValue: '1')],
      ),
    ]);
    final before = repo.snapshot;
    expect(
      () => repo.applyPendingBatch(batch.id, {'delete'}),
      throwsA(_rejected),
    );
    expect(identical(before, repo.snapshot), isTrue);
    expect(repo.rowsOf('a'), hasLength(1));
  });

  test(
    'restoring an old chat card retains message order and the latest preview',
    () {
      final repo = ChatRepository(initial: [], clock: () => _now);
      addTearDown(repo.dispose);
      final session = repo.createSession();
      ChatMessage message(
        String id,
        String content, {
        ChatMessageType type = ChatMessageType.text,
      }) => ChatMessage(
        id: id,
        sessionId: session.id,
        role: ChatRole.assistant,
        type: type,
        content: content,
        createdAt: _now,
      );
      final first = message('first', 'older reply');
      final card = message('card', '', type: ChatMessageType.todoCard);
      final latest = message('latest', 'latest reply');
      repo.appendMessage(first);
      repo.appendMessage(card);
      repo.appendMessage(latest);
      repo.removeMessage(session.id, card.id);
      repo.insertMessageAt(1, card);
      repo.insertMessageAt(1, card);
      expect(repo.messagesOf(session.id).map((item) => item.id), [
        'first',
        'card',
        'latest',
      ]);
      expect(repo.sessionById(session.id)!.lastMessagePreview, 'latest reply');
      expect(
        () => repo.messagesOf(session.id).removeAt(0),
        throwsUnsupportedError,
      );
      expect(
        () => repo.insertMessageAt(
          0,
          ChatMessage(
            id: 'invalid',
            sessionId: 'missing',
            role: ChatRole.user,
            type: ChatMessageType.text,
            content: 'invalid',
            createdAt: _now,
          ),
        ),
        throwsA(_rejected),
      );
    },
  );

  test(
    'composition accepts injected stores and disposes their pending work',
    () async {
      var generated = 0;
      final todos = TodoRepository(initial: [], clock: () => _now);
      final container = ProviderContainer(
        overrides: [
          todoListProvider.overrideWith((ref) => todos),
          reportListProvider.overrideWith(
            (ref) => ReportRepository(
              initial: [],
              clock: () => _now,
              generationDelay: const Duration(milliseconds: 10),
              compose: (report) {
                generated++;
                return report.copyWith(status: ReportStatus.ready);
              },
            ),
          ),
        ],
      );
      todos.addTodo(title: 'Injected task');
      expect(container.read(todoListProvider).single.title, 'Injected task');
      container
          .read(reportListProvider.notifier)
          .startGeneration(
            periodStart: _now,
            periodEnd: _now,
            type: ReportType.custom,
            periodLabel: 'scope disposal',
            categories: [],
          );
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(generated, 0);
    },
  );

  test('every seeded repository can publish immutable snapshots', () {
    final categories = CategoryRepository();
    final todos = TodoRepository(clock: () => _now);
    final chat = ChatRepository(clock: () => _now);
    final memories = MemoryRepository(clock: () => _now);
    final reports = ReportRepository(clock: () => _now);
    final tables = DataTableRepository(clock: () => _now);
    final quota = QuotaRepository();
    addTearDown(() {
      categories.dispose();
      todos.dispose();
      chat.dispose();
      memories.dispose();
      reports.dispose();
      tables.dispose();
      quota.dispose();
    });
    expect(() => categories.snapshot.clear(), throwsUnsupportedError);
    expect(() => todos.snapshot.clear(), throwsUnsupportedError);
    expect(() => chat.snapshot.clear(), throwsUnsupportedError);
    expect(() => memories.snapshot.clear(), throwsUnsupportedError);
    expect(() => reports.snapshot.clear(), throwsUnsupportedError);
    expect(() => tables.snapshot.rows.clear(), throwsUnsupportedError);
    expect(
      () => tables.snapshot.rows.first.values.clear(),
      throwsUnsupportedError,
    );
    expect(() => quota.snapshot.bars.clear(), throwsUnsupportedError);
    final previous = todos.snapshot;
    todos.addTodo(title: 'new');
    expect(todos.snapshot.length, previous.length + 1);
    expect(previous.any((todo) => todo.title == 'new'), isFalse);
  });

  test(
    'category deletion promotes archived children without orphaning them',
    () {
      final repo = CategoryRepository(
        initial: [
          const Category(id: 'parent', name: 'parent', color: Colors.blue),
          const Category(
            id: 'child',
            name: 'child',
            color: Colors.blue,
            parentId: 'parent',
            archived: true,
          ),
          const Category(id: 'other', name: 'other', color: Colors.blue),
        ],
      );
      addTearDown(repo.dispose);
      expect(repo.moveCategory('parent', 'other', 0), isFalse);
      repo.removeKeepChildren('parent');
      expect(repo.byId('child')!.parentId, isNull);
      expect(repo.byId('child')!.archived, isTrue);
      expect(repo.archivedRoots.map((item) => item.id), contains('child'));
    },
  );

  test('category commands reject invalid trees without modifying state', () {
    final repo = CategoryRepository(initial: []);
    addTearDown(repo.dispose);
    expect(
      () => repo.createCategory(
        name: 'orphan',
        color: Colors.blue,
        parentId: 'missing',
      ),
      throwsA(_rejected),
    );
    expect(repo.snapshot, isEmpty);
    repo.add(const Category(id: 'parent', name: 'parent', color: Colors.blue));
    repo.add(
      const Category(
        id: 'child',
        name: 'child',
        parentId: 'parent',
        color: Colors.blue,
      ),
    );
    expect(
      () => repo.createCategory(
        name: 'third',
        color: Colors.blue,
        parentId: 'child',
      ),
      throwsA(_rejected),
    );
    expect(() => repo.add(repo.byId('parent')!), throwsA(_rejected));
    repo.setArchived('parent', true);
    repo.setArchived('child', false);
    expect(repo.byId('parent')!.archived, isFalse);
    expect(repo.byId('child')!.archived, isFalse);
  });

  test('todo writes enforce IDs and consistent completion timestamps', () {
    final repo = TodoRepository(initial: [], clock: () => _now);
    addTearDown(repo.dispose);
    final todo = repo.addTodo(title: ' task ', id: 'a');
    expect(todo.title, 'task');
    expect(() => repo.addTodo(title: 'duplicate', id: 'a'), throwsA(_rejected));
    expect(() => repo.addTodo(title: '  '), throwsA(_rejected));
    repo.updateTodo(todo.copyWith(status: TodoStatus.done));
    expect(repo.byId('a')!.completedAt, _now);
    repo.updateTodo(repo.byId('a')!.copyWith(status: TodoStatus.pending));
    expect(repo.byId('a')!.completedAt, isNull);
    repo.insertRaw(todo.copyWith(title: 'stale undo'));
    expect(repo.byId('a')!.title, 'task');
  });

  test(
    'streaming updates and removals keep searchable chat previews current',
    () {
      final repo = ChatRepository(initial: [], clock: () => _now);
      addTearDown(repo.dispose);
      final session = repo.createSession();
      final user = ChatMessage(
        id: 'u',
        sessionId: session.id,
        role: ChatRole.user,
        type: ChatMessageType.text,
        content: 'Question',
        createdAt: _now,
      );
      final assistant = ChatMessage(
        id: 'a',
        sessionId: session.id,
        role: ChatRole.assistant,
        type: ChatMessageType.text,
        content: '',
        createdAt: _now,
      );
      repo.appendMessage(user);
      repo.appendMessage(assistant);
      expect(repo.sessionById(session.id)!.lastMessagePreview, 'Question');
      repo.updateMessage(assistant.copyWith(content: 'Complete answer'));
      expect(
        repo.sessionById(session.id)!.lastMessagePreview,
        'Complete answer',
      );
      expect(() => repo.appendMessage(user), throwsA(_rejected));
      expect(
        () => repo.appendMessage(
          ChatMessage(
            id: 'orphan',
            sessionId: 'missing',
            role: ChatRole.user,
            type: ChatMessageType.text,
            content: 'lost',
            createdAt: _now,
          ),
        ),
        throwsA(_rejected),
      );
      repo.removeMessage(session.id, 'a');
      expect(repo.sessionById(session.id)!.lastMessagePreview, 'Question');
      expect(() => repo.messagesOf(session.id).clear(), throwsUnsupportedError);
    },
  );

  test(
    'concurrent reports finish independently and stopping one preserves others',
    () async {
      final repo = ReportRepository(
        initial: [],
        clock: () => _now,
        generationDelay: const Duration(milliseconds: 10),
      );
      addTearDown(repo.dispose);
      final first = _generate(repo, 'first');
      final second = _generate(repo, 'second');
      final stopped = _generate(repo, 'stopped');
      repo.stopGeneration(stopped.id);
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(repo.byId(first.id)!.status, ReportStatus.ready);
      expect(repo.byId(second.id)!.status, ReportStatus.ready);
      expect(repo.byId(stopped.id), isNull);
      repo.stopGeneration(first.id);
      expect(repo.byId(first.id), isNotNull);
    },
  );

  test(
    'report completion failures become retryable and dispose cancels work',
    () async {
      var calls = 0;
      final repo = ReportRepository(
        initial: [],
        clock: () => _now,
        generationDelay: const Duration(milliseconds: 10),
        compose: (report) {
          calls++;
          throw StateError('simulated failure');
        },
      );
      final report = _generate(repo, 'retry');
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(repo.byId(report.id)!.status, ReportStatus.failed);
      expect(repo.byId(report.id)!.failureReason, isNotEmpty);
      repo.regenerate(report.id);
      expect(repo.byId(report.id)!.status, ReportStatus.generating);
      repo.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(calls, 1);
    },
  );

  test(
    'data batch validation is atomic for cross-table and stale row changes',
    () {
      final repo = _tableRepo();
      addTearDown(repo.dispose);
      final batch = _batch(repo, [
        _update('ok'),
        _update('wrong_table', rowId: 'row_b'),
      ]);
      final before = repo.snapshot;
      expect(
        () => repo.applyPendingBatch(batch.id, {'ok', 'wrong_table'}),
        throwsA(_rejected),
      );
      expect(identical(repo.snapshot, before), isTrue);
      expect(repo.rowsOf('a').single.values['amount'], '1');
      expect(repo.snapshot.logs, isEmpty);
      repo.discardPendingBatch(batch.id);
      final stale = _batch(repo, [_update('stale')]);
      repo.updateCell('row_a', 'amount', '5');
      final modified = repo.snapshot;
      expect(
        () => repo.applyPendingBatch(stale.id, {'stale'}),
        throwsA(_rejected),
      );
      expect(identical(repo.snapshot, modified), isTrue);
    },
  );

  test(
    'batch publishes once, preserves unchecked changes, and undo is audited',
    () {
      final repo = _tableRepo();
      addTearDown(repo.dispose);
      final batch = _batch(repo, [
        _update('selected'),
        _update('unchecked', field: 'name', oldValue: 'a', newValue: 'new'),
      ]);
      var notifications = 0;
      final unsubscribe = repo.addListener(
        (_) => notifications++,
        fireImmediately: false,
      );
      addTearDown(unsubscribe);
      expect(repo.applyPendingBatch(batch.id, {'selected'}), ['row_a']);
      expect(notifications, 1);
      expect(repo.batchesOf('a').single.changes.single.id, 'unchecked');
      expect(repo.rowsOf('a').single.values['amount'], '2');
      repo.undoLastApply();
      expect(repo.rowsOf('a').single.values['amount'], '1');
      expect(repo.batchesOf('a').single.changes.length, 2);
      expect(repo.logsOfRow('row_a').first.reason, '撤销 AI 批次');
    },
  );

  test('undo rejects newer manual edits instead of losing them', () {
    final repo = _tableRepo();
    addTearDown(repo.dispose);
    final batch = _batch(repo, [_update('ai')]);
    repo.applyPendingBatch(batch.id, {'ai'});
    repo.updateCell('row_a', 'amount', '9');
    final before = repo.snapshot;
    expect(repo.undoLastApply, throwsA(_rejected));
    expect(identical(repo.snapshot, before), isTrue);
    expect(repo.rowsOf('a').single.values['amount'], '9');
  });

  test('undo retains first snapshot for multiple changes to the same row', () {
    final repo = _tableRepo();
    addTearDown(repo.dispose);
    final batch = _batch(repo, [
      _update('amount'),
      _update('name', field: 'name', oldValue: 'a', newValue: 'new'),
    ]);
    repo.applyPendingBatch(batch.id, {'amount', 'name'});
    repo.undoLastApply();
    expect(repo.rowsOf('a').single.values, {'name': 'a', 'amount': '1'});
  });

  test('rollback respects log insertion order when timestamps are equal', () {
    final repo = _tableRepo();
    addTearDown(repo.dispose);
    repo.updateCell('row_a', 'amount', '2');
    final target = repo.logsOfRow('row_a').first;
    repo.updateCell('row_a', 'amount', '3');
    repo.updateCell('row_a', 'name', 'new');
    repo.rollbackTo('row_a', target.id);
    expect(repo.rowsOf('a').single.values, {'name': 'a', 'amount': '2'});
    expect(repo.logsOfRow('row_a').length, 4);
  });

  test(
    'invalid table seed, orphan row, duplicate ID never partially commit',
    () {
      final repo = _tableRepo();
      addTearDown(repo.dispose);
      final before = repo.snapshot;
      expect(
        () => repo.createTable(
          name: 'bad',
          columns: [DataColumnDef(name: 'name', type: 'text')],
          seedRows: [
            {'name': 'valid'},
            {'missing': 'invalid'},
          ],
        ),
        throwsA(_rejected),
      );
      expect(identical(repo.snapshot, before), isTrue);
      expect(
        () => repo.addRow('missing', {'name': 'orphan'}),
        throwsA(_rejected),
      );
      expect(
        () => repo.addRow('a', {'name': 'duplicate'}, id: 'row_a'),
        throwsA(_rejected),
      );
      expect(identical(repo.snapshot, before), isTrue);
    },
  );
}
