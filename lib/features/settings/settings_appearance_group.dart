part of 'settings_page.dart';

SettingsGroupCard _appearanceSettingsGroup(
  BuildContext context,
  WidgetRef ref,
) {
  final themeMode = ref.watch(themeModeProvider);
  final fontScale = ref.watch(fontScaleProvider);
  final language = ref.watch(
    appPreferencesSnapshotProvider.select((p) => p.language),
  );
  final themeLabel = switch (themeMode) {
    ThemeMode.light => context.strings.light,
    ThemeMode.dark => context.strings.dark,
    ThemeMode.system => context.strings.systemDefault,
  };
  return SettingsGroupCard(
    flat: true,
    dividerIndent: 16,
    children: [
      SettingsRow(
        compact: true,
        icon: LucideIcons.languages,
        title: context.strings.languageLabel,
        value: switch (language) {
          'en' => 'English',
          'zh' => '简体中文',
          _ => context.strings.systemDefault,
        },
        showChevron: true,
        onTap: () => context.push(AppRoutes.appearance),
      ),
      SettingsRow(
        compact: true,
        leading: Icon(
          themeMode == ThemeMode.dark ? LucideIcons.moon : LucideIcons.sun,
          size: 20,
          color: AppColors.of(context).labelSecondary,
        ),
        title: context.strings.theme,
        value: themeLabel,
        showChevron: true,
        onTap: () => context.push(AppRoutes.appearance),
      ),
      SettingsRow(
        compact: true,
        icon: LucideIcons.type,
        title: context.strings.textSize,
        value: fontScale <= 0.9
            ? context.strings.small
            : (fontScale >= 1.15
                  ? context.strings.large
                  : context.strings.standard),
        showChevron: true,
        onTap: () => context.push(AppRoutes.appearance),
      ),
    ],
  );
}
