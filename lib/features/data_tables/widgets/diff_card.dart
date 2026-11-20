import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';

/// diff 卡（07-data-tables.md §3.4/§3.5 共用）：fill1 底、r-md、内边距 12。
/// [danger] 为 true 时加 2px red 左边条（删除类变更警示）。
class DiffCard extends StatelessWidget {
  const DiffCard({
    super.key,
    this.header,
    required this.children,
    this.danger = false,
  });

  /// 卡内标题，如「修改 贵州茅台」。
  final String? header;
  final List<Widget> children;

  /// 删除类：red 左边条 2px。
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.fill1,
        borderRadius: AppRadii.brMd,
        border: danger
            ? Border(left: BorderSide(color: c.labelPrimary, width: 2))
            : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Text(
              header!,
              style: AppTextStyles.footnote.copyWith(
                color: c.labelSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// 单字段 diff 行：字段名 caption 居左，before → after 居右展开。
/// - before/after 都有：before 删除线 + 箭头 + after 600；
/// - 仅 after（新增值）：普通值；
/// - 仅 before（删除值）：中性删除线。
/// [lowConfidence]：附「AI 不太确定」文字，避免只依赖颜色。
class FieldDiffLine extends StatelessWidget {
  const FieldDiffLine({
    super.key,
    required this.field,
    this.before,
    this.after,
    this.lowConfidence = false,
  });

  final String field;
  final String? before;
  final String? after;

  /// 低置信度值附明确文字，提醒重点核对。
  final bool lowConfidence;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final beforeText = (before == null || before!.isEmpty) ? null : before;
    final afterText = (after == null || after!.isEmpty) ? null : after;

    final Widget value = switch ((beforeText, afterText)) {
      (final b?, final a?) => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: b,
              style: AppTextStyles.body.copyWith(
                color: c.labelPrimary,
                decoration: TextDecoration.lineThrough,
                decorationColor: c.labelPrimary,
              ),
            ),
            TextSpan(
              text: '  →  ',
              style: AppTextStyles.body.copyWith(color: c.labelQuaternary),
            ),
            TextSpan(
              text: a,
              style: AppTextStyles.body.copyWith(
                color: lowConfidence ? c.labelSecondary : c.labelPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      (final b?, null) => Text(
        b,
        style: AppTextStyles.body.copyWith(
          color: c.labelPrimary,
          decoration: TextDecoration.lineThrough,
          decorationColor: c.labelPrimary,
        ),
      ),
      (null, final a?) => Text(
        a,
        style: AppTextStyles.body.copyWith(
          color: lowConfidence ? c.labelSecondary : c.labelPrimary,
        ),
      ),
      (null, null) => Text(
        '—',
        style: AppTextStyles.body.copyWith(color: c.labelQuaternary),
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              field,
              style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                value,
                if (lowConfidence && afterText != null)
                  Text(
                    context.strings.aiIsUnsurePleaseVerify,
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
