import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/data/repositories/data_table_repository.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/features/data_tables/data_table_detail_page.dart';
import 'package:towork/theme/app_theme.dart';

final _now = DateTime(2026, 9, 24);

/// 演示模式（无 session）：内存 DataTableRepository 直接作为 dataTableProvider。
DataTableRepository _seededRepo() {
  final repo = DataTableRepository(
    initial: DataTableBundle(
      tables: [
        DataTableDef(
          id: 'table',
          name: '持仓',
          columns: [
            DataColumnDef(name: '名称', type: 'text', isRequired: true),
            DataColumnDef(name: '数量', type: 'number', unit: '股'),
          ],
          createdAt: _now,
        ),
      ],
      rows: [],
      logs: [],
    ),
  );
  repo.addRow('table', {'名称': '贵州茅台', '数量': '100'});
  return repo;
}

Finder _pressable(String semanticLabel) => find.byWidgetPredicate(
  (widget) => widget is AppPressable && widget.semanticLabel == semanticLabel,
);

void main() {
  testWidgets('表设置删除表：确认后清空并可通过撤销恢复', (tester) async {
    final repo = _seededRepo();
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(AppToast.dismiss);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataTableProvider.overrideWith((ref) => repo)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DataTableDetailPage(tableId: 'table'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('贵州茅台'), findsOneWidget);

    await tester.tap(_pressable('表设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除表'));
    await tester.pumpAndSettle();
    // 影响预检文案包含行数。
    expect(find.textContaining('1 行记录'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    // 表删除后页面进入空态，数据行消失，Toast 提供撤销。
    expect(find.textContaining('可能被归档或删除'), findsOneWidget);
    expect(repo.tableById('table'), isNull);
    expect(repo.rowsOf('table'), isEmpty);
    expect(find.text('已删除「持仓」'), findsOneWidget);

    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    expect(repo.tableById('table'), isNotNull);
    expect(repo.rowsOf('table'), hasLength(1));
    expect(repo.rowsOf('table').single.values['名称'], '贵州茅台');
    // 撤销后页面恢复显示数据。
    expect(find.text('贵州茅台'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
