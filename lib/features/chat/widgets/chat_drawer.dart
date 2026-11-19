import '../../../app/app_preferences_provider.dart';
import '../../../app/routes.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/membership/membership_badge.dart';
import '../../../app/providers.dart';
import '../../../core/workspace_actions.dart';
import '../../../domain/models/models.dart';
import '../../../domain/use_cases/category_actions.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'workspace_search.dart';
import '../../../core/categories/category_catalog.dart';
import '../../../core/categories/widgets/category_action_sheets.dart';
import '../../../core/categories/widgets/category_edit_sheet.dart';
import 'sidebar_controls.dart';
import 'sidebar_quota_strip.dart';

import 'package:flutter/services.dart';

const workspaceEntries = [
  (LucideIcons.listTodo, '待办', AppRoutes.todos),
  (LucideIcons.calendarDays, '日程', AppRoutes.visualization),
  (LucideIcons.fileText, '报告', AppRoutes.reports),
  (LucideIcons.table2, '数据', AppRoutes.dataTables),
  (LucideIcons.brain, '记忆', AppRoutes.memory),
  (LucideIcons.settings2, '设置', AppRoutes.settings),
];

/// Shared workspace destinations in two rows of three shortcuts.
class ChatDrawer extends ConsumerStatefulWidget {
  const ChatDrawer({
    super.key,
    required this.currentSessionId,
    required this.onSessionSelected,
    required this.onNewSession,
    this.desktop = false,
    this.onCollapse,
    this.onDismiss,
  });
  final String? currentSessionId;
  final ValueChanged<String> onSessionSelected;
  final VoidCallback onNewSession;
  final bool desktop;
  final VoidCallback? onCollapse;
  final VoidCallback? onDismiss;

