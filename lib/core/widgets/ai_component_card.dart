import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Compact surface shared by interactive assistant content.
class AiComponentCard extends StatelessWidget {
  const AiComponentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: c.bgPrimary,
        border: Border.all(color: c.separator, width: .5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
