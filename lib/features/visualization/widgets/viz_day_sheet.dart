import 'package:towork/l10n/strings.dart';

import '../../../core/todo/todo_step_actions.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../app/providers.dart';
import '../../../core/workspace_actions.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// 下钻明细底部 Sheet（05 文档 §4.4 / §5.4）：
/// 某日/某分类的 Todo 明细列表，可直接勾选完成（250ms 弹性 + 触觉）。
class VizDaySheet extends ConsumerWidget {
  const VizDaySheet({
    super.key,
    required this.title,
    required this.filter,
    this.emptyText,
  });

  final String title;

  /// 在仓库全量 Todo 上的过滤条件（Sheet 内部 watch，勾选即时刷新）。
  final bool Function(Todo todo) filter;
  final String? emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final todos = ref.watch(todoListProvider).where(filter).toList()
      ..sort((a, b) {
        final ad = a.dueAt ?? a.createdAt;
        final bd = b.dueAt ?? b.createdAt;
        return ad.compareTo(bd);
      });

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.subhead.copyWith(
                color: c.labelPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: todos.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          emptyText ?? context.strings.noActivityThisDay,
                          style: AppTextStyles.body.copyWith(
                            color: c.labelTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: todos.length,
                      separatorBuilder: (_, _) =>
                          Divider(indent: 34, color: c.separator),
                      itemBuilder: (context, index) =>
                          _TodoRow(todo: todos[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoRow extends ConsumerWidget {
  const _TodoRow({required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final category = ref
        .watch(categoryListProvider.notifier)
        .byId(todo.categoryId);
    final done = todo.status == TodoStatus.done;
    final due = todo.dueAt;
    final dueText = due == null
        ? context.strings.noDueTime
        : context.strings.dueAt(
            due.hour.toString().padLeft(2, '0'),
            due.minute.toString().padLeft(2, '0'),
          );

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          AppPressable(
            onTap: () async {
              if (!await confirmRemainingSteps(context, [todo]) ||
                  !context.mounted) {
                return;
              }
              workspaceUi(
                context,
                () => ref.read(workspaceUiCommandsProvider).toggleTodo(todo.id),
              );
              HapticFeedback.mediumImpact();
            },

            behavior: HitTestBehavior.translucent,
            semanticLabel: done
                ? context.strings.markIncompleteBuild(todo.title)
                : context.strings.completeBuild2(todo.title),
            child: AnimatedContainer(
              duration: AppMotion.todoComplete,
              curve: Curves.easeOutBack,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? c.brand : Colors.transparent,
                shape: BoxShape.circle,
                border: done ? null : Border.all(color: c.fill3, width: 1.5),
              ),
              child: done
                  ? Icon(LucideIcons.check, size: 14, color: c.onBrand)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        todo.title,
                        style: AppTextStyles.body.copyWith(
                          color: done ? c.labelTertiary : c.labelPrimary,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (todo.source == TodoSource.ai) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: c.fill1,
                          borderRadius: AppRadii.brXs,
                        ),
                        child: Text(
                          'AI',
                          style: AppTextStyles.caption.copyWith(
                            color: c.labelSecondary,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${category?.name ?? context.strings.uncategorized} $dueText',
                  style: AppTextStyles.footnote.copyWith(
                    color: c.labelTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
