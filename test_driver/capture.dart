import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      final dir = Directory(
        Platform.environment['TOWORK_SCREENSHOT_DIR'] ??
            'screenshots/kimi-replica',
      )..createSync(recursive: true);
      final shots = data?['screenshots'] as Map<String, dynamic>? ?? {};
      for (final entry in shots.entries) {
        File('${dir.path}/${entry.key}.png')
            .writeAsBytesSync(base64Decode(entry.value as String));
      }
    },
  );
}
