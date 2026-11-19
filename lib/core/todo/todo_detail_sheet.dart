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
import '../widgets/app_chip.dart';
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
        AppToast.show(context, message: '标题不能为空，请填写后再关闭');
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
      if (await _saveText() && mounted) Navigator.of(context).pop();
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
              '这条待办不在了',
              style: AppTextStyles.title3.copyWith(color: c.labelSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '它可能被删除，也可能在另一台设备上改过',
              style: AppTextStyles.body.copyWith(color: c.labelTertiary),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: '回到待办列表',
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
                  const SizedBox(height: 8),
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
            semanticLabel: '关闭',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(LucideIcons.x, size: 24, color: c.labelSecondary),
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
            semanticLabel: '更多',
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: TodoCheckbox(
              checked: done,
              size: 28,
              checkedColor: c.brand,
              onTap: () {
                workspaceUi(
                  context,
                  () =>
                      ref.read(workspaceUiCommandsProvider).toggleTodo(todo.id),
                );
              },
              semanticLabel: done
                  ? '标记未完成，${todo.title}'
                  : '标记完成，${todo.title}',
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
                    hintText: '待办标题',
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
                    hintText: '添加备注…',
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
          label: '状态',
          value: todo.status.label,
          onTap: () => _pickStatus(todo),
        ),
        TodoFieldRow(
          icon: LucideIcons.flag,
          label: '优先级',
          value: todo.priority.label,
          onTap: () => _pickPriority(todo),
        ),
        TodoFieldRow(
          icon: LucideIcons.folder,
          label: '分类',
          value: categoryArchived
              ? '原分类已归档'
              : _categoryPath(todo, categories) ?? '未分类',
          valueColor: category == null || categoryArchived
              ? c.labelTertiary
              : null,
          onTap: () => _pickCategory(todo, categories),
        ),
        TodoFieldRow(
          icon: LucideIcons.calendar,
          label: '截止',
          value: todo.dueAt == null
              ? '无截止'
              : dueSmartLabel(todo.dueAt!, now) +
                    (todo.isOverdue(now) ? '（${countdown ?? '已逾期'}）' : ''),
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
          label: '提醒',
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
          label: '重复',
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
          label: '标签',
          value: todo.tags.isEmpty
              ? '添加标签'
              : todo.tags.map((t) => '#$t').join(' '),
          valueColor: todo.tags.isEmpty ? c.labelTertiary : null,
          expanded: _expanded == 'tags',
          onTap: () => _toggleField('tags'),
          editor: _TagsEditor(
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
  Widget _buildTraceCard(AppColors c, Todo todo) {
    final chatRepo = ref.read(sessionListProvider.notifier);
    final message = chatRepo.messageById(todo.sourceMessageId);
    final session = message == null
        ? null
        : chatRepo.sessionById(message.sessionId);
    final now = DateTime.now();

    if (message == null || session == null) {
      // §6.4 来源消息失效降级
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.bgSecondary,
            borderRadius: AppRadii.brXl,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(LucideIcons.sparkles, size: 16, color: c.labelSecondary),
              Text(
                '来自对话',
                style: AppTextStyles.footnote.copyWith(
                  color: c.labelSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '原始对话已删除',
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: AppPressable(
        onTap: () {
          final source = chatRepo.messageById(todo.sourceMessageId);
          final currentSession = chatRepo.sessionById(source?.sessionId);
          if (currentSession == null) {
            AppToast.show(context, message: '原始对话已不可用');
            return;
          }
          final router = GoRouter.of(context);
          ref.read(currentSessionIdProvider.notifier).state = currentSession.id;
          Navigator.of(context).pop();
          router.go(AppRoutes.home);
        },
        behavior: HitTestBehavior.opaque,
        borderRadius: AppRadii.brXl,
        semanticLabel: '由对话生成，原文：${message.content}，双击查看对话',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.bgSecondary,
            borderRadius: AppRadii.brXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.sparkles, size: 16, color: c.labelSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '来自对话',
                    style: AppTextStyles.footnote.copyWith(
                      color: c.labelSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 2,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.labelSecondary,
                      borderRadius: AppRadii.brFull,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '「${message.content}」',
                      style: AppTextStyles.footnote.copyWith(
                        color: c.labelPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${session.title} ${relativeTimeLabel(message.createdAt, now)}',
                      style: AppTextStyles.caption.copyWith(
                        color: c.labelTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: c.labelTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // E. 元信息区
  Widget _buildMeta(AppColors c, Todo todo) {
    // 等宽数字：Geist Mono 未随包内置，用 Inter tabular figures 近似（TODO: 接入 Geist Mono asset）。
    final style = AppTextStyles.caption.copyWith(
      color: c.labelTertiary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final lines = <String>[
      '创建于 ${metaTimeLabel(todo.createdAt)}',
      if (todo.updatedAt != null) '更新于 ${metaTimeLabel(todo.updatedAt!)}',
      if (todo.completedAt != null) '完成于 ${metaTimeLabel(todo.completedAt!)}',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 0.5, color: c.separator),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line, style: style),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // F. 危险区
  Widget _buildDanger(AppColors c, Todo todo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppButton(
        label: '删除这条待办',
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
            label: '复制标题',
            onTap: () {
              Navigator.of(context).pop();
              Clipboard.setData(ClipboardData(text: todo.title));
              AppToast.show(context, message: '已复制标题');
            },
          ),
          TodoOptionRow(
            icon: LucideIcons.trash2,
            label: '删除',
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
      title: '状态',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in TodoStatus.values)
            TodoOptionRow(
              label: s.label,
              selected: todo.status == s,
              onTap: () {
                Navigator.of(context).pop();
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
      title: '优先级',
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
      title: '分类',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TodoOptionRow(
              label: '未分类',
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
              '删除这条待办？',
              style: AppTextStyles.title2.copyWith(
                color: AppColors.of(context).labelPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '「${todo.title}」将被删除，删除后 10 秒内可撤销。',
              style: AppTextStyles.body.copyWith(
                color: AppColors.of(context).labelSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppButton(
              label: '删除',
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
              label: '取消',
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

class _TagsEditor extends StatefulWidget {
  const _TagsEditor({required this.todo, required this.onChanged});

  final Todo todo;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_TagsEditor> createState() => _TagsEditorState();
}

class _TagsEditorState extends State<_TagsEditor> {
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
                decoration: const InputDecoration(hintText: '标签名'),
              ),
            ),
            AppButton(label: '添加', type: AppButtonType.ghost, onPressed: _add),
          ],
        ),
      ],
    );
  }
}
