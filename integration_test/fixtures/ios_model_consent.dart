import 'dart:io';

import 'package:flutter/material.dart';
import 'package:towork/app/model_transmission.dart';
import 'package:towork/data/ai/openai_compatible_gateway.dart';
import 'package:towork/data/platform/apple_distribution.dart';
import 'package:towork/domain/ai/model_gateway.dart';

import '../../test/support/loopback_transport.dart';

void main() => runApp(const MaterialApp(home: _Probe()));

class _Probe extends StatefulWidget {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  HttpServer? server;
  int requests = 0;
  int step = 0;
  bool busy = false;
  String? failure;
  OpenAiCompatibleGateway? gateway;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => advance());
  }

  Future<void> advance() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (step == 0) {
        await AppleDistribution.resetModelConsent();
        {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          this.server = server;
          gateway = OpenAiCompatibleGateway(
            authorize: platformModelAuthorization,
            transport: LoopbackTransport(server.port),
          );
          server.listen((request) async {
            requests++;
            await request.drain<void>();
            request.response.headers.contentType = ContentType(
              'text',
              'event-stream',
            );
            request.response.write(
              'data: {"choices":[{"index":0,"delta":{"content":"OK"},"finish_reason":"stop"}]}\n\ndata: [DONE]\n\n',
            );
            await request.response.close();
          });
        }
      } else if (step == 5) {
        await AppleDistribution.resetModelConsent();
      } else {
        final expectAllow = step == 1 || step == 2 || step == 4;
        final origin = step == 3 || step == 4 ? 'two.example' : 'one.example';
        final before = requests;
        try {
          await gateway!.testConnection(
            profile: ModelProfile(
              product: ProviderKind.custom,
              baseUrl: 'https://$origin/v1',
              model: 'fixture',
            ),
            apiKey: 'synthetic',
          );
          if (!expectAllow) throw StateError('unexpected authorization');
        } on ModelFailure catch (failure) {
          if (expectAllow || failure.code != ModelFailureCode.cancelled) {
            rethrow;
          }
        }
        if (requests != before + (expectAllow ? 1 : 0)) {
          throw StateError('request count $requests');
        }
      }
      step++;
    } catch (error) {
      failure = error.toString();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    gateway?.close();
    server?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: failure != null || step == 8
          ? Text(failure ?? '通过 $requests')
          : TextButton(
              onPressed: busy ? null : advance,
              child: Text('验证 $step'),
            ),
    ),
  );
}
