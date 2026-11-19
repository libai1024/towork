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

class _ApprovalModel implements ModelGateway {
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
    expect(apiKey, 'synthetic-approval-key');
    final round = ++calls;
    List<JsonObject> actions;
    if (round == 1) {
      actions = [
        tool('a', 'todo_create', {'title': '接受任务'}),
        tool('b', 'todo_create', {'title': '拒绝任务'}),
      ];
    } else if (round == 2) {
      final results = request.messages
          .where((m) => m['role'] == 'tool')
          .toList();
      expect(results.map((r) => r['tool_call_id']), ['a', 'b']);
      expect(
        jsonDecode(results.last['content']! as String)['reason'],
        'user_rejected',
      );
      final entity =
          jsonDecode(results.first['content']! as String)['entity'] as Map;
      actions = [
        tool('c', 'todo_complete', {
          'id': entity['id'],
          'expected_version': entity['version'],
        }),
      ];
    } else if (round == 4) {
      actions = [
        tool('edit', 'todo_update', {
          'id': 'manual-target',
          'expected_version': 1,
          'patch': {'title': '意图标题'},
        }),
      ];
    } else {
      expect([3, 5], contains(round));
      yield ModelCompleted(
        assistantMessage: {
          'role': 'assistant',
          'content': round == 3 ? '已创建并完成接受任务，另一项已拒绝。' : '已更新目标，保留人工备注。',
        },
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
  testWidgets(
    'partial approval, restored rejection and multi-batch undo through production UI',
    (tester) async {
      final support = await getApplicationSupportDirectory();
      final folder = await Directory(
        '${support.path}/approval-test-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${folder.path}/fixture.sqlite');
      final model = _ApprovalModel();
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
        while (!ready() && elapsed.elapsed < const Duration(seconds: 10)) {
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
            newKey: 'synthetic-approval-key',
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
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      Future<void> selectHistory() async {
        final menu = find.byTooltip('打开菜单');
        if (menu.evaluate().isNotEmpty) {
          await tester.tap(menu);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('两项审批测试').first);
        await tester.pumpAndSettle();
      }

      try {
        await open(initial: true);
        final input = find.byKey(const ValueKey('chat-text-input'));
        await tester.tap(input);
        await tester.pumpAndSettle();
        await tester.enterText(input, '两项审批测试');
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await until(
          () =>
              container!
                  .read(localChatRuntimeProvider)!
                  .projection
                  .data
                  .turns
                  .isNotEmpty &&
              latest().status == AgentRunStatus.awaitingConfirmation &&
              !container!.read(chatViewModelProvider).isGenerating,
        );
        final second = find.byKey(const ValueKey('agent-select-b'));
        await tester.ensureVisible(second);
        await tester.tap(second);
        await tester.pumpAndSettle();
        await tapText('接受选中（1）');
        await until(
          () =>
              latest().receipts.length == 1 &&
              !container!.read(chatViewModelProvider).isGenerating,
        );
        expect(model.calls, 1);
        expect(container!.read(todoListProvider).single.title, '接受任务');
        expect(latest().status, AgentRunStatus.awaitingConfirmation);
        await close();
        await open();
        await selectHistory();
        expect(find.byKey(const ValueKey('agent-select-a')), findsNothing);
        expect(find.byKey(const ValueKey('agent-select-b')), findsOneWidget);
        await tapText('拒绝选中（1）');
        await until(
          () =>
              model.calls == 2 &&
              latest().status == AgentRunStatus.awaitingConfirmation &&
              !container!.read(chatViewModelProvider).isGenerating,
        );
        expect(container!.read(todoListProvider), hasLength(1));
        await tapText('全部接受');
        await until(
          () =>
              latest().status == AgentRunStatus.succeeded &&
              !container!.read(chatViewModelProvider).isGenerating,
        );
        expect(latest().receipts, hasLength(2));
        await tapText('撤销');
        await until(
          () =>
              container!.read(todoListProvider).isEmpty &&
              container!
                      .read(localChatRuntimeProvider)!
                      .projection
                      .data
                      .turns
                      .single
                      .undoneAt !=
                  null,
        );
        await close();
        await open();
        await selectHistory();
        expect(container!.read(todoListProvider), isEmpty);
        expect(find.text('已撤销本次修改'), findsOneWidget);
        expect(model.calls, 3);
        final workspace = SqliteWorkspaceCommandStore(db!);
        await workspace.execute(
          WorkspaceCommand(
            operationId: 'seed-target',
            actions: [
              WorkspaceMutation(
                actionId: 'seed',
                kind: WorkspaceEntityKind.todo,
                entityId: 'manual-target',
                mutation: WorkspaceMutationKind.create,
                patch: {'title': '原有任务'},
              ),
            ],
          ),
        );
        final nextInput = find.byKey(const ValueKey('chat-text-input'));
        await tester.tap(nextInput);
        await tester.pumpAndSettle();
        await tester.enterText(nextInput, '刷新差异测试');
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await until(
          () =>
              latest().status == AgentRunStatus.awaitingConfirmation &&
              !container!.read(chatViewModelProvider).isGenerating,
        );
        // Simulate a concurrent manual edit through the real command boundary.
        await workspace.execute(
          WorkspaceCommand(
            operationId: 'manual-note',
            actions: [
              WorkspaceMutation(
                actionId: 'note',
                kind: WorkspaceEntityKind.todo,
                entityId: 'manual-target',
                mutation: WorkspaceMutationKind.update,
                expectedVersion: 1,
                patch: {'note': '人工新增备注'},
              ),
            ],
          ),
        );
        await tapText('全部接受');
        await until(
          () =>
              latest().status == AgentRunStatus.failed &&
              !container!.read(chatViewModelProvider).isGenerating,
        );
        expect(latest().receipts, isEmpty);
        await tapText('刷新差异');
        await until(
          () => latest().status == AgentRunStatus.awaitingConfirmation,
        );
        expect(model.calls, 4);
        expect((await workspace.load()).todos.single.data['title'], '原有任务');
        await tapText('全部接受');
        await until(
          () =>
              latest().status == AgentRunStatus.succeeded &&
              !container!.read(chatViewModelProvider).isGenerating,
        );
        expect((await workspace.load()).todos.single.data['title'], '意图标题');
        expect((await workspace.load()).todos.single.data['note'], '人工新增备注');
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
        expect((await workspace.load()).todos.single.data['title'], '原有任务');
        expect((await workspace.load()).todos.single.data['note'], '人工新增备注');
        expect(model.calls, 5);
      } finally {
        await close();
        await folder.delete(recursive: true);
      }
    },
  );
}
