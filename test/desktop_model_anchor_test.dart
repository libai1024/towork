import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/main.dart';

void main() {
  Future<void> mount(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 820);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
    await tester.pumpAndSettle();
  }

  void expectAnchored(WidgetTester tester) {
    final trigger = tester.getRect(find.byTooltip('选择模型'));
    final panel = tester.getRect(find.byKey(const ValueKey('model-picker')));
    expect(panel.left, closeTo(trigger.left, .1));
    final below = (panel.top - trigger.bottom - 8).abs() < .1;
    final above = (panel.bottom - trigger.top + 8).abs() < .1;
    expect(below || above, isTrue, reason: 'menu follows composer anchor');
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'desktop model menu follows its actual button with either sidebar',
    (tester) async {
      await mount(tester);
      await tester.tap(find.byTooltip('选择模型'));
      await tester.pumpAndSettle();
      expectAnchored(tester);
      await tester.tap(find.byKey(const ValueKey('provider-platform')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('快速'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('收起侧栏'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('选择模型'));
      await tester.pumpAndSettle();
      expectAnchored(tester);
    },
  );

  testWidgets('open model menu follows its button across window breakpoints', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byTooltip('选择模型'));
    await tester.pumpAndSettle();
    for (final size in [
      const Size(760, 820),
      const Size(899, 820),
      const Size(900, 820),
      const Size(1399, 820),
      const Size(1400, 820),
      const Size(1600, 820),
      const Size(760, 820),
      const Size(1280, 820),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expectAnchored(tester);
    }
  });

  testWidgets('open menu tracks nested navigator bounds when sidebar toggles', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byTooltip('选择模型'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('收起侧栏'));
    await tester.pumpAndSettle();
    expectAnchored(tester);
    await tester.tap(find.byTooltip('展开侧栏'));
    await tester.pumpAndSettle();
    expectAnchored(tester);
    await tester.tap(find.byKey(const ValueKey('provider-platform')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('快速'));
    await tester.pumpAndSettle();
    expect(find.text('快速'), findsOneWidget);
    expect(find.byKey(const ValueKey('model-picker')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
