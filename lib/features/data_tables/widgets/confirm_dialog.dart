import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';

/// 居中确认弹窗（本 feature 内共用）：bgPrimary、r-xl、遮罩 #0009（规范 §4.5）。
/// 返回 true = 用户点了确认。
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final c = AppColors.of(context);
  final result = await showDialog<bool>(
    context: context,
    barrierColor: c.scrim,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: c.bgPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.brXl),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.title2.copyWith(color: c.labelPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.body.copyWith(color: c.labelSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: context.strings.cancel,
                    type: AppButtonType.ghost,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: confirmLabel ?? context.strings.confirm,
                    type: destructive
                        ? AppButtonType.destructive
                        : AppButtonType.primary,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
