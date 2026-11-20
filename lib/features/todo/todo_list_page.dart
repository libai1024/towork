import 'package:towork/l10n/strings.dart';

import 'widgets/todo_option_menu_row.dart';
import '../../core/todo/todo_step_actions.dart';
import '../../core/todo/recurrence_action_sheet.dart';
import 'widgets/recurrence_window_status.dart';
import '../../app/routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/workspace_nav_bar.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_toast.dart';
import '../../app/providers.dart';
import '../../core/workspace_actions.dart';
import '../../app/todo/async_todo_commands.dart';
import '../../app/workspace_state.dart';
import '../../domain/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../core/todo/todo_utils.dart';
import '../../app/todo/todo_view_model.dart';
import '../../core/todo/todo_detail_sheet.dart';
import '../../core/todo/todo_item.dart';
import '../../core/todo/create_todo_sheet.dart';
import 'widgets/todo_quick_filter_bar.dart';
import '../../core/categories/widgets/category_edit_sheet.dart';
import '../../core/widgets/workspace_scope_rail.dart';
import '../../core/widgets/workspace_bottom_bar.dart';

part 'todo_board_view.dart';

/// 待办总览（02-todo-list.md）：列表/看板双视图 + 快速过滤 + 分组锚点 +
/// 滑动操作 + 批量多选。支持 ?categoryId= 初始过滤（路由侧已注册，不改路由）。
class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({
    super.key,
    this.categoryId,
    this.notificationTodo,
    this.notificationToken,
    this.notificationKind,
  });

  final String? categoryId;
  final String? notificationTodo, notificationToken;
  final String? notificationKind;

  @override
  ConsumerState<TodoListPage> createState() => _TodoListPageState();
}

enum _TodoView { list, board }

class _TodoListPageState extends ConsumerState<TodoListPage> {
  _TodoView _view = _TodoView.list;
  TodoGroupBy _groupBy = TodoGroupBy.category;
  TodoQuickFilter _filter = TodoQuickFilter.all;
  bool _showCompleted = true;

  final _searchCtrl = TextEditingController();

  /// 路由 ?categoryId= 传入的初始分类过滤（含子分类），可在页内清除。
  String? _categoryFilterId;
  String? _subCategoryId;
  bool _completedExpanded = false;

  final _collapsed = <String>{};

  bool _selectionMode = false;
  final _selectedIds = <String>{};

  final _boardCtrl = PageController(viewportFraction: .94);

  @override
  void initState() {
    super.initState();
    _categoryFilterId = widget.categoryId;
    _openNotification();
  }