  @override
  ConsumerState<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends ConsumerState<ChatDrawer> {
  bool _categoriesOpen = true;
  bool _sorting = false;
  final Set<String> _expanded = {};
  UiCategoryUndo? _pendingUndo;
  Timer? _undoTimer;

  @override
  void dispose() {
    _undoTimer?.cancel();
    _pendingUndo?.dispose();
    super.dispose();
  }

  void _close() {
    if (!widget.desktop) widget.onDismiss?.call();
  }

  /// 分类排序的无障碍等价操作：读屏自定义「上移/下移」落到
  /// [WorkspaceUiCommands.moveWithin]，与拖拽重排同一持久化链路。
  void _moveWithin(String categoryId, int delta) {
    workspaceUi(
      context,
      () => ref.read(workspaceUiCommandsProvider).moveWithin(categoryId, delta),
    );
  }

  void _go(String route) {
    _close();
    widget.desktop ? context.go(route) : context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final user = ref.watch(userProfileProvider);
    final sessions = ref.watch(sessionListProvider);
    final route = GoRouterState.of(context).uri;
    final categories = ref.watch(categoryListProvider);

    final controlHeight = math.max(
      44.0,
      MediaQuery.textScalerOf(context).scale(14) * (20 / 14) + 8,
    );
    final header = SidebarHeader(
      desktop: widget.desktop,
      user: user,
      height: controlHeight,
      onProfile: () => _go(AppRoutes.settings),
      onTier: () => _go(AppRoutes.membership),
      onNew: () {
        _close();
        widget.onNewSession();
      },
      onCollapse: widget.onCollapse,
    );
    final content = ListView(
      key: const ValueKey('sidebar-list'),
      padding: EdgeInsets.fromLTRB(
        12,
        widget.desktop ? 4 : controlHeight + 14,
        12,
        controlHeight + 16,
      ),
      children: [
        SidebarQuotaStrip(onOpen: () => _go(AppRoutes.modelAccounts)),
        GridView.count(
          key: const ValueKey('sidebar-feature-grid'),
          padding: EdgeInsets.zero,
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          mainAxisExtent: 40 + MediaQuery.textScalerOf(context).scale(12) * 2,
          children: [
            for (final (icon, label, path) in workspaceEntries)
              _feature(c, icon, label, path, route.path.startsWith(path)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppPressable(
                semanticLabel: _categoriesOpen ? '收起分类' : '展开分类',
                onTap: () => setState(() => _categoriesOpen = !_categoriesOpen),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      '分类',
                      style: AppTextStyles.footnote.copyWith(
                        color: c.labelSecondary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      _categoriesOpen
                          ? LucideIcons.chevronDown
                          : LucideIcons.chevronRight,
                      size: 12,
                      color: c.labelTertiary,
                    ),
                  ],
                ),
              ),
            ),
            // 排序模式不再只能长按进入：显式按钮对键盘/
            // 读屏/触屏用户同等可达（长按入口保留）。
            if (!_sorting)
              IconButton(
                tooltip: '分类排序',
                onPressed: _categoriesOpen
                    ? () => setState(() => _sorting = true)
                    : null,
                icon: Icon(
                  LucideIcons.arrowUpDown,
                  size: 16,
                  color: c.labelTertiary,
                ),
              ),
            if (_sorting)
              TextButton(
                onPressed: () => setState(() => _sorting = false),
                child: const Text('完成'),
              ),
            IconButton(
              tooltip: '新建分类',
              onPressed: () => CategoryEditSheet.showCreate(context),
              icon: Icon(
                LucideIcons.folderPlus,
                size: 16,
                color: c.labelTertiary,
              ),
            ),
          ],
        ),
        if (_categoriesOpen) ...[
          _categoryList(c, categories, route, null),
          _row(
            c,
            icon: LucideIcons.plus,
            label: '新建分类',
            muted: true,
            onTap: () => CategoryEditSheet.showCreate(context),
          ),
        ],
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Text(
            '历史会话',
            style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
          ),
        ),
        if (sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '暂无会话',
              style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
            ),
          ),
        for (var i = 0; i < sessions.length; i++) ...[
          if (i == 0 ||
              _group(sessions[i].updatedAt) !=
                  _group(sessions[i - 1].updatedAt))
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
              child: Text(
                _group(sessions[i].updatedAt),
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
            ),
          _row(
            c,
            label: sessions[i].title,
            selected:
                route.path == '/' && widget.currentSessionId == sessions[i].id,
            onTap: () {
              _close();
              widget.onSessionSelected(sessions[i].id);
            },
          ),
        ],
      ],
    );
    return Material(
      color: c.bgSecondary,
      child: SafeArea(
        child: Column(
          children: [
            if (widget.desktop)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                child: header,
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  content,
                  IgnorePointer(
                    child: CustomPaint(
                      painter: SidebarEdgeFade(
                        color: c.bgSecondary,
                        extent: controlHeight + 8,
                        showTop: !widget.desktop,
                      ),
                    ),
                  ),
                  if (!widget.desktop)
                    Positioned(top: 6, left: 14, right: 14, child: header),
                  Positioned(
                    bottom: 8,
                    left: 14,
                    right: 14,
                    child: SidebarSearchBar(
                      desktop: widget.desktop,
                      height: controlHeight,
                      onToggleTheme: _toggleTheme,
                      onSearch: () {
                        _close();
                        showWorkspaceSearch(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (widget.desktop)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 12, 12),
                child: Row(
                  children: [
                    AppAvatar(
                      nickname: user.nickname,
                      size: 32,
                      onTap: () => _go(AppRoutes.settings),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppPressable(
                        onTap: () => _go(AppRoutes.settings),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.nickname,
                              style: AppTextStyles.footnote,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            MembershipBadge(
                              tier: user.tier,
                              onTap: () => _go(AppRoutes.membership),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '切换明暗主题',
                      onPressed: _toggleTheme,
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.dark
                            ? LucideIcons.sun
                            : LucideIcons.moon,
                        size: 18,
                        color: c.labelSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleTheme() {
    savePreferences(context, ref, {
      'theme': Theme.of(context).brightness == Brightness.dark
          ? 'light'
          : 'dark',
    });
  }

  Widget _feature(
    AppColors c,
    IconData icon,
    String label,
    String path,
    bool selected,
  ) => AppPressable(
    semanticLabel: label,
    borderRadius: BorderRadius.circular(10),
    onTap: () => _go(path),
    child: Container(
      decoration: BoxDecoration(
        color: selected ? c.fill2 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 21,
            color: selected ? c.labelPrimary : c.labelSecondary,
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: selected ? c.labelPrimary : c.labelSecondary,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _categoryList(
    AppColors c,
    List<Category> all,
    Uri route,
    String? parentId,
  ) {
    final siblings =
        all.where((e) => e.parentId == parentId && !e.archived).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ReorderableListView.builder(
      key: ValueKey('sidebar-categories-${parentId ?? 'root'}'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      padding: EdgeInsets.zero,
      itemCount: siblings.length,
      onReorderItem: (oldIndex, newIndex) {
        workspaceUi(
          context,
          () => ref
              .read(workspaceUiCommandsProvider)
              .moveCategory(siblings[oldIndex].id, parentId, newIndex),
        );
      },
      proxyDecorator: (child, index, animation) => Material(
        color: c.bgPrimary,
        elevation: 5,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
      itemBuilder: (context, index) {
        final cat = siblings[index];
        final hasChildren = all.any((e) => e.parentId == cat.id && !e.archived);
        return Column(
          key: ValueKey('sidebar-category-${cat.id}'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: route.queryParameters['categoryId'] == cat.id
                    ? c.fill2
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppPressable(
                      minSize: 44,
                      semanticLabel: cat.name,
                      onLongPress: () {
                        HapticFeedback.selectionClick();
                        setState(() => _sorting = true);
                      },
                      onTap: () => _sorting
                          ? _editCategory(cat)
                          : _go(AppRoutes.todosForCategory(cat.id)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: c.categorySurface(cat.color),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                categoryIconFor(cat.iconKey),
                                size: 17,
                                color: c.categoryForeground,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                cat.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_sorting) ...[
                    IconButton(
                      tooltip: '编辑${cat.name}',
                      onPressed: () => _editCategory(cat),
                      icon: Icon(
                        LucideIcons.penLine,
                        size: 16,
                        color: c.labelSecondary,
                      ),
                    ),
                    ReorderableDragStartListener(
                      key: ValueKey('category-drag-${cat.id}'),
                      index: index,
                      child: Semantics(
                        label: '拖动排序${cat.name}',
                        // 拖拽手势读屏无法完成：提供 上移/下移 自定义
                        // 操作（走 moveWithin，与拖拽同一落库链路）。
                        customSemanticsActions: {
                          if (index > 0)
                            CustomSemanticsAction(label: '上移'): () =>
                                _moveWithin(cat.id, -1),
                          if (index < siblings.length - 1)
                            CustomSemanticsAction(label: '下移'): () =>
                                _moveWithin(cat.id, 1),
                        },
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            LucideIcons.gripHorizontal,
                            size: 18,
                            color: c.labelTertiary,
                          ),
                        ),
                      ),
                    ),
                  ] else if (hasChildren)
                    IconButton(
                      tooltip: '展开${cat.name}子分类',
                      onPressed: () => setState(
                        () => _expanded.contains(cat.id)
                            ? _expanded.remove(cat.id)
                            : _expanded.add(cat.id),
                      ),
                      icon: Icon(
                        _expanded.contains(cat.id)
                            ? LucideIcons.chevronDown
                            : LucideIcons.chevronRight,
                        size: 14,
                        color: c.labelTertiary,
                      ),
                    ),
                ],
              ),
            ),
            if (_expanded.contains(cat.id))
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _categoryList(c, all, route, cat.id),
              ),
          ],
        );
      },
    );
  }

  Future<void> _editCategory(Category category) async {
    final result = await CategoryEditSheet.showEdit(context, category);
    if (result != 'delete' || !mounted) return;
    final categories = ref.read(categoryListProvider.notifier);
    final subtree = categories.subtreeIds(category.id);
    final todos = ref.read(todoListProvider);
    final preview = ref
        .read(workspaceUiCommandsProvider)
        .previewCategoryDelete(category.id);
    final release = ref
        .read(workspaceUiCommandsProvider)
        .session
        ?.holdAutomaticWork();
    CategoryDeleteStrategy? strategy;
    try {
      strategy = await showCategoryDeleteConfirm(
        context,
        name: category.name,
        todoCount: todos
            .where((todo) => subtree.contains(todo.categoryId))
            .length,
        childCount: subtree.length - 1,
        seriesCount: preview.seriesCount,
        detachedCount: preview.detachedCount,
      );
    } finally {
      release?.call();
    }
    if (strategy != null && mounted) {
      try {
        final undo = await ref
            .read(workspaceUiCommandsProvider)
            .deleteCategory(
              category.id,
              preview: preview,
              policy: strategy == CategoryDeleteStrategy.deleteAll
                  ? CategoryDeletionPolicy.deleteSubtree
                  : CategoryDeletionPolicy.keepTodosAndChildren,
            );
        if (!mounted) {
          undo.dispose();
          return;
        }
        _undoTimer?.cancel();
        _pendingUndo?.dispose();
        _pendingUndo = undo;
        _undoTimer = Timer(const Duration(seconds: 3), undo.dispose);
        AppToast.show(
          context,
          message: '已删除「${undo.categoryName}」',
          actionLabel: '恢复',
          onAction: () async {
            if (!mounted) return;
            final result = await workspaceUi(context, undo.undo);
            if (!mounted) return;
            _undoTimer?.cancel();
            if (result != null && result != CategoryUndoResult.restored) {
              AppToast.show(context, message: '相关记录已变化，无法恢复');
            }
          },
        );
      } catch (error) {
        if (mounted) {
          AppToast.show(context, message: workspaceErrorMessage(error));
        }
      }
    }
  }

  Widget _row(
    AppColors c, {
    IconData? icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    bool muted = false,
    String? trailing,
  }) => AppPressable(
    semanticLabel: label,
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      constraints: BoxConstraints(minHeight: widget.desktop ? 44 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? c.fill1 : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: c.labelSecondary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: muted ? c.labelTertiary : c.labelPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
            ),
        ],
      ),
    ),
  );

  String _group(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = today
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    return days <= 0
        ? '今天'
        : days == 1
        ? '昨天'
        : days < 7
        ? '近 7 天'
        : '更早';
  }
}
