import 'package:towork/l10n/strings.dart';
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
    message: context.strings.copyReply,
    excludeFromSemantics: true,
    child: AppPressable(
      semanticLabel: context.strings.copyReply,
      minSize: 48,
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) {
          AppToast.show(context, message: context.strings.copied);
        }
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
