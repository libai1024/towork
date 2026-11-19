import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/assist_provider.dart';
import 'package:towork/app/navigation_requests.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/app/speech_provider.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/domain/assist/quick_assist.dart';
import 'package:towork/app/chat/chat_view_model.dart';
import 'package:towork/features/chat/widgets/chat_thread.dart';
import 'package:towork/shell/quick_assist_panel.dart';
import 'package:towork/shell/quick_assist_app.dart';

import 'support/free/fake_speech.dart';

class _Host implements AssistHost {
  _Host([this.initial = const AssistLaunch()]);

  final AssistLaunch initial;
  final again = StreamController<AssistLaunch>.broadcast(sync: true);
  final events = <String>[];
  AssistHandoff? handoff;
  bool? keptPanel;
  String? notice;

  @override
  Future<AssistLaunch> launch() async => initial;

  @override
  Stream<AssistLaunch> get relaunches => again.stream;

  @override
  Future<void> close() async => events.add('close');

  @override
  Future<void> hide(String notice) async {
    this.notice = notice;
    events.add('hide');
  }

  @override
  Future<void> openApp(AssistHandoff handoff, {bool keepPanel = false}) async {
    this.handoff = handoff;
    keptPanel = keepPanel;
    events.add('open');
  }
}

void main() {
  late FakeSpeechInput speech;
  setUp(() => speech = FakeSpeechInput());
  tearDown(() async {
    AppToast.dismiss();
    await speech.bus.close();
  });

  const card = ValueKey('quick-assist-card');
  const handle = ValueKey('quick-assist-handle');
  const input = ValueKey('chat-text-input');
  final greeting = find.byKey(const ValueKey('quick-assist-greeting'));
  Finder suggestion(String label) =>
      find.byKey(ValueKey('quick-assist-suggestion-$label'));

  Future<ProviderContainer> mount(
    WidgetTester tester,
    _Host host, {
    ChatInputMode mode = ChatInputMode.keyboard,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    addTearDown(host.again.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistHostProvider.overrideWithValue(host),
          speechInputProvider.overrideWithValue(speech),
          speechNetworkRouteProvider.overrideWithValue(() async => true),
          initialInputModeProvider.overrideWithValue(mode),
        ],
        child: const QuickAssistApp(),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(QuickAssistPanel)),
    );
  }

  String text(WidgetTester tester) =>
      tester.widget<TextField>(find.byKey(input)).controller!.text;

  /// 把时间往前推到这次回复收完。回复由计时器驱动，不会自己排帧。
  Future<void> finish(WidgetTester tester) async {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(QuickAssistPanel)),
    );
    bool generating() => container.read(chatViewModelProvider).isGenerating;
    for (var i = 0; i < 300 && generating(); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(generating(), isFalse);
    await tester.pumpAndSettle();
  }

  /// 点一下并等离场动画播完。
  Future<void> leave(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('半屏展开：卡片贴底、占窗口一半多一点，空白页给出问候和建议', (tester) async {
    final host = _Host();
    await mount(tester, host);
    final rect = tester.getRect(find.byKey(card));
    expect(rect.left, 8);
    expect(rect.right, 382);
    expect(rect.bottom, 836);
    expect(rect.height, closeTo(844 * .56, .5));
    expect(greeting, findsOneWidget);
    expect(suggestion('今天还有什么要做'), findsOneWidget);
    expect(suggestion('记一条待办'), findsOneWidget);
    expect(find.byType(ChatThread), findsNothing);
    expect(host.events, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('键盘弹出时卡片整体上移，不被遮挡', (tester) async {
    await mount(tester, _Host());
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byKey(card));
    expect(rect.bottom, 844 - 300 - 8);
    expect(rect.top, greaterThanOrEqualTo(8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('上拖展开，下拖收回半屏，半屏再下拖关闭', (tester) async {
    final host = _Host();
    await mount(tester, host);
    final half = tester.getRect(find.byKey(card)).height;
    await tester.tap(find.bySemanticsLabel('展开快问面板'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(card)).height, greaterThan(half));
    await tester.tap(find.bySemanticsLabel('收起快问面板'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(card)).height, half);

    await tester.drag(find.byKey(handle), const Offset(0, -140));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(card)).height, 844 - 8 - 8);

    await tester.drag(find.byKey(handle), const Offset(0, 140));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(card)).height, half);
    expect(host.events, isEmpty);

    await tester.drag(find.byKey(handle), const Offset(0, 140));
    await tester.pumpAndSettle();
    expect(host.events, ['close']);
  });

  testWidgets('点卡片以外、按返回键、点关闭按钮都会关闭', (tester) async {
    var host = _Host();
    await mount(tester, host);
    await tester.tapAt(const Offset(195, 120));
    await tester.pumpAndSettle();
    expect(host.events, ['close']);

    // 每次都是一个全新的面板，和真实的窗口一样。
    await tester.pumpWidget(const SizedBox());
    host = _Host();
    await mount(tester, host);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(host.events, ['close']);

    await tester.pumpWidget(const SizedBox());
    host = _Host();
    await mount(tester, host);
    await tester.tap(find.byKey(const ValueKey('quick-assist-close')));
    await tester.pumpAndSettle();
    expect(host.events, ['close']);
    // 卡片已经滑走，再点空白处不会重复收尾。
    await tester.tapAt(const Offset(195, 120));
    await tester.pumpAndSettle();
    expect(host.events, ['close']);
  });

  testWidgets('建议项直接发出一句话并进入对话', (tester) async {
    final host = _Host();
    final container = await mount(tester, host);
    await tester.tap(suggestion('今天还有什么要做'));
    await tester.pump();
    expect(container.read(currentSessionIdProvider), isNotNull);
    expect(find.byType(ChatThread), findsOneWidget);
    expect(find.text('今天还有什么要做？'), findsOneWidget);
    expect(greeting, findsNothing);
    await finish(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('「记一条待办」只预填，等用户接着写', (tester) async {
    final container = await mount(tester, _Host());
    await tester.tap(suggestion('记一条待办'));
    await tester.pumpAndSettle();
    expect(text(tester), '帮我记一条待办：');
    expect(container.read(currentSessionIdProvider), isNull);
  });

  testWidgets('分享带入的文字只预填不发送，并给出针对它的建议', (tester) async {
    final host = _Host(
      const AssistLaunch(source: AssistSource.share, text: '周五下午三点和李总开会'),
    );
    final container = await mount(tester, host);
    expect(text(tester), '周五下午三点和李总开会');
    expect(container.read(currentSessionIdProvider), isNull);
    expect(find.text('处理这段文字'), findsOneWidget);
    expect(suggestion('记成待办'), findsOneWidget);
    expect(suggestion('今天还有什么要做'), findsNothing);

    await tester.tap(suggestion('记成待办'));
    await tester.pump();
    expect(container.read(currentSessionIdProvider), isNotNull);
    expect(find.textContaining('把下面的内容记成待办：'), findsOneWidget);
    expect(text(tester), isEmpty, reason: '原文已经随建议发出');
    await finish(tester);
  });

  testWidgets('清空带入的文字后回到通用建议', (tester) async {
    await mount(
      tester,
      _Host(const AssistLaunch(source: AssistSource.selection, text: '一段话')),
    );
    await tester.enterText(find.byKey(input), '');
    await tester.pumpAndSettle();
    expect(suggestion('记成待办'), findsNothing);
    expect(suggestion('记一条待办'), findsOneWidget);
  });

  testWidgets('语音唤起直接开始听写', (tester) async {
    await mount(
      tester,
      _Host(const AssistLaunch(source: AssistSource.voice, voice: true)),
      mode: ChatInputMode.voice,
    );
    expect(speech.starts, hasLength(1));
    expect(find.text('正在听…'), findsOneWidget);
    final bounds = tester.getRect(find.byKey(card));
    final recording = tester.getRect(
      find.byKey(const ValueKey('voice-live-panel')),
    );
    // The recording covers the interior of the card, inside its outline.
    expect(bounds.contains(recording.topLeft), isTrue);
    expect(bounds.contains(recording.bottomRight), isTrue);
    expect((bounds.topLeft - recording.topLeft).distance, lessThan(2));
    expect((bounds.bottomRight - recording.bottomRight).distance, lessThan(2));
    expect(recording.top, greaterThan(0));
  });

  testWidgets('生成中关闭：面板收到后台，回复收完才退出', (tester) async {
    final host = _Host();
    await mount(tester, host);
    await tester.tap(suggestion('今天还有什么要做'));
    await tester.pump(const Duration(milliseconds: 100));

    await leave(tester, const ValueKey('quick-assist-close'));
    expect(host.events, ['hide']);
    expect(host.notice, contains('后台'));

    await finish(tester);
    expect(host.events, ['hide', 'close']);
  });

  testWidgets('收在后台时再次唤起：重新亮出并接着这段对话，不再自动退出', (tester) async {
    final host = _Host();
    final container = await mount(tester, host);
    await tester.tap(suggestion('今天还有什么要做'));
    await tester.pump(const Duration(milliseconds: 100));
    final session = container.read(currentSessionIdProvider);
    await leave(tester, const ValueKey('quick-assist-close'));
    expect(host.events, ['hide']);

    host.again.add(const AssistLaunch(source: AssistSource.assistant));
    await finish(tester);
    expect(host.events, ['hide']);
    expect(container.read(currentSessionIdProvider), session);
    expect(find.byType(ChatThread), findsOneWidget);
    expect(tester.getRect(find.byKey(card)).bottom, 836);
  });

  testWidgets('空闲时再次唤起是一段新对话', (tester) async {
    final host = _Host();
    final container = await mount(tester, host);
    await tester.tap(suggestion('今天还有什么要做'));
    await finish(tester);
    expect(container.read(currentSessionIdProvider), isNotNull);

    host.again.add(
      const AssistLaunch(source: AssistSource.share, text: '新带入的文字'),
    );
    await tester.pumpAndSettle();
    expect(container.read(currentSessionIdProvider), isNull);
    expect(greeting, findsOneWidget);
    expect(text(tester), '新带入的文字');
  });

  testWidgets('后台保留的面板重新唤起时从底部全宽展开', (tester) async {
    final host = _Host();
    await mount(tester, host, mode: ChatInputMode.voice);
    host.again.add(const AssistLaunch(source: AssistSource.shortcut));
    await tester.pump();
    final start = tester.getRect(find.byKey(card));
    expect(start.top, greaterThanOrEqualTo(844));
    expect(start.left, 8);
    expect(start.right, 382);
    await tester.pump(const Duration(milliseconds: 120));
    final entering = tester.getRect(find.byKey(card));
    expect(entering.top, lessThan(start.top));
    expect(entering.left, 8);
    expect(entering.right, 382);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(card)).bottom, 836);
    expect(host.events, isEmpty);
  });

  testWidgets('「新对话」回到空白页', (tester) async {
    final container = await mount(tester, _Host());
    expect(find.byKey(const ValueKey('quick-assist-new')), findsNothing);
    await tester.tap(suggestion('今天还有什么要做'));
    await finish(tester);
    await tester.tap(find.byKey(const ValueKey('quick-assist-new')));
    await tester.pumpAndSettle();
    expect(container.read(currentSessionIdProvider), isNull);
    expect(greeting, findsOneWidget);
  });

  testWidgets('空闲重新唤起清掉上次分享草稿', (tester) async {
    final host = _Host(
      const AssistLaunch(source: AssistSource.share, text: '旧分享草稿'),
    );
    await mount(tester, host);
    host.again.add(const AssistLaunch(source: AssistSource.assistant));
    await tester.pumpAndSettle();
    expect(text(tester), isEmpty);
    expect(suggestion('记一条待办'), findsOneWidget);
  });

  testWidgets('键盘打开时发送按钮可点且进入消息流', (tester) async {
    await mount(tester, _Host());
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.enterText(find.byKey(input), '检查面板发送');
    await tester.pumpAndSettle();
    final send = find.byTooltip('发送消息');
    expect(tester.getRect(send).bottom, lessThan(844 - 300));
    await tester.tap(send);
    await tester.pump();
    expect(greeting, findsNothing);
    expect(find.text('检查面板发送'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('在 ToWork 中打开：带上当前会话并关闭面板', (tester) async {
    final host = _Host();
    final container = await mount(tester, host);
    await tester.tap(suggestion('今天还有什么要做'));
    await finish(tester);
    final session = container.read(currentSessionIdProvider);

    await tester.tap(find.byKey(const ValueKey('quick-assist-open-app')));
    await tester.pumpAndSettle();
    expect(host.events, ['open']);
    expect(host.handoff!.sessionId, session);
    expect(host.handoff!.location, isNull);
    expect(host.keptPanel, isFalse);
  });

  testWidgets('生成中在 ToWork 中打开：面板留在后台收尾', (tester) async {
    final host = _Host();
    await mount(tester, host);
    await tester.tap(suggestion('今天还有什么要做'));
    await tester.pump(const Duration(milliseconds: 100));
    await leave(tester, const ValueKey('quick-assist-open-app'));
    expect(host.events, ['open']);
    expect(host.keptPanel, isTrue);

    await finish(tester);
    expect(host.events, ['open', 'close']);
  });

  testWidgets('应用内的跳转请求交还主应用处理', (tester) async {
    final host = _Host();
    final container = await mount(tester, host);
    container.read(appNavigationRequestsProvider).go(AppRoutes.modelAccounts);
    await tester.pumpAndSettle();
    expect(host.events, ['open']);
    expect(host.handoff!.location, AppRoutes.modelAccounts);
  });

  testWidgets('工作区未就绪：加载中不画卡片，失败时可重试，点空白处都能退出', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final host = _Host();
    addTearDown(host.again.close);
    var retried = 0;
    Widget app(VoidCallback? retry) => ProviderScope(
      overrides: [assistHostProvider.overrideWithValue(host)],
      child: QuickAssistApp(home: QuickAssistStartup(retry: retry)),
    );

    await tester.pumpWidget(app(null));
    await tester.pumpAndSettle();
    expect(find.byKey(card), findsNothing);
    await tester.tapAt(const Offset(195, 400));
    await tester.pump();
    expect(host.events, ['close']);

    await tester.pumpWidget(app(() => retried++));
    await tester.pumpAndSettle();
    expect(find.byKey(card), findsOneWidget);
    expect(find.textContaining('无法打开工作区'), findsOneWidget);
    await tester.tap(find.text('重新打开'));
    await tester.pump();
    expect(retried, 1);
    await tester.tapAt(const Offset(195, 120));
    await tester.pump();
    expect(host.events, ['close', 'close']);
  });
}
