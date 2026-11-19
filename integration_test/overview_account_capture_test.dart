import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/core/ai/quota_widgets.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/ai/quota.dart';
import 'package:towork/domain/settings/model_account_service.dart';
import 'package:towork/domain/settings/model_accounts.dart';
import 'package:towork/domain/settings/model_settings.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/main.dart';
import 'package:towork/shell/router.dart';

import '../test/support/free/fake_model_gateway.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('daily actions and equal-height account rows', (tester) async {
    final root = GlobalKey();
    final images = <String, String>{};
    binding.reportData = {'screenshots': images};
    final now = DateTime.now();
    final plan = ModelAccount(
      id: 'plan',
      credentialRef: 'fixture-plan',
      profile: ModelProfile(
        product: ProviderKind.zhipuCoding,
        model: 'glm-5.3-flash',
      ),
      quota: QuotaSnapshot(
        fetchedAt: now,
        windows: const [
          QuotaWindow(label: '每周', usedRatio: .41),
          QuotaWindow(label: '每月', usedRatio: .15),
          QuotaWindow(label: '5 小时', usedRatio: .20),
        ],
      ),
    );
    final api = ModelAccount(
      id: 'api',
      credentialRef: 'fixture-api',
      profile: ModelProfile(
        product: ProviderKind.deepseek,
        model: 'deepseek-chat',
      ),
      quota: QuotaSnapshot(fetchedAt: now, balance: 26.82, currency: 'CNY'),
    );
    final snapshot = ModelAccountsSnapshot(
      configuration: ModelConfiguration(profile: plan.profile),
      accounts: [plan, api],
      activeId: plan.id,
    );
    final store = FakeKimiConfigurationStore();
    final state = ProviderContainer(
      overrides: [
        modelAccountsProvider.overrideWith((ref) => Stream.value(snapshot)),
        modelAccountServiceProvider.overrideWith(
          (ref) async => ModelAccountService(
            ModelSettingsService(store, FakeKeyVault(), FakeKimiGateway()),
            store,
          ),
        ),
      ],
    );
    if (Platform.isMacOS) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1210, 820);
      await binding.setSurfaceSize(const Size(1210, 820));
    }
    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      images[name] = base64Encode(bytes!.buffer.asUint8List());
      image.dispose();
    }

    await tester.pumpWidget(
      RepaintBoundary(
        key: root,
        child: UncontrolledProviderScope(
          container: state,
          child: const ToWorkApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      state.read(themeModeProvider.notifier).state = mode;
      state.read(appRouterProvider).go(AppRoutes.home);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('打开今日总览'));
      await tester.pumpAndSettle();
      expect(find.text('全部待办').hitTestable(), findsOneWidget);
      expect(find.byTooltip('新建待办').hitTestable(), findsOneWidget);
      await shot('overview-${mode.name}');
      await tester.tap(find.byTooltip('新建待办'));
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('todo-create-title'));
      await tester.enterText(input, '整理会议纪要');
      expect(
        tester.getCenter(input).dy,
        greaterThan(tester.getCenter(find.byTooltip('创建')).dy),
      );
      await shot('capture-${mode.name}');
      await tester.tap(find.byTooltip('关闭').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('收起今日总览'));
      await tester.pumpAndSettle();
      state.read(appRouterProvider).go(AppRoutes.modelAccounts);
      await tester.pumpAndSettle();
      final planCard = find.byKey(const ValueKey('account-plan'));
      final apiCard = find.byKey(const ValueKey('account-api'));
      expect(tester.getSize(planCard).height, tester.getSize(apiCard).height);
      expect(find.text('余额 ¥26.82'), findsOneWidget);
      for (final label in ['周限', '月限']) {
        expect(
          tester.getTopLeft(find.text(label)).dy,
          tester.getTopLeft(find.text('5h')).dy,
        );
      }
      expect(find.byType(QuotaMeter), findsNWidgets(3));
      await shot('accounts-${mode.name}');
    }
    if (Platform.isMacOS) {
      tester.view.physicalSize = const Size(320, 740);
      await binding.setSurfaceSize(const Size(320, 740));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      final planCard = find.byKey(const ValueKey('account-plan'));
      final apiCard = find.byKey(const ValueKey('account-api'));
      expect(tester.getSize(planCard).height, tester.getSize(apiCard).height);
      final windows = find.descendant(
        of: planCard,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(windows).position;
      expect(position.maxScrollExtent, greaterThan(0));
      await tester.drag(windows, const Offset(-320, 0));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(find.text('月限').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
}
