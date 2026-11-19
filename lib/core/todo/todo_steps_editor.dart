import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';

import '../../domain/models/todo.dart';
import '../../domain/workspace/todo_step_edit.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../widgets/app_inline_input.dart';
import '../widgets/app_toast.dart';

/// The parent owns writes; this editor only keeps the active text/IME draft.
class TodoStepsEditor extends StatefulWidget {
  const TodoStepsEditor({
    super.key,
    required this.steps,
    required this.onEdit,
    this.readOnly = false,
  });
  final List<TodoStep> steps;
  final bool readOnly;
  final Future<bool> Function(TodoStepEdit) onEdit;
  @override
  State<TodoStepsEditor> createState() => TodoStepsEditorState();
}

class TodoStepsEditorState extends State<TodoStepsEditor> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _organizing = false;
  String? _target, _original;
  bool _adding = false;
  Future<bool>? _write;

  @override
  void dispose() {
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _open([TodoStep? step]) {
    setState(() {
      _adding = step == null;
      _target = step?.id ?? newWorkspaceId('step');
      _original = step?.title;
      _text.value = TextEditingValue(
        text: step?.title ?? '',
        selection: TextSelection.collapsed(offset: step?.title.length ?? 0),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  Future<bool> flush({bool another = false}) async {
    final pending = _write;
    if (pending != null && !await pending) return false;
    if (!mounted || _target == null) return true;
    final title = _text.text.trim();
    if (_adding && title.isEmpty) return true;
    if (title.isEmpty) {
      AppToast.show(context, message: '请输入步骤名称');
      return false;
    }
    final target = _target!;
    if (!_adding &&
        widget.steps.where((s) => s.id == target).firstOrNull?.title !=
            _original) {
      AppToast.show(context, message: '步骤已变化，请核对后再保存');
      setState(() {
        _original = widget.steps
            .where((s) => s.id == target)
            .firstOrNull
            ?.title;
      });
      return false;
    }
    final edit = _adding
        ? TodoStepEdit.add(target, title)
        : TodoStepEdit.rename(target, title);
    if ((!_adding && title == _original) || await _submit(edit)) {
      if (!mounted) return false;
    } else {
      return false;
    }
    setState(() {
      _target = null;
      _text.clear();
    });
    if (another && _adding) _open();
    return true;
  }

  Future<bool> _submit(TodoStepEdit edit) async {
    if (_write != null) return false;
    final write = widget.onEdit(edit);
    setState(() {
      _write = write;
    });
    try {
      return await write;
    } finally {
      if (mounted) setState(() => _write = null);
    }
  }

  Future<void> _afterDraft(VoidCallback callback) async {
    if (await flush() && mounted) callback();
  }

  Widget _action(String label, IconData icon, VoidCallback? press) =>
      IconButton(
        tooltip: label,
        icon: Icon(icon, size: 17),
        onPressed: press,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      );

  Widget _input() {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('step-input'),
            controller: _text,
            focusNode: _focus,
            readOnly: _write != null,
            style: AppTextStyles.footnote.copyWith(
              fontSize: 14,
              color: c.labelPrimary,
            ),
            maxLength: TodoStep.maxTitle,
            decoration: appInlineInput(
              hintText: '步骤名称',
              hintStyle: TextStyle(color: c.labelTertiary),
            ).copyWith(counterText: ''),
            textInputAction: TextInputAction.done,
            onEditingComplete: () => flush(another: true),
          ),
        ),
        _action(
          '放弃编辑',
          LucideIcons.x,
          () => setState(() {
            _target = null;
            _text.clear();
          }),
        ),
        _action('保存步骤', LucideIcons.check, () => flush(another: _adding)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context), steps = widget.steps;
    final next = steps.indexWhere((s) => !s.done);
    final editing = !widget.readOnly;
    if (!editing && steps.isEmpty) return const SizedBox.shrink();
    final secondary = AppTextStyles.caption.copyWith(color: c.labelSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (steps.isNotEmpty)
          Row(
            children: [
              Text(
                '步骤',
                style: AppTextStyles.footnote.copyWith(
                  color: c.labelPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${steps.where((s) => s.done).length}/${steps.length}',
                  style: secondary,
                ),
              ),
              if (editing) ...[
                _action(
                  '添加步骤',
                  LucideIcons.plus,
                  steps.length < TodoStep.maxCount
                      ? () => _afterDraft(_open)
                      : null,
                ),
                TextButton(
                  onPressed: () => _afterDraft(
                    () => setState(() {
                      _target = null;
                      _organizing = !_organizing;
                    }),
                  ),
                  child: Text(_organizing ? '完成整理' : '整理', style: secondary),
                ),
              ],
            ],
          )
        else if (_target == null && editing)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _open,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text('添加步骤', style: secondary),
            ),
          ),
        for (final (index, s) in steps.indexed)
          _row(index, s, next, editing, c),
        if (_target != null && _adding && editing) _input(),
      ],
    );
  }

  Widget _row(int index, TodoStep step, int next, bool editable, AppColors c) {
    final current = editable && index == next;
    final titleStyle = AppTextStyles.footnote.copyWith(
      fontSize: 14,
      color: step.done ? c.labelSecondary : c.labelPrimary,
      fontWeight: current ? FontWeight.w600 : FontWeight.w400,
    );
    final organize = _organizing && editable;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 38),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: current ? c.labelPrimary : c.bgPrimary,
              border: Border.all(color: current ? c.labelPrimary : c.separator),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${index + 1}',
                style: AppTextStyles.caption.copyWith(
                  color: current ? c.bgPrimary : c.labelSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (_target == step.id && !_adding && editable)
            Expanded(child: _input())
          else ...[
            Expanded(
              child: organize
                  ? InkWell(
                      onTap: () => _afterDraft(() => _open(step)),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(step.title, style: titleStyle),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(step.title, style: titleStyle),
                    ),
            ),
            if (organize) ...[
              _action(
                '上移第${index + 1}步',
                LucideIcons.chevronUp,
                index > 0
                    ? () => _afterDraft(
                        () => _submit(TodoStepEdit.move(step.id, -1)),
                      )
                    : null,
              ),
              _action(
                '下移第${index + 1}步',
                LucideIcons.chevronDown,
                index < widget.steps.length - 1
                    ? () => _afterDraft(
                        () => _submit(TodoStepEdit.move(step.id, 1)),
                      )
                    : null,
              ),
              _action(
                '删除第${index + 1}步',
                LucideIcons.x,
                () => _afterDraft(() => _submit(TodoStepEdit.remove(step.id))),
              ),
            ] else if (step.done)
              Icon(LucideIcons.check, size: 14, color: c.labelSecondary)
            else if (current)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  '下一步',
                  style: AppTextStyles.caption.copyWith(
                    color: c.labelSecondary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
    final inner = Stack(
      alignment: Alignment.centerLeft,
      children: [
        Positioned.fill(
          left: 9.5,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 1,
                    color: index > 0 ? c.separator : null,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1,
                    color: index < widget.steps.length - 1 ? c.separator : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        row,
      ],
    );
    if (organize) return KeyedSubtree(key: ValueKey(step.id), child: inner);
    final toggle = editable && _write == null
        ? () => _afterDraft(
            () => _submit(TodoStepEdit.check(step.id, !step.done)),
          )
        : null;
    return Semantics(
      key: ValueKey(step.id),
      label: '第${index + 1}步，${step.title}${current ? '，下一步' : ''}',
      checked: step.done,
      enabled: editable,
      onTap: toggle,
      excludeSemantics: true,
      child: InkWell(onTap: toggle, child: inner),
    );
  }
}
