import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/agent/agent_runner.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/agent_tool_executor.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';

class _NativeModel implements ModelGateway {
  int count = 0;
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    count++;
    if (request.messages.last['role'] == 'user') {
      yield ModelCompleted(
        assistantMessage: {
          'role': 'assistant',
          'content': null,
          'tool_calls': [
            {
              'id': 'native-call',
              'type': 'function',
              'function': {
                'name': 'todo_create',
                'arguments': jsonEncode({'title': '原生 Agent 待办'}),
              },
            },
          ],
        },
        finishReason: 'tool_calls',
      );
    } else {
      expect(request.messages.last['role'], 'tool');
      expect(request.messages.last['tool_call_id'], 'native-call');
      yield ModelCompleted(
        assistantMessage: {'role': 'assistant', 'content': '已创建'},
        finishReason: 'stop',
      );
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native Agent confirmation, atomic receipt and reopened history', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Text('ToWork Agent 原生事务验证')),
      ),
    );
    await tester.runAsync(() async {
      final support = await getApplicationSupportDirectory();
      final directory = await Directory(
        '${support.path}/agent-fixture-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${directory.path}/agent.sqlite');
      var db = AppDatabase.background(file);
      try {
        final prefs = SqliteAppPreferencesStore(db);
        final first = await prefs.loadOrCreate();
        await prefs.update({
          'permission': 'askAll',
        }, expectedVersion: first.version);
        final model = _NativeModel();
        AgentRunner runner() => AgentRunner(
          gateway: model,
          store: SqliteAgentRunStore(db),
          tools: SqliteAgentToolExecutor(db),
        );
        final initial = AgentRun(
          id: 'native-run',
          sessionId: 'native-session',
          inputId: 'native-input',
          profile: ModelProfile(model: 'fixture-only'),
          history: const [
            {'role': 'user', 'content': '记录一条待办'},
          ],
        );
        final waiting = await runner().start(
          initial,
          apiKey: 'synthetic-native-key',
        );
        expect(waiting.status, AgentRunStatus.awaitingConfirmation);
        expect((await SqliteWorkspaceCommandStore(db).load()).todos, isEmpty);
        await db.close();
        db = AppDatabase.background(file);
        final restored = await SqliteAgentRunStore(db).read(waiting.id);
        final completed = await runner().resume(
          restored.id,
          apiKey: 'synthetic-native-key',
          approval: AgentApproval(
            runRevision: restored.revision,
            proposalId: restored.proposal!['id']! as String,
            digest: restored.proposal!['digest']! as String,
          ),
        );
        expect(completed.status, AgentRunStatus.succeeded);
        expect(completed.receipts, hasLength(1));
        expect(model.count, 2);
        await db.close();
        db = AppDatabase.background(file);
        expect(
          (await SqliteAgentRunStore(db).read(completed.id)).toJson(),
          completed.toJson(),
        );
        expect(
          (await SqliteWorkspaceCommandStore(
            db,
          ).load()).todos.single.data['title'],
          '原生 Agent 待办',
        );
        await runner().start(initial, apiKey: 'synthetic-native-key');
        expect(model.count, 2);
        expect(await db.select(db.workspaceOperations).get(), hasLength(1));
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    });
  });
}
