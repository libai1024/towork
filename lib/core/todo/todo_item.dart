import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/app_pressable.dart';
import '../../domain/models/models.dart';
import '../ai/model_identity.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import 'todo_checkbox.dart';
import 'todo_summary.dart';

/// 紧凑列表行；完成、来源与整行操作均保持至少 44 px 触控空间。
class TodoListItem extends StatelessWidget {
  const TodoListItem({
    super.key,
    required this.todo,
    required this.now,
    this.categoryLabel,
    this.categoryColor,
    this.plainCategory = false,
    this.selectionMode = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.onToggleDone,
    this.onToggleSelect,
    this.onAiSourceTap,
  });

  final Todo todo;
  final DateTime now;
  final String? categoryLabel;
  final Color? categoryColor;
  final bool plainCategory;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleDone;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onAiSourceTap;

  @override
  Widget build(BuildContext context) {
    final done = todo.status == TodoStatus.done;
    return AppPressable(
      onTap: selectionMode ? onToggleSelect : onTap,
      onLongPress: onLongPress,
      semanticLabel: todo.title,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 5, 12, 5),
        child: Row(
          children: [
            TodoCheckbox(
              checked: selectionMode ? selected : done,
              size: 20,
              onTap: selectionMode ? onToggleSelect : onToggleDone,
              semanticLabel: selectionMode
                  ? '选择待办：${todo.title}'
                  : done
                  ? '恢复待办：${todo.title}'
                  : '完成待办：${todo.title}',
            ),
            const SizedBox(width: 2),
            Expanded(
              child: TodoSummary(
                todo: todo,
                now: now,
                categoryLabel: categoryLabel,
                categoryColor: categoryColor,
                plainCategory: plainCategory,
              ),
            ),
            if (!selectionMode &&
                todo.source == TodoSource.ai &&
                onAiSourceTap != null)
              ModelSourceBadge(
                model: todo.sourceModel,
                product: todo.sourceProvider,
                onTap: onAiSourceTap,
              ),
          ],
        ),
      ),
    );
  }
}

/// 移动端滑动操作行（02 §5.2）：
/// 右滑露出墨色完成/恢复；左滑短滑露出「改期 / 删除」两枚 72 宽按钮，
/// 左滑过 50% 屏宽松手直接触发删除。跟手、松手吸附 200ms ease-out。
class TodoSwipeRow extends StatefulWidget {
  const TodoSwipeRow({
    super.key,
    required this.child,
    this.enabled = true,
    this.isDone = false,
    this.onComplete,
    this.onReschedule,
    this.onDelete,
  });

  final Widget child;
  final bool enabled;
  final bool isDone;
  final VoidCallback? onComplete;
  final VoidCallback? onReschedule;
  final VoidCallback? onDelete;

  @override
  State<TodoSwipeRow> createState() => TodoSwipeRowState();
}

