import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/chat/chat_view_model.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/repositories/todo_repository.dart';
import 'package:towork/data/services/mock_chat_service.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/chat/local_chat.dart';
import 'package:towork/domain/chat/todo_panel.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/features/chat/widgets/chat_messages.dart';
import 'package:towork/features/chat/widgets/chat_thread.dart';
import 'package:towork/features/chat/widgets/ai_todo_panel.dart';
import 'package:towork/theme/app_theme.dart';

import '../../support/free/fake_model_gateway.dart';

class _Generation extends ChatViewModel {
  _Generation(ChatStore chats, TodoStore todos)
    : super(
        chats: chats,
        todos: todos,
        gateway: MockChatService(),
        currentSession: () => 'session',
        selectSession: (_) {},
      );
  final undone = <String>[];
  void publish(ChatGenerationState value) => state = value;
  @override
  Future<void> undoRun(String id) async => undone.add(id);
}

void main() {
  late AppDatabase db;
  late LocalChatRuntime runtime;
  late TodoRepository todos;
  late _Generation generation;
  late ProviderContainer container;
  late ScrollController scroll;
  final now = DateTime(2026, 11, 17);

  LocalChatTurn turn(AgentRun run, {DateTime? undoneAt, int position = 0}) =>
      LocalChatTurn(
        inputId: 'input-${run.id}',
        sessionId: 'session',
        content: '整理一下',
        position: position,
        historyStart: 0,
        createdAt: now,
        agentEnabled: true,
        run: run,
        undoneAt: undoneAt,
        createdTodoIds: run.receipts.isEmpty ? [] : ['todo-1', 'todo-2'],
      );

  AgentRun run({
    AgentRunStatus status = AgentRunStatus.succeeded,
    bool writes = true,
    String id = 'run',
    int panelCount = 0,
  }) => AgentRun(
    id: id,
    sessionId: 'session',
    inputId: 'input-$id',
    profile: ModelProfile(model: 'fixture', product: ProviderKind.moonshot),
    history: [
      {'role': 'user', 'content': '整理一下'},
      {'role': 'assistant', 'content': '先整理资料。'},
      {'role': 'tool', 'content': '{}', 'tool_call_id': 'query'},
      for (var i = 0; i < panelCount; i++) ...[
        {
          'role': 'assistant',
          'tool_calls': [
            {
              'id': 'panel-$i',
              'type': 'function',
              'function': {'name': 'show_todo_list', 'arguments': '{}'},
            },
          ],
        },
        {
          'role': 'tool',
          'tool_call_id': 'panel-$i',
          'content': jsonEncode({
            'ui': TodoPanel(
              title: '清单 $i',
              asOfLocal: '2026-11-17T09:00+08:00',
              overview: false,
              sections: [
                TodoPanelSection(
                  title: '清单 $i',
                  todoIds: ['todo-${i + 1}'],
                  matchedCount: 1,
                ),
              ],
            ).toJson(),
          }),
        },
      ],
      {'role': 'assistant', 'content': '两件事都已记下。'},
    ],
    status: status,
    receipts: writes ? ['op-1'] : [],
    failureCode: status == AgentRunStatus.failed ? 'model_network' : null,
  );

  void project(List<LocalChatTurn> turns) => runtime.projection.accept(
    LocalChatSnapshot([
      LocalConversation(
        id: 'session',
        title: '测试会话',
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ], turns),
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final settings = ModelSettingsService(
      db,
      FakeKeyVault(),
      FakeKimiGateway(),
    );
    runtime = LocalChatRuntime(
      db,
      settings,
      LocalChatSnapshot([], []),
      await db.readConfiguration(),
    );
    todos = TodoRepository(
      initial: [
        for (var i = 1; i <= 2; i++)
          Todo(id: 'todo-$i', title: '项目事项 $i', createdAt: now),
      ],
    );
    generation = _Generation(runtime.projection, todos);
    container = ProviderContainer(
      overrides: [
        localChatRuntimeProvider.overrideWith((ref) => runtime),
        todoListProvider.overrideWith((ref) => todos),
        chatViewModelProvider.overrideWith((ref) => generation),
      ],
    );
    scroll = ScrollController();
  });
  tearDown(() async {
    AppToast.dismiss();
    container.dispose();
    scroll.dispose();
    await runtime.dispose();
    await db.close();
  });

  Future<void> mount(
    WidgetTester tester, {
    bool dark = false,
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: ChatThread(sessionId: 'session', controller: scroll),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 16));
  }

  testWidgets('multiple interactive panels share one terminal action row', (
    tester,
  ) async {
    project([turn(run(writes: false, panelCount: 2))]);
    await mount(tester);
    expect(find.byType(AiTodoPanel), findsNWidgets(2));
    expect(find.byTooltip('复制回复'), findsOneWidget);
    expect(find.byTooltip('撤销本次全部修改'), findsNothing);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('display panels replace overlapping receipt cards in one run', (
    tester,
  ) async {
    project([turn(run(panelCount: 1))]);
    await mount(tester);
    expect(find.byType(AiTodoPanel), findsOneWidget);
    expect(find.byType(AiTodoCard), findsOneWidget);
    expect(find.text('项目事项 1'), findsOneWidget);
    expect(find.text('项目事项 2'), findsOneWidget);
    expect(find.byTooltip('复制回复'), findsOneWidget);
    expect(find.byTooltip('撤销本次全部修改'), findsOneWidget);
    await unmount(tester);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'multi-round reply has one copy and undo after all cards, dark=$dark',
      (tester) async {
        project([turn(run())]);
        final clipboard = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard.add((call.arguments as Map)['text'] as String);
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await mount(tester, dark: dark);
        expect(find.byType(AiTextMessage), findsNWidgets(2));
        expect(find.byType(AiTodoCard), findsNWidgets(2));
        final copy = find.byTooltip('复制回复');
        final undo = find.byTooltip('撤销本次全部修改');
        expect(copy, findsOneWidget);
        expect(undo, findsOneWidget);
        expect(find.text('撤销'), findsNothing);
        expect(find.text('已提交 1 批操作'), findsNothing);
        expect(
          tester.getTopLeft(copy).dy,
          greaterThan(tester.getBottomLeft(find.byType(AiTodoCard).last).dy),
        );
        expect(tester.getSize(copy), const Size(48, 48));
        await tester.tap(copy);
        await tester.pumpAndSettle();
        expect(clipboard, ['先整理资料。\n\n两件事都已记下。']);
        await tester.tap(undo);
        await tester.pumpAndSettle();
        expect(generation.undone, ['run']);
        expect(tester.takeException(), isNull);
        await unmount(tester);
      },
    );
  }

  testWidgets(
    'streaming hides footer until persisted, historical reply remains independent',
    (tester) async {
      final current = run(status: AgentRunStatus.generating, writes: false);
      project([
        turn(run(id: 'history', writes: false)),
        turn(current, position: 1),
      ]);
      generation.publish(
        const ChatGenerationState(
          isGenerating: true,
          sessionId: 'session',
          runId: 'run',
          messageId: 'stream_run',
          streamingText: '正在继续整理',
        ),
      );
      await mount(tester);
      expect(find.byTooltip('复制回复'), findsOneWidget, reason: '历史轮仍可复制');
      expect(find.text('正在继续整理', findRichText: true), findsOneWidget);
      project([turn(current.next(AgentRunStatus.succeeded), position: 1)]);
      await tester.pumpAndSettle();
      expect(find.text('正在继续整理', findRichText: true), findsNothing);
      generation.publish(const ChatGenerationState());
      await tester.pumpAndSettle();
      expect(find.byTooltip('复制回复'), findsNWidgets(2), reason: '每轮一个');
      expect(find.text('回复已保存'), findsNothing);
      await unmount(tester);
    },
  );

  for (final status in [
    AgentRunStatus.cancelled,
    AgentRunStatus.failed,
    AgentRunStatus.interrupted,
  ]) {
    testWidgets('$status retains recovery and one footer', (tester) async {
      project([turn(run(status: status))]);
      await mount(tester, scale: 1.5);
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.byTooltip('复制回复'), findsOneWidget);
      if (status == AgentRunStatus.failed) {
        expect(find.text('重试'), findsOneWidget);
      }
      if (status == AgentRunStatus.interrupted) {
        expect(find.text('继续处理'), findsOneWidget);
      }
      if (status == AgentRunStatus.cancelled) {
        expect(find.text('已停止本次请求'), findsOneWidget);
        final undo = find.byTooltip('撤销本次全部修改');
        expect(undo, findsOneWidget);
        await tester.tap(undo);
        await tester.pumpAndSettle();
        expect(generation.undone, ['run']);
      }
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets(
    'another engine generating keeps processing feedback without actions',
    (tester) async {
      project([turn(run(status: AgentRunStatus.generating))]);
      await mount(tester);
      expect(find.text('正在处理'), findsOneWidget);
      expect(find.byTooltip('复制回复'), findsNothing);
      expect(find.byTooltip('撤销本次全部修改'), findsNothing);
      expect(find.byType(AiTodoCard), findsNWidgets(2));
      await unmount(tester);
    },
  );

  testWidgets('undo removes result cards and keeps one readable footer', (
    tester,
  ) async {
    project([turn(run(), undoneAt: now)]);
    await mount(tester);
    expect(find.byType(AiTodoCard), findsNothing);
    expect(find.byTooltip('复制回复'), findsOneWidget);
    expect(find.byTooltip('撤销本次全部修改'), findsNothing);
    expect(find.text('已撤销本次修改'), findsOneWidget);
    await unmount(tester);
  });
}
