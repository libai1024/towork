import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_button.dart';

/// Empty state with an optional recovery action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: c.labelTertiary),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.subhead.copyWith(color: c.labelSecondary),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                style: AppTextStyles.body.copyWith(color: c.labelTertiary),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              AppButton(
                label: actionLabel!,
                type: AppButtonType.ghost,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
