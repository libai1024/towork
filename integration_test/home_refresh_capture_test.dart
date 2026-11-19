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
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/speech_provider.dart';
import 'package:towork/app/assist_provider.dart';
import 'package:towork/domain/speech/speech_input.dart';
import 'package:towork/domain/assist/quick_assist.dart';
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
import '../test/support/free/fake_speech.dart';

/// Native production widgets and isolated SQLite, with synthetic accounts and
/// a scripted answer. Captures never read the user's workspace or credentials.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home, model picker and conversation in both themes', (
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
      '${support.path}/home-review-${DateTime.now().microsecondsSinceEpoch}',
    ).create();
    final database = AppDatabase.background(
      File('${directory.path}/review.sqlite'),
    );
    final profile = await database.loadOrCreateProfile();
    await database.renameProfile('小林', expectedVersion: profile.version);
    final settings = ModelSettingsService(
      database,
      FakeKeyVault(),
      _PreviewModel(),
    );
    final accounts = ModelAccountService(
      settings,
      SqliteModelAccountStore(database),
    );
    for (final product in [
      ProviderKind.moonshot,
      ProviderKind.deepseek,
      ProviderKind.zhipu,
    ]) {
      await accounts.save(
        profile: ModelProfile(
          product: product,
          model: ProviderCatalog.of(product).models.first.id,
        ),
        newKey: 'synthetic-ui-review-key',
      );
    }
    final speech = FakeSpeechInput();
    final container = ProviderContainer(
      overrides: [
        speechInputProvider.overrideWithValue(speech),
        assistHostProvider.overrideWithValue(_Host()),
        localDatabaseProvider.overrideWith((ref) async => database),
        modelSettingsServiceProvider.overrideWith((ref) async => settings),
        modelAccountServiceProvider.overrideWith((ref) async => accounts),
      ],
    );
    final captureKey = GlobalKey();
    final shots = <String, String>{};
    binding.reportData = {'screenshots': shots};
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: UncontrolledProviderScope(
          container: container,
          child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
        ),
      ),
    );
    Future<void> until(bool Function() ready) async {
      for (var i = 0; i < 200 && !ready(); i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(ready(), isTrue);
      await tester.pumpAndSettle();
    }

    await until(() => container.read(localChatRuntimeProvider) != null);
    final platform = Platform.isAndroid ? 'android' : 'macos';
    Future<void> capture(String name, {bool recording = false}) async {
      // Let native insets and keyboard animations arrive before pumping layout.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!recording) await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
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
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }

    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      container.read(themeModeProvider.notifier).state = theme;
      await capture('home-${theme.name}');
      await tester.tap(find.byTooltip('选择模型'));
      await capture('providers-${theme.name}');
      await tester.tap(find.byKey(const ValueKey('provider-deepseek')));
      await capture('models-${theme.name}');
      await tester.tap(find.byKey(const ValueKey('model-picker-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('provider-platform')));
      await capture('models-thinking-${theme.name}');
      await tester.tap(find.byTooltip('选择模型'), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    container.read(themeModeProvider.notifier).state = ThemeMode.light;
    container.read(fontScaleProvider.notifier).state = 1.6;
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('选择模型'));
    await capture('providers-large-type');
    await tester.tap(find.byKey(const ValueKey('provider-deepseek')));
    await capture('models-large-type');
    await tester.tap(find.byTooltip('选择模型'), warnIfMissed: false);
    container.read(fontScaleProvider.notifier).state = 1;
    await tester.pumpAndSettle();
    void previewLevels() {
      for (final level in [.14, .28, .54, .81, .65, .22, .48, .64, .35]) {
        speech.bus.add(
          SpeechEvent(speech.starts.last, SpeechEventKind.level, level: level),
        );
      }
    }

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('voice-input'))),
    );
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump(const Duration(milliseconds: 250));
    for (final (index, partial) in ['帮我', '帮我记下', '帮我记下明天下午的会议'].indexed) {
      speech.emit(speech.starts.single, SpeechEventKind.partial, text: partial);
      for (final level in [.16, .44, .72 - index * .1, .32]) {
        speech.bus.add(
          SpeechEvent(
            speech.starts.single,
            SpeechEventKind.level,
            level: level,
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    await capture('voice-hold-light', recording: true);
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('voice-target-revise'))),
    );
    await capture('voice-revise-light', recording: true);
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('voice-target-cancel'))),
    );
    await capture('voice-cancel-light', recording: true);
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('switch-to-keyboard')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('chat-text-input')),
      '帮我理一下今天的工作顺序',
    );
    await capture('keyboard');
    await tester.tap(find.byTooltip('选择模型'));
    await capture('providers-keyboard');
    await tester.tap(find.byKey(const ValueKey('provider-deepseek')));
    await capture('models-keyboard');
    await tester.tap(find.byTooltip('选择模型'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('发送消息'));
    await until(
      () =>
          !container.read(chatViewModelProvider).isGenerating &&
          container.read(currentSessionIdProvider) != null,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await capture('conversation-light');
    final chatHold = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('voice-input'))),
    );
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
    speech.emit(speech.starts.last, SpeechEventKind.partial, text: '提醒我明天下午开会');
    await capture('voice-chat-recording', recording: true);
    for (final action in ['revise', 'cancel']) {
      await chatHold.moveTo(
        tester.getCenter(find.byKey(ValueKey('voice-target-$action'))),
      );
      await capture('voice-chat-$action', recording: true);
    }
    await chatHold.up();
    await tester.pumpAndSettle();
    container.read(themeModeProvider.notifier).state = ThemeMode.dark;
    await capture('conversation-dark');
    final darkHold = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('voice-input'))),
    );
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
    speech.emit(speech.starts.last, SpeechEventKind.partial, text: '提醒我明天下午开会');
    await capture('voice-chat-recording-dark', recording: true);
    await darkHold.moveTo(
      tester.getCenter(find.byKey(const ValueKey('voice-target-cancel'))),
    );
    await darkHold.up();
    await tester.pumpAndSettle();
    final list = find.byKey(const ValueKey('chat-message-list'));
    final scroll = tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    scroll.position.jumpTo(200.0.clamp(0.0, scroll.position.maxScrollExtent));
    await tester.pumpAndSettle();
    await capture('header-scroll-dark');
    if (Platform.isAndroid) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: UncontrolledProviderScope(
            container: container,
            child: const QuickAssistApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture('quick-assist');
      final quickHold = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('voice-input'))),
      );
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 200));
      speech.emit(
        speech.starts.last,
        SpeechEventKind.partial,
        text: '提醒我明天下午参加会议',
      );
      previewLevels();
      await capture('quick-voice-dark', recording: true);
      await quickHold.moveTo(
        tester.getCenter(find.byKey(const ValueKey('voice-target-cancel'))),
      );
      await capture('quick-voice-cancel-dark', recording: true);
      await quickHold.up();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('选择模型'));
      await capture('quick-assist-providers');
      await tester.tap(find.byKey(const ValueKey('provider-deepseek')));
      await capture('quick-assist-models');
    }
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await speech.bus.close();
    await database.close();
    await directory.delete(recursive: true);
  });
}

class _PreviewModel extends FakeKimiGateway {
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    yield ModelCompleted(
      assistantMessage: {
        'role': 'assistant',
        'content':
            '可以先把今天分成三段，给需要专注的事情留出完整时间。\n\n'
            '**上午 先完成最重要的一件事**\n\n'
            '整理项目方案，把目标、关键步骤和待确认的问题写清楚。先完成初稿，再集中处理消息。\n\n'
            '**下午 推进协作事项**\n\n'
            '和同事确认分工，把会议结论整理成可执行的待办，并补上负责人和截止时间。\n\n'
            '**下班前 留十分钟收尾**\n\n'
            '检查今天的完成情况，把尚未完成的事项安排到合适的日期。你也可以把具体事项发给我，我们一起排出顺序。\n\n'
            '**给临时事项留出空间**\n\n'
            '下午预留半小时处理临时问题，收到新需求时先记下来，再根据截止时间调整安排。\n\n'
            '开始工作前，把需要的资料放在一起，关掉无关提醒。每完成一项就记录结果，方便明天继续。',
      },
      finishReason: 'stop',
      usage: {'total_tokens': 120},
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
