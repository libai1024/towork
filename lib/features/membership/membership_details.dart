import 'package:flutter/material.dart';

import '../../app/membership_plan.dart';
import '../../core/widgets/app_pressable.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class MembershipDetails extends StatelessWidget {
  const MembershipDetails({
    super.key,
    required this.plan,
    required this.onAnnualChanged,
  });
  final MembershipPlan plan;
  final ValueChanged<bool> onAnnualChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MembershipDetail(label: '每月积分', value: '${plan.credits} 点'),
        if (plan.tier < 2)
          MembershipDetail(
            label: plan.tier == 0 ? '模型接入' : '上下文',
            value: plan.tier == 0 ? '自有 API Key' : '短上下文',
          )
        else
          Row(
            children: [
              for (final annual in [false, true])
                Expanded(
                  child: Semantics(
                    selected: plan.annual == annual,
                    child: AppPressable(
                      semanticLabel: annual ? '年付' : '月付',
                      onTap: () => onAnnualChanged(annual),
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 10,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: plan.annual == annual
                              ? c.fill1
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${annual ? '年付' : '月付'}  ¥${MembershipPlan(family: plan.family, tier: plan.tier, annual: annual).price}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.footnote.copyWith(
                            color: plan.annual == annual
                                ? c.labelPrimary
                                : c.labelSecondary,
                            fontWeight: plan.annual == annual
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class MembershipDetail extends StatelessWidget {
  const MembershipDetail({super.key, required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 44),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.of(context).labelSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.footnote.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
