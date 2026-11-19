import 'package:flutter/material.dart';

/// 暖纸 墨色 一点陶土橙（DESIGN.md §色彩）。
///
/// 界面九成以上是暖白纸面与墨色文字；陶土橙 [accent] 只留给「此刻最重要的
/// 一个动作」和品牌记号，一屏最多出现一两处。组件内禁止出现裸 hex，
/// 一律经此取色。
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brand,
    required this.brandHover,
    required this.brandActive,
    required this.accent,
    required this.accentText,
    required this.accentSoft,
    required this.red,
    required this.green,
    required this.yellow,
    required this.orange,
    required this.purple,
    required this.cyan,
    required this.pink,
    required this.bgGround,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.labelPrimary,
    required this.labelSecondary,
    required this.labelTertiary,
    required this.labelQuaternary,
    required this.fill1,
    required this.fill2,
    required this.fill3,
    required this.fill4,
    required this.separator,
    required this.scrim,
    required this.toastBackground,
    required this.onToast,
  });

  // 品牌与语义色
  final Color brand;
  final Color brandHover;
  final Color brandActive;

  /// 陶土橙：发送按钮、品牌记号、进度与选中强调。只承载图标或大字。
  final Color accent;

  /// 纸面上的橙色小字与链接（对比度 ≥ 4.5:1）。
  final Color accentText;

  /// 橙色的浅底：提示条、选中卡片底色。
  final Color accentSoft;
  final Color red;
  final Color green;
  final Color yellow;
  final Color orange;
  final Color purple;
  final Color cyan;
  final Color pink;

  // 背景
  final Color bgGround;
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;

  // 文字（透明度灰阶）
  final Color labelPrimary;
  final Color labelSecondary;
  final Color labelTertiary;
  final Color labelQuaternary;

  // 填充与分割线
  final Color fill1;
  final Color fill2;
  final Color fill3;
  final Color fill4;
  final Color separator;

  /// 遮罩：Always-TransparencyDarkFill（#0009），弹层/抽屉专用。
  final Color scrim;

  /// Toast 反色底（亮面近黑 / 暗面近白）与其上的文字色。
  final Color toastBackground;
  final Color onToast;

  /// Foreground on the monochrome primary action in both themes.
  Color get onBrand => bgPrimary;

  /// 陶土橙上的图标色。
  Color get onAccent => const Color(0xFFFFFFFF);
  Color get overdueForeground => red;
  Color get overdueSurface =>
      _dark ? const Color(0xFF3A2A28) : const Color(0xFFF4E4E1);
  Color get categoryForeground => labelSecondary;
  bool get _dark => bgGround.computeLuminance() < .5;

  /// Classification hue is decorative: existing/custom colors are softened
  /// here without changing stored category data or reusing warning colors.
  Color categorySurface(Color color) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.saturation < .08) return fill1;
    final hue = hsl.hue;
    if (hue < 45 || hue >= 330) {
      return _dark ? const Color(0xFF372E25) : const Color(0xFFF4E9DB);
    }
    if (hue < 85) {
      return _dark ? const Color(0xFF332F22) : const Color(0xFFF2ECD9);
    }
    if (hue < 170) {
      return _dark ? const Color(0xFF26302A) : const Color(0xFFE6EEE4);
    }
    if (hue < 245) {
      return _dark ? const Color(0xFF253137) : const Color(0xFFE3ECEE);
    }
    return _dark ? const Color(0xFF2C2836) : const Color(0xFFECE8F2);
  }

  /// Restrained chart marks and category dots, including legacy stored hues.
  /// Pair each series with a label; color alone never identifies the data.
  Color categoryAccent(Color color) =>
      Color.lerp(categorySurface(color), categoryForeground, .75)!;

  // 语义色 25% 透明度变体（徽标底色）
  Color get red25 => red.withValues(alpha: 0.25);
  Color get green25 => green.withValues(alpha: 0.25);
  Color get orange25 => orange.withValues(alpha: 0.25);
  Color get purple25 => purple.withValues(alpha: 0.25);
  Color get brand25 => brand.withValues(alpha: 0.25);

  /// Stable source hues; presentation uses categorySurface/categoryForeground.
  List<Color> get categoryPalette => const [
    Color(0xFF4A6B76),
    Color(0xFF7A6A53),
    Color(0xFF4E6E56),
    Color(0xFF7A6A33),
    Color(0xFF87592E),
    Color(0xFF655A85),
    Color(0xFF536D6C),
    Color(0xFF6A625C),
  ];

  /// 月之亮面
  static const light = AppColors(
    brand: Color(0xFF141413),
    brandHover: Color(0xFF30302E),
    brandActive: Color(0xFF000000),
    accent: Color(0xFFC15F3C),
    accentText: Color(0xFFA84E2C),
    accentSoft: Color(0xFFF5E6DE),
    red: Color(0xFF7C4B45),
    green: Color(0xFF4E6E56),
    yellow: Color(0xFF7A6A33),
    orange: Color(0xFF87592E),
    purple: Color(0xFF655A85),
    cyan: Color(0xFF4A6B76),
    pink: Color(0xFF83505C),
    bgGround: Color(0xFFFAF9F5),
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF5F4EE),
    bgTertiary: Color(0xFFF0EEE6),
    labelPrimary: Color(0xFF141413),
    labelSecondary: Color(0xFF5E5D59),
    labelTertiary: Color(0xFF64635E),
    labelQuaternary: Color(0xFF64635E),
    fill1: Color(0xFFF0EEE6),
    fill2: Color(0xFFE8E6DC),
    fill3: Color(0x2A000000),
    fill4: Color(0x40000000),
    separator: Color(0xFFE8E6DC),
    scrim: Color(0x99000000),
    toastBackground: Color(0xFF141413),
    onToast: Color(0xFFFAF9F5),
  );

  /// 月之暗面
  static const dark = AppColors(
    brand: Color(0xFFFAF9F5),
    brandHover: Color(0xFFE8E6DC),
    brandActive: Color(0xFFFFFFFF),
    accent: Color(0xFFD97757),
    accentText: Color(0xFFE08A6D),
    accentSoft: Color(0xFF3A2A23),
    red: Color(0xFFD2A29B),
    green: Color(0xFFA3BFA9),
    yellow: Color(0xFFCBB987),
    orange: Color(0xFFD0A886),
    purple: Color(0xFFB7ADD1),
    cyan: Color(0xFF9FBCC6),
    pink: Color(0xFFD0ABB5),
    bgGround: Color(0xFF1F1E1D),
    bgPrimary: Color(0xFF2A2A28),
    bgSecondary: Color(0xFF242422),
    bgTertiary: Color(0xFF30302E),
    labelPrimary: Color(0xFFFAF9F5),
    labelSecondary: Color(0xFFB8B5A9),
    labelTertiary: Color(0xFFABA89C),
    labelQuaternary: Color(0xFFABA89C),
    fill1: Color(0xFF30302E),
    fill2: Color(0xFF3A3A37),
    fill3: Color(0x2EFFFFFF),
    fill4: Color(0x40FFFFFF),
    separator: Color(0xFF3D3D3A),
    scrim: Color(0x99000000),
    toastBackground: Color(0xFFFAF9F5),
    onToast: Color(0xFF2A2A28),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? brand,
    Color? brandHover,
    Color? brandActive,
    Color? accent,
    Color? accentText,
    Color? accentSoft,
    Color? red,
    Color? green,
    Color? yellow,
    Color? orange,
    Color? purple,
    Color? cyan,
    Color? pink,
    Color? bgGround,
    Color? bgPrimary,
    Color? bgSecondary,
    Color? bgTertiary,
    Color? labelPrimary,
    Color? labelSecondary,
    Color? labelTertiary,
    Color? labelQuaternary,
    Color? fill1,
    Color? fill2,
    Color? fill3,
    Color? fill4,
    Color? separator,
    Color? scrim,
    Color? toastBackground,
    Color? onToast,
  }) {
    return AppColors(
      brand: brand ?? this.brand,
      brandHover: brandHover ?? this.brandHover,
      brandActive: brandActive ?? this.brandActive,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      accentSoft: accentSoft ?? this.accentSoft,
      red: red ?? this.red,
      green: green ?? this.green,
      yellow: yellow ?? this.yellow,
      orange: orange ?? this.orange,
      purple: purple ?? this.purple,
      cyan: cyan ?? this.cyan,
      pink: pink ?? this.pink,
      bgGround: bgGround ?? this.bgGround,
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgTertiary: bgTertiary ?? this.bgTertiary,
      labelPrimary: labelPrimary ?? this.labelPrimary,
      labelSecondary: labelSecondary ?? this.labelSecondary,
      labelTertiary: labelTertiary ?? this.labelTertiary,
      labelQuaternary: labelQuaternary ?? this.labelQuaternary,
      fill1: fill1 ?? this.fill1,
      fill2: fill2 ?? this.fill2,
      fill3: fill3 ?? this.fill3,
      fill4: fill4 ?? this.fill4,
      separator: separator ?? this.separator,
      scrim: scrim ?? this.scrim,
      toastBackground: toastBackground ?? this.toastBackground,
      onToast: onToast ?? this.onToast,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      brand: l(brand, other.brand),
      brandHover: l(brandHover, other.brandHover),
      brandActive: l(brandActive, other.brandActive),
      accent: l(accent, other.accent),
      accentText: l(accentText, other.accentText),
      accentSoft: l(accentSoft, other.accentSoft),
      red: l(red, other.red),
      green: l(green, other.green),
      yellow: l(yellow, other.yellow),
      orange: l(orange, other.orange),
      purple: l(purple, other.purple),
      cyan: l(cyan, other.cyan),
      pink: l(pink, other.pink),
      bgGround: l(bgGround, other.bgGround),
      bgPrimary: l(bgPrimary, other.bgPrimary),
      bgSecondary: l(bgSecondary, other.bgSecondary),
      bgTertiary: l(bgTertiary, other.bgTertiary),
      labelPrimary: l(labelPrimary, other.labelPrimary),
      labelSecondary: l(labelSecondary, other.labelSecondary),
      labelTertiary: l(labelTertiary, other.labelTertiary),
      labelQuaternary: l(labelQuaternary, other.labelQuaternary),
      fill1: l(fill1, other.fill1),
      fill2: l(fill2, other.fill2),
      fill3: l(fill3, other.fill3),
      fill4: l(fill4, other.fill4),
      separator: l(separator, other.separator),
      scrim: l(scrim, other.scrim),
      toastBackground: l(toastBackground, other.toastBackground),
      onToast: l(onToast, other.onToast),
    );
  }
}
