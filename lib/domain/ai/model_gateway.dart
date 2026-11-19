import 'dart:convert';

import 'provider_catalog.dart';

export 'provider_catalog.dart';

typedef JsonObject = Map<String, Object?>;

/// Credentials belong to a vault, never to a serializable provider profile.
class ModelProfile {
  ModelProfile({
    required this.model,
    this.region = ProviderRegion.china,
    this.product = ProviderKind.moonshot,
    this.revision = 1,
    this.disableThinking = false,
    this.baseUrl,
  }) {
    if (model.trim().isEmpty || model != model.trim() || revision < 1) {
      throw const ModelFailure(ModelFailureCode.configuration);
    }
    if (descriptor.needsBaseUrl) {
      final uri = Uri.tryParse(baseUrl ?? '');
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          baseUrl != baseUrl!.trim()) {
        throw const ModelFailure(ModelFailureCode.configuration);
      }
    }
  }

  /// 仅需要自填地址的服务商使用：OpenAI 兼容接口根地址（https）。
  final String? baseUrl;
  final String model;
  final ProviderRegion region;
  final ProviderKind product;
  final int revision;

  /// 「少思考」意图。具体发什么参数由服务商描述决定，见 [reasoningParameters]。
  final bool disableThinking;

  ProviderDescriptor get descriptor => ProviderCatalog.of(product);

  Uri get completionsUri =>
      descriptor.completionsUri(region, customBase: baseUrl);

  /// 同一个「少思考」意图在各家的写法不同：能关的发 `thinking.disabled`，
  /// 不能关的压到 `reasoning_effort: low`，其余不发，避免被服务商拒绝。
  JsonObject get reasoningParameters {
    if (!disableThinking) return const {};
    return switch (descriptor.thinkingFor(model)) {
      ThinkingControl.toggle => const {
        'thinking': {'type': 'disabled'},
      },
      ThinkingControl.effort => const {'reasoning_effort': 'low'},
      ThinkingControl.none => const {},
    };
  }

  ModelProfile copyWith({
    String? model,
    int? revision,
    bool? disableThinking,
  }) => ModelProfile(
    model: model ?? this.model,
    region: region,
    product: product,
    revision: revision ?? this.revision,
    disableThinking: disableThinking ?? this.disableThinking,
    baseUrl: baseUrl,
  );
}

enum ModelFailureCode {
  configuration,
  authentication,
  forbidden,
  rateLimited,

  /// 订阅额度或账户余额用尽；与一时的限流不同，等一会儿重试没有用。
  quota,
  unavailableModel,
  provider,
  network,
  timeout,
  cancelled,
  protocol,
  truncated,
  budget,
  contextBudget,
}

/// Deliberately excludes upstream messages, request bodies and credentials.
class ModelFailure implements Exception {
  const ModelFailure(this.code, {this.statusCode});

  final ModelFailureCode code;
  final int? statusCode;

  @override
  String toString() => 'ModelFailure(${code.name}, status: $statusCode)';
}

/// A detachable cancellation signal that is independent of the HTTP library.
class ModelCancellation {
  bool _cancelled = false;
  final Set<void Function()> _listeners = {};

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    final pending = List<void Function()>.of(_listeners);
    _listeners.clear();
    for (final listener in pending) {
      listener();
    }
  }

  void Function() onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
    return () => _listeners.remove(listener);
  }
}

/// Copies JSON deeply so in-flight requests cannot change after approval.
JsonObject immutableJson(JsonObject value) {
  Object? freeze(Object? item) => switch (item) {
    Map<String, Object?> map => Map<String, Object?>.unmodifiable(
      map.map((key, value) => MapEntry(key, freeze(value))),
    ),
    List<Object?> list => List<Object?>.unmodifiable(list.map(freeze)),
    null || String() || bool() || num() => item,
    _ => throw const ModelFailure(ModelFailureCode.configuration),
  };
  // Reject non-JSON numbers before handing a request to a transport.
  try {
    jsonEncode(value);
  } on JsonUnsupportedObjectError {
    throw const ModelFailure(ModelFailureCode.configuration);
  }
  return freeze(value)! as JsonObject;
}

class ModelRequest {
  ModelRequest({
    required this.profile,
    required List<JsonObject> messages,
    List<JsonObject> tools = const [],
    this.maxTokens = 4096,
  }) : messages = List.unmodifiable(messages.map(immutableJson)),
       tools = List.unmodifiable(tools.map(immutableJson)) {
    if (messages.isEmpty || maxTokens < 1 || maxTokens > 32768) {
      throw const ModelFailure(ModelFailureCode.configuration);
    }
  }

  final ModelProfile profile;
  final List<JsonObject> messages;
  final List<JsonObject> tools;
  final int maxTokens;

  JsonObject toJson() => {
    'model': profile.model,
    'messages': messages,
    'stream': true,
    'stream_options': {'include_usage': true},
    'max_tokens': maxTokens,
    ...profile.reasoningParameters,
    if (tools.isNotEmpty) 'tools': tools,
  };
}

sealed class ModelEvent {
  const ModelEvent();
}

class ModelTextDelta extends ModelEvent {
  const ModelTextDelta(this.text);
  final String text;
}

/// Only this terminal event may supply tool calls to the execution layer.
class ModelCompleted extends ModelEvent {
  ModelCompleted({
    required JsonObject assistantMessage,
    required this.finishReason,
    JsonObject? usage,
  }) : assistantMessage = immutableJson(assistantMessage),
       usage = usage == null ? null : immutableJson(usage);

  final JsonObject assistantMessage;
  final String finishReason;
  final JsonObject? usage;

  String get text => assistantMessage['content'] as String? ?? '';
}

abstract interface class ModelDirectory {
  Future<List<String>> listModels(
    Uri endpoint, {
    required String apiKey,
    required ModelCancellation cancellation,
  });
}

abstract interface class ModelGateway {
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  });
}
