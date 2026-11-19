import 'dart:convert';
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
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/app/chat/chat_view_model.dart';
import 'package:towork/main.dart';

import '../test/support/free/fake_model_gateway.dart';

class _RecurringModel implements ModelGateway {
  int calls = 0;
  JsonObject tool(String id, String name, JsonObject args) => {
    'id': id,
    'type': 'function',
    'function': {'name': name, 'arguments': jsonEncode(args)},
  };
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    expect(apiKey, 'synthetic-recurrence-key');
    final round = ++calls;
    List<JsonObject> actions;
    if (round == 1) {
      actions = [
        for (final id in ['a', 'b'])
          tool(id, 'todo_repeat_create', {
            'title': id == 'a' ? '每日复盘' : '拒绝系列',
            'due_at': '2026-09-24T01:00:00.000Z',
            'repeat_rule': 'FREQ=DAILY;COUNT=4',
            'repeat_timezone': 'Asia/Shanghai',
          }),
      ];
    } else if (round == 3 || round == 6) {
      actions = [
        tool('query$round', 'todo_list', {'query': '每日'}),
      ];
    } else if (round == 4 || round == 7) {
      final rows =
          jsonDecode(request.messages.last['content']! as String)['items']
              as List;
      final todo = rows.singleWhere((e) => e['occurrence_index'] == 1) as Map;
      actions = [
        tool(
          'change$round',
          round == 4 ? 'todo_repeat_update' : 'todo_repeat_delete',
          {
            'id': todo['id'],
            'expected_version': todo['version'],
            'expected_series_version': todo['series_version'],
            'scope': 'current_and_future',
            if (round == 4) 'patch': {'title': '每日新复盘'},
          },
        ),
      ];
    } else {
      expect([2, 5, 8], contains(round));
      yield ModelCompleted(
        assistantMessage: {'role': 'assistant', 'content': '本次操作已处理。'},
        finishReason: 'stop',
      );
      return;
    }
    yield ModelCompleted(
      assistantMessage: {
        'role': 'assistant',
        'content': null,
        'tool_calls': actions,
      },
      finishReason: 'tool_calls',
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'recurrence approval, restart, scoped refresh, delete and undo through production UI',
    (tester) async {
      final support = await getApplicationSupportDirectory();
      final folder = await Directory(
        '${support.path}/recurrence-agent-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${folder.path}/fixture.sqlite');
      final model = _RecurringModel();
      final vault = FakeKeyVault();
      AppDatabase? db;
      ProviderContainer? container;
      AgentRun latest() => container!
          .read(localChatRuntimeProvider)!
          .projection
          .data
          .turns
          .last
          .run;
      Future<void> until(bool Function() ready) async {
        final elapsed = Stopwatch()..start();
        while (!ready() && elapsed.elapsed < const Duration(seconds: 15)) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(
          ready(),
          isTrue,
          reason:
              'calls=${model.calls}; error=${container?.read(chatViewModelProvider).error}',
        );
        await tester.pumpAndSettle();
      }

      Future<void> settled(AgentRunStatus status) => until(
        () =>
            container!
                .read(localChatRuntimeProvider)!
                .projection
                .data
                .turns
                .isNotEmpty &&
            latest().status == status &&
            !container!.read(chatViewModelProvider).isGenerating,
      );
      Future<void> open({bool initial = false}) async {
        final current = AppDatabase.background(file);
        db = current;
        final settings = ModelSettingsService(current, vault, model);
        if (initial) {
          await settings.save(
            profile: ModelProfile(
              model: 'fixture',
              product: ProviderKind.kimiCode,
            ),
            expectedVersion: 0,
            newKey: 'synthetic-recurrence-key',
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

      Future<void> tapText(String label) async {
        final button = find.text(label).last;
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      Future<void> send(String text) async {
        final input = find.byKey(const ValueKey('chat-text-input'));
        await tester.tap(input);
        await tester.pumpAndSettle();
        await tester.enterText(input, text);
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await settled(AgentRunStatus.awaitingConfirmation);
      }

      Future<WorkspaceSnapshot> snapshot() =>
          SqliteWorkspaceCommandStore(db!).load();
      try {
        await open(initial: true);
        await send('重复待办审批');
        expect(find.text('本次及以后 4 条待办变更'), findsNWidgets(2));
        final checkbox = find.byKey(const ValueKey('agent-select-b'));
        await tester.ensureVisible(checkbox);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
        await tapText('接受选中（1）');
        await until(
          () =>
              latest().receipts.length == 1 &&
              !container!.read(chatViewModelProvider).isGenerating,
        );
        expect((await snapshot()).todos, hasLength(4));
        expect((await snapshot()).series, hasLength(1));
        expect(
          container!.read(localWorkspaceSessionProvider)!.automaticWorkHeld,
          isFalse,
        );
        await close();
        await open();
        final menu = find.byTooltip('打开菜单');
        if (menu.evaluate().isNotEmpty) {
          await tester.tap(menu);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('重复待办审批').first);
        await tester.pumpAndSettle();
        await tapText('拒绝选中（1）');
        await settled(AgentRunStatus.succeeded);
        expect(model.calls, 2);
        expect((await snapshot()).todos, hasLength(4));
        await send('修改第二次及以后的复盘标题');
        expect(model.calls, 4);
        final before = await snapshot();
        final selected = before.todos.singleWhere(
          (e) => e.data['occurrence_index'] == 1,
        );
        await SqliteWorkspaceCommandStore(db!).execute(
          WorkspaceCommand(
            operationId: 'manual-note',
            actions: [
              WorkspaceMutation(
                actionId: 'note',
                kind: WorkspaceEntityKind.todo,
                entityId: selected.id,
                mutation: WorkspaceMutationKind.update,
                expectedVersion: selected.version,
                patch: {'note': '人工备注'},
              ),
            ],
          ),
        );
        await tapText('全部接受');
        await settled(AgentRunStatus.failed);
        await tapText('刷新差异');
        await settled(AgentRunStatus.awaitingConfirmation);
        final detail = find.text('查看全部变更').last;
        await tester.ensureVisible(detail);
        await tester.tap(detail);
        await tester.pumpAndSettle();
        expect(find.text('编辑 每日新复盘'), findsWidgets);
        await tapText('全部接受');
        await settled(AgentRunStatus.succeeded);
        expect(
          (await snapshot()).todos.where((e) => e.data['title'] == '每日新复盘'),
          hasLength(3),
        );
        expect(
          (await snapshot())
              .find(WorkspaceEntityKind.todo, selected.id)!
              .data['note'],
          '人工备注',
        );
        await tapText('撤销');
        await until(
          () =>
              container!
                  .read(localChatRuntimeProvider)!
                  .projection
                  .data
                  .turns
                  .last
                  .undoneAt !=
              null,
        );
        expect(
          (await snapshot()).todos.where((e) => e.data['title'] == '每日复盘'),
          hasLength(4),
        );
        expect(
          (await snapshot())
              .find(WorkspaceEntityKind.todo, selected.id)!
              .data['note'],
          '人工备注',
        );
        await send('删除第二次及以后的复盘');
        expect(model.calls, 7);
        expect((await snapshot()).todos, hasLength(4));
        await tapText('全部接受');
        await settled(AgentRunStatus.succeeded);
        expect((await snapshot()).todos, hasLength(1));
        await tapText('撤销');
        await until(
          () =>
              container!
                  .read(localChatRuntimeProvider)!
                  .projection
                  .data
                  .turns
                  .last
                  .undoneAt !=
              null,
        );
        expect((await snapshot()).todos, hasLength(4));
        expect(container!.read(todoListProvider), hasLength(4));
        expect(model.calls, 8);
        expect(tester.takeException(), isNull);
      } finally {
        await close();
        await folder.delete(recursive: true);
      }
    },
  );
}
