import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Keeps the field name visible when an editor contains a value.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      ExcludeSemantics(
        child: Text(
          label,
          style: AppTextStyles.footnote.copyWith(
            color: AppColors.of(context).labelSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Semantics(label: label, child: child),
    ],
  );
}
