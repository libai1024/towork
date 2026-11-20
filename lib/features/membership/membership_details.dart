import 'package:towork/l10n/strings.dart';
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
        MembershipDetail(
          label: context.strings.monthlyCredits,
          value: context.strings.credits(plan.credits),
        ),
        if (plan.tier < 2)
          MembershipDetail(
            label: plan.tier == 0
                ? context.strings.modelAccess
                : context.strings.context,
            value: plan.tier == 0
                ? context.strings.yourOwnApiKey
                : context.strings.shortContext,
          )
        else
          Row(
            children: [
              for (final annual in [false, true])
                Expanded(
                  child: Semantics(
                    selected: plan.annual == annual,
                    child: AppPressable(
                      semanticLabel: annual
                          ? context.strings.yearlyBuild
                          : context.strings.monthlyBuild2,
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
                          '${annual ? context.strings.yearlyBuild : context.strings.monthlyBuild2}  ¥${MembershipPlan(family: plan.family, tier: plan.tier, annual: annual).price}',
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
