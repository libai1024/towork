import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../theme/app_system_ui.dart';

/// 所有窗口共用的外框：应用内字号和系统栏图标颜色。
///
/// 全局字号（小 0.9 / 标准 1.0 / 大 1.15）在系统文字缩放之上叠加倍数，
/// 不替换系统设置；系统级大字号（含读屏放大档位）仍然生效。
class AppFrame extends ConsumerWidget {
  const AppFrame({super.key, required this.child, this.systemUi});

  final Widget? child;

  /// 为空时按当前主题明暗取默认样式。
  final SystemUiOverlayStyle? systemUi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(fontScaleProvider);
    final media = MediaQuery.of(context).copyWith(
      textScaler: _AppTextScaler(MediaQuery.textScalerOf(context), scale),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          systemUi ?? AppSystemUi.forBrightness(Theme.of(context).brightness),
      child: MediaQuery(data: media, child: child ?? const SizedBox.shrink()),
    );
  }
}

/// 在系统 [TextScaler]（可能来自读屏/无障碍放大，非线性）之上叠加应用内
/// 字号倍数：`scale(f) = base.scale(f) * multiplier`。
/// 相等性按 (base, multiplier) 实现，避免每次重建都向整棵树广播
/// MediaQuery 变更。
class _AppTextScaler extends TextScaler {
  const _AppTextScaler(this.base, this.multiplier)
    : assert(multiplier > 0, 'multiplier must be positive');

  final TextScaler base;
  final double multiplier;

  @override
  double scale(double fontSize) => base.scale(fontSize) * multiplier;

  // 仅供旧 API 兼容读取；实际缩放一律走 [scale]。
  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * multiplier;

  @override
  bool operator ==(Object other) =>
      other is _AppTextScaler &&
      other.base == base &&
      other.multiplier == multiplier;

  @override
  int get hashCode => Object.hash(base, multiplier);
}
