import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/notifications/native_notification_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  test('background initialization preserves foreground tap routing and ignores launch navigation', () async {
    var launchChecks = 0;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'getNotificationAppLaunchDetails') {
        launchChecks++;
        return null;
      }
      return true;
    });
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final taps = <String?>[];
    await NativeNotificationService().initialize(taps.add);
    await NativeNotificationService(background: true)
        .initialize((_) => fail('background cannot navigate'));
    final response = Completer<void>();
    binding.channelBuffers.push(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('didReceiveNotificationResponse', {
          'notificationId': 1,
          'payload': 'target',
          'notificationResponseType': 0,
        }),
      ),
      (_) => response.complete(),
    );
    await response.future;
    expect(taps, ['target']);
    expect(launchChecks, 1);
  });
}
