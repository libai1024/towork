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
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/chat_persistence.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/context_window.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/app/chat/chat_view_model.dart';
import 'package:towork/main.dart';

import '../test/support/free/fake_model_gateway.dart';
import '../test/support/free/scripted_todo_model.dart';

class _InspectModel extends ScriptedTodoModel {
  final requests = <ModelRequest>[];
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) {
    requests.add(request);
    return super.stream(request, apiKey: apiKey, cancellation: cancellation);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'long history rolls over in real chat UI without losing approval, effects or saved history',
    (tester) async {
      final support = await getApplicationSupportDirectory();
      final directory = await Directory(
        '${support.path}/context-ui-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${directory.path}/chat.sqlite');
      final vault = FakeKeyVault();
      final model = _InspectModel();
      AppDatabase? db;
      ProviderContainer? container;
      String? oldRunId;
      Future<void> until(bool Function() condition) async {
        final watch = Stopwatch()..start();
        while (!condition() && watch.elapsed < const Duration(seconds: 15)) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(condition(), isTrue);
        await tester.pumpAndSettle();
      }

      AgentRun latest() => container!
          .read(localChatRuntimeProvider)!
          .projection
          .data
          .turns
          .last
          .run;
      Future<void> open({bool initial = false}) async {
        final current = AppDatabase.background(file);
        db = current;
        final settings = ModelSettingsService(current, vault, model);
        if (initial) {
          final config = await settings.save(
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
          // Seed an old complete provider exchange. Long reasoning stays protocol
          // data; it is deliberately not rendered as visible chat text.
          final turn = await ChatPersistence(current).prepare(
            inputId: 'old-input',
            content: '保留的旧对话',
            profile: config.configuration.profile,
            agentEnabled: true,
          );
          final runs = SqliteAgentRunStore(current);
          final running = await runs.save(
            turn.run.next(AgentRunStatus.generating, round: 1),
            expectedRevision: turn.run.revision,
          );
          final done = await runs.save(
            running.next(
              AgentRunStatus.succeeded,
              history: [
                ...running.history,
                {
                  'role': 'assistant',
                  'content': '旧回复仍可查看',
                  'reasoning_content': 'private-history-' * 8000,
                },
              ],
            ),
            expectedRevision: running.revision,
          );
          oldRunId = done.id;
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
        final menu = find.byTooltip('打开菜单');
        if (menu.evaluate().isNotEmpty) {
          await tester.tap(menu);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('保留的旧对话').first);
        await tester.pumpAndSettle();
      }

      Future<void> close() async {
        await tester.pumpWidget(const SizedBox());
        container?.dispose();
        container = null;
        await db?.close();
        db = null;
      }

      try {
        await open(initial: true);
        final input = find.byKey(const ValueKey('chat-text-input'));
        await tester.tap(input);
        await tester.enterText(input, '创建测试任务');
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await until(
          () =>
              !container!.read(chatViewModelProvider).isGenerating &&
              latest().status == AgentRunStatus.awaitingConfirmation,
        );
        expect(latest().historyOmittedTurns, 1);
        expect(container!.read(todoListProvider), isEmpty);
        final button = find.text('全部接受').last;
        await tester.ensureVisible(button);
        await tester.tap(button);
        await until(
          () =>
              latest().status == AgentRunStatus.succeeded &&
              container!.read(todoListProvider).length == 1,
        );
        final notice = find.textContaining('本次未带入较早的 1 轮对话');
        await tester.ensureVisible(notice.last);
        expect(notice, findsOneWidget);
        expect(model.requests, hasLength(2));
        for (final request in model.requests) {
          expect(request.messages, contains(equals(ContextWindow.notice)));
          expect(
            request.messages.any(
              (m) => '${m['reasoning_content']}'.contains('private-history-'),
            ),
            isFalse,
          );
        }
        expect(latest().receipts, hasLength(1));
        await close();
        await open();
        final runtime = container!.read(localChatRuntimeProvider)!;
        expect(runtime.projection.data.turns, hasLength(2));
        expect(latest().contextOmittedTurns, 1);
        expect(latest().receipts, hasLength(1));
        expect(container!.read(todoListProvider).single.title, '测试任务');
        final old = await runtime.runs.read(oldRunId!);
        expect(
          old.history.last['reasoning_content'],
          'private-history-' * 8000,
        );
        final oldText = find.text('旧回复仍可查看');
        // Render the old visible bubble through normal list scrolling when needed.
        if (oldText.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            oldText,
            -300,
            scrollable: find
                .descendant(
                  of: find.byKey(const ValueKey('chat-message-list')),
                  matching: find.byType(Scrollable),
                )
                .first,
            maxScrolls: 20,
          );
        }
        expect(oldText, findsOneWidget);
        expect(find.textContaining('private-history-'), findsNothing);
      } finally {
        await close();
        await directory.delete(recursive: true);
      }
    },
  );
}
