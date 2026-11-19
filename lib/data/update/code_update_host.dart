import 'package:flutter/services.dart';

class CodeUpdateHost {
  CodeUpdateHost(bool Function() canRestart) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'canRestart') return canRestart();
      throw MissingPluginException();
    });
  }
  static const _channel = MethodChannel('towork/code_update');
  void dispose() => _channel.setMethodCallHandler(null);
}
