import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/core/categories/widgets/category_action_sheets.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  for (final confirm in [false, true]) {
    testWidgets(
      'empty category shows template impact at 2x text, confirm=$confirm',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        CategoryDeleteStrategy? result;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showCategoryDeleteConfirm(
                      context,
                      name: '重复项目',
                      todoCount: 0,
                      childCount: 0,
                      seriesCount: 2,
                      detachedCount: 3,
                    );
                  },
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('打开'));
        await tester.pumpAndSettle();
        expect(find.text('里面有2 个重复系列。'), findsOneWidget);
        expect(find.textContaining('子分类的系列保留原分类'), findsOneWidget);
        final deleteAll = find.text('待办与子分类一并删除');
        await tester.ensureVisible(deleteAll);
        await tester.pumpAndSettle();
        await tester.tap(deleteAll);
        await tester.pumpAndSettle();
        expect(find.textContaining('3 条待办保留，并取消重复'), findsOneWidget);
        final button = find.text(confirm ? '删除' : '取消');
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(result, confirm ? CategoryDeleteStrategy.deleteAll : isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
