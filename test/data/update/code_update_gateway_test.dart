import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/update/code_update_gateway.dart';
import 'package:towork/domain/update/app_update.dart';
import 'package:towork/domain/update/code_update.dart';

class PatchAdapter implements HttpClientAdapter {
  List<int> bytes = [1, 2, 3];
  int status = 200;
  int requests = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    expect(options.followRedirects, false);
    return ResponseBody.fromBytes(bytes, status);
  }

  @override
  void close({bool force = false}) {}
}

CodeUpdate offer({bool withdraw = false, int size = 3}) => CodeUpdate(
  version: withdraw ? 'withdraw' : '1',
  size: withdraw ? 0 : size,
  url: withdraw
      ? null
      : SignedCodeUpdateGateway.base.resolve('objects/fixture.fptc'),
  manifest: jsonEncode({
    'payload': base64Encode(
      utf8.encode(jsonEncode({'action': withdraw ? 'withdraw' : 'publish'})),
    ),
    'signature': base64Encode(List.filled(64, 0)),
  }),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_patcher');
  late Dio dio;
  late PatchAdapter adapter;
  late SignedCodeUpdateGateway gateway;
  int applies = 0;
  PlatformException? nativeError;
  setUp(() {
    applies = 0;
    nativeError = null;
    adapter = PatchAdapter();
    dio = Dio()..httpClientAdapter = adapter;
    gateway = SignedCodeUpdateGateway(dio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'applySignedManifest');
          applies++;
          if (nativeError != null) throw nativeError!;
          final args = (call.arguments as Map);
          if (args['payload'] case final String file) {
            expect(await File(file).readAsBytes(), adapter.bytes);
          }
          return {'action': 'publish', 'ok': true};
        });
  });
  tearDown(() {
    gateway.cancel();
    dio.close(force: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'complete bytes reach native verifier and progress precedes verification',
    () async {
      final events = <String>[];
      await gateway.apply(
        offer(),
        onProgress: (n) => events.add('$n'),
        onVerifying: () => events.add('verify'),
      );
      expect(events, ['3', 'verify']);
      expect(applies, 1);
    },
  );
  test(
    'truncated and oversized downloads cannot reach native commit',
    () async {
      for (final size in [2, 4]) {
        await expectLater(
          gateway.apply(
            offer(size: size),
            onProgress: (_) {},
            onVerifying: () {},
          ),
          throwsA(isA<UpdateFailure>()),
        );
      }
      expect(applies, 0);
    },
  );
  test('redirect responses cannot reach native commit', () async {
    adapter.status = 302;
    await expectLater(
      gateway.apply(offer(), onProgress: (_) {}, onVerifying: () {}),
      throwsA(isA<UpdateFailure>()),
    );
    expect(applies, 0);
  });
  test('native signature rejection propagates without a restart', () async {
    nativeError = PlatformException(code: 'signature');
    await expectLater(
      gateway.apply(offer(), onProgress: (_) {}, onVerifying: () {}),
      throwsA(isA<PlatformException>()),
    );
    expect(applies, 1);
  });
  test('signed withdrawal is committed with no payload download', () async {
    await gateway.apply(
      offer(withdraw: true),
      onProgress: (_) => fail('withdrawal progress'),
      onVerifying: () {},
    );
    expect(adapter.requests, 0);
    expect(applies, 1);
  });
}
