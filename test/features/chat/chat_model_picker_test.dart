import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/app_preferences_provider.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/ai/quota.dart';
import 'package:towork/features/chat/widgets/sidebar_quota_strip.dart';
import 'package:towork/domain/settings/model_account_service.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/features/chat/widgets/chat_model_button.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/core/ai/brand_logos.dart';
import 'package:towork/theme/app_theme.dart';

import '../../support/free/fake_model_gateway.dart';

class _Runtime extends Fake implements LocalChatRuntime {}

void main() {
  late FakeKimiConfigurationStore store;
  late ModelAccountService service;
  late ProviderContainer container;

  setUp(() {
    store = FakeKimiConfigurationStore();
    service = ModelAccountService(
      ModelSettingsService(store, FakeKeyVault(), FakeKimiGateway()),
      store,
    );
    container = ProviderContainer(
      overrides: [
        localChatRuntimeProvider.overrideWith((ref) => _Runtime()),
        chatModelProvider.overrideWith((ref) => 'kimi-k3'),
        modelAccountServiceProvider.overrideWith((ref) async => service),
      ],
    );
  });
  tearDown(() => container.dispose());

  Future<void> add(ProviderKind kind, {String? model}) => service.save(
    profile: ModelProfile(
      product: kind,
      model: model ?? ProviderCatalog.of(kind).models.first.id,
    ),
    newKey: 'synthetic-key',
  );
  Future<void> mount(
    WidgetTester tester, {
    double scale = 1,
    Size size = const Size(360, 780),
    double keyboard = 0,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: child!,
          ),
          home: const Scaffold(
            body: Align(
              alignment: Alignment.bottomLeft,
              child: ChatModelButton(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('选择模型'));
    await tester.pumpAndSettle();
  }

  Future<void> provider(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(ValueKey('provider-$id')));
    await tester.pumpAndSettle();
  }

  Finder menuText(String name) => find.descendant(
    of: find.byKey(const ValueKey('model-picker')),
    matching: find.text(name),
  );

  testWidgets('drawer shows only the supplier and the returned plan windows', (
    tester,
  ) async {
    await add(ProviderKind.zhipuCoding, model: 'glm-5.3-flash');
    final id = (await service.load()).active!.id;
    await store.recordQuota(
      id,
      QuotaSnapshot(
        fetchedAt: DateTime.utc(2026),
        windows: const [
          QuotaWindow(label: '每周', usedRatio: .41),
          QuotaWindow(label: '5 小时', usedRatio: .2),
        ],
      ),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: SidebarQuotaStrip(onOpen: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('GLM Coding'), findsOneWidget);
    expect(find.textContaining('5.3'), findsNothing);
    expect(
      tester.getTopLeft(find.text('5h')).dy,
      tester.getTopLeft(find.text('周限')).dy,
    );
    expect(find.text('59%'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('月限'), findsNothing);
    expect(find.text('日限'), findsNothing);
  });

  testWidgets('provider then model, browsing preserves configuration', (
    tester,
  ) async {
    await add(ProviderKind.moonshot);
    await add(ProviderKind.deepseek);
    final before = store.configuration;
    await mount(tester);
    expect(menuText('Kimi K3'), findsNothing);
    expect(menuText('DS V4 Pro'), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('model-picker'))).width,
      208,
    );
    expect(tester.widget<Text>(menuText('DeepSeek')).style!.fontSize, 12);
    final panel = tester.getRect(find.byKey(const ValueKey('model-picker')));
    final row = tester.getRect(find.byKey(const ValueKey('provider-deepseek')));
    expect(row.size, const Size(200, 36));
    expect(panel.height, 157);
    expect(tester.getRect(menuText('DeepSeek')).left - panel.left, 32);
    expect(tester.getSize(find.byTooltip('选择模型')).height, 44);
    await provider(tester, 'deepseek');
    expect(store.configuration, same(before));
    expect(menuText('DS V4 Pro'), findsOneWidget);
    final models = tester.getRect(find.byKey(const ValueKey('model-picker')));
    expect(models.width, 208);
    expect(tester.getRect(menuText('DS V4 Pro')).left - models.left, 32);
    final modelRow = find.ancestor(
      of: menuText('DS V4 Pro'),
      matching: find.byType(AppPressable),
    );
    expect(
      tester
          .widget<BrandLogo>(
            find.descendant(of: modelRow, matching: find.byType(BrandLogo)),
          )
          .brand,
      AiBrand.deepseek,
    );
    await tester.tap(menuText('DS V4 Pro'));
    await tester.pumpAndSettle();
    expect(store.configuration.profile.model, 'deepseek-v4-pro');
    expect(store.configuration.profile.product, ProviderKind.deepseek);
    expect(container.read(appPreferencesSnapshotProvider).autoRoute, isFalse);
    expect(find.byKey(const ValueKey('model-picker')), findsNothing);
    expect(find.text('DeepSeek'), findsNothing);
    expect(find.text('DS V4 Pro'), findsOneWidget);
    expect(
      tester.widget<BrandLogo>(find.byType(BrandLogo)).brand,
      AiBrand.deepseek,
    );
  });

  testWidgets(
    'same provider groups multiple accounts and retains custom models',
    (tester) async {
      await add(ProviderKind.deepseek, model: 'glm-private-route');
      await add(ProviderKind.deepseek);
      await mount(tester, scale: 1.6);
      expect(find.byKey(const ValueKey('provider-deepseek')), findsOneWidget);
      await provider(tester, 'deepseek');
      expect(menuText('glm-private-route'), findsOneWidget);
      final legacy = menuText('glm-private-route');
      await tester.ensureVisible(legacy);
      await tester.tap(legacy);
      await tester.pumpAndSettle();
      expect(store.configuration.profile.model, 'glm-private-route');
      expect(
        tester.widget<BrandLogo>(find.byType(BrandLogo)).brand,
        AiBrand.deepseek,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('back returns to providers and auto route remains accessible', (
    tester,
  ) async {
    await add(ProviderKind.moonshot);
    await mount(tester);
    await provider(tester, 'platform');
    await tester.tap(find.byKey(const ValueKey('model-picker-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('provider-platform')), findsOneWidget);
    await tester.tap(menuText('自动换用'));
    await tester.pumpAndSettle();
    expect(container.read(appPreferencesSnapshotProvider).autoRoute, isTrue);
    expect(find.byKey(const ValueKey('model-picker')), findsNothing);
  });

  testWidgets(
    'outside tap closes the second level without changing the model',
    (tester) async {
      await add(ProviderKind.deepseek);
      final before = store.configuration;
      await mount(tester);
      await provider(tester, 'deepseek');
      await tester.tapAt(const Offset(340, 100));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('model-picker')), findsNothing);
      expect(store.configuration, same(before));
    },
  );

  testWidgets('empty account list offers management in compact menu', (
    tester,
  ) async {
    await mount(tester);
    expect(menuText('添加模型账户'), findsOneWidget);
    expect(menuText('管理账户'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long model names grow and remain reachable above the keyboard', (
    tester,
  ) async {
    const model = 'custom-model-with-a-long-name-for-compact-layout';
    await add(ProviderKind.deepseek, model: model);
    await mount(tester, scale: 2, size: const Size(320, 680), keyboard: 260);
    await provider(tester, 'deepseek');
    final label = menuText(model);
    await tester.ensureVisible(label);
    await tester.pumpAndSettle();
    final row = find.ancestor(of: label, matching: find.byType(AppPressable));
    expect(tester.getSize(row).height, greaterThan(36));
    final panel = tester.getRect(find.byKey(const ValueKey('model-picker')));
    expect(panel.width, 208);
    expect(panel.top, greaterThanOrEqualTo(8));
    expect(panel.bottom, lessThanOrEqualTo(408));
    expect(label.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(label);
    await tester.pumpAndSettle();
    expect(store.configuration.profile.model, model);
  });

  testWidgets('compact provider row still supports keyboard activation', (
    tester,
  ) async {
    await add(ProviderKind.deepseek);
    await mount(tester);
    final row = find.byKey(const ValueKey('provider-deepseek'));
    final pointer = find.descendant(
      of: row,
      matching: find.byType(GestureDetector),
    );
    Focus.of(tester.element(pointer)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('model-picker-back')), findsOneWidget);
    expect(menuText('DS V4 Pro'), findsOneWidget);
  });
}
