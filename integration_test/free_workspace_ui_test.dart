import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/chat/chat_view_model.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/shell/quick_assist_app.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/app_preferences_provider.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/domain/ai/permission_policy.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/core/todo/create_todo_sheet.dart';
import 'package:towork/core/todo/todo_checkbox.dart';
import 'package:towork/main.dart';

import '../test/support/free/fake_model_gateway.dart';
import '../test/support/free/scripted_todo_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native UI create, complete and reopen use persisted workspace', (
    tester,
  ) async {
    final directory = await Directory(
      '${(await getApplicationSupportDirectory()).path}/ui-fixture-${DateTime.now().microsecondsSinceEpoch}',
    ).create();
    final file = File('${directory.path}/workspace.sqlite');
    AppDatabase? db;
    ProviderContainer? container;
    final vault = FakeKeyVault();
    final model = ScriptedTodoModel();
    Future<void> open({bool quickAsk = false}) async {
      final current = AppDatabase.background(file);
      db = current;
      final settings = ModelSettingsService(current, vault, model);
      if (quickAsk) {
        await settings.save(
          profile: ModelProfile(
            model: 'panel-fixture',
            product: ProviderKind.kimiCode,
          ),
          expectedVersion: 0,
          newKey: 'synthetic-test-key',
        );
      }
      container = ProviderContainer(
        overrides: [
          localDatabaseProvider.overrideWith((ref) async => current),
          modelSettingsServiceProvider.overrideWith((ref) async => settings),
          initialAppLocationProvider.overrideWithValue(AppRoutes.todos),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container!,
          child: FreeWorkspaceBootstrap(
            child: quickAsk ? const QuickAssistApp() : const ToWorkApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> close() async {
      await tester.pumpWidget(const SizedBox());
      container?.dispose();
      container = null;
      await db?.close();
      db = null;
    }

    Future<void> awaitCommitted(bool Function() condition) async {
      final elapsed = Stopwatch()..start();
      while (!condition() && elapsed.elapsed < const Duration(seconds: 5)) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        condition(),
        isTrue,
        reason: 'Expected a committed state within five seconds',
      );
      await tester.pumpAndSettle();
    }

    try {
      await open();
      expect(container!.read(todoListProvider), isEmpty);
      expect(container!.read(categoryListProvider), isEmpty);
      final create = find.byWidgetPredicate(
        (widget) => widget is AppPressable && widget.semanticLabel == '新建待办',
      );
      await tester.tap(create.last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(CreateTodoSheet),
          matching: find.byKey(const ValueKey('todo-create-title')),
        ),
        '原生界面保存验证',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('创建'));
      await awaitCommitted(() => container!.read(todoListProvider).isNotEmpty);
      expect(find.byType(CreateTodoSheet), findsNothing);
      expect(find.text('原生界面保存验证'), findsOneWidget);
      final id = container!.read(todoListProvider).single.id;
      await close();
      await open();
      expect(find.text('原生界面保存验证'), findsOneWidget);
      expect(container!.read(todoListProvider).single.id, id);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is TodoCheckbox && widget.semanticLabel == '完成待办：原生界面保存验证',
        ),
      );
      await tester.pumpAndSettle();
      await awaitCommitted(
        () => container!.read(todoListProvider).single.status.name == 'done',
      );
      expect(container!.read(todoListProvider).single.status.name, 'done');
      await close();
      await open();
      expect(container!.read(todoListProvider).single.status.name, 'done');
      container!.read(appRouterProvider).go(AppRoutes.settings);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('AI 写入权限'));
      await tester.tap(find.text('AI 写入权限'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('总是询问'));
      await awaitCommitted(
        () =>
            container!.read(aiWritePermissionProvider) ==
            AiWritePermission.askAll,
      );
      await tester.ensureVisible(find.text('免记忆模式'));
      await tester.tap(find.text('免记忆模式'));
      await awaitCommitted(() => container!.read(memoryPausedProvider));
      await tester.ensureVisible(find.text('默认输入方式'));
      await tester.tap(find.text('默认输入方式'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('键盘'));
      await awaitCommitted(
        () =>
            container!.read(defaultInputModeProvider) == ChatInputMode.keyboard,
      );
      expect(
        container!.read(aiWritePermissionProvider),
        AiWritePermission.askAll,
      );
      expect(container!.read(memoryPausedProvider), isTrue);
      expect(container!.read(defaultInputModeProvider), ChatInputMode.keyboard);
      await close();
      await open();
      final saved = container!.read(appPreferencesSnapshotProvider);
      expect(saved.permission, AiWritePermission.askAll);
      expect(saved.memoryPaused, isTrue);
      expect(saved.inputMode, 'keyboard');
      expect(container!.read(defaultInputModeProvider), ChatInputMode.keyboard);
      if (Platform.isAndroid) {
        await close();
        await open(quickAsk: true);
        final input = find.byKey(const ValueKey('chat-text-input'));
        await tester.enterText(input, '创建测试任务');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        final confirm = find.text('全部接受');
        await awaitCommitted(() => confirm.evaluate().isNotEmpty);
        expect(container!.read(todoListProvider).single.id, id);
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await awaitCommitted(
          () =>
              container!.read(todoListProvider).length == 2 &&
              !container!.read(chatViewModelProvider).isGenerating,
        );
        final fromPanel = container!
            .read(todoListProvider)
            .singleWhere((t) => t.id != id);
        expect(fromPanel.title, '测试任务');
        expect(fromPanel.source.name, 'ai');
        await close();
        await open();
        expect(
          container!.read(todoListProvider.notifier).byId(fromPanel.id)!.title,
          '测试任务',
        );
        expect(find.text('测试任务'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    } finally {
      await close();
      await directory.delete(recursive: true);
    }
  });
}
