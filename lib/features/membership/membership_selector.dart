import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/membership_plan.dart';
import '../../core/membership/membership_mark.dart';
import '../../core/membership/membership_style.dart';
import '../../core/widgets/app_pressable.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class MembershipSelector extends StatelessWidget {
  const MembershipSelector({
    super.key,
    required this.family,
    required this.tier,
    required this.onChanged,
  });
  final MembershipFamily family;
  final int tier;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = MembershipStyle.of(context, tier);
    final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);
    return LayoutBuilder(
      builder: (context, bounds) {
        final width = math.max(bounds.maxWidth, 4 * (63 * scale + 8));
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedAlign(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(-1 + tier * 2 / 3, 0),
                    child: FractionallySizedBox(
                      widthFactor: .25,
                      heightFactor: 1,
                      child: AnimatedContainer(
                        key: const ValueKey('membership-selection-highlight'),
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: color.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Expanded(
                        child: Semantics(
                          selected: tier == i,
                          child: AppPressable(
                            semanticLabel: '选择 ${family.englishName(i)}',
                            onTap: () => onChanged(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MembershipMark(
                                    plan: MembershipPlan(
                                      family: family,
                                      tier: i,
                                    ),
                                    size: 20,
                                    color: tier == i
                                        ? color.foreground
                                        : c.labelSecondary,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    family.englishName(i),
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: tier == i
                                          ? color.foreground
                                          : c.labelPrimary,
                                    ),
                                  ),
                                  Text(
                                    membershipLevels[i],
                                    style: AppTextStyles.caption.copyWith(
                                      color: tier == i
                                          ? color.foreground
                                          : c.labelSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