class TodoSwipeRowState extends State<TodoSwipeRow>
    with SingleTickerProviderStateMixin {
  static const _actionWidth = 72.0;
  late final AnimationController _ctrl = AnimationController.unbounded(
    vsync: this,
  );
  double _width = 0;

  double get _openX => _actionWidth * 2;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void close() => _snapTo(0);

  void _snapTo(double target, {VoidCallback? then}) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = target;
      then?.call();
      return;
    }
    _ctrl
        .animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        )
        .whenComplete(() => then?.call());
  }

  void _onDragStart(DragStartDetails d) => _ctrl.stop();

  void _onDragUpdate(DragUpdateDetails d) {
    var next = _ctrl.value + d.delta.dx;
    // 超出吸附位后加阻力
    if (next < -_openX) next = -_openX + (next + _openX) * 0.4;
    if (next > 96) next = 96 + (next - 96) * 0.4;
    _ctrl.value = next.clamp(-_width * 0.85, _width * 0.55);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = _ctrl.value;
    if (v > _width * 0.4 && widget.onComplete != null) {
      _snapTo(0, then: widget.onComplete);
    } else if (v < -_width * 0.5 && widget.onDelete != null) {
      _snapTo(-_width, then: widget.onDelete);
    } else if (v < -_openX / 2) {
      _snapTo(-_openX);
    } else {
      _snapTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (!widget.enabled) return widget.child;
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        // 滑动操作的无障碍等价物：行获得键盘焦点时 Delete 直接删除
        // （完成/改期/查看编辑走 Enter 激活行的既有路径）。
        return CallbackShortcuts(
          bindings: {
            if (widget.onDelete != null)
              const SingleActivator(LogicalKeyboardKey.delete):
                  widget.onDelete!,
          },
          child: GestureDetector(
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final offset = _ctrl.value;
                return Stack(
                  children: [
                    // 右滑底层：完成 / 恢复
                    if (offset > 0)
                      Positioned.fill(
                        child: Container(
                          color: c.brand,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                          child: Icon(
                            widget.isDone
                                ? LucideIcons.undo2
                                : LucideIcons.check,
                            size: 20,
                            color: c.onBrand,
                          ),
                        ),
                      ),
                    // 左滑底层：改期 + 删除
                    if (offset < 0)
                      Positioned.fill(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _SwipeAction(
                              width: _actionWidth,
                              color: c.fill3,
                              icon: LucideIcons.calendar,
                              iconColor: c.labelPrimary,
                              label: '改期待办',
                              onTap: () {
                                close();
                                widget.onReschedule?.call();
                              },
                            ),
                            _SwipeAction(
                              width: _actionWidth,
                              color: c.brand,
                              icon: LucideIcons.trash2,
                              iconColor: c.onBrand,
                              label: '删除待办',
                              onTap: () {
                                close();
                                widget.onDelete?.call();
                              },
                            ),
                          ],
                        ),
                      ),
                    // 读屏用户无法完成横滑手势：把整行合并为一个语义
                    // 节点，并暴露 完成/改期/删除 自定义操作，等效可达。
                    Transform.translate(
                      offset: Offset(offset, 0),
                      child: MergeSemantics(
                        child: Semantics(
                          customSemanticsActions: _customActions(),
                          child: widget.child,
                        ),
                      ),
                    ),
                    // 按钮展开时点按空白处收起
                    if (offset <= -_openX * 0.9)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        right: _openX,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: close,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Map<CustomSemanticsAction, VoidCallback> _customActions() => {
    if (widget.onComplete != null)
      CustomSemanticsAction(label: widget.isDone ? '恢复待办' : '完成待办'):
          widget.onComplete!,
    if (widget.onReschedule != null)
      CustomSemanticsAction(label: '改期待办'): widget.onReschedule!,
    if (widget.onDelete != null)
      CustomSemanticsAction(label: '删除待办'): widget.onDelete!,
  };
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.width,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  final double width;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: width,
        color: color,
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}

/// 看板沿用同一信息主体，移除来源徽标和独立的底部元信息区。
class TodoBoardCard extends StatelessWidget {
  const TodoBoardCard({
    super.key,
    required this.todo,
    required this.now,
    this.categoryLabel,
    this.categoryColor,
    this.onTap,
    this.onToggleDone,
    this.onLongPress,
  });

  final Todo todo;
  final DateTime now;
  final String? categoryLabel;
  final Color? categoryColor;
  final VoidCallback? onTap;
  final VoidCallback? onToggleDone;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final done = todo.status == TodoStatus.done;
    return AppPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: todo.title,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 7, 10, 7),
        decoration: BoxDecoration(
          color: c.bgPrimary,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: c.separator, width: 0.5),
        ),
        child: Row(
          children: [
            TodoCheckbox(
              checked: done,
              size: 20,
              onTap: onToggleDone,
              semanticLabel: done ? '恢复待办：${todo.title}' : '完成待办：${todo.title}',
            ),
            const SizedBox(width: 2),
            Expanded(
              child: TodoSummary(
                todo: todo,
                now: now,
                categoryLabel: categoryLabel,
                categoryColor: categoryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
