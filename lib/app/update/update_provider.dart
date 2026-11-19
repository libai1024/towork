import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/update/http_update_gateway.dart';
import '../../data/update/update_channel.dart';
import '../../data/update/code_update_gateway.dart';
import '../../domain/update/code_update.dart';
import '../../domain/update/app_update.dart';
import 'update_controller.dart';

final updatePlatformProvider = Provider<UpdatePlatform>(
  (ref) => const UpdateChannel(),
);

final installedAppProvider = FutureProvider<InstalledApp>(
  (ref) => ref.watch(updatePlatformProvider).installed(),
);

final codeUpdateGatewayProvider = Provider<CodeUpdateGateway>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  final gateway = SignedCodeUpdateGateway(dio);
  ref.onDispose(() {
    gateway.cancel();
    dio.close(force: true);
  });
  return gateway;
});

final updateGatewayProvider = Provider<UpdateGateway>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 20),
    ),
  );
  final gateway = HttpUpdateGateway(
    dio,
    manifest: Uri.parse('https://zhaozhaoyue.top/dl/towork/latest.json'),
    platform: ref.watch(updatePlatformProvider),
    directory: () async {
      final support = await getApplicationSupportDirectory();
      return Directory('${support.path}/updates');
    },
  );
  ref.onDispose(() {
    gateway.cancel();
    dio.close(force: true);
  });
  return gateway;
});

// Keep downloads alive when navigating away. Files also survive process death.
final updateControllerProvider =
    StateNotifierProvider<UpdateController, UpdateState>((ref) {
      final controller = UpdateController(
        ref.watch(updatePlatformProvider),
        ref.watch(updateGatewayProvider),
        codeGateway: ref.watch(codeUpdateGatewayProvider),
      );
      final lifecycle = _UpdateLifecycle(controller);
      ref.onDispose(lifecycle.dispose);
      return controller;
    });

class _UpdateLifecycle with WidgetsBindingObserver {
  _UpdateLifecycle(this.controller) {
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null) didChangeAppLifecycleState(state);
  }
  final UpdateController controller;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      controller.setActive(state == AppLifecycleState.resumed);
  void dispose() => WidgetsBinding.instance.removeObserver(this);
}
