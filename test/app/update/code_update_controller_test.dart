import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/update/update_controller.dart';
import 'package:towork/domain/update/app_update.dart';
import 'package:towork/domain/update/code_update.dart';

import '../../support/update_fakes.dart';
import '../../support/code_update_fake.dart';

void main() {
  late FakeUpdatePlatform platform;
  late FakeUpdateGateway apk;
  late FakeCodeUpdateGateway code;
  late UpdateController controller;
  setUp(() {
    platform = FakeUpdatePlatform();
    apk = FakeUpdateGateway()..release = null;
    code = FakeCodeUpdateGateway();
    controller = UpdateController(platform, apk, codeGateway: code);
  });
  tearDown(() => controller.dispose());

  test('new host takes precedence and old hosts skip code checks', () async {
    apk.release = updateFixtureRelease;
    await controller.check();
    expect(controller.state.release, updateFixtureRelease);
    expect(code.checks, 0);
    apk.release = null;
    code.info = const CodeUpdateStatus();
    await controller.check();
    expect(controller.state.phase, UpdatePhase.current);
    expect(code.checks, 0);
  });

  test(
    'code update auto restarts, retry preserves commit and skips APK installer',
    () async {
      await controller.check();
      expect(controller.state.codeUpdate?.version, '1');
      await controller.download();
      expect(code.restarts, 1);
      expect(controller.state.codeReady, true);
      expect(controller.state.phase, UpdatePhase.ready);
      await controller.check();
      await controller.download();
      expect(code.applications, 1);
      await controller.install();
      expect(code.restarts, 2);
      expect(platform.permissionRequests, 0);
      expect(platform.installs, 0);
    },
  );

  test(
    'background cancels only download and prevents automatic restart',
    () async {
      code.transfer = Completer<void>();
      await controller.check();
      final pending = controller.download();
      await pumpEventQueue();
      controller.setActive(false);
      await pending;
      expect(controller.state.phase, UpdatePhase.available);
      expect(code.restarts, 0);
      expect(code.cancels, 1);
    },
  );

  test(
    'verification completes in background and restarts once on resume',
    () async {
      code.transfer = Completer<void>();
      await controller.check();
      final pending = controller.download();
      await pumpEventQueue();
      code.verifying!();
      controller.setActive(false);
      expect(code.cancels, 0);
      code.transfer!.complete();
      await pending;
      expect(controller.state.codeReady, true);
      expect(code.restarts, 0);
      controller.setActive(true);
      await pumpEventQueue();
      expect(code.restarts, 1);
      controller.setActive(false);
      controller.setActive(true);
      await pumpEventQueue();
      expect(code.restarts, 1);
    },
  );

  test('failed signature never restarts and can be checked again', () async {
    code.applyError = const UpdateFailure('code_signature');
    await controller.check();
    await controller.download();
    expect(code.restarts, 0);
    expect(controller.state.codeReady, false);
    expect(controller.state.message, contains('验证失败'));
    await controller.check();
    expect(code.checks, 2);
  });

  test('withdrawal and already committed patch have restart path', () async {
    code.offer = const CodeUpdate(
      version: 'withdraw',
      manifest: 'signed',
      size: 0,
    );
    await controller.check();
    expect(controller.state.codeUpdate!.withdrawal, true);
    await controller.download();
    expect(code.restarts, 1);
    controller.dispose();
    code.info = const CodeUpdateStatus(supported: true, pending: true);
    controller = UpdateController(platform, apk, codeGateway: code);
    await controller.check();
    expect(controller.state.phase, UpdatePhase.ready);
    expect(controller.state.codeReady, true);
    final restarts = code.restarts;
    controller.setActive(false);
    controller.setActive(true);
    expect(code.restarts, restarts);
    expect(code.checks, 1);
  });

  test('busy peer preserves ready patch for an explicit retry', () async {
    code.restartError = const UpdateFailure('restart_busy');
    await controller.check();
    await controller.download();
    expect(controller.state.phase, UpdatePhase.ready);
    expect(controller.state.message, contains('对话或输入'));
    expect(code.applications, 1);
  });
}
