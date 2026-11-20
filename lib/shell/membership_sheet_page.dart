import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/membership/membership_page.dart';
import '../theme/app_colors.dart';

Page<void> membershipSheetPage(BuildContext context, GoRouterState state) {
  final reduced = MediaQuery.disableAnimationsOf(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: false,
    barrierDismissible: true,
    barrierLabel: context.strings.closeMembership,
    barrierColor: AppColors.of(context).scrim.withValues(alpha: .22),
    transitionDuration: reduced
        ? Duration.zero
        : const Duration(milliseconds: 320),
    reverseTransitionDuration: reduced
        ? Duration.zero
        : const Duration(milliseconds: 220),
    child: const MembershipPage(),
    transitionsBuilder: (context, animation, secondary, child) => SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation.drive(CurveTween(curve: Curves.easeOutCubic))),
            child: child,
          ),
        ),
      ),
    ),
  );
}
