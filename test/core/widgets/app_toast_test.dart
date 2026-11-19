import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  testWidgets('undo is reachable at the edge of a full touch target', (
    tester,
  ) async {
    var restored = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppToast.show(
                context,
                message: '已删除任务',
                actionLabel: '撤销',
                onAction: () => restored++,
              ),
              child: const Text('删除'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('toast-action'));
    final bounds = tester.getRect(action);
    expect(bounds.width, greaterThanOrEqualTo(44));
    expect(bounds.height, greaterThanOrEqualTo(44));
    await tester.tapAt(bounds.topLeft + const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(restored, 1);
    expect(find.text('已删除任务'), findsNothing);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    final dismiss = find.byKey(const ValueKey('toast-dismiss'));
    expect(tester.getSize(dismiss), const Size(44, 44));
    await tester.tap(dismiss);
    await tester.pumpAndSettle();
    expect(find.text('已删除任务'), findsNothing);
    expect(restored, 1, reason: 'Dismissing feedback must not undo the action');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a presenter becomes harmless after its root overlay closes', (
    tester,
  ) async {
    late ValueChanged<String> oldPresenter;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              oldPresenter = AppToast.presenter(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    late ValueChanged<String> currentPresenter;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              currentPresenter = AppToast.presenter(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    currentPresenter('当前应用的提示');
    await tester.pumpAndSettle();
    oldPresenter('已关闭应用的提示');
    await tester.pumpAndSettle();
    expect(find.text('当前应用的提示'), findsOneWidget);
    expect(find.text('已关闭应用的提示'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'an action may replace its toast without dismissing the new feedback',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppToast.show(
                  context,
                  message: '已修改',
                  actionLabel: '撤销',
                  onAction: () => AppToast.show(context, message: '内容已变化，无法撤销'),
                ),
                child: const Text('执行'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('执行'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('撤销'));
      await tester.pumpAndSettle();
      expect(find.text('内容已变化，无法撤销'), findsOneWidget);
      expect(find.text('已修改'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('内容已变化，无法撤销'), findsNothing);
    },
  );
}
