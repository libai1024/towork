import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_system_ui.dart';

/// 亮（月之亮面）/暗（月之暗面）双主题。
/// 压制 Material 默认蓝色与默认阴影：ColorScheme 全量改映射到 token，
/// 卡片/弹层不升 elevation。
class AppTheme {
  AppTheme._();

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.brand,
      onPrimary: colors.onBrand,
      secondary: colors.brand,
      onSecondary: colors.onBrand,
      error: colors.red,
      onError: colors.bgPrimary,
      surface: colors.bgPrimary,
      onSurface: colors.labelPrimary,
      surfaceContainerHighest: colors.fill2,
      outline: colors.separator,
      outlineVariant: colors.separator,
      shadow: Colors.transparent,
      scrim: colors.scrim,
      inverseSurface: colors.toastBackground,
      onInverseSurface: colors.onToast,
    );

    OutlineInputBorder fieldBorder(BorderSide side) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: side,
    );
    final fieldShape = fieldBorder(BorderSide.none);
    final errorShape = fieldBorder(BorderSide(color: colors.red));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.bgGround,
      canvasColor: colors.bgGround,
      dividerColor: colors.separator,
      dividerTheme: DividerThemeData(
        color: colors.separator,
        thickness: 0.5,
        space: 0.5,
      ),
      textTheme:
          TextTheme(
            bodySmall: AppTextStyles.footnote,
            bodyMedium: AppTextStyles.body,
            bodyLarge: AppTextStyles.body,
            titleSmall: AppTextStyles.subhead,
            titleMedium: AppTextStyles.title3,
            titleLarge: AppTextStyles.title2,
            headlineMedium: AppTextStyles.title1,
          ).apply(
            bodyColor: colors.labelPrimary,
            displayColor: colors.labelPrimary,
          ),
      appBarTheme: AppBarTheme(
        titleTextStyle: AppTextStyles.title3.copyWith(
          color: colors.labelPrimary,
        ),
        toolbarHeight: 48,
        systemOverlayStyle: AppSystemUi.forBrightness(brightness),
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.bgGround,
        foregroundColor: colors.labelPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: colors.bgPrimary,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.bgPrimary,
        modalBackgroundColor: colors.bgPrimary,
        elevation: 0,
        modalElevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.bgPrimary,
        titleTextStyle: AppTextStyles.title3.copyWith(
          color: colors.labelPrimary,
        ),
        contentTextStyle: AppTextStyles.body.copyWith(
          color: colors.labelPrimary,
        ),
        elevation: 0,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.bgSecondary,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.toastBackground,
        contentTextStyle: AppTextStyles.body.copyWith(color: colors.onToast),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: colors.brand,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size(44, 44),
          side: BorderSide(color: colors.separator),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        filled: true,
        fillColor: colors.fill1,
        hintStyle: AppTextStyles.body.copyWith(color: colors.labelTertiary),
        errorStyle: AppTextStyles.caption.copyWith(color: colors.red),
        errorMaxLines: 3,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: fieldShape,
        enabledBorder: fieldShape,
        disabledBorder: fieldShape,
        focusedBorder: fieldBorder(BorderSide(color: colors.labelTertiary)),
        errorBorder: errorShape,
        focusedErrorBorder: errorShape,
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: colors.bgPrimary,
      ),
      datePickerTheme: DatePickerThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: colors.fill1,
      focusColor: colors.fill2,
      extensions: [colors],
    );
  }

  /// 月之亮面
  static ThemeData get light => _build(AppColors.light, Brightness.light);

  /// 月之暗面
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);
}