  @override
  void didUpdateWidget(covariant TodoListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notificationToken != widget.notificationToken) {
      _openNotification();
    }
    if (oldWidget.categoryId != widget.categoryId) {
      _categoryFilterId = widget.categoryId;
      _subCategoryId = null;
      _selectedIds.clear();
      _selectionMode = false;
    }
  }

  void _openNotification() {
    if (widget.notificationKind == 'morning') _filter = TodoQuickFilter.today;
    final id = widget.notificationTodo;
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(todoListProvider.notifier).byId(id) == null) {
        AppToast.show(
          context,
          message: context.strings.theTaskForThisReminderNoLonger,
        );
      } else {
        showTodoDetailSheet(
          context,
          id,
          onDeleted: (todo) => _softDelete(todo),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _boardCtrl.dispose();
    super.dispose();
  }

  // 数据派生

  TodoQueries get _model => ref.read(todoViewModelProvider);
  AsyncTodoCommands get _commands => ref.read(asyncTodoCommandsProvider);

  String? get _effectiveCategoryId {
    final child = ref.read(categoryListProvider.notifier).byId(_subCategoryId);
    return child != null &&
            !child.archived &&
            child.parentId == _categoryFilterId
        ? child.id
        : _categoryFilterId;
  }

  List<Todo> _categorySelectable(TodoOverview overview) =>
      _view == _TodoView.board ||
          _completedExpanded ||
          _filter == TodoQuickFilter.done
      ? overview.visible
      : overview.visible.where((todo) => todo.isActive).toList();

  Set<String> _selectedVisibleIds(List<Todo> visible) =>
      _selectedIds.intersection(visible.map((todo) => todo.id).toSet());

  (String?, Color?) _categoryDisplay(Todo todo) => _model.categoryDisplay(todo);

  Future<void> _toggleDone(Todo todo) async {
    if (!await confirmRemainingSteps(context, [todo]) || !mounted) return;
    final mutation = await workspaceUi(
      context,
      () => _commands.toggleDone(todo.id),
    );
    if (!mounted || mutation == null) return;
    if (todo.status != TodoStatus.done && mutation.count > 0) {
      AppToast.show(
        context,
        message: context.strings.completedToggledone(todo.title),
        completion: true,
        actionLabel: context.strings.undo,
        onAction: () => workspaceUi(context, () async {
          await mutation.undo();
          return true;
        }),
      );
    }
  }

  Future<void> _softDelete(Todo todo) async {
    if (todo.seriesId != null) {
      final deleted = await deleteRecurringTodo(context, ref, todo);
      if (deleted && mounted) setState(() => _selectedIds.remove(todo.id));
      return;
    }
    final mutation = await workspaceUi(
      context,
      () => _commands.delete([todo.id]),
    );
    if (!mounted || mutation == null) return;
    _selectedIds.remove(todo.id);
    if (mutation.count == 0) return;
    AppToast.show(
      context,
      message: context.strings.deleted,
      actionLabel: context.strings.undo,
      duration: const Duration(seconds: 10),
      onAction: () => workspaceUi(context, () async {
        await mutation.undo();
        return true;
      }),
    );
  }

  void _openDetail(Todo todo) {
    showTodoDetailSheet(context, todo.id, onDeleted: (t) => _softDelete(t));
  }

  void _openReschedule(Todo todo) {
    final now = DateTime.now();
    final today = dayOnly(now);
    final options = <(String, DateTime?)>[
      (
        context.strings.todayAt,
        DateTime(today.year, today.month, today.day, 18),
      ),
      (
        context.strings.tomorrowAt,
        DateTime(today.year, today.month, today.day + 1, 9),
      ),
      (
        context.strings.nextMondayAt,
        DateTime(today.year, today.month, today.day + 8 - today.weekday, 9),
      ),
      (context.strings.clearDueDate, null),
    ];
    AppSheet.show<void>(
      context,
      title: context.strings.reschedule,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, due) in options)
            TodoOptionMenuRow(
              label: label,
              onTap: () async {
                Navigator.of(context).pop();
                if (todo.seriesId != null) {
                  await saveTodoEdit(
                    context,
                    ref,
                    todo,
                    todo.copyWith(dueAt: due),
                  );
                  return;
                }
                final saved = await workspaceUi(
                  context,
                  () => _commands.setDue([todo.id], due),
                );
                if (!mounted || saved == null) return;
                if (due != null) {
                  AppToast.show(
                    context,
                    message: context.strings.rescheduledTo(
                      dueSmartLabel(due, now),
                    ),
                  );
                } else {
                  AppToast.show(
                    context,
                    message: context.strings.dueDateCleared,
                  );
                }
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _enterSelection(Todo todo) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(todo.id);
    });
  }

  void _exitSelection() => setState(() {
    _selectionMode = false;
    _selectedIds.clear();
  });

  // 批量操作
  Future<void> _batchDone(List<Todo> visible) async {
    if (!await confirmRemainingSteps(
          context,
          visible.where((t) => _selectedIds.contains(t.id)),
        ) ||
        !mounted) {
      return;
    }
    final mutation = await workspaceUi(
      context,
      () => _commands.complete(_selectedVisibleIds(visible)),
    );
    if (!mounted || mutation == null) return;
    _exitSelection();
    if (mutation.count == 0) return;
    AppToast.show(
      context,
      message: context.strings.completedTasks(mutation.count),
      actionLabel: context.strings.undo,
      onAction: () => workspaceUi(context, () async {
        await mutation.undo();
        return true;
      }),
    );
  }

  void _batchSetCategory(List<Todo> visible) {
    final c = AppColors.of(context);
    final repo = ref.read(categoryListProvider.notifier);
    final roots = repo.roots;
    AppSheet.show<void>(
      context,
      title: context.strings.changeCategory,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TodoOptionMenuRow(
              label: context.strings.uncategorized,
              onTap: () => _applyBatchCategory(
                null,
                context.strings.uncategorized,
                visible,
              ),
            ),
            for (final root in roots) ...[
              TodoOptionMenuRow(
                dotColor: root.color,
                label: root.name,
                onTap: () => _applyBatchCategory(root.id, root.name, visible),
              ),
              for (final child in repo.childrenOf(root.id))
                TodoOptionMenuRow(
                  dotColor: child.color,
                  label: child.name,
                  indent: 24,
                  onTap: () => _applyBatchCategory(
                    child.id,
                    '${root.name}/${child.name}',
                    visible,
                  ),
                ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    // 未使用的色 token 保持引用（选项行自带色点）。
    assert(c.brand != Colors.transparent);
  }

  Future<void> _applyBatchCategory(
    String? categoryId,
    String name,
    List<Todo> visible,
  ) async {
    Navigator.of(context).pop();
    final saved = await workspaceUi(
      context,
      () => _commands.setCategory(_selectedVisibleIds(visible), categoryId),
    );
    if (!mounted || saved == null) return;
    _exitSelection();
    AppToast.show(context, message: context.strings.movedTo(name));
  }

  void _batchSetDue(List<Todo> visible) {
    final now = DateTime.now();
    final today = dayOnly(now);
    final options = <(String, DateTime?)>[
      (
        context.strings.todayAt,
        DateTime(today.year, today.month, today.day, 18),
      ),
      (
        context.strings.tomorrowAt,
        DateTime(today.year, today.month, today.day + 1, 9),
      ),
      (
        context.strings.nextMondayAt,
        DateTime(today.year, today.month, today.day + 8 - today.weekday, 9),
      ),
      (context.strings.clearDueDate, null),
    ];
    AppSheet.show<void>(
      context,
      title: context.strings.changeDueDate,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, due) in options)
            TodoOptionMenuRow(
              label: label,
              onTap: () async {
                Navigator.of(context).pop();
                final saved = await workspaceUi(
                  context,
                  () => _commands.setDue(_selectedVisibleIds(visible), due),
                );
                if (!mounted || saved == null) return;
                _exitSelection();
                AppToast.show(
                  context,
                  message: due == null
                      ? context.strings.dueDateCleared
                      : context.strings.rescheduled(label),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _batchDelete(List<Todo> visible) {
    final targets = visible.where((t) => _selectedIds.contains(t.id)).toList();
    if (targets.isEmpty) {
      _exitSelection();
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
              context.strings.deleteTasks(targets.length),
              style: AppTextStyles.title2.copyWith(
                color: AppColors.of(context).labelPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.strings.onlySelectedRecurringOccurrencesAreDeletedUndo,
              style: AppTextStyles.body.copyWith(
                color: AppColors.of(context).labelSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: context.strings.deleteLabel,
              type: AppButtonType.destructive,
              expand: true,
              onPressed: () async {
                Navigator.of(context).pop();
                final mutation = await workspaceUi(
                  context,
                  () => _commands.delete(targets.map((todo) => todo.id)),
                );
                if (!mounted || mutation == null) return;
                _exitSelection();
                AppToast.show(
                  context,
                  message: context.strings.deletedTasks(mutation.count),
                  actionLabel: context.strings.undo,
                  duration: const Duration(seconds: 10),
                  onAction: () => workspaceUi(context, () async {
                    await mutation.undo();
                    return true;
                  }),
                );
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

  void _toggleSelectAll(List<Todo> visible) {
    setState(() {
      if (_selectedVisibleIds(visible).length == visible.length &&
          visible.isNotEmpty) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(visible.map((t) => t.id));
      }
    });
  }

  // 构建

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final category = ref
        .watch(categoryListProvider)
        .where((category) => category.id == _categoryFilterId)
        .firstOrNull;
    final childScopes = category == null
        ? <CategoryTodoScope>[]
        : ref.watch(categoryTodoScopesProvider(category.id));
    final selectedChild =
        childScopes.any((scope) => scope.category.id == _subCategoryId)
        ? _subCategoryId
        : null;
    final overview = ref.watch(
      todoOverviewProvider(
        TodoQuery(
          filter: _filter,
          groupBy: _groupBy,
          categoryId: selectedChild ?? _categoryFilterId,
          search: _searchCtrl.text,
          showCompleted: _showCompleted,
        ),
      ),
    );
    final visible = overview.visible;
    if (category != null) {
      return _buildCategoryPage(
        c,
        category,
        childScopes,
        selectedChild,
        overview,
      );
    }

    return Scaffold(
      backgroundColor: c.bgGround,
      bottomNavigationBar: _selectionMode ? _buildBatchBar(c, visible) : null,
      body: SafeArea(
        child: Column(
          children: [
            if (_selectionMode)
              _buildSelectionBar(c, visible)
            else
              _buildAppBar(
                c,
                title: category == null
                    ? context.strings.task
                    : context.strings.categoryBuild(category.name),
              ),
            _buildFilterBar(c, overview),
            const RecurrenceWindowStatus(),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_view == _TodoView.list)
                    _buildListView(c, overview)
                  else
                    _buildBoardView(c, overview),
                  if (!_selectionMode) _bottomBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPage(
    AppColors c,
    Category category,
    List<CategoryTodoScope> scopes,
    String? selectedChild,
    TodoOverview overview,
  ) {
    final activeCount = ref.watch(activeTodoCountProvider(category.id));
    return Scaffold(
      backgroundColor: c.bgGround,
      bottomNavigationBar: _selectionMode
          ? _buildBatchBar(c, _categorySelectable(overview))
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (_selectionMode)
              _buildSelectionBar(c, _categorySelectable(overview))
            else
              _buildAppBar(
                c,
                title: context.strings.categoryBuild(category.name),
              ),
            const RecurrenceWindowStatus(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TodoQuickFilterBar(
                selected: _filter,
                counts: overview.counts,
                onChanged: (filter) => setState(() => _filter = filter),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  WorkspaceScopeLayout(
                    items: [
                      WorkspaceScopeItem(
                        id: 'all',
                        label: context.strings.allLabel,
                        count: activeCount,
                      ),
                      for (final scope in scopes)
                        WorkspaceScopeItem(
                          id: scope.category.id,
                          label: scope.category.name,
                          count: scope.activeCount,
                        ),
                    ],
                    selectedId: selectedChild ?? 'all',
                    onSelected: (id) => setState(() {
                      _subCategoryId = id == 'all' ? null : id;
                      _selectedIds.clear();
                      _selectionMode = false;
                    }),
                    onAdd: category.parentId == null
                        ? () => _addCategoryType(category)
                        : null,
                    child: _view == _TodoView.board
                        ? _buildBoardView(c, overview)
                        : _buildCategoryList(c, overview, selectedChild),
                  ),
                  if (!_selectionMode) _bottomBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCategoryType(Category category) async {
    final created = await CategoryEditSheet.showCreate(
      context,
      parentId: category.id,
      lockParent: true,
    );
    if (created == null || !mounted) return;
    setState(() => _subCategoryId = created.id);
  }

  Widget _buildCategoryList(
    AppColors c,
    TodoOverview overview,
    String? selectedChild,
  ) {
    final pending = overview.visible.where((todo) => todo.isActive).toList();
    final completed = overview.visible.where((todo) => !todo.isActive).toList();
    final showCompleted = _completedExpanded || _filter == TodoQuickFilter.done;
    final entries = <Object>[
      ...pending,
      if (completed.isNotEmpty) 'completed',
      if (showCompleted) ...completed,
    ];
    if (entries.isEmpty) {
      return Center(
        child: Text(
          context.strings.noTasksMatchTheseFilters,
          style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(right: 12, bottom: 96),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry is String) {
          return AppPressable(
            semanticLabel: context.strings.expandCompletedTasks,
            onTap: () =>
                setState(() => _completedExpanded = !_completedExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    showCompleted
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 16,
                    color: c.labelSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.strings.completedToggledone(completed.length),
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final todo = entry as Todo;
        final category = ref
            .read(categoryListProvider.notifier)
            .byId(todo.categoryId);
        final item = TodoListItem(
          key: ValueKey(todo.id),
          todo: todo,
          now: overview.now,
          categoryLabel: selectedChild == null && category?.parentId != null
              ? category?.name
              : null,
          plainCategory: true,
          selectionMode: _selectionMode,
          selected: _selectedIds.contains(todo.id),
          onTap: () => _openDetail(todo),
          onLongPress: () => _enterSelection(todo),
          onToggleDone: () => _toggleDone(todo),
          onToggleSelect: () => setState(() {
            if (!_selectedIds.remove(todo.id)) _selectedIds.add(todo.id);
          }),
        );
        return Column(
          children: [
            TodoSwipeRow(
              enabled: !_selectionMode,
              isDone: todo.status == TodoStatus.done,
              onComplete: () => _toggleDone(todo),
              onReschedule: () => _openReschedule(todo),
              onDelete: () => _softDelete(todo),
              child: ColoredBox(color: c.bgGround, child: item),
            ),
            Divider(height: .5, thickness: .5, indent: 46, color: c.separator),
          ],
        );
      },
    );
  }

  // 顶栏（02 §3.2）。待办是一级目的地：桌面端由常驻侧栏导航，
  // 不再重复放「返回对话首页」箭头；移动端全屏页保留返回。
  Widget _buildAppBar(AppColors c, {required String title}) {
    final actions = [
      WorkspaceToolbarGroup(
        children: [
          WorkspaceToolbarAction(
            icon: _view == _TodoView.list
                ? LucideIcons.columns3
                : LucideIcons.list,
            label: _view == _TodoView.list
                ? context.strings.switchToBoard
                : context.strings.switchToList,
            active: _view == _TodoView.board,
            onTap: () => setState(
              () => _view = _view == _TodoView.list
                  ? _TodoView.board
                  : _TodoView.list,
            ),
          ),
          WorkspaceToolbarAction(
            icon: LucideIcons.ellipsis,
            label: context.strings.more,
            onTap: _showMoreSheet,
          ),
        ],
      ),
    ];
    if (MediaQuery.sizeOf(context).width >= desktopBreakpoint) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title3.copyWith(color: c.labelPrimary),
              ),
            ),
            for (final action in actions) ...[const SizedBox(width: 8), action],
          ],
        ),
      );
    }
    return WorkspaceNavBar(
      title: title,
      backLabel: context.strings.backToChatHome,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.home),
      actions: actions,
    );
  }

  Widget _buildViewSwitch(AppColors c) => SizedBox(
    width: 120,
    child: WorkspaceSegmentedControl(
      labels: [context.strings.list, context.strings.board],
      selectedIndex: _view.index,
      onChanged: (index) => setState(() => _view = _TodoView.values[index]),
    ),
  );

  Widget _bottomBar() => Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: WorkspaceBottomBar(
      searchController: _searchCtrl,
      hint: context.strings.searchTasks,
      onSearchChanged: (_) => setState(() {}),
      onClear: () => setState(_searchCtrl.clear),
      onAdd: _openCreateTodo,
      addLabel: context.strings.newTask,
    ),
  );

  Widget _buildSelectionBar(AppColors c, List<Todo> visible) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          AppButton(
            label: context.strings.cancel,
            type: AppButtonType.ghost,
            onPressed: _exitSelection,
          ),
          Expanded(
            child: Center(
              child: Text(
                context.strings.selectedBuildselectionbar(
                  _selectedVisibleIds(visible).length,
                ),
                style: AppTextStyles.subhead.copyWith(color: c.labelPrimary),
              ),
            ),
          ),
          AppButton(
            label:
                _selectedVisibleIds(visible).length == visible.length &&
                    visible.isNotEmpty
                ? context.strings.deselectAll
                : context.strings.selectAll,
            type: AppButtonType.ghost,
            onPressed: () => _toggleSelectAll(visible),
          ),
        ],
      ),
    );
  }

  // 快速过滤条（02 §3.3）
  Widget _buildFilterBar(AppColors c, TodoOverview overview) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TodoQuickFilterBar(
        selected: _filter,
        counts: overview.counts,
        onChanged: (filter) => setState(() => _filter = filter),
      ),
    );
  }

  // 列表视图
  Widget _buildListView(AppColors c, TodoOverview overview) {
    if (overview.visible.isEmpty) return _buildEmpty(c);
    final now = overview.now;
    final groups = overview.groups;

    final entries = <Object>[];
    for (final g in groups) {
      entries.add(g);
      if (!_collapsed.contains(g.key)) {
        for (var i = 0; i < g.todos.length; i++) {
          entries.add(g.todos[i]);
          if (i < g.todos.length - 1) entries.add(const _DividerEntry());
        }
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry is _DividerEntry) {
          return Divider(height: 0.5, indent: 56, color: c.separator);
        }
        if (entry is TodoGroup) {
          return _buildGroupHeader(c, entry);
        }
        final todo = entry as Todo;
        final (label, color) = _categoryDisplay(todo);
        final item = TodoListItem(
          key: ValueKey(todo.id),
          todo: todo,
          now: now,
          categoryLabel: label,
          categoryColor: color,
          selectionMode: _selectionMode,
          selected: _selectedIds.contains(todo.id),
          onTap: () => _openDetail(todo),
          onLongPress: () => _enterSelection(todo),
          onToggleDone: () => _toggleDone(todo),
          onToggleSelect: () => setState(() {
            if (_selectedIds.contains(todo.id)) {
              _selectedIds.remove(todo.id);
            } else {
              _selectedIds.add(todo.id);
            }
          }),
          onAiSourceTap: () {
            final chats = ref.read(sessionListProvider.notifier);
            final source = chats.messageById(todo.sourceMessageId);
            final session = chats.sessionById(source?.sessionId);
            if (session == null) {
              AppToast.show(
                context,
                message: context.strings.originalChatUnavailable,
              );
              return;
            }
            ref.read(currentSessionIdProvider.notifier).state = session.id;
            context.go(AppRoutes.home);
          },
        );
        return TodoSwipeRow(
          enabled: !_selectionMode,
          isDone: todo.status == TodoStatus.done,
          onComplete: () => _toggleDone(todo),
          onReschedule: () => _openReschedule(todo),
          onDelete: () => _softDelete(todo),
          child: Container(color: c.bgGround, child: item),
        );
      },
    );
  }

  Widget _buildGroupHeader(AppColors c, TodoGroup group) {
    final collapsed = _collapsed.contains(group.key);
    return AppPressable(
      onTap: () => setState(() {
        if (collapsed) {
          _collapsed.remove(group.key);
        } else {
          _collapsed.add(group.key);
        }
      }),

      behavior: HitTestBehavior.opaque,
      semanticLabel: context.strings.itemsBuildgroupheader(
        group.title,
        group.todos.length,
      ),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (group.dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.categoryAccent(group.dotColor!),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ] else ...[
              AnimatedRotation(
                turns: collapsed ? -0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: c.labelSecondary,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              group.title,
              style: AppTextStyles.subhead.copyWith(color: c.labelPrimary),
            ),
            const SizedBox(width: 6),
            Text(
              '${group.todos.length}',
              style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
            ),
            if (group.dotColor != null) ...[
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: collapsed ? -0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: c.labelTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 看板视图（02 §3.5）

  // 空状态（02 §6.2，按过滤语境分文案）
  Widget _buildEmpty(AppColors c) {
    final allTodos = ref.read(todoListProvider);
    if (_searchCtrl.text.trim().isNotEmpty) {
      return AppEmptyState(
        icon: LucideIcons.search,
        title: context.strings.noMatchingTasks,
      );
    }
    switch (_filter) {
      case TodoQuickFilter.all:
        if (allTodos.isEmpty) {
          return AppEmptyState(
            icon: LucideIcons.sparkles,
            title: context.strings.noTasks,
            actionLabel: context.strings.goToChatBuildempty,
            onAction: () => context.go(AppRoutes.home),
          );
        }
        return AppEmptyState(
          icon: LucideIcons.inbox,
          title: context.strings.thisListIsEmpty,
          actionLabel: context.strings.newTask,
          onAction: _openCreateTodo,
        );
      case TodoQuickFilter.today:
        return AppEmptyState(
          icon: LucideIcons.sun,
          title: context.strings.noTasksToday,
          actionLabel: context.strings.newTask,
          onAction: _openCreateTodo,
        );
      case TodoQuickFilter.week:
        return AppEmptyState(
          icon: LucideIcons.calendar,
          title: context.strings.nothingScheduledThisWeek,
        );
      case TodoQuickFilter.overdue:
        return AppEmptyState(
          icon: LucideIcons.circleCheck,
          title: context.strings.noOverdueTasks,
        );
      case TodoQuickFilter.noDue:
        return AppEmptyState(
          icon: LucideIcons.wind,
          title: context.strings.noTasksWithoutADueDate,
        );
      case TodoQuickFilter.done:
        return AppEmptyState(
          icon: LucideIcons.circleCheck,
          title: context.strings.noCompletedTasksYet,
        );
    }
  }

  // 从当前分类和看板列开始编辑。
  void _openCreateTodo([TodoStatus status = TodoStatus.pending]) {
    AppSheet.show<void>(
      context,
      child: CreateTodoSheet(categoryId: _effectiveCategoryId, status: status),
    );
  }

  // 「⋯」菜单（02 §5.5）
  void _showMoreSheet() {
    AppSheet.show<void>(
      context,
      title: context.strings.listSettings,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final c = AppColors.of(context);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_categoryFilterId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildViewSwitch(c),
                ),
              if (_categoryFilterId == null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    context.strings.groupBy,
                    style: AppTextStyles.footnote.copyWith(
                      color: c.labelTertiary,
                    ),
                  ),
                ),
                for (final (label, by) in [
                  (
                    context.strings.byCategoryShowmoresheet,
                    TodoGroupBy.category,
                  ),
                  (context.strings.byDueDate, TodoGroupBy.due),
                  (context.strings.byPriority, TodoGroupBy.priority),
                ])
                  TodoOptionMenuRow(
                    label: label,
                    selected: _groupBy == by,
                    onTap: () {
                      setState(() => _groupBy = by);
                      setSheetState(() {});
                    },
                  ),
              ],
              Divider(height: 16, color: c.separator),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.strings.showCompleted,
                          style: AppTextStyles.body.copyWith(
                            color: c.labelPrimary,
                          ),
                        ),
                      ),
                      Switch(
                        value: _showCompleted,
                        onChanged: (v) {
                          setState(() => _showCompleted = v);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
              TodoOptionMenuRow(
                icon: LucideIcons.folder,
                label: context.strings.manageCategories,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(AppRoutes.categories);
                },
              ),
              if (_categoryFilterId != null)
                TodoOptionMenuRow(
                  icon: LucideIcons.list,
                  label: context.strings.allTasks,
                  onTap: () {
                    Navigator.of(context).pop();
                    this.context.go(AppRoutes.todos);
                  },
                ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  // 批量操作工具条（02 §5.4）
  Widget _buildBatchBar(AppColors c, List<Todo> visible) {
    Widget action(
      IconData icon,
      String label,
      VoidCallback onTap, {
      Color? color,
    }) {
      return Expanded(
        child: AppPressable(
          onTap: onTap,

          behavior: HitTestBehavior.opaque,
          semanticLabel: context.strings.selectedAction(
            label,
            _selectedVisibleIds(visible).length,
          ),
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color ?? c.labelPrimary),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: color ?? c.labelSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: c.bgPrimary,
        border: Border(top: BorderSide(color: c.separator, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            action(
              LucideIcons.check,
              context.strings.complete,
              () => _batchDone(visible),
            ),
            action(
              LucideIcons.folder,
              context.strings.changeCategory,
              () => _batchSetCategory(visible),
            ),
            action(
              LucideIcons.calendar,
              context.strings.changeDueDate,
              () => _batchSetDue(visible),
            ),
            action(
              LucideIcons.trash2,
              context.strings.deleteLabel,
              () => _batchDelete(visible),
              color: c.labelPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 条目间内缩分割线占位类型。
class _DividerEntry {
  const _DividerEntry();
}
