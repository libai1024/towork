import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_model_codec.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/domain/workspace/workspace_plans.dart';

void main() {
  late Directory directory;
  late File file;
  late AppDatabase db;
  late SqliteWorkspaceCommandStore store;
  final now = DateTime.utc(2026, 9, 24, 9, 31, 12, 123, 456);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('towork-workspace-');
    file = File('${directory.path}/workspace.sqlite');
    db = AppDatabase.background(file);
    store = SqliteWorkspaceCommandStore(db, clock: () => now);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });
  WorkspaceMutation todo(
    String id, {
    Map<String, Object?> patch = const {},
    int? version,
    bool delete = false,
  }) => WorkspaceMutation(
    actionId: 'todo_$id',
    kind: WorkspaceEntityKind.todo,
    entityId: id,
    mutation: delete
        ? WorkspaceMutationKind.delete
        : version == null
        ? WorkspaceMutationKind.create
        : WorkspaceMutationKind.update,
    expectedVersion: version,
    patch: delete ? {} : {'title': '待办 $id', ...patch},
  );
  WorkspaceMutation category(
    String id, {
    String? parent,
    int? version,
    bool delete = false,
  }) => WorkspaceMutation(
    actionId: 'cat_$id',
    kind: WorkspaceEntityKind.category,
    entityId: id,
    mutation: delete
        ? WorkspaceMutationKind.delete
        : version == null
        ? WorkspaceMutationKind.create
        : WorkspaceMutationKind.update,
    expectedVersion: version,
    patch: delete ? {} : {'name': '分类 $id', 'parent_id': parent},
  );
  Future<WorkspaceReceipt> run(
    String operation,
    List<WorkspaceMutation> actions,
  ) =>
      store.execute(WorkspaceCommand(operationId: operation, actions: actions));
  Matcher failure(WorkspaceFailureCode code) =>
      throwsA(isA<WorkspaceFailure>().having((e) => e.code, 'code', code));

  test(
    'repeat timezone survives codec, reopen, rule edits and atomic undo',
    () async {
      await run('repeat-create', [
        todo(
          'repeating',
          patch: {
            'repeat_rule': 'FREQ=MONTHLY;BYMONTHDAY=31;COUNT=4',
            'repeat_timezone': 'America/New_York',
            'due_at': '2026-01-31T14:00:00Z',
          },
        ),
      ]);
      await db.close();
      db = AppDatabase.background(file);
      store = SqliteWorkspaceCommandStore(db, clock: () => now);
      final item = workspaceTodo((await store.load()).todos.single);
      expect(item.repeatTimezone, 'America/New_York');
      expect(
        todoWorkspaceData(item.copyWith(title: '保留时区'))['repeat_timezone'],
        'America/New_York',
      );
      await run('repeat-edit', [
        todo(
          'repeating',
          version: 1,
          patch: {
            'repeat_rule': 'FREQ=DAILY;COUNT=2',
            'repeat_timezone': 'Asia/Shanghai',
          },
        ),
      ]);
      await store.undo('repeat-edit', operationId: 'repeat-undo');
      final restored = workspaceTodo((await store.load()).todos.single);
      expect(restored.repeatTimezone, 'America/New_York');
      expect(restored.repeatRule, 'FREQ=MONTHLY;BYMONTHDAY=31;COUNT=4');
      final cleared = restored.copyWith(repeatRule: null, repeatTimezone: null);
      await run('repeat-clear', [
        todo('repeating', version: 3, patch: todoWorkspaceData(cleared)),
      ]);
      expect(
        workspaceTodo((await store.load()).todos.single).repeatTimezone,
        isNull,
      );
    },
  );
  test(
    'invalid repeat or timezone rolls back every action in the batch',
    () async {
      for (final (index, patch) in <Map<String, Object?>>[
        {'repeat_rule': 'FREQ=DAILY;INTERVAL=0'},
        {'repeat_rule': 'FREQ=MONTHLY;BYDAY=1MO'},
        {'repeat_rule': 'FREQ=DAILY', 'repeat_timezone': 'PST'},
      ].indexed) {
        await expectLater(
          run('invalid-repeat-$index', [
            todo('valid'),
            todo('invalid', patch: patch),
          ]),
          failure(WorkspaceFailureCode.validation),
        );
        expect((await store.load()).todos, isEmpty);
      }
    },
  );
  test(
    'legacy rules remain readable and editable without silent normalization',
    () async {
      await run('legacy-create', [todo('legacy')]);
      final data = {...(await store.load()).todos.single.data};
      data.remove('repeat_timezone');
      data['repeat_rule'] = 'FREQ=MONTHLY;BYDAY=1MO';
      await db.customStatement(
        'UPDATE work_todos SET payload = ? WHERE id = ?',
        [jsonEncode(data), 'legacy'],
      );
      final old = workspaceTodo((await store.load()).todos.single);
      expect(old.repeatTimezone, isNull);
      await run('legacy-edit-title', [
        todo('legacy', version: 1, patch: {'title': '只改标题'}),
      ]);
      expect(
        (await store.load()).todos.single.data['repeat_rule'],
        'FREQ=MONTHLY;BYDAY=1MO',
      );
      await run('legacy-reset', [
        todo('legacy', version: 2, patch: {'repeat_rule': 'FREQ=DAILY'}),
      ]);
      expect(
        (await store.load()).todos.single.data['repeat_rule'],
        'FREQ=DAILY',
      );
    },
  );

  test('multi-batch undo collapses overlapping changes and persists an idempotent audit', () async {
    await run('seed', [
      todo('existing', patch: {'title': '原有'}),
    ]);
    await run('first', [
      todo('existing', version: 1, patch: {'title': '修改'}),
      todo('new'),
    ]);
    await run('second', [
      todo('existing', version: 2, patch: {'title': '再次修改'}),
      todo('new', version: 1, patch: {'status': 'done'}),
    ]);
    final receipt = await store.undoMany([
      'first',
      'second',
    ], operationId: 'undo-group');
    final data = await store.load();
    expect(data.todos.single.data['title'], '原有');
    expect(data.todos.single.version, 4);
    expect(data.find(WorkspaceEntityKind.todo, 'new')!.isDeleted, isTrue);
    expect(receipt.undoOf, ['first', 'second']);
    expect(
      (await store.undoMany([
        'first',
        'second',
      ], operationId: 'undo-group')).toJson(),
      receipt.toJson(),
    );
    await db.close();
    db = AppDatabase.background(file);
    store = SqliteWorkspaceCommandStore(db);
    expect((await store.load()).todos.single.version, 4);
    expect(
      (await store.undoMany([
        'first',
        'second',
      ], operationId: 'undo-group')).undoOf,
      ['first', 'second'],
    );
    await expectLater(
      store.undoMany(['second', 'first'], operationId: 'undo-group'),
      failure(WorkspaceFailureCode.idempotencyMismatch),
    );
  });

  test('multi-batch undo preserves every item when any target has later manual edits', () async {
    await run('first', [todo('a')]);
    await run('second', [todo('b')]);
    await run('manual', [
      todo('b', version: 1, patch: {'title': '人工'}),
    ]);
    await expectLater(
      store.undoMany(['first', 'second'], operationId: 'undo'),
      failure(WorkspaceFailureCode.versionConflict),
    );
    expect((await store.load()).todos, hasLength(2));
    expect(await db.select(db.workspaceOperations).get(), hasLength(3));
  });

  test(
    'intervening edits inside a group are not erased by later Agent writes',
    () async {
      await run('first', [todo('a')]);
      await run('manual', [
        todo('a', version: 1, patch: {'note': '人工备注'}),
      ]);
      await run('last', [
        todo('a', version: 2, patch: {'status': 'done'}),
      ]);
      await expectLater(
        store.undoMany(['first', 'last'], operationId: 'undo'),
        failure(WorkspaceFailureCode.versionConflict),
      );
      expect((await store.load()).todos.single.data['note'], '人工备注');
    },
  );

  test(
    'multi-batch undo journal failure rolls back the entire compensation',
    () async {
      await run('first', [todo('a')]);
      await run('second', [todo('b')]);
      final failing = SqliteWorkspaceCommandStore(
        db,
        checkpoint: (_) => throw StateError('fault'),
      );
      await expectLater(
        failing.undoMany(['first', 'second'], operationId: 'undo'),
        failure(WorkspaceFailureCode.storageUnavailable),
      );
      expect((await store.load()).todos, hasLength(2));
      expect(await db.select(db.workspaceOperations).get(), hasLength(2));
    },
  );

  test('promote deletion clears root references and retains child todos; undo restores links', () async {
    await run('base', [
      category('root'),
      category('child', parent: 'root'),
      todo('root_todo', patch: {'category_id': 'root'}),
      todo('child_todo', patch: {'category_id': 'child'}),
    ]);
    final plan = WorkspacePlans.deleteCategory(
      await store.load(),
      'root',
      operationId: 'delete',
      mode: WorkspaceCategoryDeleteMode.promoteChildren,
    );
    await store.execute(plan);
    final after = await store.load();
    expect(after.categories.single.data['parent_id'], isNull);
    expect(
      after.find(WorkspaceEntityKind.todo, 'root_todo')!.data['category_id'],
      isNull,
    );
    expect(after.find(WorkspaceEntityKind.todo, 'child_todo')!.version, 1);
    await store.undo('delete', operationId: 'undo');
    final restored = await store.load();
    expect(
      restored.find(WorkspaceEntityKind.category, 'child')!.data['parent_id'],
      'root',
    );
    expect(
      restored.find(WorkspaceEntityKind.todo, 'root_todo')!.data['category_id'],
      'root',
    );
  });
  test('archive cascades down; restoring a child restores its parent, not siblings', () async {
    await run('base', [
      category('root'),
      category('first', parent: 'root'),
      category('second', parent: 'root'),
    ]);
    await store.execute(
      WorkspacePlans.archiveCategory(
        await store.load(),
        'root',
        operationId: 'archive',
        archived: true,
      ),
    );
    expect(
      (await store.load()).categories.every((e) => e.data['archived'] == true),
      isTrue,
    );
    await store.execute(
      WorkspacePlans.archiveCategory(
        await store.load(),
        'first',
        operationId: 'restore',
        archived: false,
      ),
    );
    final after = await store.load();
    expect(
      after.find(WorkspaceEntityKind.category, 'root')!.data['archived'],
      isFalse,
    );
    expect(
      after.find(WorkspaceEntityKind.category, 'first')!.data['archived'],
      isFalse,
    );
    expect(
      after.find(WorkspaceEntityKind.category, 'second')!.data['archived'],
      isTrue,
    );
  });
  test(
    'subtree deletion refuses a new reference created after the preview',
    () async {
      await run('base', [category('root'), category('child', parent: 'root')]);
      final plan = WorkspacePlans.deleteCategory(
        await store.load(),
        'root',
        operationId: 'delete',
        mode: WorkspaceCategoryDeleteMode.deleteSubtree,
      );
      await run('later', [
        todo('new', patch: {'category_id': 'child'}),
      ]);
      await expectLater(
        store.execute(plan),
        failure(WorkspaceFailureCode.validation),
      );
      expect((await store.load()).categories, hasLength(2));
      expect((await store.load()).todos, hasLength(1));
    },
  );
  test(
    'subtree deletion plan includes child categories and linked todos',
    () async {
      await run('base', [
        category('root'),
        category('child', parent: 'root'),
        todo('one', patch: {'category_id': 'child'}),
        todo('keep'),
      ]);
      await store.execute(
        WorkspacePlans.deleteCategory(
          await store.load(),
          'root',
          operationId: 'delete',
          mode: WorkspaceCategoryDeleteMode.deleteSubtree,
        ),
      );
      expect((await store.load()).categories, isEmpty);
      expect((await store.load()).todos.single.id, 'keep');
    },
  );
  test(
    'all todo fields, category and microsecond timestamps survive reopen',
    () async {
      final receipt = await run('create', [
        category('root'),
        todo(
          'one',
          patch: {
            'note': '正文\n第二行',
            'status': 'done',
            'priority': 'urgent',
            'due_at': '2026-09-25T02:00:00.123456Z',
            'remind_at': '2026-09-25T01:00:00Z',
            'category_id': 'root',
            'source': 'ai',
            'source_message_id': 'message_one',
            'tags': ['工作', '中文'],
            'repeat_rule': 'FREQ=WEEKLY;BYDAY=WE',
            'sort_order': 3,
            'remind_rules': [
              {'id': 'r1', 'offset_minutes': -30},
              {'id': 'r2', 'absolute_at': '2026-09-25T01:00:00Z'},
            ],
          },
        ),
      ]);
      expect(receipt.affected.last.data['completed_at'], now.toIso8601String());
      await db.close();
      db = AppDatabase.background(file);
      store = SqliteWorkspaceCommandStore(db, clock: () => now);
      final loaded = await store.load();
      expect(loaded.categories, hasLength(1));
      expect(loaded.todos.single.toJson(), receipt.affected.last.toJson());
      final raw = await db.select(db.workTodos).getSingle();
      expect(raw.categoryId, 'root');
      expect(raw.status, 'done');
      expect(raw.sortOrder, 3);
    },
  );
  test(
    'patch omission preserves fields and explicit null clears nullable fields',
    () async {
      await run('create', [
        todo(
          'one',
          patch: {
            'note': '笔记',
            'due_at': '2026-09-25T02:00:00Z',
            'status': 'done',
          },
        ),
      ]);
      await run('patch', [
        WorkspaceMutation(
          actionId: 'edit',
          kind: WorkspaceEntityKind.todo,
          entityId: 'one',
          mutation: WorkspaceMutationKind.update,
          expectedVersion: 1,
          patch: {'note': null, 'status': 'pending'},
        ),
      ]);
      final entity = (await store.load()).todos.single;
      expect(entity.data['note'], isNull);
      expect(entity.data['due_at'], '2026-09-25T02:00:00.000Z');
      expect(entity.data['completed_at'], isNull);
      expect(entity.data['title'], '待办 one');
    },
  );
  test(
    'idempotent retry returns original receipt after later edits and reopen',
    () async {
      final input = WorkspaceCommand(
        operationId: 'create',
        actions: [todo('one')],
      );
      final first = await store.execute(input);
      await run('edit', [
        todo('one', version: 1, patch: {'title': '后来改名'}),
      ]);
      await db.close();
      db = AppDatabase.background(file);
      store = SqliteWorkspaceCommandStore(db);
      final retry = await store.execute(input);
      expect(retry.toJson(), first.toJson());
      expect((await store.load()).todos.single.version, 2);
      await expectLater(
        run('create', [todo('different')]),
        failure(WorkspaceFailureCode.idempotencyMismatch),
      );
      expect(await db.select(db.workspaceOperations).get(), hasLength(2));
    },
  );
  test('same ID with reordered JSON keys is the same command', () async {
    final first = await run('same', [
      todo('one', patch: {'note': 'a', 'priority': 'high'}),
    ]);
    final second = await run('same', [
      todo('one', patch: {'priority': 'high', 'note': 'a'}),
    ]);
    expect(second.toJson(), first.toJson());
  });
  test(
    'concurrent duplicate requests commit once on the shared connection',
    () async {
      final command = WorkspaceCommand(
        operationId: 'duplicate',
        actions: [todo('one')],
      );
      final receipts = await Future.wait(
        List.generate(4, (_) => store.execute(command)),
      );
      expect(receipts.every((r) => r.affected.single.version == 1), isTrue);
      expect(await db.select(db.workspaceOperations).get(), hasLength(1));
      expect((await store.load()).todos, hasLength(1));
    },
  );
  test(
    'stale version rejects the whole batch without changing other records',
    () async {
      await run('create', [todo('one'), todo('two')]);
      await run('edit', [todo('two', version: 1)]);
      await expectLater(
        run('stale', [
          todo('one', version: 1, patch: {'title': '不应保存'}),
          todo('two', version: 1),
        ]),
        failure(WorkspaceFailureCode.versionConflict),
      );
      expect(
        (await store.load()).find(WorkspaceEntityKind.todo, 'one')!.version,
        1,
      );
      expect(await db.select(db.workspaceOperations).get(), hasLength(2));
    },
  );
  for (final checkpoint in WorkspaceCommitCheckpoint.values) {
    test(
      'fault at ${checkpoint.name} rolls back entities, audit and receipt',
      () async {
        await run('base', [
          category('root'),
          todo('one', patch: {'category_id': 'root'}),
        ]);
        final failing = SqliteWorkspaceCommandStore(
          db,
          checkpoint: (at) {
            if (at == checkpoint) throw StateError('synthetic IO failure');
          },
        );
        final command = WorkspaceCommand(
          operationId: 'delete',
          actions: [
            category('root', version: 1, delete: true),
            todo('one', version: 1, delete: true),
          ],
        );
        await expectLater(
          failing.execute(command),
          failure(WorkspaceFailureCode.storageUnavailable),
        );
        final loaded = await store.load();
        expect(loaded.categories, hasLength(1));
        expect(loaded.todos.single.version, 1);
        expect(await db.select(db.workspaceOperations).get(), hasLength(1));
        // The failed operation ID was not consumed; retry after recovery can commit.
        await store.execute(command);
        expect((await store.load()).todos, isEmpty);
      },
    );
  }
  test(
    'read-only write failure does not invent a receipt or discard prior data',
    () async {
      await run('base', [todo('one')]);
      await db.customStatement('PRAGMA query_only = ON');
      await expectLater(
        run('fail', [todo('one', version: 1)]),
        failure(WorkspaceFailureCode.storageUnavailable),
      );
      expect((await store.load()).todos.single.version, 1);
      expect(await db.select(db.workspaceOperations).get(), hasLength(1));
    },
  );
  test('category graph rejects dangling references, cycles, depth three and live children of archived parent', () async {
    await expectLater(
      run('dangling', [
        todo('one', patch: {'category_id': 'missing'}),
      ]),
      failure(WorkspaceFailureCode.validation),
    );
    await expectLater(
      run('cycle', [category('a', parent: 'b'), category('b', parent: 'a')]),
      failure(WorkspaceFailureCode.validation),
    );
    await expectLater(
      run('deep', [
        category('a'),
        category('b', parent: 'a'),
        category('c', parent: 'b'),
      ]),
      failure(WorkspaceFailureCode.validation),
    );
    await run('tree', [category('a'), category('b', parent: 'a')]);
    await expectLater(
      run('archive', [
        WorkspaceMutation(
          actionId: 'archive',
          kind: WorkspaceEntityKind.category,
          entityId: 'a',
          mutation: WorkspaceMutationKind.update,
          expectedVersion: 1,
          patch: {'archived': true},
        ),
      ]),
      failure(WorkspaceFailureCode.validation),
    );
    expect(await db.select(db.workspaceOperations).get(), hasLength(1));
  });
  test(
    'batch can create related rows in reverse order and delete them atomically',
    () async {
      await run('tree', [
        todo('one', patch: {'category_id': 'child'}),
        category('child', parent: 'root'),
        category('root'),
      ]);
      await expectLater(
        run('bad-delete', [category('root', version: 1, delete: true)]),
        failure(WorkspaceFailureCode.validation),
      );
      final deleted = await run('delete', [
        category('root', version: 1, delete: true),
        category('child', version: 1, delete: true),
        todo('one', version: 1, delete: true),
      ]);
      expect((await store.load()).todos, isEmpty);
      await store.undo(deleted.changesetId, operationId: 'undo');
      final restored = await store.load();
      expect(restored.todos.single.version, 3);
      expect(restored.categories, hasLength(2));
    },
  );
  test(
    'undo persists across restart and does not overwrite unrelated edits',
    () async {
      await run('create', [todo('one'), todo('two')]);
      await run('delete', [todo('one', version: 1, delete: true)]);
      await run('other', [
        todo('two', version: 1, patch: {'title': '应保留'}),
      ]);
      await db.close();
      db = AppDatabase.background(file);
      store = SqliteWorkspaceCommandStore(db);
      final receipt = await store.undo('delete', operationId: 'undo');
      expect(receipt.affected.single.version, 3);
      expect(
        (await store.load())
            .find(WorkspaceEntityKind.todo, 'two')!
            .data['title'],
        '应保留',
      );
      expect(
        (await store.undo('delete', operationId: 'undo')).toJson(),
        receipt.toJson(),
      );
      await expectLater(
        store.undo('delete', operationId: 'undo-again'),
        failure(WorkspaceFailureCode.versionConflict),
      );
    },
  );
  test(
    'undo conflict is atomic, even if the first affected entity still matches',
    () async {
      await run('base', [todo('one'), todo('two')]);
      await run('edit', [todo('one', version: 1), todo('two', version: 1)]);
      await run('later', [todo('two', version: 2)]);
      await expectLater(
        store.undo('edit', operationId: 'undo'),
        failure(WorkspaceFailureCode.versionConflict),
      );
      expect(
        (await store.load()).find(WorkspaceEntityKind.todo, 'one')!.version,
        2,
      );
      expect(await db.select(db.workspaceOperations).get(), hasLength(3));
    },
  );
  test(
    'undo category creation refuses to orphan a later linked todo',
    () async {
      await run('cat', [category('root')]);
      await run('todo', [
        todo('one', patch: {'category_id': 'root'}),
      ]);
      await expectLater(
        store.undo('cat', operationId: 'undo'),
        failure(WorkspaceFailureCode.validation),
      );
      expect((await store.load()).categories, hasLength(1));
    },
  );
  test('tombstones prevent deleted IDs from being reused', () async {
    await run('base', [todo('one')]);
    await run('delete', [todo('one', version: 1, delete: true)]);
    await expectLater(
      run('recreate', [todo('one')]),
      failure(WorkspaceFailureCode.versionConflict),
    );
    expect(
      (await store.load()).find(WorkspaceEntityKind.todo, 'one')!.isDeleted,
      isTrue,
    );
  });
  test('watch emits committed snapshots and cannot expose partial category deletion', () async {
    final snapshots = <WorkspaceSnapshot>[];
    final first = Completer<void>();
    final deleted = Completer<void>();
    final subscription = store.watch().listen((snapshot) {
      snapshots.add(snapshot);
      if (!first.isCompleted) first.complete();
      if (snapshot.find(WorkspaceEntityKind.todo, 'one')?.isDeleted == true &&
          !deleted.isCompleted) {
        deleted.complete();
      }
    });
    addTearDown(
      () => subscription.cancel().timeout(const Duration(seconds: 3)),
    );
    await first.future.timeout(const Duration(seconds: 3));
    await run('base', [
      category('root'),
      todo('one', patch: {'category_id': 'root'}),
    ]);
    await run('delete', [
      category('root', version: 1, delete: true),
      todo('one', version: 1, delete: true),
    ]);
    await deleted.future.timeout(const Duration(seconds: 3));
    expect(
      snapshots.every((s) => s.todos.length == s.categories.length),
      isTrue,
    );
  });
  test(
    'invalid payloads and ambiguous mutations are rejected without writes',
    () async {
      for (final patch in <Map<String, Object?>>[
        {'title': '  '},
        {'status': 'invented'},
        {'title': null},
        {'unknown': true},
        {'due_at': '2026-02-30T12:00:00Z'},
        {'due_at': '2026-09-24'},
        {
          'remind_rules': [
            {
              'id': 'r',
              'absolute_at': '2026-09-24T12:00:00Z',
              'offset_minutes': 1,
            },
          ],
        },
        {
          'remind_rules': [
            {'id': 'r'},
          ],
        },
        {'color_value': 42},
      ]) {
        await expectLater(
          run('invalid', [todo('one', patch: patch)]),
          failure(WorkspaceFailureCode.validation),
        );
      }
      await expectLater(
        run('duplicate', [todo('one'), todo('one')]),
        failure(WorkspaceFailureCode.validation),
      );
      expect((await store.load()).entities, isEmpty);
    },
  );
  test(
    'inputs and outputs cannot be mutated through nested JSON aliases',
    () async {
      final tags = ['原始'];
      final action = todo('one', patch: {'tags': tags});
      tags.add('外部修改');
      final receipt = await run('create', [action]);
      expect(receipt.affected.single.data['tags'], ['原始']);
      expect(
        () => (receipt.affected.single.data['tags']! as List).add('修改'),
        throwsUnsupportedError,
      );
    },
  );
  test('v2 migration preserves identity and configuration while starting empty workspace', () async {
    await db.close();
    final legacy = sqlite.sqlite3.open(file.path);
    legacy.execute(
      File('test/fixtures/local/schema_v2.sql').readAsStringSync(),
    );
    legacy.execute(
      "INSERT INTO local_profiles VALUES (1, 'old-local-id', '旧用户', 5, 1750000000)",
    );
    legacy.execute(
      "INSERT INTO provider_configurations VALUES (1, 'code', 'china', 'kimi-for-coding', 1, 9, 'reference-only')",
    );
    legacy.close();
    db = AppDatabase.background(file);
    store = SqliteWorkspaceCommandStore(db);
    expect((await db.loadOrCreateProfile()).id, 'old-local-id');
    expect((await db.loadOrCreateProfile()).version, 5);
    expect((await db.readConfiguration()).credentialRef, 'reference-only');
    expect((await db.readConfiguration()).version, 9);
    expect((await store.load()).entities, isEmpty);
    await run('after-migration', [todo('one')]);
    expect((await store.load()).todos, hasLength(1));
  });
  test(
    'failed migration rolls back newly created tables and preserves v2 data',
    () async {
      await db.close();
      final legacy = sqlite.sqlite3.open(file.path);
      legacy.execute(
        File('test/fixtures/local/schema_v2.sql').readAsStringSync(),
      );
      legacy.execute(
        "INSERT INTO local_profiles VALUES (1, 'preserved-id', '原记录', 1, 1750000000)",
      );
      // Simulate a conflicting table so the third CREATE fails after two succeeded.
      legacy.execute('CREATE TABLE workspace_operations (unexpected TEXT)');
      legacy.close();
      db = AppDatabase.background(file);
      store = SqliteWorkspaceCommandStore(db);
      await expectLater(
        store.load(),
        failure(WorkspaceFailureCode.storageUnavailable),
      );
      await db.close();
      final preserved = sqlite.sqlite3.open(file.path);
      expect(preserved.select('PRAGMA user_version').single['user_version'], 2);
      expect(
        preserved
            .select('SELECT local_user_id FROM local_profiles')
            .single['local_user_id'],
        'preserved-id',
      );
      expect(
        preserved.select(
          "SELECT name FROM sqlite_master WHERE name IN ('work_todos', 'work_categories')",
        ),
        isEmpty,
      );
      preserved.execute('DROP TABLE workspace_operations');
      preserved.close();
      db = AppDatabase.background(file);
      store = SqliteWorkspaceCommandStore(db);
      expect((await store.load()).entities, isEmpty);
    },
  );
}
