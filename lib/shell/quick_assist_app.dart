import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'quick_assist_panel.dart';
import '../theme/app_theme.dart';
import 'app_frame.dart';

/// 快捷面板的应用外壳。
///
/// 运行在自己的透明窗口和引擎里，没有路由器：整个界面只有一张浮在
/// 底部的卡片，其余部分透出下面的应用。
class QuickAssistApp extends ConsumerWidget {
  const QuickAssistApp({super.key, this.home = const QuickAssistPanel()});

  final Widget home;

  /// 透明区域透出下面的应用，系统栏图标沿用快问窗口的浅色样式。
  static const systemUi = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'ToWork 快问',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ref.watch(themeModeProvider),
    builder: (context, child) => AppFrame(systemUi: systemUi, child: child),
    home: home,
  );
}
