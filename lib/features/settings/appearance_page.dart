import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_preferences_provider.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/widgets/app_toast.dart';
import '../../theme/app_colors.dart';
import 'widgets/settings_shared.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    return Scaffold(
      backgroundColor: AppColors.of(context).bgGround,
      body: SafeArea(
        child: Column(
          children: [
            SettingsNavBar(
              title: context.strings.appearance,
              onBack: () => context.popOrGo(AppRoutes.settings),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      SettingsSectionTitle(
                        label: context.strings.languageLabel,
                        topGap: 4,
                      ),
                      SettingsGroupCard(
                        dividerIndent: 12,
                        children: [
                          for (final (code, name) in [
                            ('system', context.strings.systemDefault),
                            ('zh', '简体中文'),
                            ('en', 'English'),
                          ])
                            SheetOptionRow(
                              title: name,
                              selected:
                                  ref
                                      .watch(appPreferencesSnapshotProvider)
                                      .language ==
                                  code,
                              onTap: () => savePreferences(context, ref, {
                                'language': code,
                              }),
                            ),
                        ],
                      ),
                      SettingsSectionTitle(
                        label: context.strings.theme,
                        topGap: 4,
                      ),
                      SettingsGroupCard(
                        dividerIndent: 38,
                        children: [
                          for (final (value, label, icon) in [
                            (
                              ThemeMode.system,
                              context.strings.systemDefault,
                              LucideIcons.monitor,
                            ),
                            (
                              ThemeMode.light,
                              context.strings.light,
                              LucideIcons.sun,
                            ),
                            (
                              ThemeMode.dark,
                              context.strings.dark,
                              LucideIcons.moon,
                            ),
                          ])
                            SheetOptionRow(
                              title: label,
                              icon: icon,
                              selected: mode == value,
                              onTap: () => savePreferences(context, ref, {
                                'theme': value.name,
                              }),
                              onLongPress: () => AppToast.show(
                                context,
                                message: _moonPhaseLine(),
                              ),
                            ),
                        ],
                      ),
                      SettingsSectionTitle(label: context.strings.textSize),
                      SettingsGroupCard(
                        dividerIndent: 12,
                        children: [
                          for (final (value, label) in [
                            (0.9, context.strings.small),
                            (1.0, context.strings.standard),
                            (1.15, context.strings.large),
                          ])
                            SheetOptionRow(
                              title: label,
                              selected: fontScale == value,
                              onTap: () => savePreferences(context, ref, {
                                'font_scale': value,
                              }),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _moonPhaseLine() {
    const synodic = 29.530588853;
    final referenceNewMoon = DateTime.utc(2000, 1, 6, 18, 14);
    final days =
        DateTime.now().toUtc().difference(referenceNewMoon).inMilliseconds /
        Duration.millisecondsPerDay;
    final age = days % synodic;
    final index = ((age / synodic) * 8).round() % 8;
    final phases = [
      ('🌑', strings.newMoon, strings.aGoodTimeToStartAList),
      ('🌒', strings.waxingCrescent, strings.aGoodTimeToBegin),
      ('🌓', strings.firstQuarter, strings.aGoodTimeToWrapUp),
      ('🌔', strings.waxingGibbous, strings.aGoodTimeForAFinalPush),
      ('🌕', strings.fullMoon, strings.aGoodTimeToCelebrate),
      ('🌖', strings.waningGibbous, strings.aGoodTimeToReflect),
      ('🌗', strings.lastQuarter, strings.aGoodTimeToDeclutter),
      ('🌘', strings.waningCrescent, strings.aGoodTimeForAnEarlyNight),
    ];
    final (emoji, name, line) = phases[index];
    return strings.tonight(emoji, name, line);
  }
}
