import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/main.dart';

/// 外观字号倍数必须「叠加」在系统文字缩放之上：
/// 系统级大字号（如 1.5）不因应用内选了某个档位而被整体替换。
void main() {
  testWidgets('app font scale multiplies the system text scaler', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ToWorkApp)),
    );

    double effectiveScale() => MediaQuery.textScalerOf(
      tester.element(find.byKey(const ValueKey('home-greeting'))),
    ).scale(100);

    // 默认「标准 1.0」：系统 1.5 完整保留（修复前会被替换成 1.0）。
    expect(effectiveScale(), closeTo(150, 0.001));
    // 「大 1.15」：150 × 1.15。
    container.read(fontScaleProvider.notifier).state = 1.15;
    await tester.pump();
    expect(effectiveScale(), closeTo(150 * 1.15, 0.001));
    // 「小 0.9」：150 × 0.9，同样不丢系统缩放。
    container.read(fontScaleProvider.notifier).state = 0.9;
    await tester.pump();
    expect(effectiveScale(), closeTo(150 * 0.9, 0.001));
  });
}
