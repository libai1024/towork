import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/workspace_actions.dart';
import '../../../core/todo/todo_checkbox.dart';
import '../../../core/todo/todo_summary.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';

/// A live task backed by a committed operation, shared with quick assist.
class AiTodoCard extends StatefulWidget {
  const AiTodoCard({
    super.key,
    required this.todo,
    this.category,
    this.onEdit,
    this.onUndo,
    this.onToggleDone,
    this.completionResult = false,
    this.animateCompletion = false,
    this.undoLabel = '撤销待办',
  });

  final Todo todo;
  final Category? category;
  final VoidCallback? onEdit, onUndo;
  final Future<void> Function()? onToggleDone;
  final bool completionResult, animateCompletion;
  final String undoLabel;

  @override
  State<AiTodoCard> createState() => _AiTodoCardState();
}

class _AiTodoCardState extends State<AiTodoCard> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onToggleDone?.call();
    } catch (error) {
      if (mounted) {
        AppToast.show(context, message: workspaceErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final done = widget.todo.status == TodoStatus.done;
    final label = switch (widget.todo.status) {
      TodoStatus.done => '已完成',
      TodoStatus.cancelled => '已取消',
      TodoStatus.inProgress => '进行中',
      TodoStatus.pending => widget.completionResult ? '已恢复为待办' : '已创建',
    };
    return Container(
      key: const ValueKey('created-todo-content'),
      padding: EdgeInsets.fromLTRB(
        widget.onToggleDone == null ? 8 : 2,
        4,
        widget.onEdit == null && widget.onUndo == null ? 8 : 2,
        4,
      ),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.separator, width: .5),
      ),
      child: Row(
        children: [
          if (widget.onToggleDone != null || widget.completionResult) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                TodoCheckbox(
                  size: 18,
                  checkedColor: c.green,
                  checked: done,
                  animateOnMount: widget.animateCompletion,
                  onTap: _busy
                      ? null
                      : widget.onToggleDone == null
                      ? null
                      : _toggle,
                  semanticLabel:
                      '${done ? '恢复待办' : '完成待办'} ${widget.todo.title}',
                ),
                if (_busy)
                  ExcludeSemantics(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: MediaQuery.disableAnimationsOf(context)
                          ? Icon(
                              LucideIcons.ellipsis,
                              size: 18,
                              color: c.labelSecondary,
                            )
                          : CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: c.labelSecondary,
                            ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 2),
          ],
          Expanded(
            child: TodoSummary(
              todo: widget.todo,
              now: DateTime.now(),
              categoryLabel: widget.category?.name,
              categoryColor: widget.category?.color,
              statusLabel: label,
              compact: true,
            ),
          ),
          if (widget.onEdit != null)
            _ResultAction(
              label: '修改待办',
              icon: LucideIcons.pencil,
              onTap: _busy ? null : widget.onEdit,
            ),
          if (widget.onUndo != null)
            _ResultAction(
              label: widget.undoLabel,
              icon: LucideIcons.undo2,
              onTap: _busy ? null : widget.onUndo,
            ),
        ],
      ),
    );
  }
}

class _ResultAction extends StatelessWidget {
  const _ResultAction({required this.label, required this.icon, this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    excludeFromSemantics: true,
    child: AppPressable(
      semanticLabel: label,
      minSize: 48,
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(
          icon,
          size: 16,
          color: AppColors.of(context).labelSecondary,
        ),
      ),
    ),
  );
}
