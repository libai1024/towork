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
              title: '外观',
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
                      const SettingsSectionTitle(label: '主题', topGap: 4),
                      SettingsGroupCard(
                        dividerIndent: 38,
                        children: [
                          for (final (value, label, icon) in const [
                            (ThemeMode.system, '跟随系统', LucideIcons.monitor),
                            (ThemeMode.light, '浅色', LucideIcons.sun),
                            (ThemeMode.dark, '深色', LucideIcons.moon),
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
                      const SettingsSectionTitle(label: '字号'),
                      SettingsGroupCard(
                        dividerIndent: 12,
                        children: [
                          for (final (value, label) in const [
                            (0.9, '小'),
                            (1.0, '标准'),
                            (1.15, '大'),
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
    const phases = [
      ('🌑', '新月', '适合开一张新清单'),
      ('🌒', '娥眉月', '适合起步'),
      ('🌓', '上弦月', '适合收尾'),
      ('🌔', '盈凸月', '适合冲刺'),
      ('🌕', '满月', '适合庆祝一下'),
      ('🌖', '亏凸月', '适合复盘'),
      ('🌗', '下弦月', '适合断舍离'),
      ('🌘', '残月', '适合早睡'),
    ];
    final (emoji, name, line) = phases[index];
    return '$emoji 今晚是$name，$line';
  }
}
