import 'package:flutter/material.dart';

import '../../app/membership_plan.dart';

class MembershipMark extends StatelessWidget {
  const MembershipMark({
    super.key,
    required this.plan,
    this.size = 24,
    this.color,
  });
  final MembershipPlan plan;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Image.asset(
    plan.family.asset(plan.tier, 'png'),
    width: size,
    height: size,
    fit: BoxFit.contain,
    color: color,
    excludeFromSemantics: true,
  );
}
