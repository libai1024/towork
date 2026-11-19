import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/core/widgets/app_sheet.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/data/repositories/data_table_repository.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/features/data_tables/widgets/add_row_sheet.dart';
import 'package:towork/features/data_tables/widgets/ai_confirm_sheet.dart';
import 'package:towork/features/data_tables/widgets/row_detail_page.dart';
import 'package:towork/theme/app_theme.dart';

final _now = DateTime(2026, 9, 23);
DataTableBundle _initial() => DataTableBundle(
  tables: [
    DataTableDef(
      id: 'table',
      name: '测试表',
      columns: [DataColumnDef(name: '标题', type: 'text', isRequired: true)],
      createdAt: _now,
    ),
  ],
  rows: [],
  logs: [],
);

class _FailOnceRepository extends DataTableRepository {
  _FailOnceRepository() : super(initial: _initial());
  bool rejectNext = true;

  @override
  DataRow addRow(
    String tableId,
    Map<String, String> values, {
    DataChangeSource source = DataChangeSource.manual,
    String? reason,
    String? sourceLabel,
    String? id,
  }) {
    if (rejectNext) {
      rejectNext = false;
      throw const RepositoryException(
        RepositoryErrorCode.conflict,
        '记录已有变更，请重试',
      );
    }
    return super.addRow(
      tableId,
      values,
      source: source,
      reason: reason,
      sourceLabel: sourceLabel,
      id: id,
    );
  }
}

Future<void> _mount(
  WidgetTester tester,
  DataTableRepository repo,
  Widget home,
) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(AppToast.dismiss);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dataTableProvider.overrideWith((ref) => repo)],
      child: MaterialApp(theme: AppTheme.light, home: home),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _launcher(VoidCallback Function(BuildContext) action) => Scaffold(
  body: Builder(
    builder: (context) =>
        TextButton(onPressed: action(context), child: const Text('打开')),
  ),
);

void main() {
  testWidgets(
    'failed AI apply keeps selection and permits a valid subset retry',
    (tester) async {
      final repo = DataTableRepository(initial: _initial());
      final batch = repo.pushPendingBatch(
        tableId: 'table',
        reason: '确认内容',
        sourceLabel: '测试',
        changes: [
          PendingRowChange(
            id: 'valid',
            action: DataChangeAction.create,
            rowLabel: '合法记录',
            createValues: {'标题': '合法记录'},
          ),
          PendingRowChange(
            id: 'invalid',
            action: DataChangeAction.create,
            rowLabel: '缺少标题',
          ),
        ],
      );
      await _mount(
        tester,
        repo,
        _launcher(
          (context) =>
              () => AppSheet.show<void>(
                context,
                child: AiConfirmSheet(
                  table: repo.tableById('table')!,
                  batch: batch,
                  onApply: (ids) => repo.applyPendingBatch(batch.id, ids),
                  onDiscard: () => repo.discardPendingBatch(batch.id),
                ),
              ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('应用所选 (2)'));
      await tester.pumpAndSettle();
      expect(find.text('「标题」不能为空'), findsOneWidget);
      expect(find.byType(AiConfirmSheet), findsOneWidget);
      expect(repo.rowsOf('table'), isEmpty);
      expect(repo.batchesOf('table').single.changes, hasLength(2));
      final invalidTile = find.byKey(const ValueKey('ai-change-invalid'));
      await tester.tap(
        find
            .descendant(of: invalidTile, matching: find.byType(AppPressable))
            .first,
      );
      await tester.pump();
      await tester.tap(find.text('应用所选 (1)'));
      await tester.pumpAndSettle();
      expect(find.byType(AiConfirmSheet), findsNothing);
      expect(repo.rowsOf('table').single.values['标题'], '合法记录');
      expect(repo.batchesOf('table').single.changes.single.id, 'invalid');
      expect(tester.takeException(), isNull);
      AppToast.dismiss();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('failed row submission preserves entered values for retry', (
    tester,
  ) async {
    final repo = _FailOnceRepository();
    await _mount(
      tester,
      repo,
      _launcher(
        (context) =>
            () => showAddRowSheet(context, repo.tableById('table')!),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('未填写'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '保留输入');
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('记录已有变更，请重试'), findsOneWidget);
    expect(find.text('新增一行'), findsOneWidget);
    expect(find.text('保留输入'), findsOneWidget);
    expect(repo.rowsOf('table'), isEmpty);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('新增一行'), findsNothing);
    expect(repo.rowsOf('table').single.values['标题'], '保留输入');
    expect(tester.takeException(), isNull);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('invalid cell edit stays open and succeeds after correction', (
    tester,
  ) async {
    final repo = DataTableRepository(initial: _initial());
    final row = repo.addRow('table', {'标题': '原值'});
    await _mount(tester, repo, RowDetailPage(tableId: 'table', rowId: row.id));
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is AppPressable && widget.semanticLabel == '编辑标题',
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('「标题」不能为空'), findsOneWidget);
    expect(find.text('已保存'), findsNothing);
    expect(repo.rowsOf('table').single.values['标题'], '原值');
    await tester.enterText(find.byType(TextField), '修正后的值');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(repo.rowsOf('table').single.values['标题'], '修正后的值');
    expect(find.text('已保存'), findsOneWidget);
    expect(tester.takeException(), isNull);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });
}
