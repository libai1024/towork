import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/chat/local_chat.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/core/agent/agent_run_card.dart';
import 'package:towork/theme/app_theme.dart';

import '../../support/free/fake_model_gateway.dart';

/// 终态任务行的「撤销」保持 ≥44×44 触控目标（紧凑视觉不缩小命中区）。
void main() {
  testWidgets('quiet run line undo keeps a 44pt hit target', (tester) async {
    // testWidgets 的 fake async 跑不了后台 isolate，用内存库。
    final db = AppDatabase(NativeDatabase.memory());
    final settings = ModelSettingsService(
      db,
      FakeKeyVault(),
      FakeKimiGateway(),
    );
    await settings.save(
      profile: ModelProfile(model: 'fixture', product: ProviderKind.kimiCode),
      expectedVersion: 0,
      newKey: 'synthetic-key',
    );
    final now = DateTime.now();
    final profile = ModelProfile(
      model: 'fixture',
      product: ProviderKind.kimiCode,
    );
    final run = AgentRun(
      id: 'run-1',
      sessionId: 'session-1',
      inputId: 'input-1',
      profile: profile,
      history: [
        {'role': 'user', 'content': '提醒我明天交报告'},
        {'role': 'assistant', 'content': '已创建'},
      ],
      status: AgentRunStatus.succeeded,
      receipts: ['op-1'],
    );
    final runtime = LocalChatRuntime(
      db,
      settings,
      LocalChatSnapshot(
        [
          LocalConversation(
            id: 'session-1',
            title: '会话',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        [
          LocalChatTurn(
            inputId: 'input-1',
            sessionId: 'session-1',
            content: '提醒我明天交报告',
            position: 0,
            historyStart: 0,
            createdAt: now,
            agentEnabled: true,
            run: run,
          ),
        ],
      ),
      await db.readConfiguration(),
    );
    addTearDown(() async {
      await runtime.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localChatRuntimeProvider.overrideWith((ref) => runtime)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(child: AgentRunCard(runId: 'run-1')),
          ),
        ),
      ),
    );
    await tester.pump();

    // 成功终态退化为紧凑状态行，撤销是行内唯一按钮。
    expect(find.text('已提交 1 批操作'), findsOneWidget);
    final undo = find.byType(TextButton);
    expect(undo, findsOneWidget);
    final size = tester.getSize(undo);
    expect(size.height, greaterThanOrEqualTo(44), reason: '触控高度 ≥44');
    expect(size.width, greaterThanOrEqualTo(44), reason: '触控宽度 ≥44');

    // 先卸载组件树，让 ProviderScope/LiveChatViewModel 在校验前释放订阅；
    // drift 关闭流查询会挂一个零时长定时器，推进一帧让它落地。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 16));
  });
}
