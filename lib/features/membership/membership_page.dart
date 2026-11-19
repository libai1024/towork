import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/membership_plan.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/work_mark.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'membership_card.dart';
import 'membership_details.dart';
import 'membership_selector.dart';
import 'membership_success.dart';

/// A single package-selection surface, presented by the router as a sheet.
class MembershipPage extends ConsumerStatefulWidget {
  const MembershipPage({super.key});
  @override
  ConsumerState<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends ConsumerState<MembershipPage> {
  late int tier = ref.read(membershipSelectionProvider)?.tier ?? 1;
  late bool annual = ref.read(membershipSelectionProvider)?.annual ?? false;
  bool forward = true;
  bool opening = false;
  double headerDrag = 0;

  void select(int value) {
    if (value == tier || opening) return;
    HapticFeedback.selectionClick();
    setState(() {
      forward = value > tier;
      tier = value;
    });
  }

  Future<void> apply(MembershipPlan plan) async {
    if (opening) return;
    setState(() => opening = true);
    ref.read(membershipSelectionProvider.notifier).state = plan;
    await Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => MembershipSuccess(plan: plan),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    if (mounted) context.popOrGo(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    const family = MembershipFamily.music;
    final active = ref.watch(membershipSelectionProvider);
    final currentTier =
        active?.tier ??
        membershipTierForLabel(ref.watch(userProfileProvider).tier);
    final plan = MembershipPlan(family: family, tier: tier, annual: annual);
    final current =
        currentTier == tier &&
        (active == null || active.family == family) &&
        (tier < 2 || (active?.annual ?? false) == annual);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Material(
      key: const ValueKey('membership-sheet'),
      color: c.bgGround,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                key: const ValueKey('membership-sheet-header'),
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (_) => headerDrag = 0,
                onVerticalDragUpdate: (details) =>
                    headerDrag += details.delta.dy,
                onVerticalDragEnd: (details) {
                  if (headerDrag >= 48 ||
                      (headerDrag > 0 &&
                          (details.primaryVelocity ?? 0) > 600)) {
                    context.popOrGo(AppRoutes.home);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.separator,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Row(
                      children: [
                        const WorkMark(size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('ToWork 会员', style: AppTextStyles.title3),
                        ),
                        IconButton(
                          tooltip: '关闭会员',
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => context.popOrGo(AppRoutes.home),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MembershipSelector(
                        family: family,
                        tier: tier,
                        onChanged: select,
                      ),
                      const SizedBox(height: 10),
                      ClipRect(
                        child: AnimatedSwitcher(
                          duration: reduced
                              ? Duration.zero
                              : const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: Offset(
                                      reduced ? 0 : (forward ? .12 : -.12),
                                      0,
                                    ),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: MembershipCard(
                            key: ValueKey('${family.name}-$tier'),
                            plan: plan,
                            compact: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      MembershipDetails(
                        plan: plan,
                        onAnnualChanged: (value) =>
                            setState(() => annual = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AppButton(
                key: const ValueKey('membership-apply'),
                label: current ? '当前方案' : '切换为 ${plan.name}',
                expand: true,
                enabled: !current && !opening,
                onPressed: () => apply(plan),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
