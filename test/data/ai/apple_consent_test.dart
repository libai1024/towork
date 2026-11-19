import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/model_transmission.dart';
import 'package:towork/data/ai/openai_compatible_gateway.dart';
import 'package:towork/data/platform/apple_distribution.dart';
import 'package:towork/domain/ai/model_gateway.dart';

import 'chat_stream_protocol_test.dart' show chunk, fails;
import '../../support/loopback_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('towork/apple-distribution');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final profile = ModelProfile(model: 'fixture-model');
  late HttpServer server;
  late int requests;

  OpenAiCompatibleGateway gateway(TargetPlatform platform) {
    debugDefaultTargetPlatformOverride = platform;
    final client = OpenAiCompatibleGateway(
      authorize: platformModelAuthorization,
      transport: LoopbackTransport(server.port),
    );
    addTearDown(client.close);
    return client;
  }

  setUp(() async {
    final previous = HttpOverrides.current;
    HttpOverrides.global =
        null; // LoopbackTransport exercises the real local HTTP stack.
    addTearDown(() => HttpOverrides.global = previous);
    requests = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests++;
      await request.drain<void>();
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
      );
      request.response.write(
        "data: ${chunk({'content': 'OK'}, finish: 'stop')}\n\ndata: [DONE]\n\n",
      );
      await request.response.close();
    });
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
    await server.close(force: true);
  });

  test('Apple consent uses the exact origin and provider, supports denial and reset', () async {
    final client = gateway(TargetPlatform.iOS);
    final allowed = <String>{};
    var accept = false;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'resetModelConsent') {
        allowed.clear();
        return null;
      }
      expect(call.method, 'authorizeModel');
      final origin = call.arguments['origin'] as String;
      calls.add(origin);
      expect(call.arguments['provider'], isNotEmpty);
      if (accept) allowed.add(origin);
      return allowed.contains(origin);
    });
    Future<ModelCompleted> send(ModelProfile p) =>
        client.testConnection(profile: p, apiKey: 'fixture');
    await expectLater(send(profile), fails(ModelFailureCode.cancelled));
    expect(requests, 0);
    accept = true;
    await send(profile);
    accept = false;
    await send(profile);
    final custom = ModelProfile(
      model: 'local',
      product: ProviderKind.custom,
      baseUrl: 'https://other.example:8443/v1',
    );
    await expectLater(send(custom), fails(ModelFailureCode.cancelled));
    expect(calls, [
      profile.completionsUri.origin,
      profile.completionsUri.origin,
      profile.completionsUri.origin,
      custom.completionsUri.origin,
    ]);
    expect(requests, 2);
    await AppleDistribution.resetModelConsent();
    await expectLater(send(profile), fails(ModelFailureCode.cancelled));
    expect(requests, 2);
  });

  test(
    'missing and malformed Apple host responses stop transmission',
    () async {
      final client = gateway(TargetPlatform.iOS);
      Future<ModelCompleted> send() =>
          client.testConnection(profile: profile, apiKey: 'fixture');
      await expectLater(send(), fails(ModelFailureCode.configuration));
      messenger.setMockMethodCallHandler(channel, (call) async => 'yes');
      await expectLater(send(), fails(ModelFailureCode.protocol));
      expect(requests, 0);
    },
  );

  test(
    'cancelling a pending prompt settles before the late approval',
    () async {
      final client = gateway(TargetPlatform.iOS);
      final opened = Completer<void>();
      final answer = Completer<bool>();
      messenger.setMockMethodCallHandler(channel, (call) {
        opened.complete();
        return answer.future;
      });
      final signal = ModelCancellation();
      final done = expectLater(
        client.testConnection(
          profile: profile,
          apiKey: 'fixture',
          cancellation: signal,
        ),
        fails(ModelFailureCode.cancelled),
      );
      await opened.future;
      signal.cancel();
      await done.timeout(const Duration(seconds: 2));
      answer.complete(true);
      await Future<void>.delayed(Duration.zero);
      expect(requests, 0);
    },
  );

  test(
    'macOS download and App Store builds select their distribution policy',
    () async {
      final client = gateway(TargetPlatform.macOS);
      var appleCalls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'authorizeModel');
        appleCalls++;
        return false;
      });
      final request = client.testConnection(
        profile: profile,
        apiKey: 'fixture',
      );
      if (const bool.fromEnvironment('TOWORK_MAC_APP_STORE')) {
        await expectLater(request, fails(ModelFailureCode.cancelled));
        expect(appleCalls, 1);
        expect(requests, 0);
      } else {
        await request;
        expect(appleCalls, 0);
        expect(requests, 1);
      }
    },
  );

  test('Android sends directly without invoking the Apple host', () async {
    final client = gateway(TargetPlatform.android);
    var appleCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      appleCalls++;
      return false;
    });
    await client.testConnection(profile: profile, apiKey: 'fixture');
    expect(appleCalls, 0);
    expect(requests, 1);
  });
}
