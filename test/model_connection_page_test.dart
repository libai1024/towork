import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/main.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/features/settings/widgets/model_action_button.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_account_service.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/features/settings/model_connection_page.dart';
import 'package:towork/theme/app_theme.dart';

import 'support/free/fake_model_gateway.dart';

void main() {
  late FakeKimiConfigurationStore db;
  late FakeKeyVault vault;
  late FakeKimiGateway gateway;
  late ModelSettingsService service;
  late ModelAccountService accounts;
  setUp(() {
    db = FakeKimiConfigurationStore();
    vault = FakeKeyVault();
    gateway = FakeKimiGateway();
    service = ModelSettingsService(db, vault, gateway);
    accounts = ModelAccountService(service, db);
  });
  Future<void> mount(WidgetTester tester, {double width = 390}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          modelAccountServiceProvider.overrideWith((ref) async => accounts),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ModelConnectionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> mountAccounts(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialAppLocationProvider.overrideWithValue(AppRoutes.modelAccounts),
          modelAccountServiceProvider.overrideWith((ref) async => accounts),
        ],
        child: const ToWorkApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> editCustomModel(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('choose-account-model')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自定义模型').last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'add and edit open from the bottom, keyboard keeps the header visible and back returns to the account list',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final snapshot = await accounts.save(
        profile: ModelProfile(
          model: 'fixture-id',
          product: ProviderKind.custom,
          baseUrl: 'https://fixture.test/v1',
        ),
        newKey: 'fixture-key',
      );
      final id = snapshot.accounts.single.id;
      await mountAccounts(tester);
      final sheet = find.byKey(const ValueKey('model-account-sheet'));
      await tester.tap(find.byKey(const ValueKey('account-add')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
      final entering = tester.getRect(sheet);
      expect(entering.left, 0);
      expect(entering.top, greaterThan(422));
      await tester.pumpAndSettle();
      final opened = tester.getRect(sheet);
      expect(entering.top, greaterThan(opened.top));
      expect(opened.bottom, 844);
      expect(opened.width, 390);
      expect(opened.height, lessThan(422));
      final lastRow = find.byKey(const ValueKey(ProviderKind.kimiCode));
      expect(opened.bottom - tester.getRect(lastRow).bottom, 6);
      await tester.tapAt(const Offset(175, 200));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      await tester.tap(find.byKey(ValueKey('account-$id')));
      await tester.pumpAndSettle();
      final edited = tester.getRect(sheet);
      expect(edited.height, lessThan(422));
      final customRow = find.byKey(const ValueKey(ProviderKind.custom));
      expect(edited.bottom - tester.getRect(customRow).bottom, 6);
      expect(find.text('编辑模型账户'), findsOneWidget);
      final model = find.byKey(const ValueKey('model-name-input'));
      expect(tester.widget<TextField>(model).controller!.text, 'fixture-id');
      final label = tester.getRect(find.text('模型 ID'));
      final editor = tester.getRect(model);
      expect(label.right, lessThan(editor.left));
      expect((label.center.dy - editor.center.dy).abs(), lessThan(2));
      await tester.tap(model);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.getRect(sheet).bottom, 544);
      expect(
        tester.getRect(find.byKey(const ValueKey('model-save'))).bottom,
        lessThan(editor.top),
      );
      await tester.enterText(model, 'edited-id');
      await tester.pump();
      await tester.tap(find.byTooltip('保存'));
      await tester.pumpAndSettle();
      expect((await accounts.load()).byId(id)!.profile.model, 'edited-id');
      expect(sheet, findsNothing);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('account-$id')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(model).controller!.text, 'edited-id');
      tester.view.viewInsets = const FakeViewPadding(bottom: 650);
      await tester.pumpAndSettle();
      expect(tester.getRect(sheet).bottom, 194);
      expect(
        find.byKey(const ValueKey('model-save')).hitTestable(),
        findsOneWidget,
      );
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: sheet, matching: find.byType(Scrollable)).first,
      );
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('model-sheet-header')),
        const Offset(0, 90),
      );
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(find.byKey(ValueKey('account-$id')), findsOneWidget);
    },
  );

  testWidgets('probe feedback stays centered without moving the account form', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await mountAccounts(tester);
    await tester.tap(find.byKey(const ValueKey('account-add')));
    await tester.pumpAndSettle();
    final keyField = find.byKey(const ValueKey('model-key-input'));
    final sheet = find.byKey(const ValueKey('model-account-sheet'));
    await tester.enterText(keyField, 'fixture-key');
    await tester.pump();
    vault.failWrite = true;
    await tester.tap(find.byTooltip('保存'));
    await tester.pumpAndSettle();
    expect(sheet, findsOneWidget);
    expect(tester.widget<TextField>(keyField).controller!.text, 'fixture-key');
    vault.failWrite = false;
    await tester.tap(find.byTooltip('保存'));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    final id = (await accounts.load()).active!.id;
    await tester.tap(find.byKey(ValueKey('account-$id')));
    await tester.pumpAndSettle();
    List<Rect> formBounds() => [
      tester.getRect(sheet),
      tester.getRect(keyField),
      tester.getRect(find.byKey(const ValueKey('choose-account-model'))),
    ];
    final initial = formBounds();
    gateway.waitForResponse = Completer<void>();
    await tester.tap(find.byTooltip('测试连接'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('取消测试'), findsOneWidget);
    expect(formBounds(), initial);
    gateway.waitForResponse!.complete();
    await tester.pumpAndSettle();
    final success = find.textContaining('连接成功');
    expect(tester.getCenter(success), const Offset(195, 422));
    expect(formBounds(), initial);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    final withKeyboard = formBounds();
    gateway.failure = const ModelFailure(ModelFailureCode.timeout);
    await tester.tap(find.byTooltip('测试连接'));
    await tester.pumpAndSettle();
    expect(success, findsNothing);
    final failure = find.text('连接超时，请检查网络后重试');
    expect(tester.getCenter(failure), const Offset(195, 272));
    expect(formBounds(), withKeyboard);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(failure, findsNothing);
    expect(formBounds(), withKeyboard);
  });

  testWidgets('provider billing and model presets stay compact until opened', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('plan'), findsOneWidget);
    expect(find.byKey(const ValueKey('model-name-input')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('choose-account-model')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kimi K3 256K'));
    await tester.pumpAndSettle();
    expect(find.text('Kimi K3 256K'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('provider-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('provider-custom')));
    await tester.pumpAndSettle();
    expect(find.text('api'), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-base-url-input')), findsOneWidget);
    expect(find.byKey(const ValueKey('model-name-input')), findsOneWidget);
  });

  testWidgets(
    'fetch, search and select a model using the unsaved endpoint; reopen uses cache',
    (tester) async {
      await mount(tester);
      await tester.tap(find.byKey(const ValueKey('provider-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('provider-custom')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('custom-base-url-input')),
        'https://fixture.test/compatible/v1',
      );
      await tester.enterText(
        find.byKey(const ValueKey('model-key-input')),
        'fixture-key',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('获取模型列表'));
      await tester.pumpAndSettle();
      expect(gateway.directoryUri?.path, '/compatible/v1/models');
      expect(vault.values, isEmpty);
      final search = find.widgetWithText(TextField, '搜索模型');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(700 - tester.getBottomLeft(search).dy, inInclusiveRange(0, 50));
      await tester.enterText(search, 'second');
      await tester.pump();
      expect(find.text('first-model'), findsNothing);
      await tester.tap(find.text('second-model'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('model-name-input')))
            .controller!
            .text,
        'second-model',
      );
      await tester.tap(find.byTooltip('选择已获取的模型'));
      await tester.pumpAndSettle();
      expect(gateway.directoryCalls, 1);
      await tester.tap(find.byTooltip('刷新模型列表'));
      await tester.pumpAndSettle();
      expect(gateway.directoryCalls, 2);
    },
  );

  testWidgets(
    'directory failure can be retried and changing endpoint drops cached results and the draft key',
    (tester) async {
      await mount(tester);
      await tester.tap(find.byKey(const ValueKey('provider-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('provider-custom')));
      await tester.pumpAndSettle();
      final address = find.byKey(const ValueKey('custom-base-url-input'));
      final key = find.byKey(const ValueKey('model-key-input'));
      await tester.enterText(address, 'https://first.example/v1');
      await tester.enterText(key, 'draft-key');
      await tester.pump();
      gateway.failure = const ModelFailure(
        ModelFailureCode.unavailableModel,
        statusCode: 404,
      );
      await tester.tap(find.byTooltip('获取模型列表'));
      await tester.pumpAndSettle();
      expect(find.textContaining('此接口未提供模型列表'), findsOneWidget);
      gateway.failure = null;
      await tester.tap(find.byTooltip('刷新模型列表'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('first-model'));
      await tester.pumpAndSettle();
      await tester.enterText(address, 'https://second.example/v1');
      await tester.pump();
      expect(tester.widget<TextField>(key).controller!.text, isEmpty);
      expect(
        tester
            .widget<ModelActionButton>(
              find.byKey(const ValueKey('model-fetch')),
            )
            .onPressed,
        isNull,
      );
      expect(find.byTooltip('选择已获取的模型'), findsNothing);
      expect(vault.values, isEmpty);
    },
  );

  testWidgets(
    'save clears secret field; real service probe and edits invalidate result',
    (tester) async {
      await mount(tester);
      await tester.enterText(
        find.byKey(const ValueKey('model-key-input')),
        'fixture-secret',
      );
      await tester.pump();
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('model-save')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('model-save')));
      await tester.pumpAndSettle();
      expect(find.text('fixture-secret'), findsNothing);
      expect(vault.values.values, ['fixture-secret']);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('model-test')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('model-test')));
      await tester.pumpAndSettle();
      expect(find.textContaining('连接成功'), findsOneWidget);
      await editCustomModel(tester);
      await tester.enterText(
        find.byKey(const ValueKey('model-name-input')),
        'another-model',
      );
      await tester.pump();
      expect(find.textContaining('连接成功'), findsNothing);
      expect(
        tester
            .widget<ModelActionButton>(find.byKey(const ValueKey('model-test')))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    '401 is explained accurately and never prints raw server content',
    (tester) async {
      await service.save(
        profile: ModelProfile(model: 'fixture'),
        expectedVersion: 0,
        newKey: 'fixture-secret',
      );
      gateway.failure = const ModelFailure(
        ModelFailureCode.authentication,
        statusCode: 401,
      );
      await mount(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('model-test')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('model-test')));
      await tester.pumpAndSettle();
      expect(find.textContaining('模型权益（401）'), findsOneWidget);
      expect(find.text('fixture-secret'), findsNothing);
    },
  );
  testWidgets('cancelled late response does not become successful', (
    tester,
  ) async {
    await service.save(
      profile: ModelProfile(model: 'fixture'),
      expectedVersion: 0,
      newKey: 'fixture-secret',
    );
    gateway.waitForResponse = Completer<void>();
    await mount(tester, width: 1100);
    await tester.tap(find.byKey(const ValueKey('model-test')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('取消测试'));
    gateway.waitForResponse!.complete();
    await tester.pumpAndSettle();
    expect(find.text('已取消测试'), findsOneWidget);
    expect(find.textContaining('连接成功'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('vault failure offers retry without claiming a saved key', (
    tester,
  ) async {
    vault.failWrite = true;
    await mount(tester);
    await tester.enterText(
      find.byKey(const ValueKey('model-key-input')),
      'fixture-secret',
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('model-save')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('model-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('系统安全存储暂不可用'), findsOneWidget);
    expect(find.text('已保存到此设备，可测试连接'), findsNothing);
    expect((await service.load()).hasKey, isFalse);
  });

  testWidgets(
    'draft test never saves a key and rejects an edited draft result',
    (tester) async {
      await mount(tester);
      await tester.enterText(
        find.byKey(const ValueKey('model-key-input')),
        'draft-secret',
      );
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('model-test')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('model-test')));
      await tester.pumpAndSettle();
      expect(find.textContaining('连接成功（未保存）'), findsOneWidget);
      expect(vault.values, isEmpty);
      expect((await service.load()).configuration.version, 0);

      gateway.waitForResponse = Completer<void>();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('model-test')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('model-test')));
      await tester.pumpAndSettle();
      await editCustomModel(tester);
      await tester.enterText(
        find.byKey(const ValueKey('model-name-input')),
        'edited-during-test',
      );
      gateway.waitForResponse!.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('连接成功'), findsNothing);
      expect(find.textContaining('正在测试'), findsNothing);
      expect(vault.values, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed service initialization can be retried', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          modelAccountServiceProvider.overrideWith((ref) async {
            if (++attempts == 1) {
              throw StateError('private-initialization-detail');
            }
            return accounts;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ModelConnectionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('暂时无法完成操作，请重试'), findsOneWidget);
    expect(find.textContaining('private-initialization-detail'), findsNothing);
    await tester.tap(find.text('重新载入'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('model-key-input')), findsOneWidget);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });
}
