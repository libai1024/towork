import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/assist_provider.dart';
import 'package:towork/core/todo/todo_checkbox.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/domain/assist/quick_assist.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/features/chat/widgets/ai_todo_card.dart';
import 'package:towork/shell/quick_assist_app.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/app/chat/chat_view_model.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/model_account_store.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_account_service.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/main.dart';

import '../test/support/free/fake_model_gateway.dart';

/// Native production widgets and isolated SQLite, with synthetic accounts and
/// a scripted answer. Captures never read the user's workspace or credentials.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rich replies, approval, completion, undo and quick assist', (
    tester,
  ) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!Platform.isAndroid) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      await binding.setSurfaceSize(const Size(1280, 900));
    }
    final support = await getApplicationSupportDirectory();
    final directory = await Directory(
      '${support.path}/reply-review-${DateTime.now().microsecondsSinceEpoch}',
    ).create();
    final database = AppDatabase.background(
      File('${directory.path}/review.sqlite'),
    );
    final profile = await database.loadOrCreateProfile();
    await database.renameProfile('小林', expectedVersion: profile.version);
    final previewModel = _PreviewModel();
    final prefs = SqliteAppPreferencesStore(database);
    final oldPrefs = await prefs.loadOrCreate();
    await prefs.update({
      'permission': 'askAll',
    }, expectedVersion: oldPrefs.version);
    final settings = ModelSettingsService(
      database,
      FakeKeyVault(),
      previewModel,
    );
    final accounts = ModelAccountService(
      settings,
      SqliteModelAccountStore(database),
    );
    for (final product in [ProviderKind.moonshot]) {
      await accounts.save(
        profile: ModelProfile(
          product: product,
          model: ProviderCatalog.of(product).models.first.id,
        ),
        newKey: 'synthetic-ui-review-key',
      );
    }
    final container = ProviderContainer(
      overrides: [
        assistHostProvider.overrideWithValue(_Host()),
        localDatabaseProvider.overrideWith((ref) async => database),
        modelSettingsServiceProvider.overrideWith((ref) async => settings),
        modelAccountServiceProvider.overrideWith((ref) async => accounts),
      ],
    );
    final captureKey = GlobalKey();
    // Keep database projections alive when changing the presented app shell.
    final bootstrapKey = GlobalKey();
    final shots = <String, String>{};
    binding.reportData = {'screenshots': shots};
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: UncontrolledProviderScope(
          container: container,
          child: FreeWorkspaceBootstrap(
            key: bootstrapKey,
            child: const ToWorkApp(),
          ),
        ),
      ),
    );
    Future<void> until(bool Function() ready, {bool settle = true}) async {
      for (var i = 0; i < 200 && !ready(); i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(ready(), isTrue);
      if (settle) await tester.pumpAndSettle();
    }

    await until(() => container.read(localChatRuntimeProvider) != null);
    final platform = Platform.isAndroid ? 'android' : 'macos';
    Future<void> capture(
      String name, {
      bool settle = true,
      bool shortPause = false,
    }) async {
      // Let native insets and keyboard animations arrive before pumping layout.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (settle) await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      shots['$platform-$name'] = base64Encode(bytes!.buffer.asUint8List());
      image.dispose();
      expect(tester.takeException(), isNull, reason: name);
      if (Platform.isAndroid) {
        debugPrint('TOWORK_CAPTURE_READY $name');
        await Future<void>.delayed(
          Duration(milliseconds: shortPause ? 400 : 1500),
        );
      }
    }

    AgentRun latest() => container
        .read(localChatRuntimeProvider)!
        .projection
        .data
        .turns
        .last
        .run;
    Future<void> send(String text) async {
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
    }

    Future<void> idle() =>
        until(() => !container.read(chatViewModelProvider).isGenerating);
    Future<void> accept() async {
      await Scrollable.ensureVisible(
        tester.element(find.text('全部接受')),
        alignment: .45,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('全部接受'));
      await idle();
    }

    Future<void> scrollTo(double offset) async {
      final list = find.byKey(const ValueKey('chat-message-list'));
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: list, matching: find.byType(Scrollable)).first,
      );
      scroll.position.jumpTo(
        offset.clamp(0.0, scroll.position.maxScrollExtent),
      );
      await tester.pumpAndSettle();
    }

    container.read(themeModeProvider.notifier).state = ThemeMode.light;
    await send('帮我整理项目收尾步骤，附上代码和时间表');
    await until(
      () => container.read(chatViewModelProvider).streamingText.isNotEmpty,
      settle: false,
    );
    await capture('reply-streaming', settle: false);
    previewModel.finishStreaming.complete();
    await idle();
    await scrollTo(0);
    await capture('reply-light');
    await scrollTo(350);
    await capture('reply-code-table');
    container.read(themeModeProvider.notifier).state = ThemeMode.dark;
    await capture('reply-dark');

    container.read(currentSessionIdProvider.notifier).state = null;
    container.read(themeModeProvider.notifier).state = ThemeMode.light;
    await tester.pumpAndSettle();
    await send('帮我记下整理项目方案');
    await until(() => latest().status == AgentRunStatus.awaitingConfirmation);
    await capture('approval');
    await accept();
    await until(() => container.read(todoListProvider).isNotEmpty);
    expect(find.byType(AiTodoCard), findsOneWidget);
    expect(find.byTooltip('复制回复'), findsOneWidget);
    expect(find.byTooltip('撤销本次全部修改'), findsOneWidget);
    expect(find.text('撤销'), findsNothing);
    expect(find.text('已提交 1 批操作'), findsNothing);
    await capture('task-created');
    await tester.tap(find.byTooltip('复制回复'));
    await tester.pumpAndSettle();
    expect(
      (await Clipboard.getData('text/plain'))?.text,
      '我来记下这件事。\n\n已记下。完成后可以直接勾选这条待办。',
    );
    AppToast.dismiss();
    await tester.pumpAndSettle();
    debugPrint('TOWORK_MOTION_READY');
    await Future<void>.delayed(const Duration(seconds: 1));
    await tester.tap(find.byType(TodoCheckbox));
    await until(
      () => container.read(todoListProvider).single.status == TodoStatus.done,
    );
    await capture('task-manual-complete', shortPause: true);
    await tester.tap(find.byKey(const ValueKey('toast-action')));
    await until(
      () =>
          container.read(todoListProvider).single.status == TodoStatus.pending,
    );
    await capture('task-restored');
    await send('项目方案整理好了，帮我标记完成');
    await until(() => latest().status == AgentRunStatus.awaitingConfirmation);
    await accept();
    await until(
      () => container
          .read(localChatRuntimeProvider)!
          .projection
          .data
          .turns
          .last
          .completedTodoIds
          .isNotEmpty,
    );
    AppToast.dismiss();
    await scrollTo(double.maxFinite);
    await capture('task-ai-complete');
    container.read(themeModeProvider.notifier).state = ThemeMode.dark;
    await capture('task-ai-complete-dark');
    if (Platform.isAndroid) {
      container.read(defaultInputModeProvider.notifier).state =
          ChatInputMode.voice;
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: UncontrolledProviderScope(
            container: container,
            child: FreeWorkspaceBootstrap(
              key: bootstrapKey,
              child: const QuickAssistApp(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await scrollTo(double.maxFinite);
      await capture('quick-assist-complete');
    }
    final finalRunId = latest().id;
    final footer = find.byKey(ValueKey('activity_$finalRunId'));
    final undo = find.descendant(
      of: footer,
      matching: find.byTooltip('撤销本次全部修改'),
    );
    await Scrollable.ensureVisible(tester.element(undo), alignment: .7);
    await tester.pumpAndSettle();
    await tester.tap(undo);
    await until(
      () =>
          container
              .read(localChatRuntimeProvider)!
              .projection
              .turn(finalRunId)
              ?.undoneAt !=
          null,
    );
    await until(
      () =>
          container.read(todoListProvider).single.status == TodoStatus.pending,
    );
    expect(
      find.descendant(of: footer, matching: find.byTooltip('复制回复')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: footer, matching: find.byTooltip('撤销本次全部修改')),
      findsNothing,
    );
    await capture('run-undone');
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await database.close();
    await directory.delete(recursive: true);
  });
}

