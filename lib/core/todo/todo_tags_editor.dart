import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/models/todo.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_chip.dart';
import 'todo_editor_controls.dart';

class TodoTagsEditor extends StatefulWidget {
  const TodoTagsEditor({
    super.key,
    required this.todo,
    required this.onChanged,
  });

  final Todo todo;
  final ValueChanged<List<String>> onChanged;

  @override
  State<TodoTagsEditor> createState() => TodoTagsEditorState();
}

class TodoTagsEditorState extends State<TodoTagsEditor> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final v = _ctrl.text.trim().replaceAll('#', '');
    if (v.isEmpty || widget.todo.tags.contains(v)) return;
    widget.onChanged([...widget.todo.tags, v]);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return TodoEditorBox(
      children: [
        if (widget.todo.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in widget.todo.tags)
                AppChip(
                  label: '#$tag',
                  icon: LucideIcons.x,
                  onTap: () => widget.onChanged(
                    widget.todo.tags.where((t) => t != tag).toList(),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(hintText: context.strings.tagName),
              ),
            ),
            AppButton(
              label: context.strings.addBuild,
              type: AppButtonType.ghost,
              onPressed: _add,
            ),
          ],
        ),
      ],
    );
  }
}
