import 'dart:convert';
import 'dart:io';

import 'package:towork/agent/agent_runner.dart';
import 'package:towork/app/model_transmission.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/agent_tool_executor.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';

/// Manual opt-in smoke only. Synthetic data, disposable DB, no background jobs.
Future<void> main(List<String> arguments) async {
  if (!arguments.contains('--allow-paid-request')) {
    stderr.writeln(
      'Use --allow-paid-request for up to 3 model calls on synthetic data.',
    );
    exitCode = 64;
    return;
  }
  final env = <String, String>{...Platform.environment};
  final file = File('.env');
  if (await file.exists()) {
    for (final line in await file.readAsLines()) {
      if (line.startsWith('#')) continue;
      final separator = line.indexOf('=');
      if (separator > 0) {
        env.putIfAbsent(
          line.substring(0, separator).trim(),
          () => line.substring(separator + 1).trim(),
        );
      }
    }
  }
  final key = env['KIMI_API_KEY'];
  if (key == null || key.trim().isEmpty) {
    stderr.writeln('KIMI_API_KEY is missing.');
    exitCode = 64;
    return;
  }
  final code = arguments.contains('--kimi-code');
  final profile = ModelProfile(
    product: code ? ProviderKind.kimiCode : ProviderKind.moonshot,
    model: code
        ? env['KIMI_CODE_MODEL'] ?? 'kimi-for-coding'
        : env['KIMI_MODEL_DEFAULT'] ?? 'kimi-k2.6',
    disableThinking: true,
  );
  final directory = await Directory.systemTemp.createTemp('towork-agent-smoke');
  final dbFile = File('${directory.path}/probe.sqlite');
  var db = AppDatabase.background(dbFile);
  final gateway = createPlatformModelGateway();
  final watch = Stopwatch()..start();
  try {
    final prefs = SqliteAppPreferencesStore(db);
    final initial = await prefs.loadOrCreate();
    await prefs.update({
      'permission': 'askAll',
    }, expectedVersion: initial.version);
    AgentRunner runner() => AgentRunner(
      gateway: gateway,
      store: SqliteAgentRunStore(db),
      tools: SqliteAgentToolExecutor(db),
      maxRounds: 3,
      maxTokens: 2048,
    );
    final waiting = await runner().start(
      AgentRun(
        id: 'smoke-run',
        sessionId: 'smoke-session',
        inputId: 'smoke-input',
        profile: profile,
        history: const [
          {
            'role': 'system',
            'content': 'This is a synthetic integration test in a disposable database. Use the todo_create tool exactly once as requested. After receiving the tool result, reply briefly without further tool calls. Never claim a write succeeded before receiving a receipt.',
          },
          {
            'role': 'user',
            'content': '请调用 todo_create 创建一条标题恰好为“工具闭环测试”的待办，只填写 title。',
          },
        ],
      ),
      apiKey: key,
    );
    if (waiting.status != AgentRunStatus.awaitingConfirmation ||
        (await SqliteWorkspaceCommandStore(db).load()).todos.isNotEmpty) {
      throw StateError('proposal_gate');
    }
    final calls = waiting.proposal!['calls']! as List;
    if (calls.length != 1 || (calls.single as Map)['name'] != 'todo_create') {
      throw StateError('unexpected_action');
    }
    // Approve only the exact synthetic request, never an arbitrary model proposal.
    final preview = (calls.single as Map)['after'] as Map;
    if (preview['title'] != '工具闭环测试') throw StateError('unexpected_title');
    final result = await runner().resume(
      waiting.id,
      apiKey: key,
      approval: AgentApproval(
        runRevision: waiting.revision,
        proposalId: waiting.proposal!['id']! as String,
        digest: waiting.proposal!['digest']! as String,
      ),
    );
    if (result.status != AgentRunStatus.succeeded ||
        result.receipts.length != 1) {
      throw StateError('completion_gate');
    }
    await db.close();
    db = AppDatabase.background(dbFile);
    final saved = await SqliteAgentRunStore(db).read(result.id);
    final todos = (await SqliteWorkspaceCommandStore(db).load()).todos.toList();
    if (saved.status != AgentRunStatus.succeeded ||
        todos.length != 1 ||
        todos.single.data['title'] != '工具闭环测试') {
      throw StateError('reopen_gate');
    }
    stdout.writeln(
      jsonEncode({
        'status': 'passed',
        'product': profile.product.name,
        'model': profile.model,
        'rounds': saved.round,
        'receipt_count': saved.receipts.length,
        'reopened': true,
        'elapsed_ms': watch.elapsedMilliseconds,
        'usage': saved.usage,
      }),
    );
  } catch (error) {
    stderr.writeln(
      jsonEncode({
        'status': 'failed',
        'error_type': error.runtimeType.toString(),
        if (error is ModelFailure) 'code': error.code.name,
        if (error is AgentFailure) 'code': error.code.name,
      }),
    );
    exitCode = 1;
  } finally {
    gateway.close();
    await db.close();
    await directory.delete(recursive: true);
  }
}
