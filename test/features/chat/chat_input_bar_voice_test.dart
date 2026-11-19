import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/speech_provider.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/domain/speech/speech_input.dart';
import 'package:towork/features/chat/widgets/chat_input_bar.dart';
import 'package:towork/features/chat/widgets/voice_gesture_geometry.dart';
import 'package:towork/features/settings/widgets/speech_diagnostics_sheet.dart';
import 'package:towork/theme/app_theme.dart';
import 'package:towork/theme/app_colors.dart';

import '../../support/free/fake_speech.dart';

void main() {
  late FakeSpeechInput input;
  late TextEditingController text;
  late FocusNode focus;
  late List<(String, String)> sent;
  setUp(() {
    input = FakeSpeechInput();
    text = TextEditingController();
    focus = FocusNode();
    sent = [];
  });
  tearDown(() async {
    AppToast.dismiss();
    await input.bus.close();
    text.dispose();
    focus.dispose();
  });
  Future<void> mount(
    WidgetTester tester, {
    bool online = true,
    bool accepted = true,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          speechInputProvider.overrideWithValue(input),
          speechNetworkRouteProvider.overrideWithValue(() async => online),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ChatInputBar(
                controller: text,
                focusNode: focus,
                isGenerating: false,
                onSend: () {},
                onStop: () {},
                mobile: true,
                onVoiceSubmit: (value, id) async {
                  sent.add((value, id));
                  return accepted;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  final voice = find.byKey(const ValueKey('voice-input'));
  final keyboard = find.byKey(const ValueKey('switch-to-keyboard'));
  void noModal() {
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('重试'), findsNothing);
  }

  Future<void> start(WidgetTester tester) async {
    await tester.longPress(voice);
    await tester.pumpAndSettle();
  }

  testWidgets('short taps do not prepare or start the microphone', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(voice);
    await tester.pumpAndSettle();
    expect(input.preparations, 0);
    expect(input.starts, isEmpty);
    expect(find.text('按住开始录音，松开发送'), findsOneWidget);
  });

  testWidgets('recording and slide zones have one haptic per transition', (
    tester,
  ) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
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
    await mount(tester);
    final gesture = await tester.startGesture(tester.getCenter(voice));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(haptics, ['HapticFeedbackType.mediumImpact']);
    input.emit(input.starts.single, SpeechEventKind.partial, text: '第一句');
    await tester.pump();
    expect(haptics, hasLength(1));
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('voice-target-revise'))),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(0, -5));
    await tester.pump();
    expect(haptics, [
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.selectionClick',
    ]);
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('voice-target-cancel'))),
    );
    await tester.pump();
    expect(haptics, hasLength(3));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(sent, isEmpty);
  });

  testWidgets('dragging back from cancel sends once on release', (
    tester,
  ) async {
    await mount(tester);
    final origin = tester.getCenter(voice);
    final gesture = await tester.startGesture(origin);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    final id = input.starts.single;
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('voice-target-cancel'))),
    );
    await tester.pump();
    expect(find.text('松开取消'), findsOneWidget);
    await gesture.moveTo(origin);
    await tester.pump();
    expect(find.text('松开发送'), findsOneWidget);
    input.emit(id, SpeechEventKind.finalResult, text: '继续发送');
    await tester.pump(const Duration(seconds: 2));
    expect(sent, isEmpty);
    await gesture.up();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(sent, [('继续发送', id)]);
  });

  testWidgets('empty text entry supports tap to type and hold to dictate', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(keyboard);
    await tester.pumpAndSettle();
    focus.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('按住转文字'), findsOneWidget);
    await tester.tap(voice);
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    await tester.enterText(find.byType(TextField), '现有草稿');
    await tester.longPress(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(input.starts, isEmpty);
    expect(text.text, '现有草稿');
    text.clear();
    focus.unfocus();
    await tester.pumpAndSettle();
    final hold = await tester.startGesture(tester.getCenter(voice));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    final id = input.starts.single;
    await hold.up();
    await tester.pump();
    input.emit(id, SpeechEventKind.finalResult, text: '转成文字');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(sent, [('转成文字', id)]);
  });

  testWidgets(
    'long transcripts leave both targets fixed and a neutral lane above the thumb',
    (tester) async {
      await mount(tester);
      final gesture = await tester.startGesture(tester.getCenter(voice));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      final id = input.starts.single;
      final cancel = find.byKey(const ValueKey('voice-target-cancel'));
      final edit = find.byKey(const ValueKey('voice-target-revise'));
      final left = tester.getCenter(cancel);
      final right = tester.getCenter(edit);
      final words = List.filled(30, '请把项目会议调整到下午').join('，');
      input.emit(id, SpeechEventKind.partial, text: words);
      await tester.pumpAndSettle();
      expect(tester.getCenter(cancel), left);
      expect(tester.getCenter(edit), right);
      expect(tester.getSize(cancel).height, greaterThanOrEqualTo(44));
      await gesture.moveTo(Offset((left.dx + right.dx) / 2, left.dy - 10));
      await tester.pump();
      expect(find.text('松开发送'), findsOneWidget);
      expect(find.byTooltip('选择模型'), findsNothing);
      expect(find.text(words), findsOneWidget);
      await gesture.moveTo(left);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(sent, isEmpty);
    },
  );

  testWidgets('curved wings select at the outer edges and commit on release', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mount(tester);
    final gesture = await tester.startGesture(tester.getCenter(voice));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
    final panel = tester.getRect(
      find.byKey(const ValueKey('voice-live-panel')),
    );
    final geometry = VoiceGestureGeometry(panel.size);
    final edgeY = panel.top + geometry.crest - .03 * geometry.unit;
    await gesture.moveTo(Offset(panel.left + 3, panel.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('松开发送'), findsOneWidget);
    await gesture.moveTo(Offset(panel.left + 3, edgeY));
    await tester.pumpAndSettle();
    expect(find.text('松开取消'), findsOneWidget);
    final id = input.starts.single;
    input.emit(id, SpeechEventKind.finalResult, text: '下午开会');
    await tester.pump();
    await gesture.moveTo(Offset(panel.right - 3, edgeY));
    await tester.pump();
    expect(find.text('松开编辑'), findsOneWidget);
    expect(text.text, isEmpty);
    expect(sent, isEmpty);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(text.text, '下午开会');
    expect(sent, isEmpty);
    semantics.dispose();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('voice recording follows the $mode palette across gestures', (
      tester,
    ) async {
      await mount(tester, themeMode: mode);
      final colors = mode == ThemeMode.light ? AppColors.light : AppColors.dark;
      final gesture = await tester.startGesture(tester.getCenter(voice));
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pumpAndSettle();
      final transcript = find.byKey(const ValueKey('voice-live-text'));
      final container = find
          .ancestor(of: transcript, matching: find.byType(Container))
          .first;
      Color bubbleColor() =>
          (tester.widget<Container>(container).decoration! as BoxDecoration)
              .color!;
      expect(bubbleColor(), colors.brand);
      expect(tester.widget<Text>(transcript).style!.color, colors.onBrand);
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('voice-target-cancel'))),
      );
      await tester.pump();
      expect(bubbleColor(), colors.overdueSurface);
      expect(
        tester.widget<Text>(transcript).style!.color,
        colors.overdueForeground,
      );
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('voice-target-revise'))),
      );
      await tester.pump();
      expect(bubbleColor(), colors.brand);
      expect(tester.widget<Text>(find.text('编辑')).style!.color, colors.onBrand);
      await gesture.cancel();
      await tester.pumpAndSettle();
    });
  }

  testWidgets('keyboard Space holds and releases the same capture', (
    tester,
  ) async {
    await mount(tester);
    final pointer = find
        .descendant(of: voice, matching: find.byType(GestureDetector))
        .first;
    Focus.of(tester.element(pointer)).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    final id = input.starts.single;
    expect(input.stops, isEmpty);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(input.stops, [id]);
    input.emit(id, SpeechEventKind.finalResult, text: '空格键录音');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(sent, [('空格键录音', id)]);
  });

  testWidgets('screen reader can explicitly start and stop dictation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mount(tester);
    tester
        .getSemantics(voice)
        .owner!
        .performAction(tester.getSemantics(voice).id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    final id = input.starts.single;
    expect(input.stops, isEmpty);
    expect(tester.getSemantics(voice).label, '正在录音');
    expect(tester.getSemantics(voice).hint, '激活结束录音，识别后发送');
    tester
        .getSemantics(voice)
        .owner!
        .performAction(tester.getSemantics(voice).id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(input.stops, [id]);
    expect(tester.getSemantics(voice).label, '正在识别语音');
    expect(
      tester
          .getSemantics(voice)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    input.emit(id, SpeechEventKind.finalResult, text: '待发送文字');
    await tester.pump();
    expect(tester.getSemantics(voice).label, '语音待发送');
    expect(
      tester
          .getSemantics(voice)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    await tester.tap(find.byTooltip('取消语音输入'));
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('hold releases inline and sends only after a real final', (
    tester,
  ) async {
    await mount(tester);
    final gesture = await tester.startGesture(tester.getCenter(voice));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    final id = input.starts.single;
    expect(input.stops, isEmpty);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(input.stops, [id]);
    expect(sent, isEmpty);
    noModal();
    input.emit(id, SpeechEventKind.finalResult, text: '按住说话');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(sent, [('按住说话', id)]);
    noModal();
  });
  testWidgets(
    'release before permission resolves cannot start a late recording',
    (tester) async {
      input.prepareGate = Completer();
      await mount(tester);
      final gesture = await tester.startGesture(tester.getCenter(voice));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.up();
      await tester.pump();
      input.prepareGate!.complete(input.capabilities);
      await tester.pumpAndSettle();
      expect(input.starts, isEmpty);
      expect(sent, isEmpty);
      noModal();
    },
  );
  testWidgets(
    'held recording streams live partials; slide-up revises into text',
    (tester) async {
      await mount(tester);
      final gesture = await tester.startGesture(tester.getCenter(voice));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      final id = input.starts.single;
      input.emit(id, SpeechEventKind.partial, text: '帮我记');
      await tester.pump();
      expect(find.byKey(const ValueKey('voice-live-text')), findsOneWidget);
      expect(find.text('帮我记'), findsOneWidget);
      input.emit(id, SpeechEventKind.partial, text: '帮我记一条待办');
      await tester.pump();
      expect(find.text('帮我记一条待办'), findsOneWidget);
      // 上滑进入修改区：提示切换，松开后转写落进输入框且不发送。
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('voice-target-revise'))),
      );
      await tester.pump();
      expect(find.text('松开编辑'), findsOneWidget);
      await gesture.up();
      await tester.pump();
      expect(input.stops, [id]);
      input.emit(id, SpeechEventKind.finalResult, text: '帮我记一条待办，明天开会');
      await tester.pumpAndSettle();
      expect(text.text, '帮我记一条待办，明天开会');
      expect(focus.hasFocus, isTrue);
      expect(sent, isEmpty);
      input.emit(id, SpeechEventKind.finalResult, text: '迟到的最终');
      await tester.pump(const Duration(seconds: 3));
      expect(sent, isEmpty);
      noModal();
    },
  );
  testWidgets('slide far up cancels outright and rejects late final', (
    tester,
  ) async {
    await mount(tester);
    final gesture = await tester.startGesture(tester.getCenter(voice));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    final id = input.starts.single;
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('voice-target-cancel'))),
    );
    await tester.pump();
    expect(find.text('松开取消'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    input.emit(id, SpeechEventKind.finalResult, text: '取消');
    await tester.pump(const Duration(seconds: 3));
    expect(sent, isEmpty);
    expect(text.text, isEmpty);
    expect(input.cancels, contains(id));
    noModal();
  });
  testWidgets('switch to keyboard preserves transcript and cancels auto-send', (
    tester,
  ) async {
    await mount(tester);
    await start(tester);
    input.emit(input.starts.single, SpeechEventKind.finalResult, text: '可编辑草稿');
    await tester.pump();
    await tester.tap(keyboard);
    await tester.pump(const Duration(seconds: 3));
    expect(text.text, '可编辑草稿');
    expect(sent, isEmpty);
    expect(find.byType(TextField), findsOneWidget);
    noModal();
  });
  testWidgets('system gesture interruption keeps partial transcript', (
    tester,
  ) async {
    await mount(tester);
    final gesture = await tester.startGesture(tester.getCenter(voice));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    final id = input.starts.single;
    input.emit(id, SpeechEventKind.partial, text: '来电前已说的话');
    await tester.pump();
    // 系统打断（来电、通知下拉）触发 onLongPressCancel：不是用户取消，
    // 已识别的 partial 前缀应按草稿保留，而不是整体丢弃。
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(text.text, '来电前已说的话');
    expect(sent, isEmpty);
    expect(input.cancels, contains(id));
    noModal();
  });
  testWidgets(
    'permission failure shows one toast and immediately restores input',
    (tester) async {
      input.capabilities = SpeechCapabilities(
        available: true,
        authorized: false,
        locales: [],
        onDeviceSupported: true,
      );
      await mount(tester);
      await start(tester);
      expect(input.starts, isEmpty);
      expect(find.text('请在系统设置中允许麦克风权限'), findsOneWidget);
      expect(find.text('按住说话'), findsOneWidget);
      noModal();
    },
  );
  testWidgets('no result shows a toast without a retry panel', (tester) async {
    await mount(tester);
    await start(tester);
    input.emit(
      input.starts.single,
      SpeechEventKind.error,
      error: SpeechFailureCode.noResult,
    );
    await tester.pumpAndSettle();
    expect(find.text('没有听清，请再说一次'), findsOneWidget);
    expect(find.text('按住说话'), findsOneWidget);
    noModal();
    // A new user gesture can record again after the failure.
    await start(tester);
    expect(input.starts, hasLength(2));
    await tester.tap(find.byTooltip('取消语音输入'));
    await tester.pumpAndSettle();
  });
  testWidgets('connectivity misreport does not block the send', (tester) async {
    await mount(tester, online: false);
    await start(tester);
    input.emit(input.starts.single, SpeechEventKind.finalResult, text: '离线草稿');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    // 网络预检在部分 ROM 上误报 none：不再拦截，照常提交，
    // 真实网络错误由请求层处理。
    expect(sent, [('离线草稿', input.starts.single)]);
    expect(find.text('按住说话'), findsOneWidget);
    noModal();
  });
  testWidgets('background cancels pending send and retains text', (
    tester,
  ) async {
    await mount(tester);
    await start(tester);
    input.emit(input.starts.single, SpeechEventKind.finalResult, text: '中断草稿');
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(sent, isEmpty);
    expect(text.text, '中断草稿');
    noModal();
  });
  testWidgets(
    'diagnostics only inspects without recording or requesting permission',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [speechInputProvider.overrideWithValue(input)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: SpeechDiagnosticsSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('识别服务：可用'), findsOneWidget);
      expect(input.inspections, 1);
      expect(input.preparations, 0);
      expect(input.starts, isEmpty);
    },
  );
}
