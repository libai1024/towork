import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/todo/todo_detail_sheet.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/app/recurrence_commands.dart';
import 'package:towork/app/workspace_ui_commands.dart';
import 'package:towork/core/widgets/app_button.dart';
import 'package:towork/core/widgets/app_sheet.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/core/todo/recurrence_action_sheet.dart';
import 'package:towork/theme/app_theme.dart';

class _HeldCommands extends RecurrenceCommands {
  _HeldCommands(super.session, {required super.clock});
  Completer<void>? gate;
  bool fail = false;
  final submitted = <String>[];
  @override
  Future<UiWorkspaceChange<WorkspaceReceipt>> execute(
    WorkspaceCommand command,
  ) async {
    submitted.add(command.operationId);
    await gate?.future;
    if (fail) {
      throw const WorkspaceFailure(WorkspaceFailureCode.storageUnavailable);
    }
    return super.execute(command);
  }
}

class _Harness {
  _Harness(
    this.directory,
    this.db,
    this.session,
    this.service,
    this.commands,
    this.id,
    this.proposal,
  );
  final Directory directory;
  final AppDatabase db;
  final LocalWorkspaceSession session;
  final _HeldCommands service;
  final WorkspaceUiCommands commands;
  final String id;
  final RecurrenceProposal proposal;
}

Future<void> _withHarness(
  WidgetTester tester,
  Future<void> Function(_Harness) body, {
  bool narrow = false,
  bool detail = false,
}) async {
  late _Harness h;
  await tester.runAsync(() async {
    final dir = await Directory.systemTemp.createTemp('repeat-sheet');
    final db = AppDatabase.background(File('${dir.path}/db.sqlite'));
    final store = SqliteWorkspaceCommandStore(db);
    final session = LocalWorkspaceSession(store, await store.load());
    final commands = WorkspaceUiCommands(
      session.todos,
      session.categories,
      session: session,
    );
    final service = _HeldCommands(
      session,
      clock: () => DateTime.utc(2026, 9, 24),
    );
    final first = await commands.createTodo(
      title: '原始标题',
      dueAt: DateTime.utc(2026, 9, 24),
    );
    await service.execute(
      service
          .startProposal(first, 'FREQ=DAILY;COUNT=4', 'Asia/Shanghai')
          .choices
          .single
          .command,
    );
    service.submitted.clear();
    final current = session.todos.byId(first.id)!;
    final proposal = service.editProposal(
      current,
      current.copyWith(title: '修改标题', note: '需要核对附件'),
    );
    h = _Harness(dir, db, session, service, commands, first.id, proposal);
  });
  if (narrow) {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  final container = ProviderContainer();
  container.read(localWorkspaceSessionProvider.notifier).state = h.session;
  container.read(todoListProvider);
  container.read(categoryListProvider);
  try {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: narrow ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => detail
                    ? showTodoDetailSheet(context, h.id, onDeleted: (_) {})
                    : AppSheet.show<void>(
                        context,
                        dismissible: false,
                        child: RecurrenceActionSheet(
                          service: h.service,
                          proposal: h.proposal,
                        ),
                      ),
                child: const Text('打开范围预览'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开范围预览'));
    await tester.pumpAndSettle();
    await body(h);
    expect(tester.takeException(), isNull);
  } finally {
    AppToast.dismiss();
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await h.session.dispose();
      container.dispose();
      await h.db.close();
      await h.directory.delete(recursive: true);
    });
  }
}

Future<void> _tap(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pump();
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 100 && !ready(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(ready(), isTrue);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'detail can edit again immediately after undo restores its text',
    (tester) async {
      await _withHarness(tester, (h) async {
        final title = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == '待办标题',
        );
        await tester.enterText(title, '本次改名');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        await _tap(tester, '确认修改');
        await _until(
          tester,
          () =>
              h.session.todos.byId(h.id)!.title == '本次改名' &&
              find.byType(RecurrenceActionSheet).evaluate().isEmpty,
        );
        await _tap(tester, '撤销');
        await _until(tester, () => h.session.todos.byId(h.id)!.title == '原始标题');
        expect(tester.widget<TextField>(title).controller!.text, '原始标题');
        await tester.enterText(title, '后续改名');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text('本次及以后'), findsOneWidget);
        await _tap(tester, '本次及以后');
        await _tap(tester, '确认修改');
        await _until(
          tester,
          () => h.session.todos.snapshot.every((t) => t.title == '后续改名'),
        );
      }, detail: true);
    },
  );

  testWidgets(
    'narrow large text scope preview shows field differences and cancel writes nothing',
    (tester) async {
      await _withHarness(tester, (h) async {
        expect(find.textContaining('备注：无 → 需要核对附件'), findsOneWidget);
        await _tap(tester, '本次及以后');
        await tester.pumpAndSettle();
        expect(find.textContaining('新增 3 修改 1 删除 3'), findsOneWidget);
        await _tap(tester, '查看全部 7 条记录');
        await _tap(tester, '取消');
        await tester.pumpAndSettle();
        expect(h.service.submitted, isEmpty);
        expect(
          h.session.todos.snapshot.every((t) => t.title == '原始标题'),
          isTrue,
        );
      }, narrow: true);
    },
  );

  testWidgets(
    'failed submit keeps preview, blocks duplicate actions and reuses exact operation on retry',
    (tester) async {
      await _withHarness(tester, (h) async {
        await _tap(tester, '本次及以后');
        h.service.gate = Completer<void>();
        h.service.fail = true;
        await _tap(tester, '确认修改');
        // Do not pumpAndSettle with the loading spinner active.
        await tester.tap(find.text('确认修改'));
        await tester.pump();
        expect(h.service.submitted, hasLength(1));
        final cancel = tester.widget<AppButton>(
          find.byWidgetPredicate((w) => w is AppButton && w.label == '取消'),
        );
        expect(cancel.enabled, isFalse);
        h.service.gate!.complete();
        await _until(
          tester,
          () => find.text('保存失败，原数据已保留，请重试').evaluate().isNotEmpty,
        );
        expect(
          h.session.todos.snapshot.every((t) => t.title == '原始标题'),
          isTrue,
        );
        h.service.fail = false;
        await _tap(tester, '确认修改');
        await _until(
          tester,
          () => find.byType(RecurrenceActionSheet).evaluate().isEmpty,
        );
        expect(h.service.submitted, hasLength(2));
        expect(h.service.submitted.toSet(), hasLength(1));
        expect(
          h.session.todos.snapshot.every((t) => t.title == '修改标题'),
          isTrue,
        );
      });
    },
  );

  testWidgets(
    'concurrent edit rejects the displayed proposal and preserves every other instance',
    (tester) async {
      await _withHarness(tester, (h) async {
        await _tap(tester, '本次及以后');
        await tester.runAsync(
          () => h.commands.updateTodo(
            h.session.todos.byId(h.id)!.copyWith(note: '较新的备注'),
          ),
        );
        await _tap(tester, '确认修改');
        await _until(
          tester,
          () => find.text('记录已变化，请重新打开后再操作').evaluate().isNotEmpty,
        );
        expect(h.session.todos.snapshot, hasLength(4));
        expect(h.session.todos.byId(h.id)!.note, '较新的备注');
        expect(
          h.session.todos.snapshot.every((t) => t.title == '原始标题'),
          isTrue,
        );
        final confirm = tester.widget<AppButton>(
          find.byWidgetPredicate((w) => w is AppButton && w.label == '确认修改'),
        );
        expect(confirm.enabled, isFalse);
        await _tap(tester, '取消');
        await tester.pumpAndSettle();
      });
    },
  );
}
