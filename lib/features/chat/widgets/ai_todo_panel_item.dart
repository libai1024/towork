import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/todo/todo_checkbox.dart';
import '../../../core/todo/todo_utils.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class AiTodoPanelItem extends StatelessWidget {
  const AiTodoPanelItem({
    super.key,
    required this.todo,
    required this.now,
    required this.busy,
    required this.onToggle,
    required this.onEdit,
  });

  final Todo todo;
  final DateTime now;
  final bool busy;
  final VoidCallback onToggle, onEdit;

  static TextStyle _title(BuildContext context, Todo todo) {
    final c = AppColors.of(context);
    return AppTextStyles.footnote.copyWith(
      inherit: false,
      color: todo.isActive ? c.labelPrimary : c.labelSecondary,
      decoration: todo.isActive ? null : TextDecoration.lineThrough,
    );
  }

  static TextSpan _metadata(BuildContext context, Todo todo, DateTime now) {
    final c = AppColors.of(context);
    final parts = <TextSpan>[
      if (!todo.isActive || todo.status == TodoStatus.inProgress)
        TextSpan(
          text: todo.status.label,
          style: TextStyle(
            color: todo.status == TodoStatus.done ? c.green : c.labelSecondary,
          ),
        ),
      if (todo.isActive && todo.priority != TodoPriority.none)
        TextSpan(
          text: todo.priority.label,
          style: TextStyle(
            color: todo.priority == TodoPriority.urgent
                ? c.accentText
                : c.labelSecondary,
          ),
        ),
      if (todo.dueAt != null)
        TextSpan(
          text: dueBadgeLabel(todo, now),
          style: TextStyle(
            color: todo.isOverdue(now) ? c.overdueForeground : c.labelSecondary,
          ),
        ),
    ];
    return TextSpan(
      style: AppTextStyles.caption.copyWith(
        inherit: false,
        color: c.labelSecondary,
      ),
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) const TextSpan(text: ' '),
          parts[i],
        ],
      ],
    );
  }

  /// The same text metrics reserve the largest five-item page for every group.
  static double heightFor(
    BuildContext context,
    double width,
    Todo todo,
    DateTime now,
  ) {
    double measure(TextSpan text) {
      final painter = TextPainter(
        text: text,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
      )..layout(maxWidth: math.max(1, width - 48));
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final title = measure(
      TextSpan(text: todo.title, style: _title(context, todo)),
    );
    final metadata = _metadata(context, todo, now);
    final detailHeight = metadata.children!.isEmpty ? 0 : measure(metadata) + 1;
    return math.max(48, (title + detailHeight + 8).ceilToDouble());
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final done = todo.status == TodoStatus.done;
    final metadata = _metadata(context, todo, now);
    return AnimatedOpacity(
      opacity: busy ? .5 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 150),
      child: Row(
        children: [
          TodoCheckbox(
            size: 18,
            checked: done,
            checkedColor: c.green,
            onTap: busy || todo.status == TodoStatus.cancelled
                ? null
                : onToggle,
            semanticLabel: '${done ? '恢复' : '完成'}待办：${todo.title}',
          ),
          Expanded(
            child: AppPressable(
              minSize: 48,
              onTap: busy ? null : onEdit,
              semanticLabel: '编辑待办：${todo.title}',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      style: _title(context, todo),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      child: Text(todo.title),
                    ),
                    if (metadata.children!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text.rich(metadata, style: metadata.style),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
