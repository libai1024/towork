import 'package:flutter/material.dart';

/// 圆角 token（docs/design/00-DESIGN-SPEC.md §3.2）。
class AppRadii {
  AppRadii._();

  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 16;
  static const double full = 999;

  static BorderRadius get brXs => BorderRadius.circular(xs);
  static BorderRadius get brSm => BorderRadius.circular(sm);
  static BorderRadius get brMd => BorderRadius.circular(md);
  static BorderRadius get brLg => BorderRadius.circular(lg);
  static BorderRadius get brXl => BorderRadius.circular(xl);
  static BorderRadius get brXxl => BorderRadius.circular(xxl);
  static BorderRadius get brFull => BorderRadius.circular(full);

  /// 底部弹层顶部圆角（r-2xl）
  static BorderRadius get brSheetTop =>
      const BorderRadius.vertical(top: Radius.circular(xxl));
}
