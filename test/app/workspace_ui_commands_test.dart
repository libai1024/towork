import 'package:towork/domain/repositories/todo_store.dart';

import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart' show driftRuntimeOptions;

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/app/workspace_ui_commands.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/domain/use_cases/category_actions.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/app/todo/async_todo_commands.dart';

void main() {
  late Directory dir;
  late AppDatabase db;
  late LocalWorkspaceSession session;
  late WorkspaceUiCommands commands;
  late AsyncTodoCommands todos;
  Future<void> attach() async {
    final store = SqliteWorkspaceCommandStore(db);
    session = LocalWorkspaceSession(store, await store.load());
    commands = WorkspaceUiCommands(
      session.todos,
      session.categories,
      session: session,
    );
    todos = AsyncTodoCommands(commands, DateTime.now);
  }

  Future<void> close() async {
    await session.dispose();
    session.todos.dispose();
    session.categories.dispose();
    await db.close();
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('towork-ui-commands');
    db = AppDatabase.background(File('${dir.path}/db.sqlite'));
    await attach();
  });
  tearDown(() async {
    await close();
    await dir.delete(recursive: true);
  });

  test('empty production workspace never injects demo seeds', () {
    expect(session.todos.snapshot, isEmpty);
    expect(session.categories.snapshot, isEmpty);
    expect(session.todos, isNot(isA<TodoStore>()));
  });
  test('manual create, batch completion, restart and durable undo use the same records', () async {
    final createdCategory = await commands.run(
      (t, c) => c.createCategory(name: '工作', color: const Color(0xff112233)),
    );
    final a = await todos.create(
      title: '准备周会',
      categoryId: createdCategory.value.id,
    );
    final b = await todos.create(
      title: '发送资料',
      categoryId: createdCategory.value.id,
    );
    expect(a.version, 1);
    final completed = await todos.complete([a.id, b.id]);
    expect(completed.count, 2);
    expect(
      session.todos.snapshot.every((t) => t.status == TodoStatus.done),
      isTrue,
    );
    await completed.undo();
    expect(
      session.todos.snapshot.every((t) => t.status == TodoStatus.pending),
      isTrue,
    );
    final deleted = await todos.delete([a.id]);
    expect(session.todos.byId(a.id), isNull);
    await deleted.undo();
    await close();
    db = AppDatabase.background(File('${dir.path}/db.sqlite'));
    await attach();
    expect(session.todos.snapshot, hasLength(2));
    expect(session.todos.byId(a.id)!.version, 5);
    expect(session.categories.snapshot.single.color, const Color(0xff112233));
  });
  test(
    'a stale detail edit is rejected instead of overwriting newer fields',
    () async {
      final initial = await todos.create(title: '初始');
      await commands.updateTodo(initial.copyWith(note: '已提交备注'));
      await expectLater(
        commands.updateTodo(initial.copyWith(title: '旧页面改名')),
        throwsA(isA<WorkspaceFailure>()),
      );
      expect(session.todos.byId(initial.id)!.note, '已提交备注');
      expect(session.todos.byId(initial.id)!.title, '初始');
    },
  );
  test(
    'failed save keeps projection intact and form retry reuses stable identity',
    () async {
      await db.customStatement('PRAGMA query_only = ON');
      await expectLater(
        commands.createTodo(title: '重试', operationId: 'same-form'),
        throwsA(isA<WorkspaceFailure>()),
      );
      expect(session.todos.snapshot, isEmpty);
      await db.customStatement('PRAGMA query_only = OFF');
      final result = await commands.createTodo(
        title: '重试',
        operationId: 'same-form',
      );
      expect(result.id, 'same-form_t_0');
      expect(session.todos.snapshot, hasLength(1));
    },
  );
  test(
    'a second connection can replay a committed form after other writes',
    () async {
      await todos.create(title: '已有记录');
      final due = DateTime(2026, 11, 20, 16);
      Future<Todo> submit(
        AsyncTodoCommands target, {
        String title = '  核对款项  ',
      }) => target.create(
        operationId: 'same-completed-form',
        title: title,
        note: '检查明细',
        priority: TodoPriority.urgent,
        dueAt: due,
        status: TodoStatus.done,
        remindRules: const [RemindRule(id: 'r1', offsetMinutes: 15)],
      );
      final original = await submit(todos);
      expect(original.sortOrder, 1);
      expect(original.completedAt, isNotNull);
      await todos.create(title: '另一条待办');
      final previousWarning =
          driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases =
            previousWarning,
      );
      final peerDb = AppDatabase.background(File('${dir.path}/db.sqlite'));
      final store = SqliteWorkspaceCommandStore(peerDb);
      final peer = LocalWorkspaceSession(store, await store.load());
      try {
        final peerCommands = WorkspaceUiCommands(
          peer.todos,
          peer.categories,
          session: peer,
        );
        final peerTodos = AsyncTodoCommands(peerCommands, DateTime.now);
        final replay = await submit(peerTodos);
        expect(replay.id, original.id);
        expect(replay.sortOrder, original.sortOrder);
        expect(replay.completedAt, original.completedAt);
        expect(replay.createdAt, original.createdAt);
        expect(replay.note, '检查明细');
        expect(replay.dueAt, due);
        expect(replay.priority, TodoPriority.urgent);
        expect(replay.remindRules.single.offsetMinutes, 15);
        expect(peer.todos.snapshot, hasLength(3));
        await expectLater(
          submit(peerTodos, title: '另一份表单'),
          throwsA(
            isA<WorkspaceFailure>().having(
              (e) => e.code,
              'code',
              WorkspaceFailureCode.idempotencyMismatch,
            ),
          ),
        );
        final chat = await peerCommands.appendTodo(
          title: '检查邮件',
          source: TodoSource.ai,
          sourceMessageId: 'chat1',
        );
        expect(chat.value.source, TodoSource.ai);
        expect(chat.value.sourceMessageId, 'chat1');
        await chat.undo();
      } finally {
        await peer.dispose();
        peer.todos.dispose();
        peer.categories.dispose();
        await peerDb.close();
      }
      await close();
      db = AppDatabase.background(File('${dir.path}/db.sqlite'));
      await attach();
      expect(session.todos.snapshot, hasLength(3));
      expect(session.todos.byId(original.id)!.title, '核对款项');
      expect(session.todos.byId(original.id)!.version, 1);
    },
  );

  test(
    'category delete and undo update both projections in one commit',
    () async {
      final category = (await commands.run(
        (t, c) => c.createCategory(name: '项目', color: const Color(0xff334455)),
      )).value;
      final task = await todos.create(title: '任务', categoryId: category.id);
      final undo = await commands.deleteCategory(
        category.id,
        preview: CategoryDeletePreview.capture(
          category.id,
          session.categories,
          session.todos,
        ),
        policy: CategoryDeletionPolicy.keepTodosAndChildren,
      );
      expect(session.categories.snapshot, isEmpty);
      expect(session.todos.byId(task.id)!.categoryId, isNull);
      expect(await undo.undo(), CategoryUndoResult.restored);
      expect(session.categories.snapshot.single.id, category.id);
      expect(session.todos.byId(task.id)!.categoryId, category.id);
    },
  );
  test('older receipt cannot replace a newer committed projection', () async {
    final task = await todos.create(title: '初始');
    final older = session.snapshot;
    await commands.updateTodo(task.copyWith(title: '较新'));
    session.accept(older);
    expect(session.todos.byId(task.id)!.title, '较新');
  });
  test(
    'category confirmation cannot silently include a newly attached task',
    () async {
      final category = (await commands.run(
        (t, c) => c.createCategory(name: '待确认', color: const Color(0xff334455)),
      )).value;
      await todos.create(title: '预览中的任务', categoryId: category.id);
      final preview = CategoryDeletePreview.capture(
        category.id,
        session.categories,
        session.todos,
      );
      await todos.create(title: '确认期间新加入', categoryId: category.id);
      await expectLater(
        commands.deleteCategory(
          category.id,
          policy: CategoryDeletionPolicy.deleteSubtree,
          preview: preview,
        ),
        throwsA(
          isA<WorkspaceFailure>().having(
            (e) => e.code,
            'code',
            WorkspaceFailureCode.versionConflict,
          ),
        ),
      );
      expect(session.todos.snapshot, hasLength(2));
      expect(session.categories.snapshot, hasLength(1));
    },
  );
}
