import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/ai/brand_logos.dart';
import '../../../core/ai/model_identity.dart';
import '../../../domain/ai/model_gateway.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'settings_shared.dart';
import 'billing_mark.dart';

/// 当前服务商一行：点开在弹层里换，页面保持短小。
class ModelProviderField extends StatelessWidget {
  const ModelProviderField({
    super.key,
    required this.descriptor,
    required this.enabled,
    required this.onTap,
  });
  final ProviderDescriptor descriptor;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SettingsRow(
    key: const ValueKey('provider-field'),
    leading: BrandLogo(
      brand: brandOfProduct(descriptor.kind),
      size: 18,
      badge: true,
    ),
    title: '服务商',
    value: descriptor.shortLabel,
    trailing: BillingMark(descriptor: descriptor),
    enabled: enabled,
    showChevron: true,
    onTap: onTap,
  );
}

class ModelProviderOption extends StatelessWidget {
  const ModelProviderOption({
    super.key,
    required this.descriptor,
    required this.selected,
    required this.onTap,
  });
  final ProviderDescriptor descriptor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: SettingsRow(
      leading: BrandLogo(
        brand: brandOfProduct(descriptor.kind),
        size: 18,
        badge: true,
      ),
      title: descriptor.shortLabel,
      value: descriptor.accessLabel,
      trailing: selected
          ? Icon(
              LucideIcons.check,
              size: 18,
              color: AppColors.of(context).brand,
            )
          : null,
      onTap: onTap,
    ),
  );
}

/// 服务商的使用须知：订阅条款限制、计费方式等用户必须知道的事。
class ModelProviderNotice extends StatelessWidget {
  const ModelProviderNotice({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(LucideIcons.info, size: 15, color: c.accentText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(color: c.labelPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
