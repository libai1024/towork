import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/data/repositories/data_table_repository.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/features/data_tables/application/ai_write_policy.dart';
import 'package:towork/features/data_tables/data_table_detail_page.dart';
import 'package:towork/features/data_tables/widgets/ai_confirm_sheet.dart';
import 'package:towork/features/data_tables/widgets/screenshot_flow_page.dart';
import 'package:towork/theme/app_theme.dart';

final _now = DateTime(2026, 9, 23);
DataTableRepository _repo() => DataTableRepository(
  clock: () => _now,
  initial: DataTableBundle(
    tables: [
      DataTableDef(
        id: 'table',
        name: '授权测试',
        columns: [DataColumnDef(name: '标题', type: 'text', isRequired: true)],
        createdAt: _now,
      ),
    ],
    rows: [
      DataRow(
        id: 'update-row',
        tableId: 'table',
        values: {'标题': '旧标题'},
        updatedAt: _now,
      ),
      DataRow(
        id: 'delete-row',
        tableId: 'table',
        values: {'标题': '待删除'},
        updatedAt: _now,
      ),
    ],
    logs: [],
  ),
);

PendingAiBatch _batch(DataTableRepository repo, {String oldTitle = '旧标题'}) =>
    repo.pushPendingBatch(
      tableId: 'table',
      reason: '权限测试',
      sourceLabel: '测试来源',
      changes: [
        PendingRowChange(
          id: 'create',
          action: DataChangeAction.create,
          rowLabel: '新增',
          createValues: {'标题': '新增'},
        ),
        PendingRowChange(
          id: 'update',
          action: DataChangeAction.update,
          rowId: 'update-row',
          rowLabel: '更新',
          fields: [
            PendingFieldChange(
              field: '标题',
              oldValue: oldTitle,
              newValue: '新标题',
              confidence: .62,
            ),
          ],
        ),
        PendingRowChange(
          id: 'delete',
          action: DataChangeAction.delete,
          rowId: 'delete-row',
          rowLabel: '删除',
          fields: [const PendingFieldChange(field: '标题', oldValue: '待删除')],
        ),
      ],
    );

