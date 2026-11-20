import 'package:towork/l10n/strings.dart';
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
      title: context.strings.revokeAiDataConsent,
      onTap: () async {
        await resetModelConsent();
        if (context.mounted) {
          AppToast.showCentered(context, context.strings.consentRevoked);
        }
      },
    ),
    SettingsRow(
      compact: true,
      icon: LucideIcons.fileText,
      title: context.strings.privacyPolicy,
      showChevron: true,
      onTap: () async {
        final opened = await openPrivacyPolicy();
        if (!opened && context.mounted) {
          AppToast.showCentered(context, context.strings.couldntOpen);
        }
      },
    ),
  ];
}
