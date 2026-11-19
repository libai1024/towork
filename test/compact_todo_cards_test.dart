import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/features/chat/widgets/chat_messages.dart';
import 'package:towork/core/todo/todo_checkbox.dart';
import 'package:towork/core/todo/todo_item.dart';
import 'package:towork/core/todo/todo_summary.dart';
import 'package:towork/theme/app_colors.dart';
import 'package:towork/theme/app_theme.dart';

final _now = DateTime(2026, 9, 24, 12);
final _todo = Todo(
  id: 'compact',
  title: '整理本周项目进展',
  createdAt: _now,
  dueAt: DateTime(2026, 9, 24, 17),
  source: TodoSource.ai,
);
const _category = Category(id: 'work', name: '工作', color: Color(0xFF32ADE6));

Widget _host(
  Widget child, {
  double width = 360,
  double scale = 1,
  bool reduceMotion = false,
  bool dark = false,
}) {
  return MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 900),
        textScaler: TextScaler.linear(scale),
        disableAnimations: reduceMotion,
      ),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

Finder _action(String label) => find.byWidgetPredicate(
  (widget) => widget is AppPressable && widget.semanticLabel == label,
);

void main() {
  testWidgets(
    'created result keeps feedback and accessible actions inside one compact card',
    (tester) async {
      var edits = 0;
      var undos = 0;
      await tester.pumpWidget(
        _host(
          AiTodoCard(
            todo: _todo.copyWith(dueAt: DateTime(2099, 1, 1, 17)),
            category: _category,
            onEdit: () => edits++,
            onUndo: () => undos++,
          ),
        ),
      );
      final card = find.byKey(const ValueKey('created-todo-content'));
      expect(
        find.descendant(of: card, matching: find.text('已创建')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.byType(AppPressable)),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: card, matching: find.text(_todo.title)),
        findsOneWidget,
      );
      expect(find.text('AI'), findsNothing);
      expect(
        tester.getSize(find.byType(AiTodoCard)).height,
        lessThanOrEqualTo(108),
      );
      for (final label in ['修改待办', '撤销待办']) {
        final rect = tester.getRect(_action(label));
        expect(rect.width, greaterThanOrEqualTo(44));
        expect(rect.height, greaterThanOrEqualTo(44));
        expect(find.byTooltip(label), findsOneWidget);
        await tester.tapAt(rect.topLeft + const Offset(3, 3));
        await tester.pump();
      }
      expect(edits, 1);
      expect(undos, 1);
    },
  );

  testWidgets(
    'list and board retain compact density and separate source/completion actions',
    (tester) async {
      var completions = 0;
      var sources = 0;
      var opened = 0;
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TodoListItem(
                todo: _todo,
                now: _now,
                categoryLabel: _category.name,
                categoryColor: _category.color,
                onTap: () => opened++,
                onToggleDone: () => completions++,
                onAiSourceTap: () => sources++,
              ),
              TodoBoardCard(
                todo: _todo,
                now: _now,
                categoryLabel: _category.name,
                categoryColor: _category.color,
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(TodoListItem)).height,
        lessThanOrEqualTo(58),
      );
      expect(
        tester.getSize(find.byType(TodoBoardCard)).height,
        lessThanOrEqualTo(64),
      );
      final source = tester.getRect(_action('查看待办来源会话'));
      expect(source.size, const Size(44, 44));
      await tester.tapAt(source.bottomRight - const Offset(3, 3));
      await tester.pump();
      await tester.tap(find.byType(TodoCheckbox).first);
      await tester.pump();
      expect(sources, 1);
      expect(completions, 1);
      expect(opened, 0);
    },
  );

  testWidgets(
    'narrow cards grow for large text without clipping deadline or actions',
    (tester) async {
      final long = _todo.copyWith(
        title: '整理本周项目进展并核对全部附件资料',
        priority: TodoPriority.urgent,
      );
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: Column(
              children: [
                AiTodoCard(
                  todo: long,
                  category: _category,
                  onEdit: () {},
                  onUndo: () {},
                ),
                TodoListItem(
                  todo: long,
                  now: _now,
                  categoryLabel: '工作/项目资料',
                  onAiSourceTap: () {},
                ),
                TodoBoardCard(todo: long, now: _now, categoryLabel: '工作/项目资料'),
              ],
            ),
          ),
          width: 280,
          scale: 2.5,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(TodoListItem)).height, greaterThan(58));
      expect(
        tester
            .widgetList<Text>(find.text(long.title))
            .every((text) => text.maxLines == null),
        isTrue,
      );
      expect(tester.getSize(_action('修改待办')), const Size(48, 48));
    },
  );

  testWidgets(
    'only overdue information uses warning color and completion clears it',
    (tester) async {
      for (final dark in [false, true]) {
        final colors = dark ? AppColors.dark : AppColors.light;
        final overdue = _todo.copyWith(
          dueAt: _now.subtract(const Duration(hours: 1)),
        );
        for (final todo in [
          _todo,
          overdue,
          overdue.copyWith(status: TodoStatus.done),
        ]) {
          await tester.pumpWidget(
            _host(
              TodoSummary(todo: todo, now: _now),
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          final deadline = tester.widget<Text>(
            find.descendant(
              of: find.byType(DueBadge),
              matching: find.byType(Text),
            ),
          );
          expect(
            deadline.style!.color,
            todo.isOverdue(_now)
                ? colors.overdueForeground
                : colors.labelSecondary,
          );
          expect(
            find.byIcon(LucideIcons.circleAlert),
            todo.isOverdue(_now) ? findsOneWidget : findsNothing,
          );
        }
      }
    },
  );

  testWidgets('revealed swipe actions remain tappable above dismiss region', (
    tester,
  ) async {
    var reschedules = 0;
    var deletes = 0;
    await tester.pumpWidget(
      _host(
        TodoSwipeRow(
          onReschedule: () => reschedules++,
          onDelete: () => deletes++,
          child: TodoListItem(todo: _todo, now: _now),
        ),
      ),
    );
    await tester.drag(find.byType(TodoSwipeRow), const Offset(-120, 0));
    await tester.pumpAndSettle();
    await tester.tap(_action('改期待办'));
    await tester.pumpAndSettle();
    expect(reschedules, 1);
    expect(deletes, 0);
    await tester.drag(find.byType(TodoSwipeRow), const Offset(-120, 0));
    await tester.pumpAndSettle();
    await tester.tap(_action('删除待办'));
    await tester.pumpAndSettle();
    expect(deletes, 1);
  });

  testWidgets('swipe actions are reachable without swiping (a11y)', (
    tester,
  ) async {
    // 读屏用户无法完成横滑：合并后的行节点直接暴露
    // 完成/改期/删除 自定义操作；键盘焦点在行上时 Delete 直接删除。
    var completes = 0;
    var reschedules = 0;
    var deletes = 0;
    await tester.pumpWidget(
      _host(
        TodoSwipeRow(
          isDone: false,
          onComplete: () => completes++,
          onReschedule: () => reschedules++,
          onDelete: () => deletes++,
          child: TodoListItem(todo: _todo, now: _now, onTap: () {}),
        ),
      ),
    );
    final semantics = tester.ensureSemantics();
    final node = tester.getSemantics(find.byType(TodoListItem));
    final data = node.getSemanticsData();
    final ids = data.customSemanticsActionIds ?? const <int>[];
    final labels = [
      for (final id in ids) CustomSemanticsAction.getAction(id)!.label,
    ];
    expect(labels, containsAll(['完成待办', '改期待办', '删除待办']));

    void invoke(String label) => node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      ids[labels.indexOf(label)],
    );

    // 读屏自定义操作与滑出按钮调用的是同一回调。
    invoke('删除待办');
    expect(deletes, 1);
    invoke('改期待办');
    expect(reschedules, 1);
    invoke('完成待办');
    expect(completes, 1);

    // 键盘路径：行获得焦点后按 Delete 删除。
    Focus.maybeOf(tester.element(find.text(_todo.title)))!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(deletes, 2);
    semantics.dispose();
  });

  testWidgets('checkbox completion settles instantly with reduce motion', (
    tester,
  ) async {
    // 减弱动态效果：完成态填充/描边瞬时切换，不再排 150ms 补间帧。
    await tester.pumpWidget(
      _host(TodoCheckbox(checked: false, onTap: () {}), reduceMotion: true),
    );
    await tester.pumpWidget(
      _host(TodoCheckbox(checked: true, onTap: () {}), reduceMotion: true),
    );
    await tester.pump();
    expect(
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).duration,
      Duration.zero,
    );
    expect(find.byIcon(LucideIcons.check), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'thinking and streaming stop animation when reduce motion changes',
    (tester) async {
      final message = ChatMessage(
        id: 'stream',
        sessionId: 'session',
        role: ChatRole.assistant,
        type: ChatMessageType.text,
        content: '正在整理',
        createdAt: _now,
      );
      Widget content({bool streaming = true}) => Column(
        children: [
          const TypingDots(),
          AiTextMessage(message: message, streaming: streaming),
        ],
      );
      await tester.pumpWidget(_host(content()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpWidget(_host(content(), reduceMotion: true));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.textSpan?.toPlainText().startsWith('正在整理') ?? false),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(_host(content()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpWidget(_host(AiTextMessage(message: message)));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}
