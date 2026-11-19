import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/apple_distribution.dart';
import '../../app/membership_plan.dart';
import '../widgets/tier_badge.dart';
import 'membership_mark.dart';
import 'membership_style.dart';

class MembershipBadge extends ConsumerWidget {
  const MembershipBadge({super.key, required this.tier, this.onTap});
  final String tier;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = usesAppleDistribution
        ? MembershipPlan(
            family: MembershipFamily.music,
            tier: ref.watch(testFlightProvider).valueOrNull == true ? 1 : 0,
          )
        : ref.watch(membershipSelectionProvider) ??
              MembershipPlan(
                family: MembershipFamily.music,
                tier: membershipTierForLabel(tier),
              );
    final style = MembershipStyle.of(context, plan.tier);
    return TierBadge(
      tier: plan.name,
      onTap: usesAppleDistribution ? null : onTap,
      background: style.background,
      foreground: style.foreground,
      leading: MembershipMark(plan: plan, size: 12, color: style.foreground),
    );
  }
}
