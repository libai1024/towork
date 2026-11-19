import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/todo_agent_tools.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/domain/workspace/workspace_validation.dart';
import 'package:towork/core/ai/brand_logos.dart';
import 'package:towork/core/ai/model_identity.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  test('DeepSeek profile routes to the OpenAI-compatible endpoint', () {
    final profile = ModelProfile(
      model: 'deepseek-flash',
      product: ProviderKind.deepseek,
    );
    expect(
      profile.completionsUri.toString(),
      'https://api.deepseek.com/chat/completions',
    );
    expect(brandOfModel('deepseek-flash'), AiBrand.deepseek);
    expect(brandOfModel('deepseek-v4-pro'), AiBrand.deepseek);
    expect(brandOfModel('glm-4.7'), AiBrand.zhipu);
    expect(brandOfModel('kimi-for-coding'), AiBrand.kimi);
    // 自定义中转的端点拼接：根地址 + /chat/completions。
    final relay = ModelProfile(
      model: 'any-model',
      product: ProviderKind.custom,
      baseUrl: 'https://relay.example.com/v1',
    );
    expect(
      relay.completionsUri.toString(),
      'https://relay.example.com/v1/chat/completions',
    );
    expect(
      () => ModelProfile(
        model: 'x',
        product: ProviderKind.custom,
        baseUrl: 'http://insecure.example.com',
      ),
      throwsA(isA<ModelFailure>()),
    );
  });

  test('source_model rides agent todo writes through validation', () {
    final run = AgentRun(
      id: 'run_marker',
      sessionId: 'session',
      inputId: 'input_marker',
      profile: ModelProfile(
        model: 'deepseek-flash',
        product: ProviderKind.deepseek,
      ),
      history: const [
        {'role': 'user', 'content': '帮我记住'},
      ],
    );
    final proposal = TodoAgentTools.prepare(
      run,
      ModelCompleted(
        assistantMessage: {
          'role': 'assistant',
          'content': null,
          'tool_calls': [
            {
              'id': 'create_1',
              'type': 'function',
              'function': {
                'name': 'todo_create',
                'arguments': '{"title":"深海测试"}',
              },
            },
          ],
        },
        finishReason: 'tool_calls',
      ),
      WorkspaceSnapshot(const []),
      DateTime.utc(2026, 9, 25),
    );
    final call = (proposal['calls']! as List).single as Map;
    final patch = ((call['mutation']! as Map)['patch']! as Map)
        .cast<String, Object?>();
    expect(patch['source'], 'ai');
    expect(patch['source_model'], 'deepseek-flash');
    expect(patch['source_provider'], ProviderKind.deepseek.wireId);
    // 载荷可通过工作区校验（todoDefaults 接受该键）。
    expect(
      () => applyWorkspacePatch(WorkspaceEntityKind.todo, null, {
        ...patch,
        'status': 'pending',
        'title': patch['title'],
      }, DateTime.utc(2026, 9, 25)),
      returnsNormally,
    );
  });

  testWidgets('badge shows provider icon and short label; AI fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Row(children: [ModelSourceBadge(model: 'deepseek-flash')]),
        ),
      ),
    );
    expect(find.text('DS Flash'), findsOneWidget);
    expect(find.byType(BrandLogo), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(children: [ModelSourceBadge(model: 'kimi-for-coding')]),
        ),
      ),
    );
    expect(find.text('Kimi K2.8'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelSourceBadge(
            model: 'deepseek-flash',
            product: ProviderKind.custom,
          ),
        ),
      ),
    );
    expect(find.text('DS Flash'), findsOneWidget);
    expect(
      tester.widget<BrandLogo>(find.byType(BrandLogo)).brand,
      AiBrand.compatible,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Row(children: [ModelSourceBadge(model: null)]),
        ),
      ),
    );
    expect(find.text('AI'), findsOneWidget);
  });
}
