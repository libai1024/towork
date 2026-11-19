import 'package:towork/app/todo/async_todo_commands.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/features/data_tables/widgets/ai_confirm_sheet.dart';
import 'package:towork/features/data_tables/widgets/row_detail_page.dart';
import 'package:towork/features/reports/report_detail_page.dart';
import 'package:towork/features/settings/appearance_page.dart';
import 'package:towork/features/todo/todo_list_page.dart';
import 'package:towork/main.dart';

Future<(GoRouter, ProviderContainer)> mountRoute(
  WidgetTester tester,
  String location,
) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [initialAppLocationProvider.overrideWithValue(location)],
      child: const ToWorkApp(),
    ),
  );
  await tester.pumpAndSettle();
  final scope = ProviderScope.containerOf(
    tester.element(find.byType(ToWorkApp)),
  );
  return (scope.read(appRouterProvider), scope);
}

void main() {
  testWidgets('daily digest notification opens the current day filter', (
    tester,
  ) async {
    final (router, scope) = await mountRoute(tester, AppRoutes.todos);
    final todos = scope.read(asyncTodoCommandsProvider);
    await todos.delete(scope.read(todoListProvider).map((todo) => todo.id));
    final now = DateTime.now();
    await todos.create(
      title: '摘要今日目标',
      dueAt: DateTime(now.year, now.month, now.day, 23),
    );
    await todos.create(
      title: '摘要明日目标',
      dueAt: DateTime(now.year, now.month, now.day + 1, 12),
    );
    await tester.pumpAndSettle();
    expect(find.text('摘要明日目标'), findsOneWidget);
    router.go('${AppRoutes.todos}?notificationKind=morning&notice=digest-test');
    await tester.pumpAndSettle();
    expect(find.text('摘要今日目标'), findsOneWidget);
    expect(find.text('摘要明日目标'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  test(
    'route builders preserve reserved characters and reject empty segments',
    () {
      const id = '季度/报告?分类=工作 & #100%';
      expect(Uri.parse(AppRoutes.report(id)).pathSegments.last, id);
      expect(Uri.parse(AppRoutes.dataRow('table / 一', id)).pathSegments, [
        'data-tables',
        'table / 一',
        'rows',
        id,
      ]);
      expect(Uri.parse(AppRoutes.todosForCategory(id)).queryParameters, {
        'categoryId': id,
      });
      expect(() => AppRoutes.report(''), throwsArgumentError);
    },
  );

  testWidgets('router state and listeners are scoped to each app instance', (
    tester,
  ) async {
    final (first, _) = await mountRoute(tester, AppRoutes.settings);
    first.go(AppRoutes.reports);
    await tester.pumpAndSettle();
    expect(first.state.uri.path, AppRoutes.reports);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(
      () => first.routeInformationProvider.addListener(() {}),
      throwsFlutterError,
    );
    final (second, _) = await mountRoute(tester, AppRoutes.home);
    expect(identical(first, second), isFalse);
    expect(second.state.uri.path, AppRoutes.home);
    expect(tester.takeException(), isNull);
  });

  testWidgets('encoded query and detail identifiers arrive unmodified', (
    tester,
  ) async {
    const id = '工作/计划?季度=1&选中#总览';
    final (router, _) = await mountRoute(
      tester,
      AppRoutes.todosForCategory(id),
    );
    expect(
      tester.widget<TodoListPage>(find.byType(TodoListPage)).categoryId,
      id,
    );
    router.go(AppRoutes.report(id));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ReportDetailPage>(find.byType(ReportDetailPage)).reportId,
      id,
    );
    expect(find.text('这份报告已被删除'), findsOneWidget);
    expect(
      router.namedLocation(
        AppRouteNames.reportDetail,
        pathParameters: {'id': id},
      ),
      AppRoutes.report(id),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'report deep link returns to reports and another id remounts detail',
    (tester) async {
      final (router, scope) = await mountRoute(tester, AppRoutes.report('r1'));
      final firstState = tester.state(find.byType(ReportDetailPage));
      expect(
        scope.read(reportListProvider.notifier).byId('r1')!.isRead,
        isTrue,
      );
      router.go(AppRoutes.report('r2'));
      await tester.pumpAndSettle();
      expect(
        identical(firstState, tester.state(find.byType(ReportDetailPage))),
        isFalse,
      );
      await tester.tap(find.byTooltip('返回').last);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.reports);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'leaving a generating report preserves its background completion',
    (tester) async {
      final (router, scope) = await mountRoute(tester, AppRoutes.reports);
      final reports = scope.read(reportListProvider.notifier);
      reports.regenerate('r1');
      router.go(AppRoutes.report('r1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(reports.byId('r1')!.status, ReportStatus.generating);
      await tester.tap(find.byTooltip('返回').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(router.state.uri.path, AppRoutes.reports);
      expect(reports.byId('r1')!.status, ReportStatus.generating);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(reports.byId('r1')!.status, ReportStatus.ready);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'table parent does not open a pending-update dialog over a row deep link',
    (tester) async {
      await mountRoute(tester, AppRoutes.dataRow('dt_stock', 'dr1'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(RowDetailPage), findsOneWidget);
      expect(find.byType(AiConfirmSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('appearance is a nested deep link and returns to settings', (
    tester,
  ) async {
    final (router, _) = await mountRoute(tester, AppRoutes.appearance);
    expect(find.byType(AppearancePage), findsOneWidget);
    await tester.tap(find.byTooltip('返回').last);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.settings);
    expect(tester.takeException(), isNull);
  });

  testWidgets('data row deep link has parent table and handles a missing row', (
    tester,
  ) async {
    final (router, _) = await mountRoute(
      tester,
      AppRoutes.dataRow('dt_archive', 'dr5'),
    );
    expect(find.byType(RowDetailPage), findsOneWidget);
    expect(find.text('JS-2026-0028'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('返回').last);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.dataTable('dt_archive'));
    router.go(AppRoutes.dataRow('dt_archive', 'missing'));
    await tester.pumpAndSettle();
    expect(find.text('这条记录已不存在'), findsOneWidget);
    await tester.tap(find.text('返回数据表'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.dataTable('dt_archive'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown route has a safe home action', (tester) async {
    final (router, _) = await mountRoute(
      tester,
      '/does-not-exist/secret-token',
    );
    expect(find.byKey(const ValueKey('route-not-found')), findsOneWidget);
    expect(find.textContaining('secret-token'), findsNothing);
    await tester.tap(find.text('返回首页'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.home);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'top-level category back and visualization AI action work without a previous page',
    (tester) async {
      final (router, _) = await mountRoute(tester, AppRoutes.categories);
      await tester.tap(find.bySemanticsLabel('返回'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.home);
      router.go(AppRoutes.visualization);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('切换日程视图'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('问问 AI'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.home);
      expect(tester.takeException(), isNull);
    },
  );
}
