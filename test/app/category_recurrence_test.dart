import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/app/workspace_ui_commands.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/recurrence/recurrence_plans.dart';
import 'package:towork/domain/use_cases/category_actions.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/domain/workspace/workspace_plans.dart';

void main() {
  late Directory folder;
  late AppDatabase db;
  late SqliteWorkspaceCommandStore store;
  late LocalWorkspaceSession session;
  late WorkspaceUiCommands ui;
  final now = DateTime.utc(2026, 9, 24);
  final through = now.add(const Duration(days: 30));
  Future<void> attach() async {
    store = SqliteWorkspaceCommandStore(db, clock: () => now);
    session = LocalWorkspaceSession(store, await store.load());
    ui = WorkspaceUiCommands(
      session.todos,
      session.categories,
      session: session,
    );
  }

  Future<void> close() async {
    await session.dispose();
    session.todos.dispose();
    session.categories.dispose();
    await db.close();
  }

  Future<void> reopen() async {
    await close();
    db = AppDatabase.background(File('${folder.path}/db.sqlite'));
    await attach();
  }

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('category-series-');
    db = AppDatabase.background(File('${folder.path}/db.sqlite'));
    await attach();
    await session.execute(
      WorkspaceCommand(
        operationId: 'categories',
        actions: [
          for (final id in ['parent', 'child', 'other'])
            WorkspaceMutation(
              actionId: id,
              kind: WorkspaceEntityKind.category,
              entityId: id,
              mutation: WorkspaceMutationKind.create,
              patch: {'name': id, if (id == 'child') 'parent_id': 'parent'},
            ),
        ],
      ),
    );
  });
  tearDown(() async {
    await close();
    await folder.delete(recursive: true);
  });
  String owner(String category) =>
      RecurrencePlans.seriesIdFor('start-$category');
  Future<void> start(String category) async {
    await session.execute(
      WorkspaceCommand(
        operationId: 'seed-$category',
        actions: [
          WorkspaceMutation(
            actionId: 'seed',
            kind: WorkspaceEntityKind.todo,
            entityId: 'task-$category',
            mutation: WorkspaceMutationKind.create,
            patch: {
              'title': category,
              'category_id': category,
              'due_at': now.toIso8601String(),
            },
          ),
        ],
      ),
    );
    await session.execute(
      RecurrencePlans(session.snapshot, now: now).start(
        'task-$category',
        rule: 'FREQ=DAILY;COUNT=8',
        timezone: 'Asia/Shanghai',
        operationId: 'start-$category',
        through: through,
        limit: 2,
      ),
    );
  }

  WorkspaceEntity occurrence(String category, int index) =>
      session.snapshot.todos.singleWhere(
        (e) =>
            e.data['series_id'] == owner(category) &&
            e.data['occurrence_index'] == index,
      );
  Future<void> change(WorkspaceEntity e, Map<String, Object?> patch) => session
      .execute(
        WorkspaceCommand(
          operationId: newWorkspaceId('edit'),
          actions: [WorkspacePlans.update(e, patch)],
        ),
      )
      .then((_) {});
  Future<UiCategoryUndo> remove(CategoryDeletionPolicy policy) =>
      ui.deleteCategory(
        'parent',
        policy: policy,
        preview: ui.previewCategoryDelete('parent'),
      );
  Future<void> generate(String category) async {
    final command = RecurrencePlans(session.snapshot, now: now).materialize(
      owner(category),
      through: through,
      operationId: newWorkspaceId('generate'),
    );
    if (command != null) await session.execute(command);
  }

  Matcher conflict = throwsA(
    isA<WorkspaceFailure>().having(
      (e) => e.code,
      'code',
      WorkspaceFailureCode.versionConflict,
    ),
  );

  test('keep policy moves root template to inbox and promotes child with its template intact', () async {
    await start('parent');
    await start('child');
    await start('other');
    final preview = ui.previewCategoryDelete('parent');
    expect(preview.seriesCount, 2);
    expect(preview.detachedCount, 0);
    await ui.deleteCategory(
      'parent',
      policy: CategoryDeletionPolicy.keepTodosAndChildren,
      preview: preview,
    );
    await reopen();
    await generate('parent');
    await generate('child');
    await generate('other');
    expect(session.categories.byId('child')!.parentId, isNull);
    final root = session.snapshot.todos.where(
      (e) => e.data['series_id'] == owner('parent'),
    );
    expect(root, hasLength(8));
    expect(root.every((e) => e.data['category_id'] == null), isTrue);
    expect(
      session.snapshot.todos.where((e) => e.data['category_id'] == 'child'),
      hasLength(8),
    );
    expect(
      session.snapshot.todos.where((e) => e.data['category_id'] == 'other'),
      hasLength(8),
    );
  });

  test(
    'keep deletion undo restores both template and existing tasks atomically',
    () async {
      await start('parent');
      final undo = await remove(CategoryDeletionPolicy.keepTodosAndChildren);
      expect(await undo.undo(), CategoryUndoResult.restored);
      await generate('parent');
      expect(session.todos.snapshot, hasLength(8));
      expect(
        session.todos.snapshot.every((e) => e.categoryId == 'parent'),
        isTrue,
      );
    },
  );

  test('subtree deletion stops templates, preserves moved exceptions, and restores with durable undo', () async {
    await start('parent');
    await start('child');
    await start('other');
    final moved = occurrence('parent', 1), completed = occurrence('parent', 2);
    await change(moved, {'category_id': 'other', 'note': '保留的例外'});
    await change(completed, {'category_id': null, 'status': 'done'});
    final preview = ui.previewCategoryDelete('parent');
    expect(preview.detachedCount, 2);
    final command = preview.command(CategoryDeletionPolicy.deleteSubtree)!;
    await ui.deleteCategory(
      'parent',
      policy: CategoryDeletionPolicy.deleteSubtree,
      preview: preview,
    );
    await reopen();
    await generate('parent');
    await generate('child');
    expect(session.todos.snapshot, hasLength(5));
    final kept = session.todos.byId(moved.id)!;
    expect(kept.seriesId, isNull);
    expect(kept.repeatRule, isNull);
    expect(kept.categoryId, 'other');
    expect(kept.note, '保留的例外');
    expect(
      session.snapshot.series.where((e) => e.data['stop_before'] == 0),
      hasLength(2),
    );
    // Replaying the exact command after reopening doesn't repeat mutations.
    final version = kept.version;
    await session.execute(command);
    expect(session.todos.byId(moved.id)!.version, version);
    await session.undo(command.operationId, 'undo-subtree');
    expect(session.todos.snapshot, hasLength(9));
    expect(session.todos.byId(moved.id)!.seriesId, owner('parent'));
    expect(session.todos.byId(completed.id)!.completedAt, isNotNull);
    await generate('parent');
    expect(
      session.snapshot.todos.where(
        (e) => e.data['series_id'] == owner('parent'),
      ),
      hasLength(8),
    );
  });

  test('empty category still exposes and stops a template after all instances moved', () async {
    await start('parent');
    for (final item in session.snapshot.todos.toList()) {
      await change(item, {'category_id': 'other'});
    }
    expect(
      session.todos.snapshot.where((e) => e.categoryId == 'parent'),
      isEmpty,
    );
    expect(ui.previewCategoryDelete('parent').seriesCount, 1);
    await remove(CategoryDeletionPolicy.deleteSubtree);
    await generate('parent');
    expect(session.todos.snapshot, hasLength(3));
    expect(session.todos.snapshot.every((e) => e.seriesId == null), isTrue);
    // A completed moved instance remains independently editable afterwards.
    await ui.toggleTodo(session.todos.snapshot.first.id);
    await ui.toggleTodo(session.todos.snapshot.first.id);
  });

  test('a series owned elsewhere loses only its instance placed in deleted category', () async {
    await start('other');
    final exception = occurrence('other', 1);
    await change(exception, {'category_id': 'parent'});
    await remove(CategoryDeletionPolicy.deleteSubtree);
    await generate('other');
    expect(session.todos.byId(exception.id), isNull);
    expect(session.todos.snapshot, hasLength(7));
    expect(session.snapshot.series.single.data['stop_before'], isNull);
  });

  test('a split child series moved elsewhere continues after its parent category is removed', () async {
    await start('parent');
    await session.execute(
      RecurrencePlans(session.snapshot, now: now).edit(
        occurrence('parent', 1).id,
        {'category_id': 'other'},
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'split',
        through: through,
        limit: 2,
      ),
    );
    await remove(CategoryDeletionPolicy.deleteSubtree);
    final split = RecurrencePlans.seriesIdFor('split');
    final command = RecurrencePlans(
      session.snapshot,
      now: now,
    ).materialize(split, through: through, operationId: 'more-split');
    if (command != null) await session.execute(command);
    expect(session.todos.snapshot, hasLength(7));
    expect(
      session.todos.snapshot.every((e) => e.categoryId == 'other'),
      isTrue,
    );
  });

  test(
    'confirmation rejects template-only changes and moved exception edits',
    () async {
      await start('parent');
      var preview = ui.previewCategoryDelete('parent');
      final series = session.snapshot.series.single;
      await change(series, {
        'template': {
          ...(series.data['template']! as Map<String, Object?>),
          'note': '新模板',
        },
      });
      await expectLater(
        ui.deleteCategory(
          'parent',
          policy: CategoryDeletionPolicy.deleteSubtree,
          preview: preview,
        ),
        conflict,
      );
      final moved = occurrence('parent', 1);
      await change(moved, {'category_id': 'other'});
      preview = ui.previewCategoryDelete('parent');
      await change(session.snapshot.find(WorkspaceEntityKind.todo, moved.id)!, {
        'note': '后来修改',
      });
      await expectLater(
        ui.deleteCategory(
          'parent',
          policy: CategoryDeletionPolicy.deleteSubtree,
          preview: preview,
        ),
        conflict,
      );
      expect(session.categories.byId('parent'), isNotNull);
    },
  );

  test('cross-connection generation after preview rejects prepared command without partial deletion', () async {
    await start('parent');
    final command = ui
        .previewCategoryDelete('parent')
        .command(CategoryDeletionPolicy.deleteSubtree)!;
    final secondDb = AppDatabase.background(File('${folder.path}/db.sqlite'));
    try {
      final second = SqliteWorkspaceCommandStore(secondDb);
      await second.execute(
        RecurrencePlans(await second.load(), now: now).materialize(
          owner('parent'),
          through: through,
          operationId: 'external-generation',
        )!,
      );
      await expectLater(store.execute(command), conflict);
      final actual = await store.load();
      expect(actual.categories, hasLength(3));
      expect(actual.todos, hasLength(8));
    } finally {
      await secondDb.close();
    }
  });

  test('receipt failure rolls back category, instances, and template; same preview can retry', () async {
    await start('parent');
    final preview = ui.previewCategoryDelete('parent');
    final before = canonicalWorkspaceJson(
      session.snapshot.entities.map((k, v) => MapEntry(k, v.toJson())),
    );
    final failing = SqliteWorkspaceCommandStore(
      db,
      checkpoint: (_) => throw StateError('disk'),
    );
    await expectLater(
      failing.execute(preview.command(CategoryDeletionPolicy.deleteSubtree)!),
      throwsA(isA<WorkspaceFailure>()),
    );
    final actual = await store.load();
    expect(
      canonicalWorkspaceJson(
        actual.entities.map((k, v) => MapEntry(k, v.toJson())),
      ),
      before,
    );
    await ui.deleteCategory(
      'parent',
      policy: CategoryDeletionPolicy.deleteSubtree,
      preview: preview,
    );
    expect(session.todos.snapshot, isEmpty);
  });

  test(
    'undo detects edits to detached task and keeps the whole deletion applied',
    () async {
      await start('parent');
      final moved = occurrence('parent', 1);
      await change(moved, {'category_id': 'other'});
      final undo = await remove(CategoryDeletionPolicy.deleteSubtree);
      await ui.updateTodo(
        session.todos.byId(moved.id)!.copyWith(note: '删除后编辑'),
      );
      expect(await undo.undo(), CategoryUndoResult.conflict);
      expect(session.categories.byId('parent'), isNull);
      expect(session.todos.snapshot, hasLength(1));
      expect(session.snapshot.series.single.data['stop_before'], 0);
    },
  );

  test('archive retains template membership and generation, unarchive restores visibility', () async {
    await start('parent');
    final undo = await ui.archiveCategory('parent', true);
    await generate('parent');
    expect(session.todos.snapshot, hasLength(8));
    expect(
      session.todos.snapshot.every((e) => e.categoryId == 'parent'),
      isTrue,
    );
    expect(await undo.undo(), CategoryUndoResult.restored);
    expect(session.categories.byId('parent')!.archived, isFalse);
  });
}
