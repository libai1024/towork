import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/apple_distribution.dart';
import '../../../core/widgets/app_toast.dart';
import 'settings_shared.dart';

List<Widget> applePrivacyRows(BuildContext context) {
  if (!usesAppleDistribution) return const [];
  return [
    SettingsRow(
      compact: true,
      icon: LucideIcons.lockKeyhole,
      title: '撤回 AI 数据授权',
      onTap: () async {
        await resetModelConsent();
        if (context.mounted) AppToast.showCentered(context, '已撤回授权');
      },
    ),
    SettingsRow(
      compact: true,
      icon: LucideIcons.fileText,
      title: '隐私政策',
      showChevron: true,
      onTap: () async {
        final opened = await openPrivacyPolicy();
        if (!opened && context.mounted) {
          AppToast.showCentered(context, '暂时无法打开');
        }
      },
    ),
  ];
}
