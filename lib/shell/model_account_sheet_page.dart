import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/settings/model_connection_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Page-backed so a deep link, the account list and its menu open the same sheet.
Page<void> modelAccountSheetPage(
  BuildContext context,
  GoRouterState state, {
  bool create = false,
}) {
  final accountId = state.uri.queryParameters['id'];
  return settingsEditorSheetPage(
    context,
    state,
    barrierLabel: '关闭模型账户',
    child: ModelConnectionPage(
      key: ValueKey((accountId, create)),
      accountId: accountId,
      create: create,
    ),
  );
}

Page<void> settingsEditorSheetPage(
  BuildContext context,
  GoRouterState state, {
  required String barrierLabel,
  required Widget child,
}) {
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: false,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: AppColors.of(context).scrim.withValues(alpha: .18),
    transitionDuration: reducedMotion ? Duration.zero : AppMotion.enter,
    reverseTransitionDuration: reducedMotion ? Duration.zero : AppMotion.exit,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final media = MediaQuery.of(context);
      final keyboard = media.viewInsets.bottom;
      return SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, bounds) {
            final maxHeight = math.min(
              media.size.height / 2,
              math.max(0.0, bounds.maxHeight - keyboard),
            );
            return Padding(
              padding: EdgeInsets.only(bottom: keyboard),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.min(bounds.maxWidth, 640.0),
                    maxHeight: maxHeight,
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          animation.drive(
                            CurveTween(curve: Curves.easeOutCubic),
                          ),
                        ),
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
