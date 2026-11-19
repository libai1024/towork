import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

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