void main() {
  for (final permission in AiWritePermission.values) {
    test('${permission.name} applies exactly its authorized row actions', () {
      final repo = _repo();
      addTearDown(repo.dispose);
      final batch = _batch(repo);
      final policy = AiWritePolicy(repo);
      final before = repo.snapshot;
      var notifications = 0;
      final unsubscribe = repo.addListener(
        (_) => notifications++,
        fireImmediately: false,
      );
      addTearDown(unsubscribe);
      final result = policy.receive(batch.id, permission);
      switch (permission) {
        case AiWritePermission.askAll:
          expect(repo.snapshot, same(before));
          expect(result.hasWrites, isFalse);
          expect(result.pendingBatch!.changes, hasLength(3));
          expect(notifications, 0);
        case AiWritePermission.askOnChange:
          expect(result.appliedChanges.map((change) => change.id), [
            'create',
            'update',
          ]);
          expect(repo.rowsOf('table'), hasLength(3));
          expect(
            repo
                .rowsOf('table')
                .firstWhere((row) => row.id == 'update-row')
                .values['标题'],
            '新标题',
          );
          expect(result.pendingBatch!.changes.map((change) => change.id), [
            'delete',
          ]);
          expect(notifications, 1);
        case AiWritePermission.auto:
          expect(result.appliedChanges, hasLength(3));
          expect(result.containsDeletion, isTrue);
          expect(result.pendingBatch, isNull);
          expect(repo.rowsOf('table'), hasLength(2));
          expect(
            repo.rowsOf('table').any((row) => row.id == 'delete-row'),
            isFalse,
          );
          expect(
            repo
                .rowsOf('table')
                .firstWhere((row) => row.id == 'update-row')
                .values['标题'],
            '新标题',
          );
          expect(notifications, 1);
      }
      expect(() => result.appliedChanges.clear(), throwsUnsupportedError);
    });
  }

  test('automatic conflicts remain atomic and require an explicit retry', () {
    final repo = _repo();
    addTearDown(repo.dispose);
    final batch = _batch(repo, oldTitle: '过期标题');
    final policy = AiWritePolicy(repo);
    final before = repo.snapshot;
    expect(
      () => policy.receive(batch.id, AiWritePermission.auto),
      throwsA(isA<RepositoryException>()),
    );
    expect(repo.snapshot, same(before));
    final retry = policy.receive(batch.id, AiWritePermission.auto);
    expect(retry.hasWrites, isFalse);
    expect(retry.pendingBatch!.changes, hasLength(3));
    expect(repo.snapshot, same(before));
  });

  test(
    'undo and reviewed leftovers never automatically execute on revisit',
    () {
      final repo = _repo();
      addTearDown(repo.dispose);
      final batch = _batch(repo);
      final policy = AiWritePolicy(repo);
      policy.receive(batch.id, AiWritePermission.auto);
      repo.undoLastApply();
      final restored = repo.snapshot;
      final retry = policy.receive(batch.id, AiWritePermission.auto);
      expect(retry.hasWrites, isFalse);
      expect(repo.snapshot, same(restored));
      final another = _batch(repo);
      policy.requireReview(another.id);
      expect(
        policy.receive(another.id, AiWritePermission.auto).hasWrites,
        isFalse,
      );
      expect(repo.rowsOf('table'), hasLength(2));
    },
  );

  for (final permission in AiWritePermission.values) {
    testWidgets('table entry consumes current ${permission.name} setting', (
      tester,
    ) async {
      final repo = _repo();
      _batch(repo);
      await _mount(
        tester,
        repo,
        permission,
        const DataTableDetailPage(tableId: 'table'),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      if (permission == AiWritePermission.auto) {
        expect(find.byType(AiConfirmSheet), findsNothing);
        expect(repo.batchesOf('table'), isEmpty);
        expect(find.text('AI 更新了 3 处'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        expect(find.text('AI 更新了 3 处'), findsOneWidget);
      } else {
        expect(find.byType(AiConfirmSheet), findsOneWidget);
        expect(
          repo.batchesOf('table').single.changes,
          hasLength(permission == AiWritePermission.askAll ? 3 : 1),
        );
        expect(
          repo.rowsOf('table').any((row) => row.id == 'delete-row'),
          isTrue,
        );
      }
      expect(tester.takeException(), isNull);
      AppToast.dismiss();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  for (final permission in [
    AiWritePermission.askAll,
    AiWritePermission.askOnChange,
  ]) {
    testWidgets('screenshot create obeys ${permission.name} after extraction', (
      tester,
    ) async {
      final repo = _repo();
      AiWriteResult? result;
      await _mount(
        tester,
        repo,
        permission,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              child: const Text('导入截图'),
              onPressed: () async {
                result = await Navigator.of(context).push<AiWriteResult>(
                  MaterialPageRoute(
                    builder: (_) => const ScreenshotFlowPage(tableId: 'table'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('导入截图'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('开始分析'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      if (permission == AiWritePermission.askAll) {
        expect(find.byType(AiConfirmSheet), findsOneWidget);
        expect(repo.rowsOf('table'), hasLength(2));
        expect(result, isNull);
      } else {
        expect(find.byType(AiConfirmSheet), findsNothing);
        expect(find.byType(ScreenshotFlowPage), findsNothing);
        expect(repo.rowsOf('table'), hasLength(3));
        expect(result!.createsOnly, isTrue);
      }
      expect(tester.takeException(), isNull);
      AppToast.dismiss();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('automatic-write undo survives closing the table detail route', (
    tester,
  ) async {
    final repo = _repo();
    final batch = _batch(repo);
    await _mount(
      tester,
      repo,
      AiWritePermission.auto,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            child: const Text('打开数据表'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const DataTableDetailPage(tableId: 'table'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开数据表'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(repo.batchesOf('table'), isEmpty);
    expect(repo.rowsOf('table').any((row) => row.id == 'delete-row'), isFalse);
    Navigator.of(tester.element(find.byType(DataTableDetailPage))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(DataTableDetailPage), findsNothing);
    expect(find.text('撤销'), findsOneWidget);
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    expect(repo.rowsOf('table').map((row) => row.id).toSet(), {
      'update-row',
      'delete-row',
    });
    expect(
      repo
          .rowsOf('table')
          .firstWhere((row) => row.id == 'update-row')
          .values['标题'],
      '旧标题',
    );
    expect(repo.batchesOf('table').single.id, batch.id);
    expect(find.text('已撤销，改动已还原'), findsOneWidget);
    expect(tester.takeException(), isNull);
    AppToast.dismiss();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Future<void> _mount(
  WidgetTester tester,
  DataTableRepository repo,
  AiWritePermission permission,
  Widget home,
) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(AppToast.dismiss);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dataTableProvider.overrideWith((ref) => repo),
        aiWritePermissionProvider.overrideWith((ref) => permission),
      ],
      child: MaterialApp(theme: AppTheme.light, home: home),
    ),
  );
  await tester.pump();
}
