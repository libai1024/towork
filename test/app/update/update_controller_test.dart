import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/update/update_controller.dart';
import 'package:towork/domain/update/app_update.dart';

import '../../support/update_fakes.dart';

void main() {
  late FakeUpdatePlatform platform;
  late FakeUpdateGateway gateway;
  late UpdateController controller;
  setUp(() {
    platform = FakeUpdatePlatform();
    gateway = FakeUpdateGateway();
    controller = UpdateController(platform, gateway);
  });
  tearDown(() => controller.dispose());

  test('unsupported platform never requests a manifest', () async {
    platform.info = const InstalledApp(versionName: '1.1.2', versionCode: 4);
    await controller.check();
    expect(controller.state.phase, UpdatePhase.unsupported);
    expect(gateway.checks, 0);
  });

  test('check failure can retry and current release has no download', () async {
    gateway.checkError = const UpdateFailure('network');
    await controller.check();
    expect(controller.state.phase, UpdatePhase.failed);
    gateway.checkError = null;
    gateway.release = null;
    await controller.check();
    expect(controller.state.phase, UpdatePhase.current);
    await controller.download();
    expect(gateway.downloads, 0);
  });

  test(
    'download cancellation, retry, permission return, and system confirmation',
    () async {
      await controller.check();
      gateway.transfer = Completer<String>();
      final downloading = controller.download();
      await pumpEventQueue();
      expect(controller.state.received, updateFixtureRelease.size ~/ 2);
      await controller.check();
      expect(gateway.checks, 1);
      controller.cancelDownload();
      await downloading;
      expect(controller.state.phase, UpdatePhase.available);
      gateway.transfer = null;
      await controller.download();
      expect(controller.state.phase, UpdatePhase.ready);
      platform.allowed = false;
      await controller.install();
      expect(controller.state.phase, UpdatePhase.permission);
      expect(platform.permissionRequests, 1);
      expect(platform.installs, 0);
      platform.allowed = true;
      await controller.install();
      expect(controller.state.phase, UpdatePhase.installing);
      platform.status = InstallStatus.confirmation;
      await controller.pollInstallation();
      expect(platform.confirmations, 1);
      platform.status = InstallStatus.cancelled;
      await controller.pollInstallation();
      expect(controller.state.phase, UpdatePhase.ready);
      await controller.install();
      expect(platform.installs, 2);
    },
  );

  test(
    'double install is serialized and invalid APK goes back to download',
    () async {
      await controller.check();
      await controller.download();
      platform.installation = Completer<void>();
      final first = controller.install();
      await pumpEventQueue();
      await controller.install();
      expect(platform.installs, 1);
      platform.installation!.completeError(const UpdateFailure('checksum'));
      await first;
      expect(controller.state.phase, UpdatePhase.available);
      expect(controller.state.path, isNull);
    },
  );

  test('late download after scope disposal cannot update state', () async {
    await controller.check();
    gateway.transfer = Completer<String>();
    final operation = controller.download();
    await pumpEventQueue();
    controller.dispose();
    await operation;
    // Replace the disposed instance so tearDown releases exactly one live scope.
    controller = UpdateController(platform, FakeUpdateGateway());
  });

  test(
    'delta progress, applying and full fallback share one download state',
    () async {
      gateway.release = updateFixtureRelease.selectPatch(
        AppPatch(
          fromVersionCode: 3,
          fromSha256: 'a' * 64,
          url: Uri.parse('https://example.test/patch.hpatch'),
          sha256: 'b' * 64,
          size: 128,
        ),
      );
      await controller.check();
      expect(controller.state.isDelta, isTrue);
      expect(controller.state.downloadSize, 128);
      gateway.transfer = Completer<String>();
      final pending = controller.download();
      await pumpEventQueue();
      gateway.applying!();
      expect(controller.state.phase, UpdatePhase.applying);
      expect(controller.state.busy, isTrue);
      gateway.fallback!();
      expect(controller.state.isDelta, isFalse);
      expect(controller.state.downloadSize, updateFixtureRelease.size);
      expect(controller.state.received, 0);
      gateway.transfer!.complete('/private/updates/fixture.apk');
      await pending;
      expect(controller.state.phase, UpdatePhase.ready);
    },
  );
}
