import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/ai/openai_compatible_gateway.dart';
import 'package:towork/domain/ai/model_gateway.dart';

import 'chat_stream_protocol_test.dart' show chunk, fails;

/// Test-only transport routes the real Dart HTTP stack to a local fixture.
class LoopbackTransport implements HttpClientAdapter {
  LoopbackTransport(this.port);
  final int port;
  final _inner = IOHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) => _inner.fetch(
    options.copyWith(
      path: 'http://127.0.0.1:$port${options.uri.path}',
      baseUrl: '',
    ),
    body,
    cancel,
  );

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

void main() {
  late HttpServer server;
  late OpenAiCompatibleGateway gateway;
  final profile = ModelProfile(model: 'fixture-model', disableThinking: true);

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

  test('connection probe uses real HTTP, no tools/history or persisted Key', () async {
    final handled = server.first.then((request) async {
      expect(request.uri.path, '/v1/chat/completions');
      expect(request.headers.value('authorization'), 'Bearer test-only');
      expect(request.headers.value('user-agent'), 'ToWork/1.0');
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, Object?>;
      expect(body.containsKey('tools'), isFalse);
      expect(body['messages'], [
        {'role': 'user', 'content': 'Reply with OK only.'},
      ]);
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
      );
      final bytes = utf8.encode(
        'data: ${chunk({'content': 'OK'}, finish: 'stop')}\n\ndata: [DONE]\n\n',
      );
      for (final byte in bytes) {
        request.response.add([byte]);
      }
      await request.response.close();
    });
    final result = await gateway.testConnection(
      profile: profile,
      apiKey: 'test-only',
    );
    await handled;
    expect(result.text, 'OK');
    expect(result.usage, isNull);
  });

  test('model directory uses authenticated GET, preserves endpoint prefix and deduplicates IDs', () async {
    final handled = server.first.then((request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/compatible/v1/models');
      expect(request.headers.value('authorization'), 'Bearer test-only');
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"data":[{"id":"z"},{"id":"a"},{"id":"z"}]}');
      await request.response.close();
    });
    expect(
      await gateway.listModels(
        Uri.https('example.com', '/compatible/v1/models'),
        apiKey: 'test-only',
        cancellation: ModelCancellation(),
      ),
      ['a', 'z'],
    );
    await handled;
  });

  for (final entry in {
    401: ModelFailureCode.authentication,
    403: ModelFailureCode.forbidden,
    404: ModelFailureCode.unavailableModel,
    429: ModelFailureCode.rateLimited,
    503: ModelFailureCode.provider,
  }.entries) {
    test('HTTP ${entry.key} maps to safe typed failure', () async {
      final handled = server.first.then((request) async {
        await request.drain<void>();
        request.response.statusCode = entry.key;
        request.response.write('private upstream message test-only');
        await request.response.close();
      });
      await expectLater(
        gateway.testConnection(profile: profile, apiKey: 'test-only'),
        fails(entry.value),
      );
      await handled;
    });
  }

  test('redirect cannot forward the bearer key', () async {
    var requests = 0;
    server.listen((request) async {
      requests++;
      await request.drain<void>();
      request.response.statusCode = 307;
      request.response.headers.set(
        'location',
        'http://127.0.0.1:${server.port}/unexpected',
      );
      await request.response.close();
    });
    await expectLater(
      gateway.testConnection(profile: profile, apiKey: 'test-only'),
      fails(ModelFailureCode.provider),
    );
    expect(requests, 1);
  });

  test('truncated stream cannot claim success', () async {
    final handled = server.first.then((request) async {
      await request.drain<void>();
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
      );
      request.response.write('data: ${chunk({'content': 'partial'})}\n\n');
      await request.response.close();
    });
    await expectLater(
      gateway.testConnection(profile: profile, apiKey: 'test-only'),
      fails(ModelFailureCode.truncated),
    );
    await handled;
  });

  test('explicit cancellation aborts a live waiting request', () async {
    final cancellation = ModelCancellation();
    final handled = server.first.then((request) async {
      await request.drain<void>();
      cancellation.cancel();
    });
    await expectLater(
      gateway.testConnection(
        profile: profile,
        apiKey: 'test-only',
        cancellation: cancellation,
      ),
      fails(ModelFailureCode.cancelled),
    );
    await handled;
  });

  test('overall deadline is bounded while server never responds', () async {
    gateway.close();
    gateway = OpenAiCompatibleGateway(
      transport: LoopbackTransport(server.port),
      timeout: const Duration(milliseconds: 100),
    );
    final handled = server.first.then((request) => request.drain<void>());
    await expectLater(
      gateway.testConnection(profile: profile, apiKey: 'test-only'),
      fails(ModelFailureCode.timeout),
    );
    await handled;
  });

  test(
    'abrupt mid-body connection death maps to typed network failure',
    () async {
      // 响应头已返回、响应体中途断开（连接被重置/上游提前关闭）时，
      // 原始 IOException 不允许逃出网关：必须落为可重试的类型化网络失败。
      // 用裸 ServerSocket 发送未终止的 chunked 响应后销毁连接，确保断流确定复现。
      final raw = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => raw.close());
      gateway.close();
      gateway = OpenAiCompatibleGateway(transport: LoopbackTransport(raw.port));
      final payload = utf8.encode('data: ${chunk({'content': 'partial'})}\n\n');
      final head = ascii.encode(
        'HTTP/1.1 200 OK\r\n'
        'Content-Type: text/event-stream\r\n'
        'Transfer-Encoding: chunked\r\n\r\n',
      );
      final frame = [
        ...ascii.encode('${payload.length.toRadixString(16)}\r\n'),
        ...payload,
        ...ascii.encode('\r\n'),
      ];
      raw.listen((socket) async {
        socket.add(head);
        await socket.flush();
        socket.add(frame);
        await socket.flush();
        // 不发送 0 长度终止块即销毁 socket：客户端读到的是中途断流。
        socket.destroy();
      });
      await expectLater(
        gateway.testConnection(profile: profile, apiKey: 'test-only'),
        fails(ModelFailureCode.network),
      );
    },
  );

  test(
    'runner-style cancellation aborts the live body with no late events',
    () async {
      // 复刻 AgentRunner._collect 的消费方式：StreamIterator + 传输层取消。
      // 取消必须及时结束迭代（finally 释放连接），且不再投递任何后续事件。
      final released = Completer<void>();
      server.listen((request) async {
        try {
          await request.drain<void>();
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
          );
          request.response.bufferOutput = false;
          request.response.add(
            utf8.encode('data: ${chunk({'content': 'ok'})}\n\n'),
          );
          await request.response.flush();
          await released.future;
          request.response.add(utf8.encode('data: [DONE]\n\n'));
          await request.response.flush();
          await request.response.close();
        } catch (_) {
          // 客户端中止后服务端写失败是预期噪声。
        }
      });
      final cancellation = ModelCancellation();
      final iterator = StreamIterator<ModelEvent>(
        gateway.stream(
          ModelRequest(
            profile: profile,
            messages: const [
              {'role': 'user', 'content': 'Reply with OK only.'},
            ],
          ),
          apiKey: 'test-only',
          cancellation: cancellation,
        ),
      );
      final events = <ModelEvent>[];
      addTearDown(() async {
        cancellation.cancel();
        await iterator.cancel().timeout(const Duration(seconds: 5));
      });
      expect(await iterator.moveNext(), isTrue);
      events.add(iterator.current);
      expect(events.single, isA<ModelTextDelta>());
      // Consumer cancels: transport first (runner contract), then the iterator.
      cancellation.cancel();
      await iterator.cancel().timeout(const Duration(seconds: 5));
      released.complete();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(events, hasLength(1), reason: '取消后不得再投递事件');
    },
  );
}
