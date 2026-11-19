import 'package:towork/app/speech_provider.dart';
import 'package:towork/domain/speech/speech_input.dart';

import 'support/free/fake_speech.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/features/chat/widgets/chat_drawer.dart';
import 'package:towork/main.dart';
import 'package:towork/app/providers.dart';

Future<ProviderContainer> mount(
  WidgetTester tester,
  Size size, {
  FakeSpeechInput? speech,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (speech != null) speechInputProvider.overrideWithValue(speech),
      ],
      child: const ToWorkApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(ToWorkApp)));
}

GoRouter routerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(ToWorkApp)))
        .read(appRouterProvider);

void main() {
  testWidgets(
    'desktop grid is 3 by 2, and sidebar persists through all tools',
    (tester) async {
      await mount(tester, const Size(1280, 840));
      final positions = [
        for (final e in workspaceEntries) tester.getCenter(find.text(e.$2)),
      ];
      expect(positions[0].dy, positions[1].dy);
      expect(positions[1].dy, positions[2].dy);
      expect(positions[3].dy, positions[4].dy);
      expect(positions[4].dy, positions[5].dy);
      expect(positions[3].dy, greaterThan(positions[0].dy));
      expect(
        tester.getCenter(find.text('分类')).dy,
        greaterThan(positions.last.dy),
      );
      for (final e in workspaceEntries) {
        await tester.tap(find.text(e.$2).first);
        await tester.pumpAndSettle();
        expect(find.byType(ChatDrawer), findsOneWidget);
        expect(routerOf(tester).routeInformationProvider.value.uri.path, e.$3);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byTooltip('收起侧栏'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatDrawer), findsNothing);
      await tester.tap(find.byTooltip('展开侧栏'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatDrawer), findsOneWidget);
    },
  );

  testWidgets('category navigation refreshes the existing todo route', (
    tester,
  ) async {
    await mount(tester, const Size(1280, 840));
    routerOf(tester).go('/todos?categoryId=cat_stock');
    await tester.pumpAndSettle();
    expect(find.text('分类：炒股'), findsOneWidget);
    expect(find.textContaining('含子分类'), findsNothing);
    routerOf(tester).go('/todos?categoryId=cat_family');
    await tester.pumpAndSettle();
    expect(find.text('分类：家庭'), findsOneWidget);
    expect(find.textContaining('分类：炒股'), findsNothing);
    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部待办'));
    await tester.pumpAndSettle();
    expect(routerOf(tester).routeInformationProvider.value.uri.path, '/todos');
    expect(routerOf(tester).routeInformationProvider.value.uri.query, isEmpty);
    expect(find.textContaining('分类：'), findsNothing);
  });

  testWidgets('small Android composer and drawer fit, model changes stick', (
    tester,
  ) async {
    final container = await mount(tester, const Size(360, 780));
    final composer = tester.getRect(
      find.byKey(const ValueKey('chat-composer')),
    );
    expect(composer.bottom, closeTo(770, .01));
    await tester.tap(find.byTooltip('选择模型'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('provider-platform')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('快速'));
    await tester.pumpAndSettle();
    expect(container.read(chatModelProvider), '快速');
    expect(find.text('Kimi'), findsNothing);
    expect(find.text('快速'), findsOneWidget);
    await tester.tap(find.byTooltip('打开菜单'));
    await tester.pumpAndSettle();
    expect(find.text('分类'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stopping during initial delay never adds a late reply or task', (
    tester,
  ) async {
    final container = await mount(tester, const Size(390, 844));
    final count = container.read(todoListProvider).length;
    await tester.tap(find.byKey(const ValueKey('switch-to-keyboard')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('chat-text-input')),
      '提醒我明天交报告',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('发送消息'));
    await tester.pump();
    await tester.tap(find.byTooltip('停止生成'));
    await tester.pump(const Duration(seconds: 5));
    final id = container.read(currentSessionIdProvider)!;
    expect(
      container.read(sessionListProvider.notifier).messagesOf(id).length,
      1,
    );
    expect(container.read(todoListProvider).length, count);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop command search finds mock conversations', (
    tester,
  ) async {
    await mount(tester, const Size(1280, 840));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('workspace-search-input')),
      '体检',
    );
    await tester.pumpAndSettle();
    expect(find.text('妈妈的体检安排'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('quick capture creates a categorized mock task', (tester) async {
    final container = await mount(tester, const Size(1280, 840));
    final count = container.read(todoListProvider).length;
    expect(find.byTooltip('快速记录 ⌘⇧Space'), findsNothing);
    await tester.tap(find.byTooltip('打开今日总览'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('新建待办'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('todo-create-title')),
      '准备周会资料',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('分类'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('工作').hitTestable().last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('截止日期'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明天').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('创建'));
    await tester.pumpAndSettle();
    expect(container.read(todoListProvider).length, count + 1);
    final todo = container
        .read(todoListProvider)
        .firstWhere((t) => t.title == '准备周会资料');
    expect(todo.categoryId, 'cat_work');
    expect(todo.dueAt, isNotNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('desktop model picker pops only its own route', (tester) async {
    final container = await mount(tester, const Size(1280, 820));
    await tester.tap(find.byTooltip('选择模型'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('provider-platform')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('快速'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(container.read(chatModelProvider), '快速');
    expect(routerOf(tester).routeInformationProvider.value.uri.path, '/');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'sidebar long press enables reordering and category appearance editing',
    (tester) async {
      final container = await mount(tester, const Size(390, 844));
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('关闭菜单'), findsNothing);
      await tester.longPress(find.text('炒股'));
      await tester.pumpAndSettle();
      expect(find.text('完成'), findsOneWidget);
      final original = container
          .read(categoryListProvider.notifier)
          .roots
          .map((c) => c.id)
          .toList();
      await tester.drag(
        find.byKey(const ValueKey('category-drag-cat_stock')),
        const Offset(0, 80),
      );
      await tester.pumpAndSettle();
      expect(
        container
            .read(categoryListProvider.notifier)
            .roots
            .map((c) => c.id)
            .toList(),
        isNot(original),
      );
      await tester.tap(find.byTooltip('编辑炒股'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('图标，星星'));
      await tester.tap(find.bySemanticsLabel(RegExp('颜色，灰紫，')));
      await tester.ensureVisible(find.text('完  成'));
      await tester.tap(find.text('完  成'));
      await tester.pumpAndSettle();
      final category = container
          .read(categoryListProvider.notifier)
          .byId('cat_stock')!;
      expect(category.iconKey, 'star');
      expect(category.color.toARGB32(), isNot(0xFFFF3B30));
      expect(routerOf(tester).routeInformationProvider.value.uri.path, '/');
      expect(find.byTooltip('编辑炒股'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'default input mode setting updates composer, voice preview remains editable',
    (tester) async {
      final speech = FakeSpeechInput();
      addTearDown(speech.bus.close);
      final container = await mount(
        tester,
        const Size(390, 844),
        speech: speech,
      );
      expect(find.byKey(const ValueKey('voice-input')), findsOneWidget);
      await tester.longPress(find.byKey(const ValueKey('voice-input')));
      await tester.pumpAndSettle();
      speech.emit(
        speech.starts.single,
        SpeechEventKind.partial,
        text: '提醒我明天下午三点前把季度报告发给王总',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('switch-to-keyboard')));
      await tester.pumpAndSettle();
      expect(find.text('提醒我明天下午三点前把季度报告发给王总'), findsOneWidget);
      routerOf(tester).go('/settings');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('默认输入方式'));
      await tester.tap(find.text('默认输入方式'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('键盘'));
      await tester.pumpAndSettle();
      expect(container.read(defaultInputModeProvider), ChatInputMode.keyboard);
      routerOf(tester).go('/');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-text-input')), findsOneWidget);
      expect(find.text('按住转文字'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('voice-input')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('voice-input')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test('input preference is saved and rolled back if storage fails', () async {
    ChatInputMode? saved;
    final preference = InputModePreference(
      ChatInputMode.voice,
      (mode) async => saved = mode,
    );
    await preference.select(ChatInputMode.keyboard);
    expect(saved, ChatInputMode.keyboard);
    expect(preference.state, ChatInputMode.keyboard);
    final failing = InputModePreference(
      ChatInputMode.voice,
      (_) async => throw StateError('storage unavailable'),
    );
    await expectLater(failing.select(ChatInputMode.keyboard), throwsStateError);
    expect(failing.state, ChatInputMode.voice);
    preference.dispose();
    failing.dispose();
  });
}
