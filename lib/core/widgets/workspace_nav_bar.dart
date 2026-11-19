import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_pressable.dart';
import 'app_inline_input.dart';
import 'glass_surface.dart';

/// Floating navigation sits above content without enclosing the content in glass.
class WorkspaceNavBar extends StatelessWidget {
  const WorkspaceNavBar({
    super.key,
    required this.title,
    required this.onBack,
    this.backLabel = '返回',
    this.actions = const [],
  });

  final String title;
  final VoidCallback onBack;
  final String backLabel;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
    child: Row(
      children: [
        GlassIconButton(
          icon: LucideIcons.chevronLeft,
          iconSize: 20,
          elevated: false,
          label: backLabel,
          onTap: onBack,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title3.copyWith(
                color: AppColors.of(context).labelPrimary,
              ),
            ),
          ),
        ),
        for (final action in actions) ...[const SizedBox(width: 6), action],
      ],
    ),
  );
}

/// Related toolbar actions share one material instead of stacking glass surfaces.
class WorkspaceToolbarGroup extends StatelessWidget {
  const WorkspaceToolbarGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => GlassSurface(
    elevated: false,
    child: Row(mainAxisSize: MainAxisSize.min, children: children),
  );
}

class WorkspaceToolbarAction extends StatelessWidget {
  const WorkspaceToolbarAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.text,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = onTap == null ? c.labelTertiary : c.labelPrimary;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        selected: active ? true : null,
        child: AppPressable(
          semanticLabel: label,
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: active ? c.fill2 : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 19, color: color),
                      if (text != null) ...[
                        const SizedBox(width: 5),
                        Text(
                          text!,
                          style: AppTextStyles.body.copyWith(color: color),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The same capsule search grammar is used in each business workflow.
class WorkspaceSearchField extends StatelessWidget {
  const WorkspaceSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    this.clearLabel = '清除搜索',
    this.focusNode,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String clearLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassSurface(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(LucideIcons.search, size: 18, color: c.labelSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: autofocus,
                style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                cursorColor: c.brand,
                textInputAction: TextInputAction.search,
                decoration: appInlineInput(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: hint,
                  hintStyle: AppTextStyles.body.copyWith(
                    color: c.labelTertiary,
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
            if (controller.text.isNotEmpty)
              AppPressable(
                semanticLabel: clearLabel,
                onTap: onClear,
                borderRadius: BorderRadius.circular(24),
                child: Icon(
                  LucideIcons.circleX,
                  size: 18,
                  color: c.labelSecondary,
                ),
              )
            else
              const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class WorkspaceSegmentedControl extends StatelessWidget {
  const WorkspaceSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassSurface(
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: selectedIndex == i,
                child: AppPressable(
                  semanticLabel: labels[i],
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selectedIndex == i ? c.fill2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      style: AppTextStyles.footnote.copyWith(
                        fontWeight: selectedIndex == i
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selectedIndex == i
                            ? c.labelPrimary
                            : c.labelSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
