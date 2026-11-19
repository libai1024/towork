import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/app_button.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/core/widgets/workspace_bottom_bar.dart';
import 'package:towork/data/repositories/data_table_repository.dart';
import 'package:towork/features/data_tables/data_tables_page.dart';
import 'package:towork/features/data_tables/widgets/data_table_type_sheet.dart';
import 'package:towork/theme/app_theme.dart';

AppPressable buttonNamed(WidgetTester tester, String label) => tester
    .widgetList<AppPressable>(find.byType(AppPressable))
    .firstWhere((button) => button.semanticLabel == label);

Future<void> tapNamed(WidgetTester tester, String label) async {
  await tester.tap(find.byWidget(buttonNamed(tester, label)));
  await tester.pumpAndSettle();
}

Future<GoRouter> mount(WidgetTester tester, DataTableRepository repo) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(AppToast.dismiss);
  final router = GoRouter(
    initialLocation: '/data',
    routes: [
      GoRoute(
        path: '/data',
        builder: (_, _) => const DataTablesPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, _) => const Scaffold(body: Text('表详情')),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dataTableProvider.overrideWith((ref) => repo)],
      child: MaterialApp.router(routerConfig: router, theme: AppTheme.light),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('new type selects its scope and new tables inherit it', (
    tester,
  ) async {
    final repo = DataTableRepository(clock: () => DateTime(2026, 9, 23));
    final router = await mount(tester, repo);
    await tapNamed(tester, '新增类型');
    await tester.enterText(find.byType(TextField).last, '项目');
    await tester.pump();
    await tester.tap(find.byTooltip('创建'));
    await tester.pumpAndSettle();
    final type = repo.snapshot.types.singleWhere((type) => type.name == '项目');
    expect(find.text('股票持仓'), findsNothing);
    expect(find.text('0 张表'), findsOneWidget);
    final add = find
        .descendant(
          of: find.byType(WorkspaceBottomBar),
          matching: find.byType(AppPressable),
        )
        .last;
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(DataTableTypeField, '项目'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '项目台账');
    await tester.tap(find.widgetWithText(AppButton, '创建'));
    await tester.pumpAndSettle();
    expect(
      repo.snapshot.tables.singleWhere((table) => table.name == '项目台账').typeId,
      type.id,
    );
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('项目台账'), findsOneWidget);
    expect(find.text('1 张表'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing a table type updates the filtered list immediately', (
    tester,
  ) async {
    final repo = DataTableRepository(clock: () => DateTime(2026, 9, 23));
    await mount(tester, repo);
    await tester.tap(find.text('工作'));
    await tester.pumpAndSettle();
    expect(find.text('档案接收记录'), findsOneWidget);
    await tester.longPress(find.text('档案接收记录'));
    await tester.pumpAndSettle();
    await tapNamed(tester, '修改类型');
    await tapNamed(tester, '选择类型生活');
    expect(repo.tableById('dt_archive')!.typeId, 'type_life');
    expect(find.text('档案接收记录'), findsNothing);
    await tester.tap(find.text('生活'));
    await tester.pumpAndSettle();
    expect(find.text('档案接收记录'), findsOneWidget);
    expect(find.text('2 张表'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('duplicate type names keep the editor open without writing', (
    tester,
  ) async {
    final repo = DataTableRepository();
    await mount(tester, repo);
    await tapNamed(tester, '新增类型');
    await tester.enterText(find.byType(TextField).last, '工作');
    await tester.pump();
    await tester.tap(find.byTooltip('创建'));
    await tester.pumpAndSettle();
    expect(find.text('该类型已存在'), findsOneWidget);
    expect(repo.snapshot.types, hasLength(3));
    expect(find.byTooltip('创建'), findsOneWidget);
  });
}
