import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/workspace_actions.dart';
import '../../../core/widgets/ai_component_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../domain/chat/todo_panel.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'ai_todo_pagination.dart';
import 'ai_todo_panel_item.dart';

/// Membership is a saved snapshot. Completion and edits use live task data.
class AiTodoPanel extends ConsumerStatefulWidget {
  const AiTodoPanel({
    super.key,
    required this.panel,
    required this.onToggleDone,
    required this.onEdit,
  });

  final TodoPanel panel;
  final Future<void> Function(Todo) onToggleDone;
  final ValueChanged<Todo> onEdit;

  @override
  ConsumerState<AiTodoPanel> createState() => _AiTodoPanelState();
}

class _AiTodoPanelState extends ConsumerState<AiTodoPanel> {
  int _section = 0;
  final _pages = <int, int>{};
  final _busy = <String>{};
  double _bodyHeight = 0;
  (double, TextScaler)? _layout;

  @override
  void didUpdateWidget(AiTodoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The projection recreates panel objects when live records refresh.
    if (oldWidget.panel.title != widget.panel.title ||
        oldWidget.panel.asOfLocal != widget.panel.asOfLocal) {
      _section = 0;
      _pages.clear();
      _bodyHeight = 0;
    }
  }

  Future<void> _toggle(Todo todo) async {
    if (!_busy.add(todo.id)) return;
    setState(() {});
    try {
      await widget.onToggleDone(todo);
    } catch (error) {
      if (mounted) {
        AppToast.show(context, message: workspaceErrorMessage(error));
      }
    } finally {
      _busy.remove(todo.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final panel = widget.panel;
    if (panel.sections.isEmpty) return const SizedBox.shrink();
    _section = _section.clamp(0, panel.sections.length - 1);
    final section = panel.sections[_section];
    final all = {for (final todo in ref.watch(todoListProvider)) todo.id: todo};
    final groups = [
      for (final section in panel.sections)
        [for (final id in section.todoIds) ?all[id]],
    ];
    final todos = groups[_section];
    final page = (_pages[_section] ?? 0)
        .clamp(
          0,
          math.max(0, (todos.length / AiTodoPagination.pageSize).ceil() - 1),
        )
        .toInt();
    _pages[_section] = page;
    final shown = todos
        .skip(page * AiTodoPagination.pageSize)
        .take(AiTodoPagination.pageSize)
        .toList();
    final completed = todos.where((t) => t.status == TodoStatus.done).length;
    final removed = section.todoIds.length - todos.length;
    final notices = [
      for (var i = 0; i < panel.sections.length; i++)
        [
          if (panel.sections[i].matchedCount > panel.sections[i].todoIds.length)
            '另有 ${panel.sections[i].matchedCount - panel.sections[i].todoIds.length} 项未展示',
          if (panel.sections[i].todoIds.length > groups[i].length)
            '${panel.sections[i].todoIds.length - groups[i].length} 项已移除',
        ].join(' '),
    ];
    final largestCount = groups.fold(
      0,
      (count, group) => math.max(count, group.length),
    );
    final c = AppColors.of(context);
    final now = DateTime.now();
    return AiComponentCard(
      key: const ValueKey('ai-todo-panel'),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = (
            constraints.maxWidth,
            MediaQuery.textScalerOf(context),
          );
          if (_layout != layout) {
            _layout = layout;
            _bodyHeight = 0;
          }
          final heights = <String, double>{};
          var tallest = 0.0;
          for (final group in panel.overview ? groups : [shown]) {
            var pageHeight = 0.0;
            for (var i = 0; i < group.length; i++) {
              final todo = group[i];
              pageHeight += heights.putIfAbsent(
                todo.id,
                () => AiTodoPanelItem.heightFor(
                  context,
                  constraints.maxWidth,
                  todo,
                  now,
                ),
              );
              if ((i + 1) % AiTodoPagination.pageSize == 0 ||
                  i == group.length - 1) {
                tallest = math.max(tallest, pageHeight);
                pageHeight = 0;
              }
            }
          }
          // Only category switching needs a shared content height.
          _bodyHeight = panel.overview
              ? math.max(_bodyHeight, tallest)
              : shown.fold(0.0, (height, todo) => height + heights[todo.id]!);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          panel.title,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w500,
                            color: c.labelPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: math.min(
                        constraints.maxWidth * .55,
                        MediaQuery.textScalerOf(context).scale(12) * 11,
                      ),
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          ExcludeSemantics(
                            child: Opacity(
                              opacity: 0,
                              child: Text(
                                '$largestCount/$largestCount 完成',
                                style: AppTextStyles.caption,
                              ),
                            ),
                          ),
                          Text(
                            '$completed/${todos.length} 完成',
                            textAlign: TextAlign.right,
                            style: AppTextStyles.caption.copyWith(
                              color: c.labelSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (panel.overview)
                Wrap(
                  spacing: 4,
                  children: [
                    for (var i = 0; i < panel.sections.length; i++)
                      Semantics(
                        selected: _section == i,
                        child: AppPressable(
                          minSize: 48,
                          semanticLabel: '查看${panel.sections[i].title}',
                          onTap: () => setState(() => _section = i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _section == i
                                    ? c.fill2
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '${panel.sections[i].title} ${groups[i].length}',
                                style: AppTextStyles.caption.copyWith(
                                  color: _section == i
                                      ? c.labelPrimary
                                      : c.labelSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              SizedBox(
                height: todos.isEmpty ? math.max(48, _bodyHeight) : _bodyHeight,
                child: todos.isEmpty
                    ? Center(
                        child: Text(
                          removed > 0 ? '这份清单中的待办已移除' : '这个范围暂时没有待办',
                          style: AppTextStyles.footnote.copyWith(
                            color: c.labelSecondary,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final todo in shown)
                            SizedBox(
                              key: ValueKey('panel-todo-${todo.id}'),
                              height: heights[todo.id],
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: todo.id == shown.last.id
                                        ? BorderSide.none
                                        : BorderSide(
                                            color: c.separator,
                                            width: .5,
                                          ),
                                  ),
                                ),
                                child: AiTodoPanelItem(
                                  todo: todo,
                                  now: now,
                                  busy: _busy.contains(todo.id),
                                  onToggle: () => _toggle(todo),
                                  onEdit: () => widget.onEdit(todo),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              if ((panel.overview ? largestCount : todos.length) >
                  AiTodoPagination.pageSize)
                AiTodoPagination(
                  count: todos.length,
                  page: page,
                  onPage: (value) => setState(() => _pages[_section] = value),
                ),
              if (notices.any((notice) => notice.isNotEmpty))
                Stack(
                  children: [
                    for (var i = 0; i < notices.length; i++)
                      IgnorePointer(
                        ignoring: i != _section,
                        child: ExcludeSemantics(
                          excluding: i != _section,
                          child: Opacity(
                            opacity: i == _section ? 1 : 0,
                            child: Text(
                              notices[i],
                              style: AppTextStyles.caption.copyWith(
                                color: c.labelSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
