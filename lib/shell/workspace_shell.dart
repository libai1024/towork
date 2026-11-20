import 'package:towork/l10n/strings.dart';

import '../app/routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/widgets/work_mark.dart';
import '../features/chat/widgets/chat_drawer.dart';
import '../features/chat/widgets/workspace_search.dart';
import '../theme/app_colors.dart';
import '../app/workspace_state.dart';

/// A persistent desktop workspace, with a single nested navigator for all tools.
/// Phones retain native full-screen navigation and a drawer on the chat page.
class WorkspaceShell extends ConsumerWidget {
  const WorkspaceShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (MediaQuery.sizeOf(context).width < desktopBreakpoint) return child;
    final c = AppColors.of(context);
    final expanded = ref.watch(sidebarExpandedProvider);
    final session = ref.watch(currentSessionIdProvider);
    void toggle() =>
        ref.read(sidebarExpandedProvider.notifier).state = !expanded;
    void newChat() {
      ref.read(currentSessionIdProvider.notifier).state = null;
      context.go(AppRoutes.home);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            showWorkspaceSearch(context),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            showWorkspaceSearch(context),
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): newChat,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): newChat,
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true): toggle,
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): toggle,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: c.bgSecondary,
          body: Row(
            children: [
              SizedBox(
                width: expanded ? 276 : 60,
                child: expanded
                    ? ChatDrawer(
                        desktop: true,
                        onCollapse: toggle,
                        currentSessionId: session,
                        onNewSession: newChat,
                        onSessionSelected: (id) {
                          ref.read(currentSessionIdProvider.notifier).state =
                              id;
                          context.go(AppRoutes.home);
                        },
                      )
                    : SafeArea(
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            const WorkMark(size: 30),
                            const SizedBox(height: 18),
                            IconButton(
                              tooltip: context.strings.expandSidebar,
                              onPressed: toggle,
                              icon: const Icon(
                                LucideIcons.panelLeftOpen,
                                size: 20,
                              ),
                            ),
                            IconButton(
                              tooltip: context.strings.newChatBuild,
                              onPressed: newChat,
                              icon: const Icon(
                                LucideIcons.messageCirclePlus,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 20),
                            for (final (icon, label, path) in workspaceEntries)
                              IconButton(
                                tooltip: label,
                                onPressed: () => context.go(path),
                                icon: Icon(icon, size: 20),
                              ),
                            const Spacer(),
                            IconButton(
                              tooltip: context.strings.search,
                              onPressed: () => showWorkspaceSearch(context),
                              icon: const Icon(LucideIcons.search, size: 20),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 6, 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
