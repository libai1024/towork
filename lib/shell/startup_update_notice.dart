import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/routes.dart';
import '../app/update/update_controller.dart';
import '../app/update/update_provider.dart';
import '../core/widgets/app_pressable.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// One foreground notice per launch of the main workspace.
class StartupUpdateNotice extends ConsumerStatefulWidget {
  const StartupUpdateNotice({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<StartupUpdateNotice> createState() =>
      _StartupUpdateNoticeState();
}

class _StartupUpdateNoticeState extends ConsumerState<StartupUpdateNotice> {
  String? notice;
  bool visitedUpdatePage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (GoRouterState.of(context).uri.path == AppRoutes.update) {
      visitedUpdatePage = true;
      notice = null;
    }
  }

  Future<void> _check() async {
    if (!mounted ||
        visitedUpdatePage ||
        ref.read(updateControllerProvider).phase != UpdatePhase.idle) {
      return;
    }
    await ref.read(updateControllerProvider.notifier).check();
    if (!mounted || visitedUpdatePage) return;
    final state = ref.read(updateControllerProvider);
    final release = state.release;
    final patch = state.codeUpdate;
    final message = switch (state.phase) {
      UpdatePhase.available when release != null =>
        context.strings.toworkAvailable(release.versionName),
      UpdatePhase.available when patch != null =>
        patch.withdrawal
            ? context.strings.restoreBaseVersionAvailable
            : context.strings.patchPAvailable(patch.version),
      UpdatePhase.ready when state.codeReady => context.strings.patchReady,
      _ => null,
    };
    if (message != null) setState(() => notice = message);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ColoredBox(
      color: colors.bgSecondary,
      child: SafeArea(
        top: notice != null,
        bottom: false,
        left: false,
        right: false,
        child: Column(
          children: [
            if (notice case final message?)
              Material(
                color: colors.bgSecondary,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppPressable(
                            semanticLabel: context.strings.viewUpdate(message),
                            onTap: () {
                              setState(() => notice = null);
                              context.push(AppRoutes.update);
                            },
                            child: Row(
                              children: [
                                const Icon(LucideIcons.download, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: AppTextStyles.footnote,
                                  ),
                                ),
                                Text(
                                  context.strings.viewUpdateBuild,
                                  style: AppTextStyles.footnote.copyWith(
                                    color: colors.labelSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: context.strings.remindMeLater,
                          onPressed: () => setState(() => notice = null),
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}
