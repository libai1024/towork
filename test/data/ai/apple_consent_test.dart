import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/ai/openai_compatible_gateway.dart';
import 'package:towork/domain/ai/model_gateway.dart';

import 'chat_stream_protocol_test.dart' show fails;

import 'openai_compatible_http_test.dart' show LoopbackTransport;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpServer server;
  late OpenAiCompatibleGateway gateway;
  final profile = ModelProfile(model: 'fixture-model');
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    gateway = OpenAiCompatibleGateway(
      transport: LoopbackTransport(server.port),
    );
  });
  tearDown(() async {
    gateway.close();
    await server.close(force: true);
  });
  test(
    'iOS refuses to transmit before the named recipient is authorized',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      const channel = MethodChannel('towork/apple-distribution');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
        debugDefaultTargetPlatformOverride = null;
      });
      var requests = 0;
      server.listen((request) async {
        requests++;
        await request.response.close();
      });
      var prompts = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        prompts++;
        expect(call.method, 'authorizeModel');
        expect(call.arguments['origin'], profile.completionsUri.origin);
        expect(call.arguments['provider'], profile.descriptor.label);
        return false;
      });
      await expectLater(
        gateway.testConnection(profile: profile, apiKey: 'test-only'),
        fails(ModelFailureCode.cancelled),
      );
      expect(prompts, 1);
      expect(requests, 0);
    },
  );
}
