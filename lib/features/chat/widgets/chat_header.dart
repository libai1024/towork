import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/glass_surface.dart';
import '../../../theme/app_colors.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.desktop,
    required this.onMenu,
    required this.onSearch,
    required this.onOverview,
    required this.onNew,
    this.onOptions,
  });

  final bool desktop;
  final VoidCallback onMenu, onSearch, onOverview, onNew;
  final VoidCallback? onOptions;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final opacity = Theme.of(context).brightness == Brightness.dark ? .45 : .62;
    Widget action(IconData icon, String label, VoidCallback onTap) =>
        IconButton(
          tooltip: label,
          onPressed: onTap,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: Icon(icon, size: 19, color: colors.labelPrimary),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          if (!desktop)
            GlassIconButton(
              size: 48,
              icon: LucideIcons.menu,
              iconSize: 20,
              label: context.strings.openMenu,
              onTap: onMenu,
              elevated: false,
              opacity: opacity,
              blur: 18,
            ),
          const Spacer(),
          GlassSurface(
            key: const ValueKey('chat-header-glass'),
            radius: 24,
            elevated: false,
            opacity: opacity,
            blur: 18,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                action(
                  LucideIcons.search,
                  context.strings.searchChatsAndTasks,
                  onSearch,
                ),
                action(
                  LucideIcons.listTodo,
                  context.strings.openDailyOverview,
                  onOverview,
                ),
                action(
                  LucideIcons.squarePen,
                  context.strings.newChatBuild,
                  onNew,
                ),
                if (onOptions != null)
                  action(
                    LucideIcons.ellipsis,
                    context.strings.chatOptions,
                    onOptions!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