class _PreviewModel extends FakeKimiGateway {
  final finishStreaming = Completer<void>();
  int _round = 0;
  static const reply =
      '可以按下面的顺序收尾，先让交付内容完整。\n\n'
      '## 先完成方案\n\n'
      '1. 核对**目标与验收标准**。\n2. 整理关键步骤，把待确认的问题单独列出。\n3. 保存最终版本，再通知协作同事。\n\n'
      '> 给最后的检查留出十分钟，重点看附件和负责人。\n\n'
      '## 保存后再同步\n\n'
      '这段代码会等待保存成功，再发送通知。\n\n'
      '```dart\nawait saveDocument();\nawait notifyTeam();\n```\n\n'
      '| 事项 | 时间 |\n| --- | --- |\n| 整理项目方案 | 今天 15:00 |\n| 核对附件 | 今天 16:00 |\n| 团队同步 | 今天 17:00 |';
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    final round = ++_round;
    if (round == 1) {
      yield const ModelTextDelta(reply);
      await finishStreaming.future;
    }
    if (round == 2 || round == 4) {
      final JsonObject args;
      if (round == 2) {
        args = {'title': '整理项目方案'};
      } else {
        final result = request.messages.firstWhere((m) => m['role'] == 'tool');
        final entity =
            (jsonDecode(result['content'] as String) as Map)['entity'] as Map;
        // Manual completion + undo increases the version twice.
        args = {
          'id': entity['id'],
          'expected_version': (entity['version'] as int) + 2,
        };
      }
      yield ModelCompleted(
        assistantMessage: {
          'role': 'assistant',
          'content': round == 2 ? '我来记下这件事。' : '我来更新这条待办。',
          'tool_calls': [
            {
              'id': 'task-$round',
              'type': 'function',
              'function': {
                'name': round == 2 ? 'todo_create' : 'todo_complete',
                'arguments': jsonEncode(args),
              },
            },
          ],
        },
        finishReason: 'tool_calls',
      );
      return;
    }
    yield ModelCompleted(
      assistantMessage: {
        'role': 'assistant',
        'content': round == 1
            ? reply
            : round == 3
            ? '已记下。完成后可以直接勾选这条待办。'
            : '项目方案已完成。接下来可以核对附件，再发给协作同事。',
      },
      finishReason: 'stop',
    );
  }
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
