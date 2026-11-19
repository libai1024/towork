import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_pressable.dart';

class WorkspaceScopeItem {
  const WorkspaceScopeItem({required this.id, required this.label, this.count});
  final String id;
  final String label;
  final int? count;
}

/// Use the width of the content pane (which may share a window with a sidebar).
class WorkspaceScopeLayout extends StatelessWidget {
  const WorkspaceScopeLayout({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
    required this.child,
    this.onAdd,
  });

  final List<WorkspaceScopeItem> items;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback? onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final horizontal = bounds.maxWidth < 600;
      final scopes = WorkspaceScopeRail(
        items: items,
        selectedId: selectedId,
        onSelected: onSelected,
        onAdd: onAdd,
        horizontal: horizontal,
      );
      return Flex(
        direction: horizontal ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          scopes,
          Expanded(child: child),
        ],
      );
    },
  );
}

class WorkspaceScopeRail extends StatefulWidget {
  const WorkspaceScopeRail({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
    this.onAdd,
    this.addLabel = '新增类型',
    this.horizontal = false,
  });
  final List<WorkspaceScopeItem> items;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback? onAdd;
  final String addLabel;
  final bool horizontal;

  @override
  State<WorkspaceScopeRail> createState() => _WorkspaceScopeRailState();
}

class _WorkspaceScopeRailState extends State<WorkspaceScopeRail> {
  final _selectedKey = GlobalKey();

  @override
  void didUpdateWidget(WorkspaceScopeRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId == widget.selectedId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final item = _selectedKey.currentContext;
      if (item == null || !item.mounted) return;
      // Reveal a newly added type even when the previous selection was offscreen.
      Scrollable.ensureVisible(
        item,
        alignment: .5,
        duration: MediaQuery.disableAnimationsOf(item)
            ? Duration.zero
            : const Duration(milliseconds: 180),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final selectedId = widget.selectedId;
    final onAdd = widget.onAdd;
    final addLabel = widget.addLabel;
    final entries = [
      for (final item in widget.items)
        Semantics(
          key: item.id == selectedId ? _selectedKey : ValueKey(item.id),
          selected: item.id == selectedId,
          child: AppPressable(
            semanticLabel:
                '${item.label}${item.count == null ? '' : '，${item.count}项'}',
            onTap: () => widget.onSelected(item.id),
            borderRadius: BorderRadius.circular(16),
            child: Align(
              widthFactor: 1,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 180),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: item.id == selectedId ? c.fill2 : Colors.transparent,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.footnote.copyWith(
                        color: item.id == selectedId
                            ? c.labelPrimary
                            : c.labelSecondary,
                        fontWeight: item.id == selectedId
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (item.count != null)
                      Text(
                        '${item.count}',
                        style: AppTextStyles.caption.copyWith(
                          color: c.labelSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
    final add = onAdd == null
        ? null
        : Tooltip(
            message: addLabel,
            excludeFromSemantics: true,
            child: AppPressable(
              semanticLabel: addLabel,
              onTap: onAdd,
              child: const Icon(LucideIcons.folderPlus, size: 18),
            ),
          );
    if (widget.horizontal) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: entries),
              ),
            ),
            ?add,
          ],
        ),
      );
    }
    return SizedBox(
      width: 86,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(6, 4, 4, 88),
        children: [...entries, ?add],
      ),
    );
  }
}
