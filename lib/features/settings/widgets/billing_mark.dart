import 'package:flutter/material.dart';

import '../../../domain/ai/provider_catalog.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class BillingMark extends StatelessWidget {
  const BillingMark({super.key, required this.descriptor});
  final ProviderDescriptor descriptor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: colors.fill1,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        descriptor.accessLabel,
        style: AppTextStyles.caption.copyWith(color: colors.labelSecondary),
      ),
    );
  }
}
