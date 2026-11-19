import '../../../app/routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/workspace_state.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_inline_input.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../../app/providers.dart';
import '../../../core/workspace_actions.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/todo/todo_detail_sheet.dart';

/// History stays on its own surface; only the bottom search controls float.
/// Capture the router before opening because a mobile drawer can close while
/// this route is visible and its original BuildContext can be disposed.
Future<void> showWorkspaceSearch(BuildContext context) async {
  final router = GoRouter.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final sessionId = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭搜索',
    barrierColor: AppColors.of(context).scrim.withValues(alpha: .2),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const _WorkspaceSearch(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      if (MediaQuery.disableAnimationsOf(context)) return child;
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .025),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
  if (sessionId == null) return;
  container.read(currentSessionIdProvider.notifier).state = sessionId;
  router.go(AppRoutes.home);
}

class _WorkspaceSearch extends ConsumerStatefulWidget {
  const _WorkspaceSearch();

  @override
  ConsumerState<_WorkspaceSearch> createState() => _WorkspaceSearchState();
}

class _WorkspaceSearchState extends ConsumerState<_WorkspaceSearch> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _changeQuery(String value) {
    setState(() => _query = value.trim().toLowerCase());
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _clearQuery() {
    _controller.clear();
    _changeQuery('');
    _focus.requestFocus();
  }

  /// 空态/无结果的出口动作：关掉搜索回到对话页，让用户直接说一句。
  void _exitToConversation() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(AppRoutes.home);
  }

  void _openTodo(Todo todo) {
    _focus.unfocus();
    showTodoDetailSheet(
      context,
      todo.id,
      onDeleted: (deleted) async {
        final change = await workspaceUi(
          context,
          () => ref
              .read(workspaceUiCommandsProvider)
              .run((t, c) => t.removeById(deleted.id)),
        );
        if (!mounted || change == null) return;
        AppToast.show(
          context,
          message: '已删除',
          actionLabel: '撤销',
          onAction: () => workspaceUi(context, change.undo),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final media = MediaQuery.of(context);
    final desktop = media.size.width >= desktopBreakpoint;
    final sessions =
        ref
            .watch(sessionListProvider)
            .where(
              (session) =>
                  _query.isEmpty ||
                  '${session.title} ${session.lastMessagePreview}'
                      .toLowerCase()
                      .contains(_query),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final todos = _query.isEmpty
        ? <Todo>[]
        : ref
              .watch(todoListProvider)
              .where(
                (todo) => '${todo.title} ${todo.note ?? ''}'
                    .toLowerCase()
                    .contains(_query),
              )
              .toList();
    final hasResults = sessions.isNotEmpty || todos.isNotEmpty;
    final horizontal = desktop ? 24.0 : 16.0;
    final bottomInset = media.viewInsets.bottom > 0
        ? 0.0
        : media.viewPadding.bottom;

    final surface = Material(
      key: const ValueKey('workspace-search-surface'),
      color: c.bgSecondary,
      borderRadius: desktop ? BorderRadius.circular(32) : BorderRadius.zero,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: !desktop,
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              key: const ValueKey('workspace-search-results'),
              controller: _scroll,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                if (sessions.isNotEmpty || _query.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal + 4,
                      desktop ? 20 : 16,
                      horizontal + 4,
                      6,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                        header: true,
                        child: Text(
                          '历史会话',
                          style: AppTextStyles.subhead.copyWith(
                            color: c.labelPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!hasResults)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal + 4,
                      16,
                      horizontal + 4,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: AppEmptyState(
                        icon: LucideIcons.search,
                        title: _query.isEmpty ? '暂无会话' : '无搜索结果',
                        actionLabel: '去对话页',
                        onAction: _exitToConversation,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  sliver: SliverList.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return _SearchResultRow(
                        key: ValueKey('search-session-${session.id}'),
                        title: session.title,
                        desktop: desktop,
                        onTap: () => Navigator.of(context).pop(session.id),
                      );
                    },
                  ),
                ),
                if (todos.isNotEmpty) ...[
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal + 4,
                      sessions.isEmpty ? 16 : 12,
                      horizontal + 4,
                      4,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                        header: true,
                        child: Text(
                          '待办',
                          style: AppTextStyles.body.copyWith(
                            color: c.labelSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: horizontal),
                    sliver: SliverList.builder(
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        final todo = todos[index];
                        return _SearchResultRow(
                          key: ValueKey('search-todo-${todo.id}'),
                          title: todo.title,
                          desktop: desktop,
                          onTap: () => _openTodo(todo),
                        );
                      },
                    ),
                  ),
                ],
                SliverToBoxAdapter(child: SizedBox(height: 80 + bottomInset)),
              ],
            ),
            Positioned(
              left: desktop ? 28 : 14,
              right: desktop ? 28 : 14,
              bottom: (desktop ? 24 : 16) + (desktop ? 0 : bottomInset),
              child: Row(
                key: const ValueKey('workspace-search-controls'),
                children: [
                  Expanded(
                    child: GlassSurface(
                      key: const ValueKey('workspace-search-capsule'),
                      radius: 30,
                      padding: const EdgeInsets.only(left: 14, right: 4),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.search,
                              size: 18,
                              color: c.labelSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Semantics(
                                label: '搜索会话和待办',
                                child: TextField(
                                  key: const ValueKey('workspace-search-input'),
                                  controller: _controller,
                                  focusNode: _focus,
                                  autofocus: desktop,
                                  onChanged: _changeQuery,
                                  onSubmitted: (_) => _focus.unfocus(),
                                  textInputAction: TextInputAction.search,
                                  keyboardAppearance: Theme.of(context)
                                      .brightness,
                                  style: AppTextStyles.body.copyWith(
                                    color: c.labelPrimary,
                                  ),
                                  decoration: appInlineInput(
                                    hintText: '搜索',
                                    hintStyle: AppTextStyles.body.copyWith(
                                      color: c.labelTertiary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_controller.text.isNotEmpty)
                              IconButton(
                                key: const ValueKey('workspace-search-clear'),
                                tooltip: '清除搜索',
                                icon: Icon(
                                  LucideIcons.circleX,
                                  color: c.labelSecondary,
                                  size: 18,
                                ),
                                onPressed: _clearQuery,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GlassIconButton(
                    key: const ValueKey('workspace-search-close'),
                    icon: LucideIcons.x,
                    label: '关闭搜索',
                    size: 48,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: Focus(
        autofocus: !desktop,
        child: AnimatedPadding(
          duration: media.disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: desktop
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 920,
                          maxHeight: 720,
                        ),
                        child: surface,
                      ),
                    ),
                  ),
                )
              : surface,
        ),
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    super.key,
    required this.title,
    required this.desktop,
    required this.onTap,
  });

  final String title;
  final bool desktop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppPressable(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: desktop ? 44 : 48),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: AppColors.of(context).labelPrimary,
            ),
          ),
        ),
      ),
    ),
  );
}
