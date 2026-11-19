import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/core/todo/todo_item.dart';
import 'package:towork/theme/app_theme.dart';

Todo _todo(TodoStatus status) => Todo(
  id: 't_$status',
  title: status == TodoStatus.done ? '已完成项' : '未完成项',
  status: status,
  createdAt: DateTime(2026, 9, 24),
  updatedAt: DateTime(2026, 9, 24),
);

void main() {
  testWidgets('completed todo title renders strikethrough and dimmed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              for (final status in [TodoStatus.done, TodoStatus.pending])
                TodoListItem(todo: _todo(status), now: DateTime(2026, 9, 25)),
            ],
          ),
        ),
      ),
    );
    final doneFinder = find.text('已完成项');
    expect(doneFinder, findsOneWidget);
    final style = DefaultTextStyle.of(tester.element(doneFinder)).style;
    expect(style.decoration, TextDecoration.lineThrough, reason: '完成态需删除线');
    final openStyle = DefaultTextStyle.of(tester.element(find.text('未完成项')))
        .style;
    expect(openStyle.decoration, isNull, reason: '未完成不应有删除线');
    // 完成态使用次要文字色，保持其余元信息的对比度。
    expect(
      style.color!.computeLuminance(),
      greaterThan(openStyle.color!.computeLuminance()),
      reason: '完成态文字应比未完成更淡（置灰）',
    );
    final fadedAncestors = tester
        .widgetList<Opacity>(
          find.ancestor(of: doneFinder, matching: find.byType(Opacity)),
        )
        .where((widget) => widget.opacity < 1);
    expect(fadedAncestors, isEmpty, reason: '完成态只调整文字样式，保留元信息对比度');
  });
}
