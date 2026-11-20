import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import 'app_pressable.dart';
import 'workspace_nav_bar.dart';

/// A floating search capsule and a separate primary action, above solid content.
/// Place within a SafeArea, with 88px of content padding when overlaid in a Stack.
class WorkspaceBottomBar extends StatelessWidget {
  const WorkspaceBottomBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClear,
    this.onAdd,
    this.addLabel,
    this.hint,
    this.focusNode,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;
  final VoidCallback? onAdd;
  final String? addLabel;
  final String? hint;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: WorkspaceSearchField(
              controller: searchController,
              focusNode: focusNode,
              hint: hint ?? context.strings.search,
              onChanged: onSearchChanged,
              onClear: onClear,
            ),
          ),
          if (onAdd != null) ...[
            const SizedBox(width: 10),
            WorkspaceAddButton(
              label: addLabel ?? context.strings.newLabel,
              onTap: onAdd!,
            ),
          ],
        ],
      ),
    );
  }
}

class WorkspaceAddButton extends StatelessWidget {
  const WorkspaceAddButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: AppPressable(
        semanticLabel: label,
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: c.labelPrimary,
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.plus, size: 24, color: c.bgPrimary),
        ),
      ),
    );
  }
}
