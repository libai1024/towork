import 'package:towork/l10n/strings.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_field_label.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'chat_messages.dart' show formatDue;

/// 「修改」底部 Sheet：标题 / 截止 / 分类内联编辑，预填 AI 解析值。
class ChatTodoEditSheet extends StatefulWidget {
  const ChatTodoEditSheet({
    super.key,
    required this.todo,
    this.onSteps,
    required this.categories,
    required this.onSave,
  });

  final Todo todo;
  final VoidCallback? onSteps;
  final List<Category> categories;
  final ValueChanged<Todo> onSave;

  @override
  State<ChatTodoEditSheet> createState() => ChatTodoEditSheetState();
}

class ChatTodoEditSheetState extends State<ChatTodoEditSheet> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.todo.title,
  );
  late DateTime? _dueAt = widget.todo.dueAt;
  late String? _categoryId = widget.todo.categoryId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueOptions = <(String, DateTime?)>[
      (context.strings.today, DateTime(today.year, today.month, today.day, 18)),
      (
        context.strings.tomorrow,
        DateTime(today.year, today.month, today.day + 1, 18),
      ),
      (context.strings.nextWeekBuild, today.add(const Duration(days: 7))),
      (context.strings.noDueDate, null),
    ];
    final selectableCategories =
        widget.categories.where((e) => !e.archived).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFieldLabel(
            label: context.strings.title,
            child: TextField(
              controller: _titleController,
              style: AppTextStyles.body.copyWith(color: c.labelPrimary),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.strings.due,
            style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final (label, day) in dueOptions)
                AppChip(
                  label: day == null ? label : formatDue(day),
                  selected: _dueAt == day,
                  onTap: () => setState(() => _dueAt = day),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.strings.category,
            style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final cat in selectableCategories)
                AppChip(
                  label: cat.name,
                  color: cat.color,
                  selected: _categoryId == cat.id,
                  onTap: () => setState(() => _categoryId = cat.id),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.onSteps != null)
            TextButton.icon(
              onPressed:
                  _titleController.text.trim() == widget.todo.title &&
                      _dueAt == widget.todo.dueAt &&
                      _categoryId == widget.todo.categoryId
                  ? widget.onSteps
                  : null,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text(context.strings.addStep),
            ),
          AppButton(
            expand: true,
            label: context.strings.save,
            enabled: _titleController.text.trim().isNotEmpty,
            onPressed: () {
              final title = _titleController.text.trim();
              widget.onSave(
                widget.todo.copyWith(
                  title: title,
                  dueAt: _dueAt,
                  categoryId: _categoryId,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
