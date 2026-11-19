// Native update harness. Serve the test manifest through adb reverse on 18765.
// The target APK uses lib/main.dart and replaces this isolated UI harness.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/app/update/update_provider.dart';
import 'package:towork/data/update/http_update_gateway.dart';
import 'package:towork/data/update/update_channel.dart';
import 'package:towork/main.dart';
import 'package:towork/shell/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final support = await getApplicationSupportDirectory();
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () =>
        HttpClient()
          ..badCertificateCallback = (_, host, _) => host == 'localhost',
  );
  final gateway = HttpUpdateGateway(
    dio,
    directory: () async => Directory('${support.path}/updates'),
    manifest: Uri.parse('https://localhost:18765/dl/towork/latest.json'),
    platform: const UpdateChannel(),
  );
  final container = ProviderContainer(
    overrides: [updateGatewayProvider.overrideWithValue(gateway)],
  );
  container.read(appRouterProvider).go(AppRoutes.update);
  runApp(
    UncontrolledProviderScope(container: container, child: const ToWorkApp()),
  );
}
