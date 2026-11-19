import 'dart:convert';
import 'dart:io';

import 'package:towork/app/model_transmission.dart';
import 'package:towork/domain/ai/model_gateway.dart';

/// Explicit opt-in only. Never run this probe from the default CI entry point.
Future<void> main(List<String> arguments) async {
  if (!arguments.contains('--allow-paid-request')) {
    stderr.writeln(
      'Add --allow-paid-request to enable up to three model calls.',
    );
    exitCode = 64;
    return;
  }
  final env = <String, String>{...Platform.environment};
  final file = File('.env');
  if (await file.exists()) {
    for (final line in await file.readAsLines()) {
      if (line.startsWith('#')) continue;
      final separator = line.indexOf('=');
      if (separator > 0) {
        env.putIfAbsent(
          line.substring(0, separator).trim(),
          () => line.substring(separator + 1).trim(),
        );
      }
    }
  }
  final key = env['KIMI_API_KEY'];
  if (key == null || key.isEmpty) {
    stderr.writeln('KIMI_API_KEY is missing from environment or private .env.');
    exitCode = 64;
    return;
  }
  final isCode = arguments.contains('--kimi-code');
  final profile = ModelProfile(
    product: isCode ? ProviderKind.kimiCode : ProviderKind.moonshot,
    model: isCode
        ? env['KIMI_CODE_MODEL'] ?? 'kimi-for-coding'
        : env['KIMI_MODEL_DEFAULT'] ?? 'kimi-k2.6',
    disableThinking: true,
  );
  final client = createPlatformModelGateway();
  final clock = Stopwatch()..start();
  var phase = 'connection';
  try {
    final probe = await client.testConnection(profile: profile, apiKey: key);
    stdout.writeln(
      jsonEncode({
        'phase': phase,
        'status': 'passed',
        'model': profile.model,
        'product': profile.product.name,
        'elapsed_ms': clock.elapsedMilliseconds,
        'usage': probe.usage,
      }),
    );
    if (!arguments.contains('--tools')) return;
    phase = 'tool_proposal';
    final messages = <JsonObject>[
      {
        'role': 'user',
        'content': 'Call probe_echo with text set to 测试. Use the returned result to reply in one short sentence.',
      },
    ];
    final tools = <JsonObject>[
      {
        'type': 'function',
        'function': {
          'name': 'probe_echo',
          'description': 'Returns the input as a synthetic test result. No business data is accessed.',
          'parameters': {
            'type': 'object',
            'properties': {
              'text': {'type': 'string'},
            },
            'required': ['text'],
            'additionalProperties': false,
          },
        },
      },
    ];
    final proposed =
        (await client
                .stream(
                  ModelRequest(
                    profile: profile,
                    messages: messages,
                    tools: tools,
                    maxTokens: 1024,
                  ),
                  apiKey: key,
                )
                .where((e) => e is ModelCompleted)
                .single)
            as ModelCompleted;
    final calls = proposed.assistantMessage['tool_calls'] as List<Object?>?;
    if (calls == null || calls.length != 1) {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
    final call = calls.single! as JsonObject;
    final function = call['function']! as JsonObject;
    if (function['name'] != 'probe_echo') {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
    final args = jsonDecode(function['arguments']! as String) as JsonObject;
    if (args.length != 1 || args['text'] != '测试') {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
    messages.add(proposed.assistantMessage);
    messages.add({
      'role': 'tool',
      'tool_call_id': call['id'],
      'content': jsonEncode({'text': args['text'], 'synthetic': true}),
    });
    phase = 'tool_result_reply';
    final completed =
        (await client
                .stream(
                  ModelRequest(
                    profile: profile,
                    messages: messages,
                    maxTokens: 1024,
                  ),
                  apiKey: key,
                )
                .where((e) => e is ModelCompleted)
                .single)
            as ModelCompleted;
    stdout.writeln(
      jsonEncode({
        'phase': phase,
        'status': 'passed',
        'model': profile.model,
        'elapsed_ms': clock.elapsedMilliseconds,
        'tool_count': calls.length,
        'proposal_usage': proposed.usage,
        'reply_usage': completed.usage,
        'business_writes': 0,
      }),
    );
  } on ModelFailure catch (error) {
    stdout.writeln(
      jsonEncode({
        'phase': phase,
        'status': 'failed',
        'code': error.code.name,
        'product': profile.product.name,
        'http_status': error.statusCode,
      }),
    );
    exitCode = 1;
  } catch (error) {
    stdout.writeln(
      jsonEncode({
        'phase': phase,
        'status': 'failed',
        'type': error.runtimeType.toString(),
      }),
    );
    exitCode = 1;
  } finally {
    client.close();
  }
}
