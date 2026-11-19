import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';

/// 原图查看器占位（纯 UI 阶段不接真实图片）：深色底 + 文件名 + 关闭。
void showMockImageViewer(BuildContext context, {required String label}) {
  final c = AppColors.of(context);
  showDialog<void>(
    context: context,
    barrierColor: c.scrim,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: c.bgTertiary,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.brXl),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: c.fill2,
                  borderRadius: AppRadii.brLg,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.images,
                      size: 48,
                      color: c.labelQuaternary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: AppTextStyles.footnote.copyWith(
                        color: c.labelSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '纯 UI 演示 原图占位',
                      style: AppTextStyles.caption.copyWith(
                        color: c.labelTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: AppPressable(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  semanticLabel: '关闭原图',
                  child: Text(
                    '关闭',
                    style: AppTextStyles.body.copyWith(color: c.brand),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
