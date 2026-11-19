import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/app/update/update_provider.dart';
import 'package:towork/domain/update/code_update.dart';
import 'package:towork/main.dart';
import 'package:towork/shell/router.dart';

import '../../support/code_update_fake.dart';
import '../../support/update_fakes.dart';

void main() {
  late FakeUpdateGateway apk;
  late FakeCodeUpdateGateway code;
  setUp(() {
    apk = FakeUpdateGateway();
    code = FakeCodeUpdateGateway();
  });

  Future<ProviderContainer> launch(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updatePlatformProvider.overrideWithValue(FakeUpdatePlatform()),
          updateGatewayProvider.overrideWithValue(apk),
          codeUpdateGatewayProvider.overrideWithValue(code),
        ],
        child: const ToWorkApp(),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(ToWorkApp)));
  }

  testWidgets('launch offers new APK once and opens the existing updater', (
    tester,
  ) async {
    final scope = await launch(tester);
    expect(find.text('ToWork 1.1.2 可更新'), findsOneWidget);
    expect(apk.checks, 1);
    expect(apk.downloads, 0);
    await tester.tap(find.text('查看更新'));
    await tester.pumpAndSettle();
    expect(find.text('下载更新'), findsOneWidget);
    expect(apk.checks, 1);
    scope.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    expect(find.text('查看更新'), findsNothing);
    expect(apk.downloads, 0);
  });

  testWidgets(
    'launch checks signed patches and remembers dismissal for this run',
    (tester) async {
      apk.release = null;
      final scope = await launch(tester);
      expect(find.text('补丁 P1 可更新'), findsOneWidget);
      await tester.tap(find.byTooltip('稍后提醒'));
      await tester.pumpAndSettle();
      scope.read(appRouterProvider).go(AppRoutes.settings);
      await tester.pumpAndSettle();
      scope.read(appRouterProvider).go(AppRoutes.home);
      await tester.pumpAndSettle();
      expect(find.text('查看更新'), findsNothing);
      expect(code.checks, 1);
      expect(code.applications, 0);
    },
  );

  for (final offline in [false, true]) {
    testWidgets('latest or offline startup is quiet (offline=$offline)', (
      tester,
    ) async {
      apk.release = null;
      if (offline) apk.checkError = Exception('offline');
      code.info = const CodeUpdateStatus();
      await launch(tester);
      expect(apk.checks, 1);
      expect(find.text('查看更新'), findsNothing);
      expect(find.byTooltip('打开菜单'), findsOneWidget);
    });
  }
}
