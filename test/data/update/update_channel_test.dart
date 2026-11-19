import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/update/update_channel.dart';
import 'package:towork/domain/update/app_update.dart';

import '../../support/update_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('towork/update');
  const platform = UpdateChannel();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'platform package version and signer replace display defaults',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {
          'versionName': '1.1.2',
          'versionCode': 4,
          'supported': true,
          'certSha256': 'a' * 64,
          'abis': ['arm64-v8a'],
          'availableBytes': 4096,
          'apkSha256': 'd' * 64,
        },
      );
      final info = await platform.installed();
      expect(info.label, '1.1.2 (4)');
      expect(info.canUpdate, isTrue);
      expect(info.abis, ['arm64-v8a']);
      expect(info.availableBytes, 4096);
      expect(info.apkSha256, 'd' * 64);
    },
  );

  test(
    'install forwards verified metadata and maps native validation failures',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'install') {
          throw PlatformException(code: 'signature');
        }
        return true;
      });
      expect(await platform.canInstall(), isTrue);
      await platform.requestInstallPermission();
      await expectLater(
        platform.install('/private/file.apk', updateFixtureRelease),
        throwsA(
          isA<UpdateFailure>().having((e) => e.code, 'code', 'signature'),
        ),
      );
      final args = calls.last.arguments as Map<Object?, Object?>;
      expect(args['versionCode'], 4);
      expect(args['sha256'], updateFixtureRelease.sha256);
      expect(args['size'], updateFixtureRelease.size);
    },
  );

  test(
    'unsupported host and unrecognized installation status are controlled',
    () async {
      expect((await platform.installed()).canUpdate, isFalse);
      messenger.setMockMethodCallHandler(channel, (_) async => 'unexpected');
      expect(await platform.installStatus(), InstallStatus.failed);
    },
  );

  test(
    'patch call forwards base and target identities to the native validator',
    () async {
      MethodCall? received;
      messenger.setMockMethodCallHandler(channel, (call) async {
        received = call;
        return null;
      });
      final release = updateFixtureRelease.selectPatch(
        AppPatch(
          fromVersionCode: 3,
          fromSha256: 'c' * 64,
          url: Uri.parse('https://example.test/patch.hpatch'),
          sha256: 'd' * 64,
          size: 20,
        ),
      );
      await platform.applyPatch(
        '/private/patch.hpatch',
        '/private/target.apk.part',
        release,
      );
      expect(received!.method, 'patch');
      final arguments = received!.arguments as Map;
      expect(arguments['fromSha256'], 'c' * 64);
      expect(arguments['patchSha256'], 'd' * 64);
      expect(arguments['sha256'], release.sha256);
      expect(arguments['size'], release.size);
    },
  );
}
