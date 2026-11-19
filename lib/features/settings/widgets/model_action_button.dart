import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// A 30-point glyph surface inside a full 44-point touch target.
class ModelActionButton extends StatelessWidget {
  const ModelActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.loading = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary, loading;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final enabled = onPressed != null;
    final color = primary && enabled
        ? c.onBrand
        : enabled
        ? c.labelPrimary
        : c.labelTertiary;
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: const EdgeInsets.all(6),
      icon: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary ? (enabled ? c.brand : c.fill2) : Colors.transparent,
        ),
        child: loading
            ? CupertinoActivityIndicator(radius: 8, color: color)
            : Icon(icon, size: 18, color: color),
      ),
    );
  }
}
