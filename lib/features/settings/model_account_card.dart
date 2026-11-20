part of 'model_accounts_page.dart';

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        context.strings.noModelAccountsYet,
        style: AppTextStyles.body.copyWith(color: c.labelSecondary),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    super.key,
    required this.account,
    required this.active,
    required this.priority,
    required this.now,
    required this.refreshing,
    required this.onTap,
    required this.onMenu,
    required this.onRefresh,
  });

  final ModelAccount account;
  final bool active;
  final int priority;
  final DateTime now;
  final bool refreshing;
  final VoidCallback onTap;
  final VoidCallback onMenu;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cooling = account.coolingAt(now);
    final hasQuotaApi = account.descriptor.quota != QuotaSource.none;
    final windows = account.quota?.windows ?? const [];
    final unavailable = !account.hasCredential || cooling;
    final quota = account.quota;
    final text = unavailable
        ? accountStatusLabel(account, now)
        : quota?.balance != null
        ? context.strings.balance(balanceLabel(quota!.balance!, quota.currency))
        : hasQuotaApi
        ? context.strings.quotaNotCheckedYet
        : context.strings.checkProviderConsole;
    final model = shortModelLabel(account.profile.model);
    return AppPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      semanticLabel:
          '${account.descriptor.shortLabel}，${shortModelLabel(account.profile.model)}'
          '${context.strings.priorityBuild(active ? context.strings.inUseBuild : '', priority, accountStatusLabel(account, now))}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 0, 3, 7),
        decoration: BoxDecoration(
          color: c.bgPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? c.accent : c.separator, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ProviderLogo(account.profile.product, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.descriptor.shortLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.footnote.copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.labelPrimary,
                          ),
                        ),
                      ),
                      BillingMark(descriptor: account.descriptor),
                      Flexible(
                        child: Text(
                          model,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: c.labelSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (active)
                  Tooltip(
                    message: context.strings.inUseBuild2,
                    child: Icon(
                      LucideIcons.check,
                      size: 14,
                      color: c.accentText,
                    ),
                  ),
                if (hasQuotaApi && account.hasCredential)
                  _IconAction(
                    icon: LucideIcons.refreshCw,
                    label: context.strings.refreshQuota,
                    spinning: refreshing,
                    onTap: refreshing ? null : onRefresh,
                  ),
                _IconAction(
                  icon: LucideIcons.ellipsis,
                  label: context.strings.moreActions,
                  onTap: onMenu,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: SizedBox(
                height:
                    (MediaQuery.textScalerOf(context).scale(12) * 16 / 12)
                        .ceilToDouble() +
                    8,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: !unavailable && windows.isNotEmpty
                      ? Row(
                          children: [
                            Text(
                              context.strings.remainingBuild,
                              style: AppTextStyles.caption.copyWith(
                                color: c.labelSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CompactQuotaWindows(windows: windows),
                            ),
                          ],
                        )
                      : Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: unavailable || (quota?.balance ?? 1) <= 0
                                ? c.red
                                : c.labelSecondary,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.spinning = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Tooltip(
      message: label,
      child: AppPressable(
        onTap: onTap,
        semanticLabel: label,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: spinning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, size: 18, color: c.labelSecondary),
          ),
        ),
      ),
    );
  }
}
