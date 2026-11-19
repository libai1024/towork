import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';

/// Keep document titles, text and values within the same reading column.
class WorkspaceReadingPane extends StatelessWidget {
  const WorkspaceReadingPane({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.of(context).bgGround,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: child,
      ),
    ),
  );
}
