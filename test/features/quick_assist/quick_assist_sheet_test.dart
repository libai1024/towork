import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/features/quick_assist/quick_assist_sheet.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  final card = find.byKey(const ValueKey('quick-assist-card'));
  final outside = find.byKey(const ValueKey('quick-assist-outside'));

  Future<GlobalKey<QuickAssistSheetState>> mount(
    WidgetTester tester, {
    bool reduceMotion = false,
    double keyboard = 0,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: reduceMotion);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final key = GlobalKey<QuickAssistSheetState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: QuickAssistSheet(
          key: key,
          header: const SizedBox(height: 48),
          body: const Center(child: Text('快问')),
          onDismiss: () {},
        ),
      ),
    );
    return key;
  }

  void expectTransparentBackground(WidgetTester tester) {
    expect(tester.widget<GestureDetector>(outside).child, isNull);
    expect(
      find.descendant(
        of: find.byType(QuickAssistSheet),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
  }

  testWidgets('第一帧在屏幕底部之外，卡片全宽垂直滑入且背景保持透明', (tester) async {
    await mount(tester);
    expect(tester.getRect(card).top, greaterThanOrEqualTo(844));
    expectTransparentBackground(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final entering = tester.getRect(card);
    expect(entering.top, lessThan(844));
    expect(entering.bottom, greaterThan(836));
    expect(entering.left, 8);
    expect(entering.right, 382);
    expectTransparentBackground(tester);
    await tester.pumpAndSettle();
    expect(tester.getRect(card).bottom, 836);
    expectTransparentBackground(tester);
  });

  testWidgets('键盘打开时离场滑到屏幕底部，背景保持透明', (tester) async {
    final key = await mount(tester, keyboard: 300);
    await tester.pumpAndSettle();
    final top = tester.getRect(card).top;
    final leaving = key.currentState!.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.getRect(card).top, greaterThan(top));
    expectTransparentBackground(tester);
    await tester.pumpAndSettle();
    expect(await leaving, isTrue);
    expect(tester.getRect(card).top, greaterThanOrEqualTo(844));
    expectTransparentBackground(tester);
  });

  testWidgets('减少动画时立即显示、隐藏与重新显示', (tester) async {
    final key = await mount(tester, reduceMotion: true);
    expect(tester.getRect(card).bottom, 836);
    expectTransparentBackground(tester);
    expect(await key.currentState!.dismiss(), isTrue);
    await tester.pump();
    expect(tester.getRect(card).top, greaterThanOrEqualTo(844));
    expectTransparentBackground(tester);
    key.currentState!.show();
    await tester.pump();
    expect(tester.getRect(card).bottom, 836);
    expectTransparentBackground(tester);
  });

  testWidgets('离场途中再次唤起会结束旧关闭请求并滑回半屏', (tester) async {
    final key = await mount(tester);
    await tester.pumpAndSettle();
    final leaving = key.currentState!.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    key.currentState!.show();
    expect(await leaving, isFalse);
    await tester.pumpAndSettle();
    expect(tester.getRect(card).bottom, 836);
    expectTransparentBackground(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('离场途中销毁会完成关闭请求', (tester) async {
    final key = await mount(tester);
    await tester.pumpAndSettle();
    final leaving = key.currentState!.dismiss();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(await leaving, isFalse);
    expect(tester.takeException(), isNull);
  });
}
