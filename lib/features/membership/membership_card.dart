import 'package:flutter/material.dart';

import '../../app/membership_plan.dart';
import '../../core/membership/membership_mark.dart';
import '../../theme/app_text_styles.dart';

class MembershipCard extends StatelessWidget {
  const MembershipCard({super.key, required this.plan, this.compact = false});
  final MembershipPlan plan;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ink = plan.tier < 2
        ? const Color(0xff211b16)
        : const Color(0xfffff8ec);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: (compact ? 140 : 176) + (scale - 1).clamp(0, 2) * 96,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              plan.family.asset(plan.tier, 'jpg'),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    plan.tier < 2
                        ? const Color(0x40fff8ec)
                        : const Color(0x48000000),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: DefaultTextStyle(
                style: AppTextStyles.footnote.copyWith(color: ink),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('ToWork')),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xd923231f),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MembershipMark(
                                plan: plan,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                membershipLevels[plan.tier],
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        plan.name,
                        maxLines: 1,
                        style: AppTextStyles.display.copyWith(
                          fontSize: 26,
                          height: 1.15,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
