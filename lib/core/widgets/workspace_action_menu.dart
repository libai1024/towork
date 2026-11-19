import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_anchored_popover.dart';
import 'app_pressable.dart';
import 'glass_surface.dart';

/// Keeps a short set of related actions beside the control that opened it.
Future<T?> showWorkspaceActionMenu<T>(
  BuildContext anchor, {
  required List<({T value, String label, IconData icon})> items,
  T? selected,
}) => AppAnchoredPopover.show<T>(
  anchor,
  maxWidth: 204,
  barrierColor: Colors.transparent,
  builder: (context) {
    final c = AppColors.of(context);
    return GlassSurface(
      radius: 18,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            Semantics(
              selected: selected == null ? null : selected == item.value,
              child: AppPressable(
                onTap: () => Navigator.pop(context, item.value),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 17, color: c.labelSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.label,
                          style: AppTextStyles.body.copyWith(
                            color: c.labelPrimary,
                          ),
                        ),
                      ),
                      if (item.value == selected)
                        Icon(Icons.check, color: c.labelPrimary, size: 16),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  },
);
