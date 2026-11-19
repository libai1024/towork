import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/features/settings/settings_page.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  testWidgets('AI write permission options remain inside their phone sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('AI 写入权限'));
    await tester.tap(find.text('AI 写入权限'));
    await tester.pumpAndSettle();
    final sheet = tester.getRect(find.byType(BottomSheet));
    for (final label in ['总是询问', '智能确认', '自动执行']) {
      final option = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(label),
      );
      expect(option, findsOneWidget);
      final rect = tester.getRect(option);
      expect(sheet.contains(rect.topLeft), isTrue, reason: label);
      expect(sheet.contains(rect.bottomRight), isTrue, reason: label);
    }
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('总是询问'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('AI 写入权限已设为「总是询问」'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
