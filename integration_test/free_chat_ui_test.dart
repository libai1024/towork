import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/domain/settings/model_settings.dart';
import 'package:towork/app/chat/chat_view_model.dart';
import 'package:towork/main.dart';

import '../test/support/free/fake_model_gateway.dart';
import '../test/support/free/scripted_todo_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real chat UI accepts, completes, undoes and restores local conversations',
    (tester) async {
      final support = await getApplicationSupportDirectory();
      final directory = await Directory(
        '${support.path}/chat-ui-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${directory.path}/chat.sqlite');
      final vault = FakeKeyVault();
      final model = ScriptedTodoModel();
      AppDatabase? db;
      ProviderContainer? container;
      Future<void> until(bool Function() condition) async {
        final watch = Stopwatch()..start();
        while (!condition() && watch.elapsed < const Duration(seconds: 10)) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(
          condition(),
          isTrue,
          reason:
              'Expected committed chat state; calls=${model.calls}; '
              'generating=${container?.read(chatViewModelProvider).isGenerating}; '
              'error=${switch (container?.read(chatViewModelProvider).error) {
                SettingsFailure failure => failure.code.name,
                final error => error.runtimeType.toString(),
              }}; '
              'runs=${container?.read(localChatRuntimeProvider)?.projection.data.turns.map((t) => '${t.run.status.name}:${t.run.failureCode}').join(',')}',
        );
        await tester.pumpAndSettle();
      }

      Future<void> open({bool initial = false}) async {
        final current = AppDatabase.background(file);
        db = current;
        final settings = ModelSettingsService(current, vault, model);
        if (initial) {
          await settings.save(
            profile: ModelProfile(
              model: 'native-test',
              product: ProviderKind.kimiCode,
            ),
            expectedVersion: 0,
            newKey: 'synthetic-native-key',
          );
          final prefs = SqliteAppPreferencesStore(current);
          final old = await prefs.loadOrCreate();
          await prefs.update({
            'permission': 'askAll',
            'input_mode': 'keyboard',
          }, expectedVersion: old.version);
        }
        container = ProviderContainer(
          overrides: [
            localDatabaseProvider.overrideWith((ref) async => current),
            modelSettingsServiceProvider.overrideWith((ref) async => settings),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container!,
            child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
          ),
        );
        await until(() => container!.read(localChatRuntimeProvider) != null);
      }

      Future<void> close() async {
        await tester.pumpWidget(const SizedBox());
        container?.dispose();
        container = null;
        await db?.close();
        db = null;
      }

      AgentRun latest() =>
          (container!
                  .read(localChatRuntimeProvider)!
                  .projection
                  .data
                  .turns
                  .toList()
                ..sort((a, b) => a.position.compareTo(b.position)))
              .last
              .run;
      Future<void> send(String text) async {
        final input = find.byKey(const ValueKey('chat-text-input'));
        await tester.tap(input);
        await tester.pumpAndSettle();
        await tester.enterText(input, text);
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await until(
          () =>
              !container!.read(chatViewModelProvider).isGenerating &&
              container!
                  .read(localChatRuntimeProvider)!
                  .projection
                  .data
                  .turns
                  .isNotEmpty &&
              latest().status == AgentRunStatus.awaitingConfirmation,
        );
        expect((tester.widget<TextField>(input)).controller!.text, isEmpty);
      }

      Future<void> accept() async {
        final button = find.text('全部接受').last;
        await tester.ensureVisible(button);
        await tester.tap(button);
        await until(
          () =>
              !container!.read(chatViewModelProvider).isGenerating &&
              latest().status == AgentRunStatus.succeeded,
        );
      }

      Future<void> selectHistory(String title) async {
        final menu = find.byTooltip('打开菜单');
        if (menu.evaluate().isNotEmpty) {
          await tester.tap(menu);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(title).first);
        await tester.pumpAndSettle();
      }

      try {
        await open(initial: true);
        expect(container!.read(sessionListProvider), isEmpty);
        vault.failRead = true;
        final input = find.byKey(const ValueKey('chat-text-input'));
        await tester.enterText(input, '创建测试任务');
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await until(() => !container!.read(chatViewModelProvider).isGenerating);
        expect(tester.widget<TextField>(input).controller!.text, '创建测试任务');
        expect(container!.read(sessionListProvider), isEmpty);
        expect(model.calls, 0);
        vault.failRead = false;
        await container!
            .read(localChatRuntimeProvider)!
            .settings
            .runtimeCredential();
        await send('创建测试任务');
        expect(container!.read(todoListProvider), isEmpty);
        await accept();
        await until(() => container!.read(todoListProvider).length == 1);
        expect(container!.read(todoListProvider).single.title, '测试任务');
        expect(find.textContaining('private reasoning'), findsNothing);
        final sessionId = container!.read(currentSessionIdProvider);
        await close();
        await open();
        expect(container!.read(sessionListProvider).single.id, sessionId);
        await selectHistory('创建测试任务');
        await send('完成测试任务');
        expect(container!.read(todoListProvider).single.status.name, 'pending');
        await accept();
        await until(
          () => container!.read(todoListProvider).single.status.name == 'done',
        );
        final undo = find.text('撤销').last;
        await tester.ensureVisible(undo);
        await tester.tap(undo);
        await until(
          () =>
              container!.read(todoListProvider).single.status.name == 'pending',
        );
        await tester.tap(find.byTooltip('会话选项'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('chat-session-name')),
          '保存的真实会话',
        );
        await tester.tap(find.text('保存').last);
        await until(
          () => container!.read(sessionListProvider).single.title == '保存的真实会话',
        );
        await close();
        await open();
        await selectHistory('保存的真实会话');
        expect(container!.read(todoListProvider).single.status.name, 'pending');
        expect(
          container!
              .read(localChatRuntimeProvider)!
              .projection
              .data
              .turns
              .last
              .undoneAt,
          isNotNull,
        );
        await tester.tap(find.byTooltip('会话选项'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('删除会话'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('删除').last);
        await until(() => container!.read(sessionListProvider).isEmpty);
        expect(container!.read(todoListProvider), hasLength(1));
        await close();
        await open();
        expect(container!.read(sessionListProvider), isEmpty);
        expect(container!.read(todoListProvider), hasLength(1));
      } finally {
        await close();
        await directory.delete(recursive: true);
      }
    },
  );
}
