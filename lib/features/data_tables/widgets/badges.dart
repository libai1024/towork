import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';

/// 中性 AI 来源徽标，不以彩色区分创建方式。
/// [count] 不为 null 时渲染为「AI n」入口级角标。
class AiBadge extends StatelessWidget {
  const AiBadge({super.key, this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      label: count == null ? 'AI 写入' : '有 $count 处 AI 待确认变更',
      child: Container(
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: c.fill1,
          borderRadius: AppRadii.brFull,
        ),
        alignment: Alignment.center,
        child: Text(
          count == null ? 'AI' : 'AI $count',
          style: AppTextStyles.caption.copyWith(
            color: c.labelSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 待确认用沙漏与文字表达，保留中性色。
class PendingBadge extends StatelessWidget {
  const PendingBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.hourglass, size: 12, color: c.labelSecondary),
        const SizedBox(width: 4),
        Text(
          '待确认 $count',
          style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
        ),
      ],
    );
  }
}
