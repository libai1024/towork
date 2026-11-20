import 'package:towork/l10n/strings.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class AiTodoPagination extends StatelessWidget {
  const AiTodoPagination({
    super.key,
    required this.count,
    required this.page,
    required this.onPage,
  });

  static const pageSize = 5;
  final int count, page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final controlHeight = math.max(36.0, scaler.scale(16) + 8).ceilToDouble();
    final pages = (count / pageSize).ceil();
    if (pages <= 1) return SizedBox(height: controlHeight);
    Widget arrow(IconData icon, String label, int target, bool enabled) =>
        AppPressable(
          minSize: 36,
          compact: true,
          semanticLabel: label,
          onTap: enabled ? () => onPage(target) : null,
          child: SizedBox(
            width: 48,
            height: controlHeight,
            child: Icon(
              icon,
              size: 16,
              color: enabled ? c.labelSecondary : c.labelQuaternary,
            ),
          ),
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.separator, width: .5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          arrow(
            LucideIcons.chevronLeft,
            context.strings.previousPage,
            page - 1,
            page > 0,
          ),
          Semantics(
            label: context.strings.page,
            child: SizedBox(
              height: controlHeight,
              child: DropdownButton<int>(
                isDense: true,
                // Dense buttons otherwise keep a top-aligned 24px body.
                iconSize: controlHeight,
                underline: const SizedBox.shrink(),
                key: const ValueKey('todo-panel-page'),
                value: page,
                style: AppTextStyles.caption.copyWith(color: c.labelPrimary),
                icon: Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: c.labelSecondary,
                ),
                borderRadius: BorderRadius.circular(12),
                dropdownColor: c.bgPrimary,
                menuMaxHeight: 280,
                items: [
                  for (var i = 0; i < pages; i++)
                    DropdownMenuItem(value: i, child: Text('${i + 1}/$pages')),
                ],
                onChanged: (value) {
                  if (value != null) onPage(value);
                },
              ),
            ),
          ),
          arrow(
            LucideIcons.chevronRight,
            context.strings.nextPage,
            page + 1,
            page + 1 < pages,
          ),
        ],
      ),
    );
  }
}
