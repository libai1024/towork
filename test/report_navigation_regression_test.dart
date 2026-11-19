import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/app_button.dart';
import 'package:towork/features/reports/report_detail_page.dart';
import 'package:towork/main.dart';

void main() {
  testWidgets('deletion undo remains valid after the detail page is disposed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialAppLocationProvider.overrideWithValue(AppRoutes.report('r1')),
        ],
        child: const ToWorkApp(),
      ),
    );
    await tester.pumpAndSettle();
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(ToWorkApp)),
    );
    final repository = scope.read(reportListProvider.notifier);
    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, '删除'));
    await tester.pumpAndSettle();
    expect(repository.byId('r1'), isNull);
    expect(find.byType(ReportDetailPage, skipOffstage: false), findsNothing);
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    expect(repository.byId('r1'), isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'generated report returns to its list without leaving a detail page mounted',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialAppLocationProvider.overrideWithValue(AppRoutes.reports),
          ],
          child: const ToWorkApp(),
        ),
      );
      await tester.pumpAndSettle();
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(ToWorkApp)),
      );
      final router = scope.read(appRouterProvider);
      await tester.tap(find.bySemanticsLabel('生成报告'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, '生成报告'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(ReportDetailPage), findsOneWidget);
      expect(router.state.uri.path, startsWith('${AppRoutes.reports}/r_gen_'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.reports);
      expect(find.byType(ReportDetailPage, skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
