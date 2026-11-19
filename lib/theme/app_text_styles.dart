import 'package:flutter/material.dart';

/// 字阶 token（docs/design/00-DESIGN-SPEC.md §2.2）。
/// 西文/数字用 Inter（随包字体），中文回落系统字（PingFang SC 等）。
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _inter({
    required double size,
    required double height,
    required FontWeight weight,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      height: height / size,
      fontWeight: weight,
    );
  }

  /// 衬线展示字：只用于问候语与空状态这类「一句话」的时刻，正文不用。
  /// 不随包携带中文衬线字体（体积过大），按平台回落到系统宋体；
  /// 系统没有衬线中文时自然回落到默认黑体，版式不受影响。
  static TextStyle _serif({
    required double size,
    required double height,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: 'serif',
      fontFamilyFallback: const [
        'Noto Serif CJK SC',
        'Source Han Serif SC',
        'Songti SC',
        'STSong',
        'Georgia',
      ],
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: -0.2,
    );
  }

  /// 21/28 衬线 —— 首页问候语
  static TextStyle get display => _serif(size: 21, height: 28);

  /// 18/24 衬线 —— 半屏面板问候、空状态标题
  static TextStyle get displaySmall => _serif(size: 18, height: 24);

  /// 12/16 400 —— 时间戳、徽标、辅助说明
  static TextStyle get caption =>
      _inter(size: 12, height: 16, weight: FontWeight.w400);

  /// 13/18 400 —— 列表副标题
  static TextStyle get footnote =>
      _inter(size: 13, height: 18, weight: FontWeight.w400);

  /// 14/20 400 —— 默认正文、列表主标题
  static TextStyle get body =>
      _inter(size: 14, height: 20, weight: FontWeight.w400);

  /// 15/21 400 —— 对话正文（阅读舒适档）
  static TextStyle get callout =>
      _inter(size: 15, height: 21, weight: FontWeight.w400);

  /// 15/23 400 —— 用户消息、助手正文与流式文字
  static TextStyle get chatBody =>
      _inter(size: 15, height: 23, weight: FontWeight.w400);

  /// 15.5/22 输入文字与占位提示。
  static TextStyle get chatInput =>
      _inter(size: 15.5, height: 22, weight: FontWeight.w400);

  /// 14.5/21 模型菜单文字。
  static TextStyle get menuLabel =>
      _inter(size: 14.5, height: 21, weight: FontWeight.w400);

  /// 12/16 输入区内模型名称。
  static TextStyle get modelLabel =>
      _inter(size: 12, height: 16, weight: FontWeight.w400);

  /// 15/20 500 —— 卡片标题、区块标题
  static TextStyle get subhead =>
      _inter(size: 15, height: 20, weight: FontWeight.w500);

  /// 15/21 500 —— 导航与控件
  static TextStyle get controlTitle =>
      _inter(size: 15, height: 21, weight: FontWeight.w500);

  /// 17/22 600 —— 移动端页面标题
  static TextStyle get title3 =>
      _inter(size: 17, height: 22, weight: FontWeight.w600);

  /// 18/24 600 —— 弹窗标题
  static TextStyle get title2 =>
      _inter(size: 18, height: 24, weight: FontWeight.w600);

  /// 21/27 600 —— 报告标题、摘要数字
  static TextStyle get title1 =>
      _inter(size: 21, height: 27, weight: FontWeight.w600);
}
