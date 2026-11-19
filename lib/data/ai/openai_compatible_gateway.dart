import 'dart:async';
import 'dart:convert';
import 'dart:io' show IOException;

import 'package:dio/dio.dart';

import '../../domain/ai/model_gateway.dart';
import '../../domain/ai/model_transmission.dart';
import 'chat_stream_assembler.dart';
import 'sse_decoder.dart';

class OpenAiCompatibleGateway implements ModelGateway, ModelDirectory {
  OpenAiCompatibleGateway({
    required this.authorize,
    HttpClientAdapter? transport,
    // 总闸只兜底「单次流式响应失控」；正常长回复由 idleTimeout 空闲闸
    // 与 AgentRunner.activeTimeout（2 分钟）约束，取值与其对齐，
    // 避免 90 秒杀掉仍在活跃输出的长回复。
    this.timeout = const Duration(minutes: 2),
    this.idleTimeout = const Duration(seconds: 30),
  }) : _dio = Dio() {
    if (transport != null) _dio.httpClientAdapter = transport;
  }

  final AuthorizeModelTransmission authorize;
  final Dio _dio;
  final Duration timeout;
  final Duration idleTimeout;

  @override
  Future<List<String>> listModels(
    Uri endpoint, {
    required String apiKey,
    required ModelCancellation cancellation,
  }) async {
    final token = CancelToken();
    final detach = cancellation.onCancel(() => token.cancel());
    try {
      final response = await _dio.getUri<String>(
        endpoint,
        cancelToken: token,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
          maxRedirects: 0,
          connectTimeout: idleTimeout,
          receiveTimeout: idleTimeout,
          headers: {
            'Authorization': 'Bearer ${apiKey.trim()}',
            'Accept': 'application/json',
            'User-Agent': 'ToWork/1.0',
          },
        ),
      );
      final content = jsonDecode(response.data ?? '');
      if (content is! Map || content['data'] is! List) {
        throw const ModelFailure(ModelFailureCode.protocol);
      }
      final ids = <String>{};
      for (final item in content['data'] as List) {
        if (item is Map && item['id'] is String) {
          final id = (item['id'] as String).trim();
          if (id.isNotEmpty) ids.add(id);
        }
      }
      return ids.toList()..sort();
    } on FormatException {
      throw const ModelFailure(ModelFailureCode.protocol);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      throw ModelFailure(switch (error.type) {
        DioExceptionType.cancel => ModelFailureCode.cancelled,
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => ModelFailureCode.timeout,
        DioExceptionType.badResponse => classifyHttpFailure(status, ''),
        _ => ModelFailureCode.network,
      }, statusCode: status);
    } finally {
      detach();
    }
  }

  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    if (apiKey.trim().isEmpty) {
      throw const ModelFailure(ModelFailureCode.configuration);
    }
    await authorizeModelRequest(authorize, request.profile, cancellation);
    if (cancellation?.isCancelled ?? false) {
      throw const ModelFailure(ModelFailureCode.cancelled);
    }
    final token = CancelToken();
    var expired = false;
    final detach = cancellation?.onCancel(() => token.cancel());
    final deadline = Timer(timeout, () {
      expired = true;
      token.cancel();
    });
    try {
      final response = await _dio.postUri<ResponseBody>(
        request.profile.completionsUri,
        data: request.toJson(),
        cancelToken: token,
        options: Options(
          responseType: ResponseType.stream,
          contentType: Headers.jsonContentType,
          headers: {
            'Authorization': 'Bearer ${apiKey.trim()}',
            'User-Agent': 'ToWork/1.0',
          },
          followRedirects: false,
          maxRedirects: 0,
          connectTimeout: idleTimeout,
          sendTimeout: idleTimeout,
          receiveTimeout: idleTimeout,
        ),
      );
      final body = response.data;
      if (body == null ||
          !(response.headers.value('content-type') ?? '').startsWith(
            'text/event-stream',
          )) {
        throw const ModelFailure(ModelFailureCode.protocol);
      }
      final assembler = ChatStreamAssembler();
      await for (final frame in decodeSse(body.stream.timeout(idleTimeout))) {
        if (token.isCancelled) {
          // 用户主动取消与总闸到期并发时，取消是真实原因，优先上报。
          if (cancellation?.isCancelled ?? false) {
            throw const ModelFailure(ModelFailureCode.cancelled);
          }
          throw const ModelFailure(ModelFailureCode.timeout);
        }
        yield* Stream.fromIterable(assembler.add(frame));
        if (assembler.isComplete) return;
      }
      throw const ModelFailure(ModelFailureCode.truncated);
    } on DioException catch (error) {
      if (cancellation?.isCancelled ?? false) {
        throw const ModelFailure(ModelFailureCode.cancelled);
      }
      if (expired) throw const ModelFailure(ModelFailureCode.timeout);
      final status = error.response?.statusCode;
      final code = switch (error.type) {
        DioExceptionType.cancel => ModelFailureCode.cancelled,
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => ModelFailureCode.timeout,
        DioExceptionType.badResponse => classifyHttpFailure(
          status,
          await _errorBody(error.response),
        ),
        _ => ModelFailureCode.network,
      };
      throw ModelFailure(code, statusCode: status);
    } on TimeoutException {
      throw const ModelFailure(ModelFailureCode.timeout);
    } on IOException {
      // 响应体阶段（headers 已返回）的断流不会被 dio 包装成 DioException，
      // 会以原始 HttpException/SocketException 逃出；统一映射为可重试的
      // 网络失败，调用方与 UI 只见类型化错误，不泄露内部异常文本。
      if (cancellation?.isCancelled ?? false) {
        throw const ModelFailure(ModelFailureCode.cancelled);
      }
      if (expired) throw const ModelFailure(ModelFailureCode.timeout);
      throw const ModelFailure(ModelFailureCode.network);
    } finally {
      deadline.cancel();
      detach?.call();
      // Disconnect on consumer cancellation as well as normal completion.
      if (!token.isCancelled) token.cancel();
    }
  }

  /// 错误响应体只用于分类，读取有上限，内容不落日志也不向上传递。
  static const _errorBodyLimit = 8 * 1024;

  Future<String> _errorBody(Response<dynamic>? response) async {
    final data = response?.data;
    if (data is! ResponseBody) return '';
    try {
      final bytes = <int>[];
      await for (final chunk in data.stream.timeout(
        const Duration(seconds: 3),
      )) {
        bytes.addAll(chunk);
        if (bytes.length >= _errorBodyLimit) break;
      }
      return utf8.decode(
        bytes.length > _errorBodyLimit
            ? bytes.sublist(0, _errorBodyLimit)
            : bytes,
        allowMalformed: true,
      );
    } catch (_) {
      return '';
    }
  }

  /// 把 HTTP 状态和错误体归类。各家把「额度用尽」和「一时限流」都放在
  /// 429（Kimi 偶尔是 403，DeepSeek 是 402），只能靠错误码或措辞区分：
  /// 前者换个账户才有用，后者等一会儿就好。
  static ModelFailureCode classifyHttpFailure(int? status, String body) {
    final text = body.toLowerCase();
    String? errorCode;
    String? errorType;
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final error = decoded['error'] as Map;
        errorCode = error['code']?.toString();
        errorType = error['type']?.toString();
      }
    } on FormatException {
      // 非 JSON 错误体按措辞判断。
    }
    // 智谱：订阅窗口用尽、套餐到期、余额不足。
    const zhipuExhausted = {
      '1113', '1308', '1309', '1310', //
      '1316', '1317', '1318', '1319', '1320', '1321',
    };
    // 智谱：模型不在套餐内、被风控限制。
    const zhipuDenied = {'1311', '1313', '1315'};
    final exhausted =
        status == 402 ||
        zhipuExhausted.contains(errorCode) ||
        errorType == 'exceeded_current_quota_error' ||
        text.contains('usage limit') ||
        text.contains('insufficient balance') ||
        text.contains('balance is insufficient');
    if (exhausted) return ModelFailureCode.quota;
    if (zhipuDenied.contains(errorCode)) return ModelFailureCode.forbidden;
    return switch (status) {
      401 => ModelFailureCode.authentication,
      403 => ModelFailureCode.forbidden,
      404 => ModelFailureCode.unavailableModel,
      429 => ModelFailureCode.rateLimited,
      _ => ModelFailureCode.provider,
    };
  }

  Future<ModelCompleted> testConnection({
    required ModelProfile profile,
    required String apiKey,
    ModelCancellation? cancellation,
  }) async {
    final events = stream(
      ModelRequest(
        profile: profile,
        messages: const [
          {'role': 'user', 'content': 'Reply with OK only.'},
        ],
        maxTokens: profile.disableThinking ? 128 : 2048,
      ),
      apiKey: apiKey,
      cancellation: cancellation,
    );
    await for (final event in events) {
      if (event is ModelCompleted) return event;
    }
    throw const ModelFailure(ModelFailureCode.truncated);
  }

  void close() => _dio.close(force: true);
}
