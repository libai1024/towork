import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/agent_runner.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/agent_tool_executor.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/chat_persistence.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/models/chat.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

class _Model implements ModelGateway {
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    if (request.messages.last['role'] == 'user') {
      yield ModelCompleted(
        assistantMessage: {
          'role': 'assistant',
          'tool_calls': [
            {
              'id': 'display',
              'type': 'function',
              'function': {
                'name': 'show_todo_list',
                'arguments': jsonEncode({'title': '紧急待办', 'scope': 'urgent'}),
              },
            },
          ],
        },
        finishReason: 'tool_calls',
      );
    } else {
      yield ModelCompleted(
        assistantMessage: {'role': 'assistant', 'content': '可以直接勾选。'},
        finishReason: 'stop',
      );
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'display executes under askAll without a write, persists and reopens',
    () async {
      final dir = await Directory.systemTemp.createTemp('todo-panel-agent');
      var db = AppDatabase.background(File('${dir.path}/test.sqlite'));
      try {
        final commands = SqliteWorkspaceCommandStore(db);
        await commands.execute(
          WorkspaceCommand(
            operationId: 'seed',
            actions: [
              WorkspaceMutation(
                actionId: 'one',
                kind: WorkspaceEntityKind.todo,
                entityId: 'urgent',
                mutation: WorkspaceMutationKind.create,
                patch: {'title': '提交项目方案', 'priority': 'urgent'},
              ),
            ],
          ),
        );
        final prefs = SqliteAppPreferencesStore(db);
        final before = await prefs.loadOrCreate();
        await prefs.update({
          'permission': 'askAll',
        }, expectedVersion: before.version);
        final persistence = ChatPersistence(db);
        final turn = await persistence.prepare(
          inputId: 'ask',
          content: '列出紧急待办',
          profile: ModelProfile(model: 'fixture'),
          agentEnabled: true,
        );
        final runner = AgentRunner(
          gateway: _Model(),
          store: SqliteAgentRunStore(db),
          tools: SqliteAgentToolExecutor(db),
        );
        final result = await runner.resume(
          turn.run.id,
          apiKey: 'synthetic-panel-key',
        );
        expect(result.status, AgentRunStatus.succeeded);
        expect(result.receipts, isEmpty);
        expect(await db.select(db.workspaceOperations).get(), hasLength(1));
        expect((await commands.load()).entities, hasLength(1));
        final projected = (await persistence.load()).turns.single.messages;
        expect(
          projected
              .where((m) => m.type == ChatMessageType.todoPanel)
              .single
              .todoPanel!
              .title,
          '紧急待办',
        );
        await db.close();
        db = AppDatabase.background(File('${dir.path}/test.sqlite'));
        final reopened = (await ChatPersistence(
          db,
        ).load()).turns.single.messages;
        final panel = reopened
            .singleWhere((m) => m.type == ChatMessageType.todoPanel)
            .todoPanel!;
        expect(panel.sections.single.todoIds, ['urgent']);
        expect(
          (await SqliteWorkspaceCommandStore(
            db,
          ).load()).todos.single.data['status'],
          'pending',
        );
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
