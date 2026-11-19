import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/assist_provider.dart';
import 'package:towork/app/chat/chat_view_model.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/core/agent/agent_table_preview.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/assist/quick_assist.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/features/chat/widgets/ai_todo_panel.dart';
import 'package:towork/features/chat/widgets/ai_todo_panel_item.dart';
import 'package:towork/features/chat/widgets/ai_todo_pagination.dart';
import 'package:towork/main.dart';
import 'package:towork/shell/quick_assist_app.dart';

import '../test/support/free/fake_model_gateway.dart';
import 'support/interactive_ui_gateway.dart';

import 'package:towork/features/chat/widgets/ai_question_card.dart';

/// Real Agent tools, SQLite, UI commands and conversation projection. Only the
/// model service, credential vault and assist host use synthetic substitutes.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'interactive lists and overview complete, undo, edit and reopen',
    (tester) async {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (!Platform.isAndroid) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1280, 900);
        await binding.setSurfaceSize(const Size(1280, 900));
      }
      final support = await getApplicationSupportDirectory();
      final directory = await Directory(
        '${support.path}/panel-review-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final database = AppDatabase.background(
        File('${directory.path}/review.sqlite'),
      );
      final profile = await database.loadOrCreateProfile();
      await database.renameProfile('小林', expectedVersion: profile.version);
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      final seeds = [
        (
          '确认新版首页的交互细节',
          day.add(const Duration(hours: 15)),
          'urgent',
          'pending',
        ),
        ('整理周会纪要', day.add(const Duration(hours: 16)), 'none', 'pending'),
        ('把更新说明发给项目组', day.add(const Duration(hours: 18)), 'high', 'pending'),
        (
          '核对待交付附件',
          day.subtract(const Duration(hours: 7)),
          'urgent',
          'pending',
        ),
        (
          '完善语音输入的异常提示',
          day.add(const Duration(days: 1, hours: 11)),
          'none',
          'inProgress',
        ),
        ('整理下一轮界面需求', null, 'none', 'pending'),
        for (var i = 6; i < 120; i++)
          (
            i % 10 == 0 ? '检查长标题与大字号的换行表现，并同步相关截图和待确认问题 $i' : '核对项目进展与交付事项 $i',
            day.add(Duration(hours: 17, minutes: i % 60)),
            'none',
            'pending',
          ),
      ];
      await SqliteWorkspaceCommandStore(database).execute(
        WorkspaceCommand(
          operationId: 'panel-seed',
          actions: [
            for (var i = 0; i < seeds.length; i++)
              WorkspaceMutation(
                actionId: 'seed-$i',
                kind: WorkspaceEntityKind.todo,
                entityId: 'panel-todo-$i',
                mutation: WorkspaceMutationKind.create,
                patch: {
                  'title': seeds[i].$1,
                  'due_at': seeds[i].$2?.toUtc().toIso8601String(),
                  'priority': seeds[i].$3,
                  'status': seeds[i].$4,
                },
              ),
          ],
        ),
      );
      final prefs = SqliteAppPreferencesStore(database);
      final original = await prefs.loadOrCreate();
      await prefs.update({
        'permission': 'askAll',
      }, expectedVersion: original.version);
      final settings = ModelSettingsService(
        database,
        FakeKeyVault(),
        InteractiveUiGateway(),
      );
      await settings.save(
        profile: ModelProfile(product: ProviderKind.moonshot, model: 'kimi-k3'),
        newKey: 'synthetic-panel-key',
        expectedVersion: (await database.readConfiguration()).version,
      );
      final container = ProviderContainer(
        overrides: [
          localDatabaseProvider.overrideWith((ref) async => database),
          modelSettingsServiceProvider.overrideWith((ref) async => settings),
          assistHostProvider.overrideWithValue(_Host()),
        ],
      );
      final root = GlobalKey();
      final bootstrap = GlobalKey();
      final shots = <String, String>{};
      binding.reportData = {'screenshots': shots};
      Future<void> mount(Widget child) => tester.pumpWidget(
        RepaintBoundary(
          key: root,
          child: UncontrolledProviderScope(
            container: container,
            child: FreeWorkspaceBootstrap(key: bootstrap, child: child),
          ),
        ),
      );
      await mount(const ToWorkApp());
      Future<void> until(bool Function() ready, {bool settle = true}) async {
        for (var i = 0; i < 300 && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(ready(), isTrue);
        if (settle) await tester.pumpAndSettle();
      }

      await until(() => container.read(localChatRuntimeProvider) != null);
      final runtime = container.read(localChatRuntimeProvider)!;
      Future<void> capture(String name) async {
        AppToast.dismiss();
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
        final boundary =
            root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        shots['${Platform.isAndroid ? 'android' : 'macos'}-$name'] =
            base64Encode(bytes!.buffer.asUint8List());
        image.dispose();
        expect(tester.takeException(), isNull, reason: name);
        debugPrint('TOWORK_CAPTURE_READY $name');
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      Future<void> top() async {
        final list = find.byKey(const ValueKey('chat-message-list'));
        await tester.drag(list, const Offset(0, 500));
        await tester.pumpAndSettle();
        final scroll = tester.state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)).first,
        );
        scroll.position.jumpTo(0);
        await tester.pumpAndSettle();
      }

      Future<String> send(String text, {Type resultType = AiTodoPanel}) async {
        container.read(currentSessionIdProvider.notifier).state = null;
        await tester.pumpAndSettle();
        final keyboard = find.byKey(const ValueKey('switch-to-keyboard'));
        if (keyboard.evaluate().isNotEmpty) {
          await tester.tap(keyboard);
          await tester.pumpAndSettle();
        }
        await tester.enterText(
          find.byKey(const ValueKey('chat-text-input')),
          text,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('发送消息'));
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        await until(() => !container.read(chatViewModelProvider).isGenerating);
        await until(() => find.byType(resultType).evaluate().isNotEmpty);
        if (resultType != AgentTablePreview) {
          expect(find.text('全部接受'), findsNothing);
        }
        await top();
        return container.read(currentSessionIdProvider)!;
      }

      container.read(themeModeProvider.notifier).state = ThemeMode.light;
      final listSession = await send('给我今日待办');
      expect(find.text('今日待办'), findsOneWidget);
      expect(find.byTooltip('复制回复'), findsOneWidget);
      expect(find.byType(AiTodoPanelItem), findsNWidgets(5));
      void expectTightFooter() {
        final footer = tester.getRect(find.byType(AiTodoPagination));
        final last = tester.getRect(find.byType(AiTodoPanelItem).last);
        final card = tester.getRect(
          find.byKey(const ValueKey('ai-todo-panel')),
        );
        expect(footer.top, closeTo(last.bottom, .01));
        expect(card.bottom - footer.bottom, closeTo(2.5, .01));
        expect(footer.height, 36);
      }

      expectTightFooter();
      await capture('panel-list-light');
      await tester.ensureVisible(find.bySemanticsLabel('下一页'));
      await tester.tap(find.bySemanticsLabel('下一页'));
      await tester.pumpAndSettle();
      expect(find.byType(AiTodoPanelItem), findsNWidgets(5));
      expectTightFooter();
      await top();
      await capture('panel-page-two');
      await tester.ensureVisible(find.bySemanticsLabel('上一页'));
      await tester.tap(find.bySemanticsLabel('上一页'));
      await tester.pumpAndSettle();
      await top();
      await tester.tap(find.bySemanticsLabel('完成待办：确认新版首页的交互细节'));
      await until(
        () =>
            container
                .read(todoListProvider)
                .firstWhere((t) => t.id == 'panel-todo-0')
                .status ==
            TodoStatus.done,
      );
      await tester.tap(find.byKey(const ValueKey('toast-action')));
      await until(
        () =>
            container
                .read(todoListProvider)
                .firstWhere((t) => t.id == 'panel-todo-0')
                .status ==
            TodoStatus.pending,
      );
      await tester.tap(find.bySemanticsLabel('完成待办：确认新版首页的交互细节'));
      await until(
        () =>
            container
                .read(todoListProvider)
                .firstWhere((t) => t.id == 'panel-todo-0')
                .status ==
            TodoStatus.done,
      );
      await capture('panel-completed');
      await tester.tap(find.bySemanticsLabel('恢复待办：确认新版首页的交互细节'));
      await until(
        () =>
            container
                .read(todoListProvider)
                .firstWhere((t) => t.id == 'panel-todo-0')
                .status ==
            TodoStatus.pending,
      );
      AppToast.dismiss();
      await tester.tap(find.text('确认新版首页的交互细节'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '确认首页与快问的交互细节');
      await tester.tap(find.text('保存').last);
      await until(
        () => container
            .read(todoListProvider)
            .any((t) => t.title == '确认首页与快问的交互细节'),
      );
      await capture('panel-edited');
      container.read(themeModeProvider.notifier).state = ThemeMode.dark;
      await capture('panel-list-dark');
      container.read(themeModeProvider.notifier).state = ThemeMode.light;
      final overviewSession = await send('给我工作总览');
      final overviewHeight = tester
          .getSize(find.byKey(const ValueKey('ai-todo-panel')))
          .height;
      await capture('panel-overview');
      await tester.tap(find.text('紧急待办 2'));
      await tester.pumpAndSettle();
      expect(find.text('核对待交付附件'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('ai-todo-panel'))).height,
        overviewHeight,
      );
      await capture('panel-overview-urgent');
      container.read(themeModeProvider.notifier).state = ThemeMode.dark;
      await capture('panel-overview-dark');
      container.read(fontScaleProvider.notifier).state = 1.6;
      await tester.pumpAndSettle();
      await top();
      await capture('panel-overview-large-type');
      await tester.ensureVisible(find.byType(AiTodoPagination));
      await capture('panel-overview-large-type-footer');
      container.read(fontScaleProvider.notifier).state = 1;
      container.read(themeModeProvider.notifier).state = ThemeMode.light;
      await send('显示空清单');
      expect(find.text('这个范围暂时没有待办'), findsOneWidget);
      await capture('panel-empty');
      await runtime.refresh();
      container.read(currentSessionIdProvider.notifier).state = listSession;
      await tester.pumpAndSettle();
      await top();
      expect(find.text('确认首页与快问的交互细节'), findsOneWidget);
      await capture('panel-reopened');
      final questionSession = await send('今天帮我代班。', resultType: AiQuestionCard);
      await capture('question-single');
      await tester.tap(find.text('处理今天截止的两件待办'));
      await until(() => !container.read(chatViewModelProvider).isGenerating);
      expect(find.text('已回答'), findsOneWidget);
      await capture('question-answered');
      await runtime.refresh();
      container.read(currentSessionIdProvider.notifier).state = questionSession;
      await tester.pumpAndSettle();
      expect(find.text('已回答'), findsOneWidget);
      await send('选择多个范围', resultType: AiQuestionCard);
      await tester.tap(find.text('今日待办'));
      await tester.tap(find.text('紧急待办'));
      await tester.pumpAndSettle();
      expect(container.read(chatViewModelProvider).isGenerating, isFalse);
      await capture('question-multiple');
      container.read(themeModeProvider.notifier).state = ThemeMode.dark;
      container.read(fontScaleProvider.notifier).state = 1.6;
      await capture('question-large-type-dark');
      container.read(fontScaleProvider.notifier).state = 1;
      container.read(themeModeProvider.notifier).state = ThemeMode.light;
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('补充回答'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('question-custom-answer')),
        '先排上午',
      );
      await tester.pumpAndSettle();
      await capture('question-custom');
      await tester.ensureVisible(find.byKey(const ValueKey('question-submit')));
      await tester.tap(find.byKey(const ValueKey('question-submit')));
      await until(() => !container.read(chatViewModelProvider).isGenerating);
      final answered = (await runtime.persistence.load()).turns
          .where(
            (turn) =>
                turn.sessionId == container.read(currentSessionIdProvider),
          )
          .last;
      expect(answered.content, contains('- 今日待办\n- 紧急待办\n先排上午'));
      await container
          .read(chatViewModelProvider.notifier)
          .sendPersisted('请给我长回复', model: 'fixture');
      await until(
        () => container
            .read(chatViewModelProvider)
            .streamingText
            .contains('要点 12'),
        settle: false,
      );
      final messageList = find.byKey(const ValueKey('chat-message-list'));
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(of: messageList, matching: find.byType(Scrollable))
                .first,
          )
          .position;
      await tester.pump();
      expect(position.extentAfter, lessThan(2));
      await tester.drag(messageList, const Offset(0, 250));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('chat-jump-latest')), findsOneWidget);
      await capture('reply-reading-history');
      await tester.tap(find.byKey(const ValueKey('chat-jump-latest')));
      await until(() => !container.read(chatViewModelProvider).isGenerating);
      expect(position.extentAfter, lessThan(2));
      await capture('reply-follow-latest');
      await send('新增采购表', resultType: AgentTablePreview);
      expect(
        (await SqliteWorkspaceCommandStore(database).load()).dataTables,
        isEmpty,
      );
      await capture('table-create-approval');
      await tester.tap(find.text('全部接受'));
      await until(() => find.text('采购清单已创建。').evaluate().isNotEmpty);
      expect(
        (await SqliteWorkspaceCommandStore(
          database,
        ).load()).dataTables.single.data['name'],
        '采购清单',
      );
      await capture('table-created');
      await send('编辑采购表', resultType: AgentTablePreview);
      await capture('table-edit-approval');
      container.read(themeModeProvider.notifier).state = ThemeMode.dark;
      await capture('table-edit-dark');
      container.read(themeModeProvider.notifier).state = ThemeMode.light;
      await tester.tap(find.text('全部接受'));
      await until(() => find.text('已改名，并加入到货日期。').evaluate().isNotEmpty);
      final table = (await SqliteWorkspaceCommandStore(
        database,
      ).load()).dataTables.single;
      expect(table.data['name'], '本周采购');
      expect(table.data['fields'], hasLength(4));
      await capture('table-edited');
      if (Platform.isAndroid) {
        container.read(currentSessionIdProvider.notifier).state =
            overviewSession;
        container.read(defaultInputModeProvider.notifier).state =
            ChatInputMode.voice;
        await mount(const QuickAssistApp());
        await tester.pumpAndSettle();
        await top();
        await capture('panel-quick-assist');
        await tester.ensureVisible(
          find.byKey(const ValueKey('todo-panel-page')),
        );
        await capture('panel-quick-assist-footer');
      }
      final persisted = await SqliteWorkspaceCommandStore(database).load();
      expect(persisted.todos, hasLength(120));
      expect(
        persisted.find(WorkspaceEntityKind.todo, 'panel-todo-0')!.data['title'],
        '确认首页与快问的交互细节',
      );
      expect(
        (await runtime.persistence.load()).turns.where(
          (t) => t.messages.any((m) => m.type == ChatMessageType.todoPanel),
        ),
        hasLength(3),
      );
      await tester.pumpWidget(const SizedBox());
      await runtime.dispose();
      container.dispose();
      await database.close();
      if (Platform.isAndroid) {
        final saved = await File('${directory.path}/review.sqlite')
            .copy('${support.path}/panel-validation.sqlite');
        debugPrint('TOWORK_PANEL_DATABASE ${saved.path}');
      }
      await directory.delete(recursive: true);
    },
  );
}

class _Host implements AssistHost {
  @override
  Future<AssistLaunch> launch() async => const AssistLaunch();
  @override
  Stream<AssistLaunch> get relaunches => const Stream.empty();
  @override
  Future<void> close() async {}
  @override
  Future<void> hide(String notice) async {}
  @override
  Future<void> openApp(AssistHandoff handoff, {bool keepPanel = false}) async {}
}
