import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/main.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/speech_provider.dart';
import 'package:towork/domain/speech/speech_input.dart';

import '../test/support/free/fake_speech.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final captureKey = GlobalKey();
  final shots = <String, String>{};
  final platform = Platform.isAndroid ? 'android' : 'desktop';

  testWidgets('native UI walkthrough with mock data', (tester) async {
    if (!Platform.isAndroid) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 820);
      await binding.setSurfaceSize(const Size(1280, 820));
    }
    binding.reportData = {'screenshots': shots};
    final speech = FakeSpeechInput();
    addTearDown(speech.bus.close);
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: ProviderScope(
          overrides: [speechInputProvider.overrideWithValue(speech)],
          child: const ToWorkApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 850));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ToWorkApp)),
    );
    final router = container.read(appRouterProvider);
    container.read(themeModeProvider.notifier).state = ThemeMode.light;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 850));
    Future<void> capture(String name) async {
      await tester.pump();
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      debugPrint('Capturing $platform-$name');
      final image = await boundary
          .toImage(pixelRatio: 1.5)
          .timeout(const Duration(seconds: 15));
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final prefix = const bool.fromEnvironment('VOICE_ONLY')
          ? 'speech-fix-'
          : '';
      shots['$prefix$platform-$name'] = base64Encode(
        bytes!.buffer.asUint8List(),
      );
      image.dispose();
      expect(tester.takeException(), isNull, reason: name);
    }

    Future<void> createTask() async {
      if (find
          .byKey(const ValueKey('switch-to-keyboard'))
          .evaluate()
          .isNotEmpty) {
        await tester.tap(find.byKey(const ValueKey('switch-to-keyboard')));
        await tester.pumpAndSettle();
      }
      await tester.enterText(
        find.byKey(const ValueKey('chat-text-input')),
        '提醒我明天下午三点前把报告发给王总',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('发送消息'));
      await tester.pump(const Duration(seconds: 1));
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await capture('conversation');
      expect(find.byTooltip('修改待办'), findsOneWidget);
      expect(find.byTooltip('撤销待办'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('已为你建好这条待办：')).dx,
        tester
            .getTopLeft(find.byKey(const ValueKey('created-todo-content')))
            .dx,
      );
    }

    // Focused native capture for subsequent chat layout changes.
    if (const bool.fromEnvironment('CHAT_ONLY')) {
      await createTask();
      return;
    }

    await capture('home');
    await tester.tap(find.byKey(const ValueKey('voice-input')));
    await capture('voice');
    speech.emit(speech.starts.single, SpeechEventKind.partial, text: '提醒我明天开会');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('switch-to-keyboard')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await capture('voice-transcript');
    if (const bool.fromEnvironment('VOICE_ONLY')) {
      FocusManager.instance.primaryFocus?.unfocus();
      container.read(themeModeProvider.notifier).state = ThemeMode.dark;
      await capture('voice-dark');
      return;
    }
    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('chat-text-input')),
    );
    input.controller!.clear();
    input.focusNode!.unfocus();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('switch-to-voice')));
    await tester.pump();
    await tester.tap(find.byTooltip('选择模型'));
    await capture('model-picker');
    await tester.tap(find.text('K3').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    if (Platform.isAndroid) {
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.longPress(find.text('炒股').first);
    await capture('category-sort');
    await tester.tap(find.byTooltip('编辑炒股'));
    await capture('category-edit');
    await tester.tap(find.bySemanticsLabel('关闭').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('完成'));
    if (Platform.isAndroid) {
      await tester.tapAt(
        Offset(
          tester.view.physicalSize.width / tester.view.devicePixelRatio - 8,
          180,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    if (Platform.isAndroid) {
      await tester.tap(find.byTooltip('打开菜单'));
      await capture('drawer');
      await tester.tapAt(
        Offset(
          tester.view.physicalSize.width / tester.view.devicePixelRatio - 8,
          180,
        ),
      );
    } else {
      await tester.tap(find.byTooltip('收起侧栏'));
      await capture('collapsed');
      await tester.tap(find.byTooltip('展开侧栏'));
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 850));
    if (Platform.isAndroid) {
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.tap(find.byKey(const ValueKey('sidebar-search')));
    await capture('search');
    await tester.enterText(
      find.byKey(const ValueKey('workspace-search-input')),
      '体检',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await capture('search-results');
    await tester.tap(find.byKey(const ValueKey('workspace-search-close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await createTask();

    router.go('/todos');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 850));
    await capture('todo-list');
    await tester.tap(find.byTooltip('切换到看板'));
    await capture('todos');
    for (final (path, name) in [
      ('/categories', 'categories'),
      ('/visualization', 'schedule'),
      ('/reports', 'reports'),
      ('/data-tables', 'data'),
      ('/memory', 'memory'),
      ('/settings', 'settings'),
    ]) {
      router.go(path);
      await capture(name);
    }
    container.read(currentSessionIdProvider.notifier).state = null;
    router.go('/');
    container.read(themeModeProvider.notifier).state = ThemeMode.dark;
    await capture('dark');
    router.go('/todos');
    await capture('dark-todos');
    router.go('/');
    container.read(themeModeProvider.notifier).state = ThemeMode.light;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 850));
    binding.reportData = {'screenshots': shots};
  });
}
