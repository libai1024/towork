import 'package:towork/l10n/strings.dart';

import '../../app/routes.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/workspace_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import '../../app/providers.dart';
import '../../core/workspace_actions.dart';
import '../../domain/models/models.dart';
import '../../domain/use_cases/category_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../core/categories/widgets/category_action_sheets.dart';
import '../../core/categories/widgets/category_edit_sheet.dart';
import 'widgets/category_row.dart';

part 'category_drop_intent.dart';

/// 分类管理（04-categories.md）：两级分类树 + 统计摘要 + 拖拽排序/升降级 +
/// 归档区 + 空状态示例。全部数据读写走 mock 仓库，对话页侧栏实时同步。
class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  final _scrollController = ScrollController();
  final Set<String> _expanded = {};
  final Map<String, BuildContext> _rowContexts = {};

  bool _archiveExpanded = false;
  bool _sortMode = false;
  bool _scrolled = false;
  bool _entranceAnim = false;

  /// 完成过一次拖拽后永久隐藏底部提示（本会话内生效，04 §3.2 底部提示）。

  // 拖拽状态
  String? _draggingId;
  _DropIntent? _dropIntent;
  bool _illegalHover = false;
  String? _illegalAnchorId;
  Timer? _dwellTimer;
  String? _dwellRowId;

  UiCategoryUndo? _pendingUndo;
  Timer? _undoTimer;

  WorkspaceUiCommands get _categoryActions =>
      ref.read(workspaceUiCommandsProvider);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 8;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    _undoTimer?.cancel();
    _pendingUndo?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 构建
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    ref.watch(categoryListProvider);
    ref.watch(todoListProvider);
    final repo = ref.read(categoryListProvider.notifier);
    final roots = repo.roots;
    final archivedRoots = repo.archivedRoots;

    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            _navBar(roots.isNotEmpty),
            AnimatedOpacity(
              opacity: _scrolled ? 1 : 0,
              duration: AppMotion.tabSwitch,
              child: Container(height: 0.5, color: c.separator),
            ),
            Expanded(
              child: roots.isEmpty && archivedRoots.isEmpty
                  ? _buildEmpty(c)
                  : _buildList(c, roots, archivedRoots),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBar(bool canSort) => WorkspaceNavBar(
    title: context.strings.category,
    backLabel: _sortMode
        ? context.strings.exitReorderMode
        : context.strings.back,
    onBack: _sortMode
        ? () => setState(() => _sortMode = false)
        : () => context.popOrGo(AppRoutes.home),
    actions: [
      WorkspaceToolbarGroup(
        children: [
          if (!_sortMode && canSort)
            WorkspaceToolbarAction(
              icon: LucideIcons.arrowDownUp,
              label: context.strings.reorderCategories,
              onTap: _enterSortMode,
            ),
          WorkspaceToolbarAction(
            label: _sortMode
                ? context.strings.finishReordering
                : context.strings.newCategory,
            text: _sortMode ? context.strings.complete : null,
            icon: _sortMode ? LucideIcons.check : LucideIcons.plus,
            onTap: _sortMode
                ? () => setState(() => _sortMode = false)
                : _createCategory,
          ),
        ],
      ),
    ],
  );

  Widget _buildList(
    AppColors c,
    List<Category> roots,
    List<Category> archivedRoots,
  ) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (roots.isNotEmpty) ...[
          if (archivedRoots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                context.strings.inUse,
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
            )
          else
            const SizedBox(height: 4),
          _maybeEntranceAnimated(_buildActiveCard(c, roots)),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              context.strings.allCategoriesArchived,
              style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
            ),
          ),
        if (archivedRoots.isNotEmpty) _buildArchiveSection(c, archivedRoots),
        if (_sortMode) _buildSortHint(c),
      ],
    );
  }

  /// 空状态（04 §3.5）：图标 + 主文案 + 双按钮 + 预置示例说明。
  Widget _buildEmpty(AppColors c) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.folderTree, size: 32, color: c.labelTertiary),
                const SizedBox(height: 8),
                Text(
                  context.strings.noCategories,
                  style: AppTextStyles.title3.copyWith(color: c.labelSecondary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 240,
                  child: AppButton(
                    label: context.strings.createSampleCategories,
                    expand: true,
                    onPressed: _createSamples,
                  ),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: context.strings.newCategory,
                  type: AppButtonType.ghost,
                  onPressed: _createCategory,
                ),
                const SizedBox(height: 4),
                Text(
                  context.strings.createsInvestingArchivesAndFamily,
                  style: AppTextStyles.caption.copyWith(
                    color: c.labelQuaternary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 示例创建后的整表进入动效（04 §3.5：200ms ease-out 淡入 + translateY 8→0）。
  Widget _maybeEntranceAnimated(Widget child) {
    if (!_entranceAnim) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.tabSwitch,
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  /// 活动分类按层级缩进。
  Widget _buildActiveCard(AppColors c, List<Category> roots) {
    final repo = ref.read(categoryListProvider.notifier);
    final children = <Widget>[];
    for (var i = 0; i < roots.length; i++) {
      final root = roots[i];
      final kids = repo.childrenOf(root.id);
      if (_sortMode) {
        children.add(_gapIndicator(c, null, i, kCategoryRowLeft));
      }
      if (i > 0) children.add(_separator(c, kRootSeparatorIndent));
      children.add(_activeRow(c, root, isChild: false));
      if (kids.isNotEmpty) {
        children.add(_buildChildren(c, root, kids));
      }
    }
    if (_sortMode) {
      children.add(_gapIndicator(c, null, roots.length, kCategoryRowLeft));
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        borderRadius: AppRadii.brLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  /// 子分类块：与父级之间不画线，子分类之间画线（左缩进 44+24+12）。
  Widget _buildChildren(AppColors c, Category root, List<Category> kids) {
    final expanded = _expanded.contains(root.id);
    final rows = <Widget>[];
    for (var j = 0; j < kids.length; j++) {
      if (_sortMode) {
        rows.add(_gapIndicator(c, root.id, j, kChildRowIndent));
      }
      if (j > 0) rows.add(_separator(c, kChildSeparatorIndent));
      rows.add(_activeRow(c, kids[j], isChild: true));
    }
    if (_sortMode) {
      rows.add(_gapIndicator(c, root.id, kids.length, kChildRowIndent));
    }
    return AnimatedSize(
      duration: AppMotion.tabSwitch,
      curve: Curves.easeOut,
      child: expanded
          ? Column(children: rows)
          : const SizedBox(width: double.infinity, height: 0),
    );
  }

  Widget _activeRow(AppColors c, Category category, {required bool isChild}) {
    final repo = ref.read(categoryListProvider.notifier);
    final stats = ref.watch(categoryStatsProvider(category.id));
    final hasChildren = !isChild && repo.childrenOf(category.id).isNotEmpty;
    final row = CategoryRow(
      category: category,
      stats: stats,
      isChild: isChild,
      hasChildren: hasChildren,
      expanded: _expanded.contains(category.id),
      sortMode: _sortMode,
      dropHighlighted: _dropIntent?.demoteTargetId == category.id,
      dragging: _draggingId == category.id,
      onTap: () => _openEdit(category),
      onLongPress: _enterSortMode,
      onToggleExpand: () => setState(() {
        if (_expanded.contains(category.id)) {
          _expanded.remove(category.id);
        } else {
          _expanded.add(category.id);
        }
      }),
      onMore: () => _openActions(category),
      onDragStarted: () => setState(() => _draggingId = category.id),
      onDragEnded: _onDragEnded,
    );
    if (!_sortMode) return row;
    return _rowDropTarget(category, isChild: isChild, child: row);
  }

  /// 已归档区（04 §3.2）：默认收起，标题行 44；归档行灰化、停止统计完成率。
  Widget _buildArchiveSection(AppColors c, List<Category> archivedRoots) {
    final repo = ref.read(categoryListProvider.notifier);
    final section = Column(
      children: [
        AppPressable(
          onTap: () => setState(() => _archiveExpanded = !_archiveExpanded),
          behavior: HitTestBehavior.opaque,
          semanticLabel: _archiveExpanded
              ? context.strings.archivedTapToCollapse
              : context.strings.archivedTapToExpand,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(LucideIcons.archive, size: 16, color: c.labelTertiary),
                  const SizedBox(width: 8),
                  Text(
                    context.strings.archived(archivedRoots.length),
                    style: AppTextStyles.footnote.copyWith(
                      color: c.labelTertiary,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _archiveExpanded ? 0.25 : 0,
                    duration: AppMotion.tabSwitch,
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: c.labelTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.tabSwitch,
          curve: Curves.easeOut,
          child: !_archiveExpanded
              ? const SizedBox(width: double.infinity, height: 0)
              : Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: c.bgPrimary,
                    borderRadius: AppRadii.brLg,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < archivedRoots.length; i++) ...[
                        if (i > 0) _separator(c, kRootSeparatorIndent),
                        _archivedRow(c, archivedRoots[i], repo),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
    if (!_sortMode) return section;
    // 拖到「已归档」区 = 非法落点（04 §5.6）。
    return DragTarget<Category>(
      onWillAcceptWithDetails: (_) => true,
      onMove: (_) =>
          _setDragState(intent: null, illegal: true, illegalAnchor: '_archive'),
      onLeave: (_) {
        if (_illegalAnchorId == '_archive') {
          _setDragState(intent: null, illegal: false);
        }
      },
      onAcceptWithDetails: (_) => _onRowDragAccept(null),
      builder: (context, candidateData, rejectedData) => section,
    );
  }

  Widget _archivedRow(AppColors c, Category category, CategoryStore repo) {
    final stats = ref.watch(categoryStatsProvider(category.id));
    final kids = repo.archivedChildrenOf(category.id);
    return Column(
      children: [
        CategoryRow(
          category: category,
          stats: stats,
          archived: true,
          hasChildren: kids.isNotEmpty,
          expanded: _expanded.contains(category.id),
          onTap: () => _openArchivedActions(category),
          onToggleExpand: () => setState(() {
            if (_expanded.contains(category.id)) {
              _expanded.remove(category.id);
            } else {
              _expanded.add(category.id);
            }
          }),
        ),
        if (kids.isNotEmpty && _expanded.contains(category.id))
          for (var j = 0; j < kids.length; j++) ...[
            if (j > 0) _separator(c, kChildSeparatorIndent),
            CategoryRow(
              category: kids[j],
              stats: ref.watch(categoryStatsProvider(kids[j].id)),
              isChild: true,
              archived: true,
              onTap: () => _openArchivedActions(kids[j]),
            ),
          ],
      ],
    );
  }

  Widget _separator(AppColors c, double indent) => Container(
    margin: EdgeInsets.only(left: indent),
    height: 0.5,
    color: c.separator,
  );

  /// 落点指示线：2px brand r-full（04 §5.6），仅在命中该间隙时出现。
  Widget _gapIndicator(
    AppColors c,
    String? parentId,
    int index,
    double indent,
  ) {
    final intent = _dropIntent;
    final active =
        intent != null &&
        !intent.isDemote &&
        intent.parentId == parentId &&
        intent.index == index;
    if (!active) return const SizedBox.shrink();
    return Container(
      height: 2,
      margin: EdgeInsets.only(left: indent, right: 16),
      decoration: BoxDecoration(color: c.brand, borderRadius: AppRadii.brFull),
    );
  }

  /// 底部提示：正常态「长按可拖拽排序」（完成过一次拖拽后隐藏）；
  /// 排序态显示落点规则（04 §3.3）。
  Widget _buildSortHint(AppColors c) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    child: Column(
      children: [
        Text(
          context.strings.dropBetweenTopLevelRowsToReorder,
          style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
        ),
        const SizedBox(height: 4),
        Text(
          context.strings.dropOntoATopLevelRowTo,
          style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // 拖拽（排序模式，04 §5.6）
  // ---------------------------------------------------------------------------

  void _enterSortMode() {
    HapticFeedback.mediumImpact();
    setState(() => _sortMode = true);
  }

  /// 行体即落点热区：上 30% = 上方间隙，下 30% = 下方间隙，
  /// 一级行中段 40% 悬停 350ms = 降级为其子分类。
  Widget _rowDropTarget(
    Category category, {
    required bool isChild,
    required Widget child,
  }) {
    return DragTarget<Category>(
      onWillAcceptWithDetails: (details) => details.data.id != category.id,
      onMove: (details) => _onRowDragMove(category, isChild, details),
      onLeave: (_) => _onRowDragLeave(category),
      onAcceptWithDetails: (details) => _onRowDragAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        _rowContexts[category.id] = context;
        return child;
      },
    );
  }

  void _onRowDragMove(
    Category row,
    bool rowIsChild,
    DragTargetDetails<Category> details,
  ) {
    final box = _rowContexts[row.id]?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final fraction = (box.globalToLocal(details.offset).dy / box.size.height)
        .clamp(0.0, 1.0);
    final payload = details.data;

    if (!rowIsChild && fraction > 0.3 && fraction < 0.7) {
      if (_canDemote(payload, row)) {
        _startDwell(row);
        return;
      }
      _cancelDwell();
      _setDragState(intent: null, illegal: true, illegalAnchor: row.id);
      return;
    }
    _cancelDwell();
    final intent = fraction <= (rowIsChild ? 0.5 : 0.3)
        ? _gapAbove(row)
        : _gapBelow(row);
    if (!_gapLegal(payload, intent.parentId)) {
      _setDragState(intent: null, illegal: true, illegalAnchor: row.id);
      return;
    }
    _setDragState(intent: intent, illegal: false);
  }

  void _onRowDragLeave(Category row) {
    if (_dwellRowId == row.id) _cancelDwell();
    if (_dropIntent?.anchorId == row.id || _illegalAnchorId == row.id) {
      _setDragState(intent: null, illegal: false);
    }
  }

  void _onRowDragAccept(Category? payload) {
    final intent = _dropIntent;
    _cancelDwell();
    setState(() {
      _dropIntent = null;
      _illegalHover = false;
      _illegalAnchorId = null;
    });
    if (intent == null || payload == null) {
      HapticFeedback.heavyImpact();
      AppToast.show(context, message: context.strings.upToTwoCategoryLevels);
      return;
    }
    _applyDrop(payload, intent);
  }

  Future<void> _applyDrop(Category payload, _DropIntent intent) async {
    final ok = await workspaceUi(
      context,
      () => _categoryActions.moveCategory(
        payload.id,
        intent.isDemote ? intent.demoteTargetId : intent.parentId,
        intent.isDemote ? 9999 : intent.index,
      ),
    );
    if (!mounted || ok == null) return;
    if (ok) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
      AppToast.show(context, message: context.strings.upToTwoCategoryLevels);
    }
  }

  void _onDragEnded() {
    _cancelDwell();
    setState(() {
      _draggingId = null;
      _dropIntent = null;
      _illegalHover = false;
      _illegalAnchorId = null;
    });
  }

  /// 350ms 驻留 = 降级落点（04 §5.6）：目标行 inset brand 描边 + brand25 底。
  void _startDwell(Category target) {
    if (_dwellRowId == target.id) return;
    _dwellTimer?.cancel();
    _dwellRowId = target.id;
    _dwellTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _dropIntent = _DropIntent.demote(target.id);
        _illegalHover = false;
        _illegalAnchorId = null;
      });
    });
  }

  void _cancelDwell() {
    _dwellTimer?.cancel();
    _dwellTimer = null;
    _dwellRowId = null;
  }

  /// 降级合法性：目标必须是一级，且被拖分类不含子分类（严格两级）。
  bool _canDemote(Category payload, Category targetRoot) {
    if (payload.id == targetRoot.id) return false;
    return ref
        .read(categoryListProvider.notifier)
        .childrenOf(payload.id)
        .isEmpty;
  }

  /// 间隙合法性：子级间隙不接受「含子分类的一级分类」（会产生第三级）。
  bool _gapLegal(Category payload, String? parentId) {
    if (parentId == null) return true;
    if (payload.parentId != null) return true;
    return ref
        .read(categoryListProvider.notifier)
        .childrenOf(payload.id)
        .isEmpty;
  }

  _DropIntent _gapAbove(Category row) {
    final repo = ref.read(categoryListProvider.notifier);
    final siblings = row.parentId == null
        ? repo.roots
        : repo.childrenOf(row.parentId!);
    final index = siblings.indexWhere((e) => e.id == row.id);
    return _DropIntent.gap(
      anchorId: row.id,
      parentId: row.parentId,
      index: index < 0 ? 0 : index,
    );
  }

  _DropIntent _gapBelow(Category row) {
    final repo = ref.read(categoryListProvider.notifier);
    // 展开的一级行下方间隙 = 其子分类列表首位。
    if (row.parentId == null && _expanded.contains(row.id)) {
      final kids = repo.childrenOf(row.id);
      if (kids.isNotEmpty) {
        return _DropIntent.gap(anchorId: row.id, parentId: row.id, index: 0);
      }
    }
    final siblings = row.parentId == null
        ? repo.roots
        : repo.childrenOf(row.parentId!);
    final index = siblings.indexWhere((e) => e.id == row.id);
    return _DropIntent.gap(
      anchorId: row.id,
      parentId: row.parentId,
      index: index < 0 ? 1 : index + 1,
    );
  }

  void _setDragState({
    _DropIntent? intent,
    required bool illegal,
    String? illegalAnchor,
  }) {
    final same =
        (_dropIntent == null && intent == null ||
            _dropIntent?.sameAs(intent) == true) &&
        _illegalHover == illegal;
    if (same) return;
    setState(() {
      _dropIntent = intent;
      _illegalHover = illegal;
      _illegalAnchorId = illegal ? illegalAnchor : null;
    });
  }

  // ---------------------------------------------------------------------------
  // 增删改（实时写入 mock 仓库，侧栏分类树同步）
  // ---------------------------------------------------------------------------

  Future<void> _createCategory() async {
    await CategoryEditSheet.showCreate(context);
  }

  Future<void> _createChild(Category parent) async {
    final created = await CategoryEditSheet.showCreate(
      context,
      parentId: parent.id,
      lockParent: true,
    );
    if (created != null && mounted) {
      setState(() => _expanded.add(parent.id));
    }
  }

  Future<void> _openEdit(Category category) async {
    final result = await CategoryEditSheet.showEdit(context, category);
    if (result == 'delete' && mounted) {
      await _deleteCategory(category.id);
    }
  }

  Future<void> _openActions(Category category) async {
    final repo = ref.read(categoryListProvider.notifier);
    final siblings = category.parentId == null
        ? repo.roots
        : repo.childrenOf(category.parentId!);
    final index = siblings.indexWhere((e) => e.id == category.id);
    final activeCount = ref
        .read(categoryListProvider)
        .where((e) => !e.archived)
        .length;
    final action = await showCategoryActions(
      context,
      isRoot: category.parentId == null,
      canSort: activeCount >= 2,
      canMoveUp: index > 0,
      canMoveDown: index >= 0 && index < siblings.length - 1,
    );
    if (action == null || !mounted) return;
    switch (action) {
      case CategoryAction.newChild:
        await _createChild(category);
      case CategoryAction.rename:
        await _openEdit(category);
      case CategoryAction.sort:
        _enterSortMode();
      case CategoryAction.moveUp:
        await workspaceUi(
          context,
          () => _categoryActions.moveWithin(category.id, -1),
        );
      case CategoryAction.moveDown:
        await workspaceUi(
          context,
          () => _categoryActions.moveWithin(category.id, 1),
        );
      case CategoryAction.archive:
        _archiveCategory(category);
      case CategoryAction.delete:
        await _deleteCategory(category.id);
    }
  }

  Future<void> _openArchivedActions(Category category) async {
    final action = await showArchivedActions(context);
    if (action == null || !mounted) return;
    switch (action) {
      case ArchivedAction.restore:
        try {
          final change = await _categoryActions.archiveCategory(
            category.id,
            false,
          );
          change.dispose();
          if (!mounted) return;
          AppToast.show(
            context,
            message: context.strings.restoredOpenarchivedactions(
              change.categoryName,
            ),
          );
        } catch (error) {
          if (mounted) {
            AppToast.show(context, message: workspaceErrorMessage(error));
          }
        }
      case ArchivedAction.delete:
        await _deleteCategory(category.id);
    }
  }

  /// 归档：轻操作无二次确认，Toast 带「撤销」（04 §5.5）。
  Future<void> _archiveCategory(Category category) async {
    try {
      final undo = await _categoryActions.archiveCategory(category.id, true);
      if (!mounted) {
        undo.dispose();
        return;
      }
      HapticFeedback.mediumImpact();
      _showUndo(
        undo,
        context.strings.archivedAndHiddenWhenCreatingTasks(undo.categoryName),
      );
    } catch (error) {
      if (mounted) {
        AppToast.show(context, message: workspaceErrorMessage(error));
      }
    }
  }

  /// Confirm deletion before changing data; the shared sheet offers cancellation.
  Future<void> _deleteCategory(String id) async {
    final repo = ref.read(categoryListProvider.notifier);
    final category = repo.byId(id);
    if (category == null) return;
    final subtree = repo.subtreeIds(id);
    final childCount = subtree.length - 1;
    final todos = ref.read(todoListProvider);
    final preview = _categoryActions.previewCategoryDelete(id);
    final todoCount = todos
        .where((t) => t.categoryId != null && subtree.contains(t.categoryId))
        .length;

    final release = _categoryActions.session?.holdAutomaticWork();
    CategoryDeleteStrategy? strategy;
    try {
      strategy = await showCategoryDeleteConfirm(
        context,
        name: category.name,
        todoCount: todoCount,
        childCount: childCount,
        seriesCount: preview.seriesCount,
        detachedCount: preview.detachedCount,
      );
    } finally {
      release?.call();
    }
    if (strategy == null || !mounted) return;

    try {
      final undo = await _categoryActions.deleteCategory(
        id,
        preview: preview,
        policy: strategy == CategoryDeleteStrategy.deleteAll
            ? CategoryDeletionPolicy.deleteSubtree
            : CategoryDeletionPolicy.keepTodosAndChildren,
      );
      if (!mounted) {
        undo.dispose();
        return;
      }
      HapticFeedback.mediumImpact();
      _showUndo(undo, context.strings.deletedEditcategory(undo.categoryName));
    } catch (error) {
      if (mounted) {
        AppToast.show(context, message: workspaceErrorMessage(error));
      }
    }
  }

  /// 空状态示例（04 §8.5 预置常量）：炒股/档案馆/家庭。
  Future<void> _createSamples() async {
    final c = AppColors.of(context);
    final saved = await workspaceUi(
      context,
      () => _categoryActions.run((t, repo) {
        repo.createCategory(
          name: context.strings.investing,
          color: c.categoryPalette[0],
          iconKey: 'trending-up',
        );
        repo.createCategory(
          name: context.strings.archives,
          color: c.categoryPalette[1],
          iconKey: 'archive',
        );
        repo.createCategory(
          name: context.strings.family,
          color: c.categoryPalette[2],
          iconKey: 'home',
        );
        return true;
      }),
    );
    if (!mounted || saved == null) return;
    setState(() => _entranceAnim = true);
  }

  void _showUndo(UiCategoryUndo undo, String message) {
    _undoTimer?.cancel();
    _pendingUndo?.dispose();
    _pendingUndo = undo;
    _undoTimer = Timer(const Duration(seconds: 3), undo.dispose);
    AppToast.show(
      context,
      message: message,
      actionLabel: context.strings.undo,
      onAction: () async {
        if (!mounted) return;
        final result = await workspaceUi(context, undo.undo);
        if (!mounted) return;
        _undoTimer?.cancel();
        if (result != null && result != CategoryUndoResult.restored) {
          AppToast.show(
            context,
            message: context.strings.relatedRecordsHaveChangedAndCannotBe,
          );
        }
      },
    );
  }
}
