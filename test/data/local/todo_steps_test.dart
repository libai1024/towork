import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/data/local/workspace_model_codec.dart';
import 'package:towork/domain/models/todo.dart';
import 'package:towork/domain/recurrence/recurrence_plans.dart';
import 'package:towork/domain/workspace/append_todo.dart';
import 'package:towork/domain/workspace/todo_step_edit.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/domain/workspace/workspace_queries.dart';

void main() {
  final now = DateTime.utc(2026, 11, 20);
  late Directory dir;
  late AppDatabase db;
  late SqliteWorkspaceCommandStore store;
  void open() {
    db = AppDatabase.background(File('${dir.path}/steps.sqlite'));
    store = SqliteWorkspaceCommandStore(db, clock: () => now);
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('towork-steps');
    open();
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  Future<WorkspaceEntity> seed({List<TodoStep> steps = const []}) async {
    final op = WorkspaceCommand(
      operationId: 'create',
      actions: [
        AppendTodo(
          operationId: 'create',
          title: '报销',
          status: TodoStatus.inProgress,
          dueAt: now,
          steps: steps,
        ),
      ],
    );
    final receipt = await store.execute(op);
    expect((await store.execute(op)).toJson(), receipt.toJson());
    return receipt.affected.single;
  }

  WorkspaceCommand plan(WorkspaceEntity e, TodoStepEdit edit, String id) {
    final t = workspaceTodo(e);
    return WorkspaceCommand(
      operationId: id,
      actions: [
        WorkspaceMutation(
          actionId: 'edit',
          kind: e.kind,
          entityId: e.id,
          expectedVersion: e.version,
          mutation: WorkspaceMutationKind.update,
          patch: edit.patch(t.steps, t.status),
        ),
      ],
    );
  }

  test(
    'move, out-of-order completion, undo, reopen and cold restart',
    () async {
      final a = await seed(
        steps: const [
          TodoStep(id: 'one', title: '核对'),
          TodoStep(id: 'two', title: '核对'),
          TodoStep(id: 'three', title: '提交'),
        ],
      );
      Future<WorkspaceEntity> edit(
        WorkspaceEntity e,
        TodoStepEdit edit,
        String id,
      ) async => (await store.execute(plan(e, edit, id))).affected.single;
      final b = await edit(a, const TodoStepEdit.move('two', -1), 'move');
      final c = await edit(b, const TodoStepEdit.check('three', true), 'third');
      final d = await edit(c, const TodoStepEdit.check('one', true), 'first');
      final command = plan(d, const TodoStepEdit.check('two', true), 'last');
      final receipt = await store.execute(command);
      expect(workspaceTodo(receipt.affected.single).completedAt?.toUtc(), now);
      expect((await store.execute(command)).toJson(), receipt.toJson());
      await db.close();
      open();
      final restored = (await store.undo(
        'last',
        operationId: 'restore',
      )).affected.single;
      expect(workspaceTodo(restored).status, TodoStatus.inProgress);
      expect(workspaceTodo(restored).steps.map((s) => (s.id, s.done)), [
        ('two', false),
        ('one', true),
        ('three', true),
      ]);
      final done = await edit(
        restored,
        const TodoStepEdit.check('two', true),
        'finish',
      );
      final reopened = await edit(
        done,
        const TodoStepEdit.check('one', false),
        'reopen',
      );
      expect(reopened.data['status'], 'pending');
      expect(reopened.data['completed_at'], isNull);
      await expectLater(
        store.execute(
          plan(d, const TodoStepEdit.rename('one', '旧写入'), 'stale'),
        ),
        throwsA(isA<WorkspaceFailure>()),
      );
      final removed = await edit(
        reopened,
        const TodoStepEdit.remove('one'),
        'remove',
      );
      expect(workspaceTodo(removed).stepProgress, '步骤 2/2');
      expect(removed.data['status'], 'pending');
    },
  );
  test(
    'recurrence inherits ordered names and gives each occurrence fresh checks',
    () async {
      final first = await seed(
        steps: const [
          TodoStep(id: 'one', title: '核对', done: true),
          TodoStep(id: 'two', title: '提交'),
        ],
      );
      final p = RecurrencePlans(await store.load(), now: now);
      await store.execute(
        p.start(
          first.id,
          rule: 'FREQ=DAILY;COUNT=3',
          timezone: 'Asia/Shanghai',
          operationId: 'repeat',
          through: now.add(const Duration(days: 3)),
        ),
      );
      final rows = (await store.load()).todos.toList()
        ..sort(
          (a, b) => (a.data['occurrence_index']! as int).compareTo(
            b.data['occurrence_index']! as int,
          ),
        );
      expect(rows.map((e) => workspaceTodo(e).completedSteps), [1, 0, 0]);
      await store.execute(
        plan(rows.first, const TodoStepEdit.check('two', true), 'finish'),
      );
      expect(
        workspaceTodo(
          (await store.load()).todos.firstWhere((e) => e.id == rows.last.id),
        ).status,
        TodoStatus.pending,
      );
    },
  );
  test('AI pages step detail with an expected version; legacy and malformed payloads', () async {
    final row = await seed(
      steps: [
        for (var i = 0; i < 14; i++)
          TodoStep(id: 's$i', title: '步骤 $i', done: true),
      ],
    );
    expect(row.data['status'], 'done');
    final snap = await store.load();
    final page = WorkspaceQueries.todo(snap, {'id': row.id});
    expect(page['completed_steps'], 14);
    expect(page['steps'] as List, hasLength(10));
    expect(page['next_step_offset'], 10);
    expect(
      WorkspaceQueries.todo(snap, {
            'id': row.id,
            'expected_version': row.version,
            'step_offset': 10,
          })['steps']
          as List,
      hasLength(4),
    );
    expect(
      () => WorkspaceQueries.todo(snap, {'id': row.id, 'step_offset': 10}),
      throwsA(isA<WorkspaceFailure>()),
    );
    final valid = const TodoStep(id: 'a', title: 'A').toJson();
    for (final data in [
      null,
      [valid, valid],
      [
        {...valid, 'done': 1},
      ],
      [
        {...valid, 'title': '  '},
      ],
    ]) {
      expect(() => TodoStep.decode(data), throwsA(isA<WorkspaceFailure>()));
    }
  });
}
