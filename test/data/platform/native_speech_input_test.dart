import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/platform/native_speech_input.dart';
import 'package:towork/domain/speech/speech_input.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('towork/speech-test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late NativeSpeechInput speech;
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'inspect' || call.method == 'prepare') {
        return {
          'available': true,
          'authorized': false,
          'locales': ['zh-CN'],
          'onDeviceSupported': false,
        };
      }
      return null;
    });
    speech = NativeSpeechInput(channel: channel);
  });
  tearDown(() async {
    await speech.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });
  test(
    'inspection is separate from authorization and does not start a capture',
    () async {
      final cap = await speech.inspect('zh-CN');
      expect(cap.available, isTrue);
      expect(cap.authorized, isFalse);
      expect(cap.locales, ['zh-CN']);
      expect(calls.map((c) => c.method), ['inspect']);
    },
  );
  test(
    'start, stop and cancel carry the exact native capture identity',
    () async {
      await speech.start('capture-one', locale: 'zh-CN', onDevice: true);
      await speech.stop('capture-one');
      await speech.cancel('capture-one');
      expect(calls.map((c) => c.arguments['id']), everyElement('capture-one'));
      expect(calls.first.arguments['onDevice'], isTrue);
    },
  );
  test('platform failures never expose raw plugin messages', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(
        code: 'permissionDenied',
        message: 'private platform payload',
      ),
    );
    await expectLater(
      speech.prepare('zh-CN'),
      throwsA(
        isA<SpeechFailure>().having(
          (e) => e.code,
          'code',
          SpeechFailureCode.permissionDenied,
        ),
      ),
    );
  });
}
