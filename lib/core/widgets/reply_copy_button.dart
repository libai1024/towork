import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import 'app_pressable.dart';
import 'app_toast.dart';

/// Copies all visible assistant text in one reply, including tool-round text.
class ReplyCopyButton extends StatelessWidget {
  const ReplyCopyButton({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: '复制回复',
    excludeFromSemantics: true,
    child: AppPressable(
      semanticLabel: '复制回复',
      minSize: 48,
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) AppToast.show(context, message: '已复制');
      },
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(
          LucideIcons.copy,
          size: 17,
          color: AppColors.of(context).labelSecondary,
        ),
      ),
    ),
  );
}
