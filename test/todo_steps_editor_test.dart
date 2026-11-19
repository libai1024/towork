import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/core/todo/todo_steps_editor.dart';
import 'package:towork/domain/models/todo.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  testWidgets(
    'earliest open step follows order, rename and out-of-order checks',
    (tester) async {
      var steps = <TodoStep>[
        const TodoStep(id: 'a', title: '核对'),
        const TodoStep(id: 'b', title: '提交'),
        const TodoStep(id: 'c', title: '归档'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: StatefulBuilder(
                  builder: (context, setState) => TodoStepsEditor(
                    steps: steps,
                    onEdit: (edit) async {
                      setState(() => steps = edit.apply(steps));
                      return true;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final next = find.bySemanticsLabel(RegExp('下一步'));
      expect(tester.getSemantics(next).label, contains('核对'));
      await tester.tap(find.byKey(const ValueKey('c')));
      await tester.pumpAndSettle();
      expect(steps.last.done, isTrue);
      await tester.tap(find.text('整理'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('上移第2步'));
      await tester.pumpAndSettle();
      expect(steps.map((s) => s.id), ['b', 'a', 'c']);
      await tester.tap(find.text('核对'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('step-input')),
        '核对全部票据',
      );
      await tester.tap(find.byTooltip('保存步骤'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('完成整理'));
      await tester.pumpAndSettle();
      expect(steps[1].title, '核对全部票据');
      expect(tester.getSemantics(next).label, contains('提交'));
      expect(steps.last.done, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
