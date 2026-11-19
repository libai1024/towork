/// 间距 token（docs/design/00-DESIGN-SPEC.md §3.1，4pt 网格）。
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// 移动端页面左右安全边距
  static const double pageHorizontal = md;
}

/// 动效 token（规范 §5）。
class AppMotion {
  AppMotion._();

  static const Duration press = Duration(milliseconds: 100);
  static const Duration enter = Duration(milliseconds: 250);
  static const Duration exit = Duration(milliseconds: 180);
  static const Duration tabSwitch = Duration(milliseconds: 200);
  static const Duration todoComplete = Duration(milliseconds: 250);

  static const pressOpacity = 0.8;
}
