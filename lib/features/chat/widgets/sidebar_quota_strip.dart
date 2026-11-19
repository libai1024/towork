import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/model_settings_provider.dart';
import '../../../core/ai/quota_widgets.dart';
import '../../../core/ai/brand_logos.dart';
import '../../../core/ai/model_identity.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 侧栏额度速览：当前供应商与已返回的额度窗口。
class SidebarQuotaStrip extends ConsumerWidget {
  const SidebarQuotaStrip({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(liveModelAccountsProvider);
    final account = accounts?.active;
    final c = AppColors.of(context);
    if (account == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: AppPressable(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(14),
          semanticLabel: '添加模型账户',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.fill1,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.sparkles, size: 16, color: c.accentText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '添加模型账户',
                    style: AppTextStyles.footnote.copyWith(
                      color: c.labelSecondary,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: c.labelTertiary,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final now = DateTime.now().toUtc();
    final status = accountStatusLabel(account, now);
    final attention = accountNeedsAttention(account, now);
    final windows = account.quota?.windows ?? const [];
    final unavailable = !account.hasCredential || account.coolingAt(now);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: AppPressable(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        semanticLabel: '模型与额度，${account.descriptor.shortLabel}',
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: c.fill1,
            borderRadius: BorderRadius.circular(14),
            border: attention
                ? Border.all(color: c.red.withValues(alpha: .35))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  BrandLogo(
                    brand: brandOfProduct(account.profile.product),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      account.descriptor.shortLabel,
                      style: AppTextStyles.footnote.copyWith(
                        color: c.labelPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (windows.isNotEmpty && unavailable)
                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(color: c.red),
                      ),
                    )
                  else if (windows.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Text(
                        '剩余',
                        style: AppTextStyles.caption.copyWith(
                          color: c.labelSecondary,
                        ),
                      ),
                    ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: c.labelTertiary,
                  ),
                ],
              ),
              if (windows.isEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  status,
                  style: AppTextStyles.caption.copyWith(
                    color: attention ? c.red : c.labelSecondary,
                  ),
                ),
              ],
              if (windows.isNotEmpty) ...[
                const SizedBox(height: 6),
                CompactQuotaWindows(windows: windows),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
