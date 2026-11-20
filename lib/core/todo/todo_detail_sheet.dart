import 'package:towork/l10n/strings.dart';

import '../../app/workspace_clock.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/workspace_state.dart';
import '../../domain/models/models.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import 'todo_tags_editor.dart';
import 'todo_steps_editor.dart';
import 'todo_step_actions.dart';
import '../widgets/app_inline_input.dart';
import '../widgets/app_pressable.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_toast.dart';
import '../workspace_actions.dart';
import 'recurrence_action_sheet.dart';
import 'todo_checkbox.dart';
import 'todo_due_editor.dart';
import 'todo_editor_controls.dart';
import 'todo_field_row.dart';
import 'todo_reminder_editor.dart';
import 'todo_repeat_editor.dart';
import 'todo_utils.dart';

part 'todo_detail_source.dart';

/// 待办详情底部 Sheet（03-todo-detail.md §3）：92% 屏高，
/// 标题/备注就地编辑，字段行就地/二级 Sheet 编辑，AI 溯源卡片，删除确认。
Future<void> showTodoDetailSheet(
  BuildContext context,
  String todoId, {
  required ValueChanged<Todo> onDeleted,
}) {
  final height = MediaQuery.of(context).size.height * 0.92 - 20;
  return AppSheet.show<void>(
    context,
    dismissible: false,
    child: SizedBox(
      height: height,
      child: TodoDetailSheet(todoId: todoId, onDeleted: onDeleted),
    ),
  );
}

class TodoDetailSheet extends ConsumerStatefulWidget {
  const TodoDetailSheet({
    super.key,
    required this.todoId,
    required this.onDeleted,
  });

  final String todoId;

  /// 普通待办的移除和撤销由页面持有；系列范围命令由详情确认并提交。
  final ValueChanged<Todo> onDeleted;

  @override
  ConsumerState<TodoDetailSheet> createState() => _TodoDetailSheetState();
}

