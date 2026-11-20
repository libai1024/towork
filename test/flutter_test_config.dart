// Existing UI fixtures assert the Simplified Chinese catalog. Locale-specific
// tests override this simulated device preference explicitly.
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    if (BindingBase.debugBindingType() == null) return;
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.localesTestValue = const [Locale('zh', 'CN')];
    addTearDown(dispatcher.clearLocalesTestValue);
  });
  await testMain();
}
