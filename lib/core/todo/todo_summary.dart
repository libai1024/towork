import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_text_styles.dart';
import 'todo_utils.dart';

/// 紧凑截止信息。只有逾期使用警示色，不为普通日期增加色块。
class DueBadge extends StatelessWidget {
  const DueBadge({super.key, required this.todo, required this.now});

  final Todo todo;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final label = dueBadgeLabel(todo, now);
    if (label.isEmpty) return const SizedBox.shrink();
    final tone = dueToneOf(todo, now);
    final overdue = tone == DueTone.overdue;
    final foreground = overdue ? c.overdueForeground : c.labelSecondary;
    return Text.rich(
      TextSpan(
        children: [
          if (overdue)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Icon(
                  LucideIcons.circleAlert,
                  size: 12,
                  color: foreground,
                ),
              ),
            ),
          TextSpan(text: label),
        ],
      ),
      style: AppTextStyles.caption.copyWith(color: foreground),
    );
  }
}

/// 优先级靠旗帜和文字表达，避免与逾期的警示红竞争。
class PriorityFlag extends StatelessWidget {
  const PriorityFlag({
    super.key,
    required this.priority,
    this.emphasize = false,
  });

  final TodoPriority priority;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    if (priority == TodoPriority.none) return const SizedBox.shrink();
    final c = AppColors.of(context);
    final color = emphasize && priority == TodoPriority.urgent
        ? c.accentText
        : c.labelSecondary;
    final withText =
        priority == TodoPriority.urgent || priority == TodoPriority.high;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.flag, size: 12, color: color),
        if (withText) ...[
          const SizedBox(width: 2),
          Text(
            priority.label,
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ],
      ],
    );
  }
}

/// 可复用的待办信息主体；对话结果、列表与看板采用相同的信息密度。
///
/// 标题独占可用宽度，日期、分类与优先级在下面自然换行；不固定高度，
/// 以便窄屏和大字号仍完整显示日期。
class TodoSummary extends StatelessWidget {
  const TodoSummary({
    super.key,
    required this.todo,
    required this.now,
    this.categoryLabel,
    this.categoryColor,
    this.plainCategory = false,
    this.statusLabel,
    this.compact = false,
  });

  final Todo todo;
  final DateTime now;
  final String? categoryLabel;
  final String? statusLabel;
  final Color? categoryColor;
  final bool plainCategory;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final inactive = !todo.isActive;
    final hasMetadata =
        todo.steps.isNotEmpty ||
        statusLabel != null ||
        todo.dueAt != null ||
        categoryLabel != null ||
        todo.priority != TodoPriority.none ||
        (todo.note?.isNotEmpty ?? false);
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedDefaultTextStyle(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          style: (compact ? AppTextStyles.footnote : AppTextStyles.body)
              .copyWith(
                color: inactive ? c.labelSecondary : c.labelPrimary,
                fontWeight: compact ? FontWeight.w400 : FontWeight.w500,
                decoration: inactive ? TextDecoration.lineThrough : null,
                decorationColor: c.labelSecondary,
              ),
          child: Text(
            todo.title,
            maxLines: largeText ? null : 2,
            overflow: largeText ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
        if (hasMetadata) ...[
          SizedBox(height: compact ? 1 : 3),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 7,
              runSpacing: 3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (todo.steps.isNotEmpty)
                  Text(
                    todo.stepProgress,
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelSecondary,
                    ),
                  ),
                if (statusLabel != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      statusLabel!,
                      style: AppTextStyles.caption.copyWith(
                        color: compact && todo.status == TodoStatus.done
                            ? c.green
                            : c.labelSecondary,
                      ),
                    ),
                  ),
                if (todo.dueAt != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: DueBadge(todo: todo, now: now),
                  ),
                if (categoryLabel != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: plainCategory
                        ? Text(
                            categoryLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: c.labelSecondary,
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: c.categorySurface(
                                categoryColor ?? c.labelSecondary,
                              ),
                              borderRadius: AppRadii.brXs,
                            ),
                            child: Text(
                              categoryLabel!,
                              style: AppTextStyles.caption.copyWith(
                                color: c.categoryForeground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                if (todo.priority != TodoPriority.none)
                  PriorityFlag(priority: todo.priority, emphasize: compact),
                if (todo.note?.isNotEmpty ?? false)
                  Icon(LucideIcons.text, size: 12, color: c.labelSecondary),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