class _TodoDetailSheetState extends ConsumerState<TodoDetailSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  final _titleFocus = FocusNode();
  final _noteFocus = FocusNode();
  final _stepsKey = GlobalKey<TodoStepsEditorState>();
  final _scroll = ScrollController();

  /// 当前内联展开的字段（due / remind / repeat / tags），一次只开一个。
  String? _expanded;
  bool _scrolled = false;
  late String _titleBaseline;
  late String _noteBaseline;
  Future<bool>? _textSave;
  bool _closing = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final todo = ref.read(todoListProvider.notifier).byId(widget.todoId);
    _titleCtrl = TextEditingController(text: todo?.title ?? '');
    _noteCtrl = TextEditingController(text: todo?.note ?? '');
    _titleBaseline = _titleCtrl.text;
    _noteBaseline = _noteCtrl.text;
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus) _saveTitle();
    });
    _noteFocus.addListener(() {
      if (!_noteFocus.hasFocus) _saveNote();
    });
    _scroll.addListener(() {
      final v = _scroll.offset > 8;
      if (v != _scrolled) setState(() => _scrolled = v);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _titleFocus.dispose();
    _noteFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Todo? get _todo => ref.read(todoListProvider.notifier).byId(widget.todoId);

  Future<bool> _commitEdit(
    Todo before,
    Todo after, {
    bool repeatSettings = false,
  }) async {
    if (_editing) return false;
    setState(() => _editing = true);
    try {
      return await saveTodoEdit(
        context,
        ref,
        before,
        after,
        repeatSettings: repeatSettings,
      );
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  Future<void> _update(Todo todo) async {
    final before = _todo;
    if (before != null) await _commitEdit(before, todo);
  }

  void _saveTitle() {
    _saveText();
  }

  void _saveNote() {
    _saveText();
  }

  Future<bool> _saveText() async {
    final pending = _textSave;
    if (pending != null) {
      if (!await pending || !mounted) return false;
      // A second edit can arrive after the drain's final comparison but before
      // its completion callback. Recheck the draft, not just the old result.
      return _saveText();
    }
    return _textSave = _drainText().whenComplete(() {
      _textSave = null;
      if (mounted) setState(() {});
    });
  }

  /// Coalesce blur/submit/close into one write. Edits made while awaiting the
  /// receipt are drained next; failed drafts stay in their controllers.
  Future<bool> _drainText() async {
    while (true) {
      if (!mounted) return false;
      final todo = _todo;
      if (todo == null) return true;
      final title = _titleCtrl.text.trim();
      final note = _noteCtrl.text.trim();
      final titleChanged = title != _titleBaseline;
      final noteChanged = note != _noteBaseline;
      if (!titleChanged && !noteChanged) return true;
      if (title.isEmpty) {
        AppToast.show(
          context,
          message: context.strings.enterATitleBeforeClosing,
        );
        return false;
      }
      final saved = await workspaceUi(context, () async {
        if ((titleChanged && todo.title != _titleBaseline) ||
            (noteChanged && (todo.note ?? '') != _noteBaseline)) {
          throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
        }
        return _commitEdit(
          todo,
          todo.copyWith(
            title: titleChanged ? title : todo.title,
            note: noteChanged ? (note.isEmpty ? null : note) : todo.note,
          ),
        );
      });
      if (saved != true) return false;
      if (titleChanged) _titleBaseline = title;
      if (noteChanged) _noteBaseline = note;
    }
  }

  Future<void> _close() async {
    if (_closing || _editing) return;
    _closing = true;
    try {
      if (await (_stepsKey.currentState?.flush() ?? Future.value(true)) &&
          await _saveText() &&
          mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      _closing = false;
    }
  }

  void _toggleField(String key) =>
      setState(() => _expanded = _expanded == key ? null : key);

  // -------------------------------------------------------------------------
  // 构建
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.watch(todoListProvider);
    final c = AppColors.of(context);
    final todo = _todo;
    if (todo == null) {
      // §6.2 空态：深链进入但待办已不存在
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.inbox, size: 48, color: c.labelQuaternary),
            const SizedBox(height: 16),
            Text(
              context.strings.taskUnavailable,
              style: AppTextStyles.title3.copyWith(color: c.labelSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              context.strings.itMayHaveBeenDeletedOrChanged,
              style: AppTextStyles.body.copyWith(color: c.labelTertiary),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: context.strings.backToTasks,
              type: AppButtonType.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }

    final done = todo.status == TodoStatus.done;
    if (!_editing && _textSave == null) {
      if (_titleCtrl.text == _titleBaseline && todo.title != _titleBaseline) {
        _titleCtrl.text = _titleBaseline = todo.title;
      }
      if (_noteCtrl.text == _noteBaseline &&
          (todo.note ?? '') != _noteBaseline) {
        _noteCtrl.text = _noteBaseline = todo.note ?? '';
      }
    }
    final inactive = done || todo.status == TodoStatus.cancelled;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: AbsorbPointer(
        absorbing: _editing,
        child: Column(
          children: [
            _buildHeader(c, todo),
            AnimatedOpacity(
              opacity: _scrolled ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Divider(height: 0.5, color: c.separator),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  _buildTitleArea(c, todo, inactive),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TodoStepsEditor(
                      key: _stepsKey,
                      steps: todo.steps,
                      readOnly: todo.status == TodoStatus.cancelled,
                      onEdit: (edit) =>
                          commitTodoStep(context, ref, todo, edit),
                    ),
                  ),
                  _buildFields(c, todo),
                  if (todo.source == TodoSource.ai) _buildTraceCard(c, todo),
                  _buildMeta(c, todo),
                  const SizedBox(height: 12),
                  _buildDanger(c, todo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A. 头部条
  Widget _buildHeader(AppColors c, Todo todo) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          AppPressable(
            onTap: _close,
            behavior: HitTestBehavior.translucent,
            semanticLabel: context.strings.close,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(LucideIcons.x, size: 24, color: c.labelSecondary),
            ),
          ),
          if (todo.dueAt != null && todo.steps.isNotEmpty)
            Flexible(
              child: Text(
                dueBadgeLabel(todo, ref.watch(workspaceClockProvider).now),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
              ),
            ),
          const Spacer(),
          if (todo.source == TodoSource.ai)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: c.fill1,
                borderRadius: AppRadii.brFull,
              ),
              alignment: Alignment.center,
              child: Text(
                'AI',
                style: AppTextStyles.caption.copyWith(
                  color: c.labelSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          AppPressable(
            onTap: () => _showMoreMenu(todo),
            behavior: HitTestBehavior.translucent,
            semanticLabel: context.strings.more,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                LucideIcons.moreHorizontal,
                size: 24,
                color: c.labelSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // B. 标题区
  Widget _buildTitleArea(AppColors c, Todo todo, bool inactive) {
    final done = todo.status == TodoStatus.done;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: TodoCheckbox(
              checked: done,
              size: 28,
              checkedColor: c.brand,
              onTap: () async {
                if (!await confirmRemainingSteps(context, [todo]) || !mounted) {
                  return;
                }
                workspaceUi(
                  context,
                  () =>
                      ref.read(workspaceUiCommandsProvider).toggleTodo(todo.id),
                );
              },
              semanticLabel: done
                  ? context.strings.markIncomplete(todo.title)
                  : context.strings.markComplete(todo.title),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleCtrl,
                  focusNode: _titleFocus,
                  style: AppTextStyles.title3.copyWith(
                    color: inactive ? c.labelTertiary : c.labelPrimary,
                    decoration: inactive ? TextDecoration.lineThrough : null,
                    decorationColor: c.labelTertiary,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _saveTitle,
                  decoration: appInlineInput(
                    hintText: context.strings.taskTitle,
                    hintStyle: AppTextStyles.title3.copyWith(
                      color: c.labelTertiary,
                    ),
                  ),
                ),
                TextField(
                  controller: _noteCtrl,
                  focusNode: _noteFocus,
                  style: AppTextStyles.callout.copyWith(
                    color: c.labelSecondary,
                  ),
                  maxLines: null,
                  onEditingComplete: _saveNote,
                  decoration: appInlineInput(
                    hintText: context.strings.addANoteBuildtitlearea,
                    hintStyle: AppTextStyles.callout.copyWith(
                      color: c.labelTertiary,
                    ),
                    padding: const EdgeInsets.only(top: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // C. 字段区
  Widget _buildFields(AppColors c, Todo todo) {
    final categories = ref.watch(categoryListProvider);
    final category = ref
        .read(categoryListProvider.notifier)
        .byId(todo.categoryId);
    final categoryArchived = category != null && category.archived;
    final now = DateTime.now();
    final countdown = countdownLabel(todo, now);

    return Column(
      children: [
        TodoFieldRow(
          icon: LucideIcons.circleDot,
          label: context.strings.status,
          value: todo.status.label,
          onTap: () => _pickStatus(todo),
        ),
        TodoFieldRow(
          icon: LucideIcons.flag,
          label: context.strings.priority,
          value: todo.priority.label,
          onTap: () => _pickPriority(todo),
        ),
        TodoFieldRow(
          icon: LucideIcons.folder,
          label: context.strings.category,
          value: categoryArchived
              ? context.strings.originalCategoryArchived
              : _categoryPath(todo, categories) ??
                    context.strings.uncategorized,
          valueColor: category == null || categoryArchived
              ? c.labelTertiary
              : null,
          onTap: () => _pickCategory(todo, categories),
        ),
        TodoFieldRow(
          icon: LucideIcons.calendar,
          label: context.strings.dueBuildfields,
          value: todo.dueAt == null
              ? context.strings.noDueDate
              : dueSmartLabel(todo.dueAt!, now) +
                    (todo.isOverdue(now)
                        ? '（${countdown ?? context.strings.overdueBuildfields}）'
                        : ''),
          valueColor: todo.isOverdue(now)
              ? c.overdueForeground
              : (todo.dueAt == null ? c.labelTertiary : null),
          caption: countdown != null && !todo.isOverdue(now) ? countdown : null,
          captionColor: c.labelSecondary,
          expanded: _expanded == 'due',
          onTap: () => _toggleField('due'),
          editor: TodoDueEditor(
            todo: todo,
            onChanged: (dueAt) => _update(todo.copyWith(dueAt: dueAt)),
          ),
        ),
        TodoFieldRow(
          icon: LucideIcons.bell,
          label: context.strings.reminder,
          value: remindSummaryOf(todo.remindRules),
          valueColor: todo.remindRules.isEmpty ? c.labelTertiary : null,
          expanded: _expanded == 'remind',
          onTap: () => _toggleField('remind'),
          editor: TodoReminderEditor(
            todo: todo,
            onChanged: (rules) =>
                _update(todo.copyWith(remindRules: rules, remindAt: null)),
          ),
        ),
        TodoFieldRow(
          icon: LucideIcons.repeat,
          label: context.strings.repeat,
          value: repeatLabelOf(todo.repeatRule),
          valueColor: todo.repeatRule == null ? c.labelTertiary : null,
          expanded: _expanded == 'repeat',
          onTap: () => _toggleField('repeat'),
          editor: TodoRepeatEditor(
            todo: todo,
            onChanged: (rule, zone) => _commitEdit(
              todo,
              todo.copyWith(
                repeatRule: rule,
                repeatTimezone: rule == null ? null : zone,
              ),
              repeatSettings: true,
            ),
          ),
        ),
        TodoFieldRow(
          icon: LucideIcons.tag,
          label: context.strings.tags,
          value: todo.tags.isEmpty
              ? context.strings.addTag
              : todo.tags.map((t) => '#$t').join(' '),
          valueColor: todo.tags.isEmpty ? c.labelTertiary : null,
          expanded: _expanded == 'tags',
          onTap: () => _toggleField('tags'),
          editor: TodoTagsEditor(
            todo: todo,
            onChanged: (tags) => _update(todo.copyWith(tags: tags)),
          ),
        ),
      ],
    );
  }

  String? _categoryPath(Todo todo, List<Category> categories) {
    final direct = ref
        .read(categoryListProvider.notifier)
        .byId(todo.categoryId);
    if (direct == null) return null;
    if (direct.parentId == null) return direct.name;
    Category? parent;
    for (final e in categories) {
      if (e.id == direct.parentId) parent = e;
    }
    return parent == null ? direct.name : '${parent.name} / ${direct.name}';
  }

  // D. 来源溯源区

  // E. 元信息区

  // F. 危险区
  Widget _buildDanger(AppColors c, Todo todo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppButton(
        label: context.strings.deleteThisTask,
        type: AppButtonType.destructive,
        icon: LucideIcons.trash2,
        expand: true,
        onPressed: () => _confirmDelete(todo),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 二级选择与菜单
  // -------------------------------------------------------------------------

  void _showMoreMenu(Todo todo) {
    AppSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TodoOptionRow(
            icon: LucideIcons.copy,
            label: context.strings.copyTitle,
            onTap: () {
              Navigator.of(context).pop();
              Clipboard.setData(ClipboardData(text: todo.title));
              AppToast.show(context, message: context.strings.titleCopied);
            },
          ),
          TodoOptionRow(
            icon: LucideIcons.trash2,
            label: context.strings.deleteLabel,
            onTap: () {
              Navigator.of(context).pop();
              _confirmDelete(todo);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _pickStatus(Todo todo) {
    AppSheet.show<void>(
      context,
      title: context.strings.status,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in TodoStatus.values)
            TodoOptionRow(
              label: s.label,
              selected: todo.status == s,
              onTap: () async {
                Navigator.of(context).pop();
                if (s == TodoStatus.done &&
                    (!await confirmRemainingSteps(context, [todo]) ||
                        !mounted)) {
                  return;
                }
                _update(
                  todo.copyWith(
                    status: s,
                    completedAt: s == TodoStatus.done ? DateTime.now() : null,
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _pickPriority(Todo todo) {
    final c = AppColors.of(context);
    AppSheet.show<void>(
      context,
      title: context.strings.priority,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in TodoPriority.values)
            TodoOptionRow(
              icon: p == TodoPriority.none ? null : LucideIcons.flag,
              iconColor: c.labelSecondary,
              label: p.label,
              selected: todo.priority == p,
              onTap: () {
                Navigator.of(context).pop();
                _update(todo.copyWith(priority: p));
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _pickCategory(Todo todo, List<Category> categories) {
    final roots =
        categories.where((e) => e.parentId == null && !e.archived).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    AppSheet.show<void>(
      context,
      title: context.strings.category,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TodoOptionRow(
              label: context.strings.uncategorized,
              selected: todo.categoryId == null,
              onTap: () {
                Navigator.of(context).pop();
                _update(todo.copyWith(categoryId: null));
              },
            ),
            for (final root in roots) ...[
              TodoOptionRow(
                dotColor: root.color,
                label: root.name,
                selected: todo.categoryId == root.id,
                onTap: () {
                  Navigator.of(context).pop();
                  _update(todo.copyWith(categoryId: root.id));
                },
              ),
              for (final child in categories.where(
                (e) => e.parentId == root.id && !e.archived,
              ))
                TodoOptionRow(
                  dotColor: child.color,
                  label: child.name,
                  indent: 24,
                  selected: todo.categoryId == child.id,
                  onTap: () {
                    Navigator.of(context).pop();
                    _update(todo.copyWith(categoryId: child.id));
                  },
                ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Todo todo) async {
    if (_editing) return;
    if (!await _saveText() || !mounted) return;
    final current = _todo;
    if (current == null) return;
    if (current.seriesId != null) {
      setState(() => _editing = true);
      final deleted = await deleteRecurringTodo(context, ref, current);
      if (!mounted) return;
      setState(() => _editing = false);
      if (deleted) Navigator.of(context).pop();
      return;
    }
    AppSheet.show<void>(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.strings.deleteThisTaskConfirmdelete,
              style: AppTextStyles.title2.copyWith(
                color: AppColors.of(context).labelPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.strings.willBeDeletedYouCanUndoWithin(todo.title),
              style: AppTextStyles.body.copyWith(
                color: AppColors.of(context).labelSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppButton(
              label: context.strings.deleteLabel,
              type: AppButtonType.destructive,
              expand: true,
              onPressed: () {
                Navigator.of(context).pop(); // 确认层
                Navigator.of(context).pop(); // 详情层
                widget.onDeleted(todo);
              },
            ),
            const SizedBox(height: 8),
            AppButton(
              label: context.strings.cancel,
              type: AppButtonType.secondary,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
