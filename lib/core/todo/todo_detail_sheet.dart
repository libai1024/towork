import 'todo_field_row.dart';
import '../widgets/app_day_calendar.dart';
import '../widgets/app_inline_input.dart';

import '../../app/routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/app_button.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_pressable.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_toast.dart';
import '../../app/providers.dart';
import '../workspace_actions.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../app/workspace_state.dart';
import '../../domain/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_text_styles.dart';
import 'todo_utils.dart';
import 'todo_checkbox.dart';
import 'recurrence_preview.dart';
import '../notifications/notification_diagnostics_sheet.dart';
import 'recurrence_action_sheet.dart';
import '../../domain/recurrence/recurrence_schedule.dart';

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
          editor: _DueEditor(
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
          editor: _RemindEditor(
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
          editor: _RepeatEditor(
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
          _SheetOptionRow(
            icon: LucideIcons.copy,
            label: '复制标题',
            onTap: () {
              Navigator.of(context).pop();
              Clipboard.setData(ClipboardData(text: todo.title));
              AppToast.show(context, message: '已复制标题');
            },
          ),
          _SheetOptionRow(
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
            _SheetOptionRow(
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
            _SheetOptionRow(
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
            _SheetOptionRow(
              label: '未分类',
              selected: todo.categoryId == null,
              onTap: () {
                Navigator.of(context).pop();
                _update(todo.copyWith(categoryId: null));
              },
            ),
            for (final root in roots) ...[
              _SheetOptionRow(
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
                _SheetOptionRow(
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

// ---------------------------------------------------------------------------
// 字段行
// ---------------------------------------------------------------------------

/// 编辑器容器（字段行下方内联展开区）。
class _EditorBox extends StatelessWidget {
  const _EditorBox({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: c.fill1, borderRadius: AppRadii.brXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 截止时间编辑器（03 §5.2）
// ---------------------------------------------------------------------------

class _DueEditor extends StatefulWidget {
  const _DueEditor({required this.todo, required this.onChanged});

  final Todo todo;
  final ValueChanged<DateTime?> onChanged;

  @override
  State<_DueEditor> createState() => _DueEditorState();
}

class _DueEditorState extends State<_DueEditor> {
  bool _showCalendar = false;

  DateTime _withCurrentTime(DateTime day) {
    final due = widget.todo.dueAt;
    if (due != null && (due.hour != 0 || due.minute != 0)) {
      return DateTime(day.year, day.month, day.day, due.hour, due.minute);
    }
    return DateTime(day.year, day.month, day.day, 18);
  }

  Future<void> _pickTime() async {
    final due = widget.todo.dueAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: due.hour, minute: due.minute),
    );
    if (picked == null) return;
    final day = dayOnly(widget.todo.dueAt ?? DateTime.now());
    widget.onChanged(
      DateTime(day.year, day.month, day.day, picked.hour, picked.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final now = DateTime.now();
    final today = dayOnly(now);
    final due = widget.todo.dueAt;
    final hasTime = due != null && (due.hour != 0 || due.minute != 0);

    final quick = <(String, DateTime)>[
      ('今天', _withCurrentTime(today)),
      ('明天', _withCurrentTime(today.add(const Duration(days: 1)))),
      ('下周一', _withCurrentTime(today.add(Duration(days: 8 - today.weekday)))),
    ];

    return _EditorBox(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, target) in quick)
              AppChip(
                label: label,
                selected: due != null && isSameDay(due, target),
                onTap: () => widget.onChanged(target),
              ),
            AppChip(
              label: '选日期…',
              icon: LucideIcons.calendar,
              selected: _showCalendar,
              onTap: () => setState(() => _showCalendar = !_showCalendar),
            ),
          ],
        ),
        if (_showCalendar) ...[
          const SizedBox(height: 12),
          AppDayCalendar(
            selected: due,
            onSelected: (day) => widget.onChanged(_withCurrentTime(day)),
          ),
        ],
        const SizedBox(height: 12),
        Divider(height: 0.5, color: c.separator),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '时间',
              style: AppTextStyles.body.copyWith(color: c.labelSecondary),
            ),
            if (hasTime)
              Text(
                timeLabel(due),
                style: AppTextStyles.body.copyWith(color: c.labelPrimary),
              )
            else
              Text(
                '全天截止',
                style: AppTextStyles.body.copyWith(color: c.labelTertiary),
              ),
            if (hasTime)
              AppButton(
                label: '清除时间',
                type: AppButtonType.ghost,
                onPressed: () => widget.onChanged(dayOnly(due)),
              )
            else
              AppButton(
                label: '添加时间',
                type: AppButtonType.ghost,
                onPressed: _pickTime,
              ),
          ],
        ),
        if (due != null) ...[
          const SizedBox(height: 8),
          Divider(height: 0.5, color: c.separator),
          const SizedBox(height: 4),
          Center(
            child: AppButton(
              label: '清除截止',
              type: AppButtonType.ghost,
              onPressed: () => widget.onChanged(null),
            ),
          ),
          Center(
            child: Text(
              '清除后不再出现在今天/本周/逾期过滤中',
              style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 提醒多规则编辑器（03 §5.3，上限 5 条）
// ---------------------------------------------------------------------------

class _RemindEditor extends StatelessWidget {
  const _RemindEditor({required this.todo, required this.onChanged});

  final Todo todo;
  final ValueChanged<List<RemindRule>> onChanged;

  void _addRule(BuildContext context) {
    AppSheet.show<void>(
      context,
      title: '添加提醒',
      child: _AddReminderSheet(
        hasDue: todo.dueAt != null,
        onAdd: (rule) => onChanged([...todo.remindRules, rule]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final rules = todo.remindRules;
    final full = rules.length >= 5;
    return _EditorBox(
      children: [
        const NotificationPermissionHint(),
        for (final rule in rules)
          Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.brand,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    remindRuleLabel(rule),
                    style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                  ),
                ),
                AppPressable(
                  onTap: () =>
                      onChanged(rules.where((e) => e.id != rule.id).toList()),
                  behavior: HitTestBehavior.translucent,
                  semanticLabel: '删除提醒：${remindRuleLabel(rule)}',
                  child: Icon(LucideIcons.x, size: 16, color: c.labelTertiary),
                ),
              ],
            ),
          ),
        if (rules.isNotEmpty) ...[Divider(height: 16, color: c.separator)],
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton(
              label: '添加提醒',
              type: AppButtonType.ghost,
              icon: LucideIcons.plus,
              onPressed: full ? null : () => _addRule(context),
            ),
            if (full)
              Text(
                '最多 5 条提醒',
                style: AppTextStyles.caption.copyWith(color: c.labelQuaternary),
              ),
          ],
        ),
        if (todo.repeatRule != null) ...[
          const SizedBox(height: 4),
          Text(
            '重复任务将在每次截止前提醒',
            style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
          ),
        ],
      ],
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet({required this.hasDue, required this.onAdd});

  final bool hasDue;
  final ValueChanged<RemindRule> onAdd;

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  int _offset = 30;
  String _unit = '分钟';
  DateTime? _absDate;
  TimeOfDay? _absTime;

  static const _unitMinutes = {'分钟': 1, '小时': 60, '天': 60 * 24};

  int get _seq => DateTime.now().millisecondsSinceEpoch % 100000;

  void _addRelative(int minutes) {
    widget.onAdd(RemindRule(id: 'rr_$_seq', offsetMinutes: minutes));
    Navigator.of(context).pop();
  }

  void _addCustom() {
    _addRelative(_offset * _unitMinutes[_unit]!);
  }

  void _addAbsolute() {
    final d = _absDate;
    final t = _absTime;
    if (d == null || t == null) return;
    widget.onAdd(
      RemindRule(
        id: 'rr_$_seq',
        absoluteAt: DateTime(d.year, d.month, d.day, t.hour, t.minute),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    const presets = [
      ('截止时', 0),
      ('前 5 分钟', 5),
      ('前 15 分钟', 15),
      ('前 30 分钟', 30),
      ('前 1 小时', 60),
      ('前 1 天', 60 * 24),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '相对截止',
              style: AppTextStyles.footnote.copyWith(
                color: widget.hasDue ? c.labelSecondary : c.labelQuaternary,
              ),
            ),
          ),
          if (!widget.hasDue)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                '先设置截止时间',
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
            ),
          for (final (label, minutes) in presets)
            _SheetOptionRow(
              label: label,
              enabled: widget.hasDue,
              onTap: () => _addRelative(minutes),
            ),
          if (widget.hasDue)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '自定义',
                    style: AppTextStyles.body.copyWith(color: c.labelSecondary),
                  ),
                  _Stepper(
                    label: '提醒提前量',
                    value: _offset,
                    min: 1,
                    max: 99,
                    onChanged: (v) => setState(() => _offset = v),
                  ),
                  for (final u in _unitMinutes.keys)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: AppChip(
                        label: u,
                        selected: _unit == u,
                        onTap: () => setState(() => _unit = u),
                      ),
                    ),
                  AppButton(
                    label: '添加',
                    type: AppButtonType.ghost,
                    onPressed: _addCustom,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Divider(height: 0.5, color: c.separator),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '指定时间',
              style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppDayCalendar(
              selected: _absDate,
              onSelected: (d) => setState(() => _absDate = d),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, tod) in [
                  ('上午 9:00', const TimeOfDay(hour: 9, minute: 0)),
                  ('中午 12:00', const TimeOfDay(hour: 12, minute: 0)),
                  ('下午 18:00', const TimeOfDay(hour: 18, minute: 0)),
                  ('晚上 20:00', const TimeOfDay(hour: 20, minute: 0)),
                ])
                  AppChip(
                    label: label,
                    selected: _absTime == tod,
                    onTap: () => setState(() => _absTime = tod),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppButton(
              label: '添加提醒',
              type: AppButtonType.primary,
              expand: true,
              enabled: _absDate != null && _absTime != null,
              onPressed: _addAbsolute,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 重复规则可视化编辑器（03 §5.4）
// ---------------------------------------------------------------------------

class _RepeatEditor extends StatefulWidget {
  const _RepeatEditor({required this.todo, required this.onChanged});

  final Todo todo;
  final Future<bool> Function(String? rule, String timezone) onChanged;

  @override
  State<_RepeatEditor> createState() => _RepeatEditorState();
}

class _RepeatEditorState extends State<_RepeatEditor> {
  late RepeatSpec _spec;
  bool _unmappable = false;
  bool _confirmClear = false;
  bool _saving = false;
  late String _timezone;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _timezone = widget.todo.repeatTimezone ?? 'Asia/Shanghai';
    _unmappable = false;
    final rule = widget.todo.repeatRule;
    if (rule != null) {
      final parsed = RepeatSpec.fromRrule(rule);
      if (parsed == null) {
        _unmappable = true;
        _spec = RepeatSpec(
          weekdays: {
            RecurrenceTimeZones.civil(
              widget.todo.dueAt ?? widget.todo.createdAt,
              _timezone,
            ).weekday,
          },
        );
      } else {
        _spec = parsed;
      }
    } else {
      _spec = RepeatSpec(
        weekdays: {
          RecurrenceTimeZones.civil(
            widget.todo.dueAt ?? widget.todo.createdAt,
            _timezone,
          ).weekday,
        },
      );
    }
  }

  Future<void> _apply({bool clear = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    final saved = await widget.onChanged(
      clear ? null : _spec.toRrule(),
      _timezone,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!saved || clear) _load();
    });
  }

  @override
  void didUpdateWidget(covariant _RepeatEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_saving &&
        (widget.todo.repeatRule != _spec.toRrule() ||
            widget.todo.repeatTimezone != _timezone) &&
        (oldWidget.todo.repeatRule != widget.todo.repeatRule ||
            oldWidget.todo.repeatTimezone != widget.todo.repeatTimezone)) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (_unmappable) {
      // 无法映射的复杂规则降级为只读 + 重置
      return _EditorBox(
        children: [
          Text(
            '自定义规则（暂不支持编辑）',
            style: AppTextStyles.body.copyWith(color: c.labelSecondary),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: '重置规则',
            type: AppButtonType.ghost,
            onPressed: () => setState(() {
              _unmappable = false;
              _spec = RepeatSpec(
                weekdays: {
                  RecurrenceTimeZones.civil(
                    widget.todo.dueAt ?? widget.todo.createdAt,
                    _timezone,
                  ).weekday,
                },
              );
              _apply();
            }),
          ),
        ],
      );
    }

    final unit = switch (_spec.freq) {
      RepeatFreq.daily => '天',
      RepeatFreq.weekly => '周',
      RepeatFreq.monthly => '月',
      RepeatFreq.yearly => '年',
    };

    return AbsorbPointer(
      absorbing: _saving,
      child: _EditorBox(
        children: [
          _editorLabel(c, '频率'),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, f) in [
                ('每天', RepeatFreq.daily),
                ('每周', RepeatFreq.weekly),
                ('每月', RepeatFreq.monthly),
                ('每年', RepeatFreq.yearly),
              ])
                AppChip(
                  label: label,
                  selected: _spec.freq == f,
                  onTap: () => setState(() {
                    _spec.freq = f;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _editorLabel(c, '间隔'),
              Text(
                '每',
                style: AppTextStyles.body.copyWith(color: c.labelSecondary),
              ),
              _Stepper(
                label: '重复间隔',
                value: _spec.interval,
                min: 1,
                max: 99,
                onChanged: (v) => setState(() {
                  _spec.interval = v;
                }),
              ),
              Text(
                unit,
                style: AppTextStyles.body.copyWith(color: c.labelSecondary),
              ),
            ],
          ),
          if (_spec.freq == RepeatFreq.weekly) ...[
            const SizedBox(height: 12),
            _editorLabel(c, '重复于'),
            Wrap(
              spacing: 8,
              children: [
                for (var d = 1; d <= 7; d++)
                  AppChip(
                    label: RepeatSpec.weekdayNames[d - 1],
                    selected: _spec.weekdays.contains(d),
                    onTap: () => setState(() {
                      if (_spec.weekdays.contains(d)) {
                        if (_spec.weekdays.length > 1) _spec.weekdays.remove(d);
                      } else {
                        _spec.weekdays.add(d);
                      }
                    }),
                  ),
              ],
            ),
          ],
          if (_spec.freq == RepeatFreq.monthly) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _editorLabel(c, '每月'),
                _Stepper(
                  label: '每月日期',
                  value: _spec.monthDay,
                  min: 1,
                  max: 31,
                  onChanged: (v) => setState(() {
                    _spec.monthDay = v;
                  }),
                ),
                Text(
                  '日',
                  style: AppTextStyles.body.copyWith(color: c.labelSecondary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _editorLabel(c, '结束'),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, e) in [
                ('永不', RepeatEnd.never),
                ('于日期', RepeatEnd.until),
                ('N 次后', RepeatEnd.count),
              ])
                AppChip(
                  label: label,
                  selected: _spec.end == e,
                  onTap: () => setState(() {
                    _spec.end = e;
                    _spec.until ??= dayOnly(DateTime.now())
                        .add(const Duration(days: 30));
                  }),
                ),
            ],
          ),
          if (_spec.end == RepeatEnd.until) ...[
            const SizedBox(height: 8),
            AppDayCalendar(
              selected: _spec.until,
              onSelected: (d) => setState(() {
                _spec.until = d;
              }),
            ),
          ],
          if (_spec.end == RepeatEnd.count) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Stepper(
                  label: '重复次数',
                  value: _spec.count,
                  min: 1,
                  max: 99,
                  onChanged: (v) => setState(() {
                    _spec.count = v;
                  }),
                ),
                Text(
                  '次',
                  style: AppTextStyles.body.copyWith(color: c.labelSecondary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 0.5, color: c.separator),
          const SizedBox(height: 8),
          _editorLabel(c, '固定时区'),
          DropdownButton<String>(
            key: const ValueKey('repeat-timezone'),
            value: _timezone,
            isExpanded: true,
            style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
            dropdownColor: Theme.of(context).scaffoldBackgroundColor,
            items: [
              for (final zone in RecurrenceTimeZones.names)
                DropdownMenuItem(
                  value: zone,
                  child: Text(zone, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (zone) {
              if (zone == null) return;
              setState(() => _timezone = zone);
            },
          ),
          const SizedBox(height: 8),
          RecurrencePreview(
            rule: _spec.toRrule(),
            anchor: widget.todo.dueAt,
            timezone: _timezone,
          ),
          const SizedBox(height: 8),
          Text(
            '月末不足所选日期时取最后一天；夏令时缺失时刻顺延至首个有效时刻，重复时刻只取一次。',
            style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            '摘要：${_spec.summary()}',
            style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: '保存重复设置',
            expand: true,
            enabled: !_saving,
            onPressed: () => _apply(),
          ),
          const SizedBox(height: 4),
          Center(
            child: AppButton(
              label: _confirmClear ? '确认清除？' : '清除重复',
              type: AppButtonType.ghost,
              onPressed: () {
                if (_confirmClear) {
                  _apply(clear: true);
                } else {
                  setState(() => _confirmClear = true);
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) setState(() => _confirmClear = false);
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorLabel(AppColors c, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
    ),
  );
}

// ---------------------------------------------------------------------------
// 标签编辑器
// ---------------------------------------------------------------------------

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
    return _EditorBox(
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

// ---------------------------------------------------------------------------
// 通用小件：选项行 / 步进器 / 小月历
// ---------------------------------------------------------------------------

class _SheetOptionRow extends StatelessWidget {
  const _SheetOptionRow({
    this.icon,
    this.iconColor,
    this.dotColor,
    required this.label,
    this.selected = false,
    this.enabled = true,
    this.indent = 0,
    this.onTap,
  });

  final IconData? icon;
  final Color? iconColor;
  final Color? dotColor;
  final String label;
  final bool selected;
  final bool enabled;
  final double indent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = !enabled ? c.labelQuaternary : c.labelPrimary;
    return AppPressable(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: EdgeInsets.fromLTRB(16 + indent, 8, 16, 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: iconColor ?? fg),
              const SizedBox(width: 12),
            ],
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.categorySurface(dotColor!),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(label, style: AppTextStyles.body.copyWith(color: fg)),
            ),
            if (selected) Icon(LucideIcons.check, size: 16, color: c.brand),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final String label;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget btn(IconData icon, VoidCallback? onTap, String action) =>
        AppPressable(
          onTap: onTap,
          semanticLabel: '$action$label',
          behavior: HitTestBehavior.translucent,
          child: Icon(icon, size: 16, color: c.labelSecondary),
        );
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: c.separator, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(
            LucideIcons.minus,
            value > min ? () => onChanged(value - 1) : null,
            '减少',
          ),
          SizedBox(
            width: 44,
            child: Center(
              child: Text(
                '$value',
                style: AppTextStyles.body.copyWith(
                  color: c.labelPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          btn(
            LucideIcons.plus,
            value < max ? () => onChanged(value + 1) : null,
            '增加',
          ),
        ],
      ),
    );
  }
}

/// 内联小月历（03 §5.2/§5.4）：整月网格 + 今天 brand 圆点 + 选中 brand 圆底。
