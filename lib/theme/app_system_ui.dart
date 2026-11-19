import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One system-bar policy for custom pages and Material app bars.
/// The page paints behind the bars; only the system icons change with theme.
abstract final class AppSystemUi {
  static SystemUiOverlayStyle forBrightness(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }
}
