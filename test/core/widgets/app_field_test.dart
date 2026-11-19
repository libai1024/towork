import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/core/widgets/app_field_label.dart';
import 'package:towork/core/widgets/app_inline_input.dart';
import 'package:towork/theme/app_text_styles.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  for (final mode in [Brightness.light, Brightness.dark]) {
    testWidgets('field label, focus and errors at large type in $mode', (
      tester,
    ) async {
      final theme = mode == Brightness.light ? AppTheme.light : AppTheme.dark;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
              child: const SizedBox(
                width: 300,
                child: AppFieldLabel(
                  label: '接口地址',
                  child: TextField(
                    decoration: InputDecoration(errorText: '请填写完整地址'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final field = find.byType(TextField);
      await tester.enterText(field, 'https://example.org');
      await tester.pumpAndSettle();
      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      expect(decorator.isFocused, isTrue);
      expect(decorator.decoration.labelText, isNull);
      expect(
        decorator.decoration.focusedErrorBorder!.borderSide.color,
        theme.colorScheme.error,
      );
      expect(
        tester.getBottomLeft(find.text('接口地址')).dy,
        lessThan(tester.getTopLeft(field).dy),
      );
      expect(find.bySemanticsLabel(RegExp('接口地址')), findsOneWidget);
      expect(find.text('请填写完整地址'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('inline editor keeps its existing surface on focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TextField(
            decoration: appInlineInput(
              hintText: '搜索',
              hintStyle: AppTextStyles.body,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    final decoration = tester
        .widget<InputDecorator>(find.byType(InputDecorator))
        .decoration;
    expect(decoration.filled, isFalse);
    expect(decoration.enabledBorder, InputBorder.none);
    expect(decoration.focusedBorder, InputBorder.none);
  });
}
