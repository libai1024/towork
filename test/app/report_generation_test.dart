import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/agent_prompt.dart';
import 'package:towork/app/report_generation.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/report_store.dart';
import 'package:towork/data/ai/openai_compatible_gateway.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/reports/report_documents.dart';

import '../support/free/fake_model_gateway.dart';

import 'package:towork/domain/settings/model_settings_service.dart';

class _SummaryGateway implements ModelGateway {
  _SummaryGateway(this.text);
  final String text;
  int calls = 0;

  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    calls++;
    expect(request.tools, isEmpty);
    final system = request.messages.first['content']! as String;
    expect(system, contains('唯一事实'));
    expect(system, contains(AgentPrompt.responseStyle));
    expect(system, contains('最多 240 字'));
    yield ModelCompleted(
      assistantMessage: {'role': 'assistant', 'content': text},
      finishReason: 'stop',
    );
  }
}

void main() {
  late Directory dir;
  late AppDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('towork-report-gen-');
    db = AppDatabase.background(File('${dir.path}/db.sqlite'));
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test(
    'weekly bounds use Monday 00:00 in the report timezone; idempotent',
    () async {
      final settings = ModelSettingsService(
        db,
        FakeKeyVault(),
        OpenAiCompatibleGateway(),
      );
      final service = ReportGenerationService(
        db,
        settings,
        clock: () => DateTime.utc(2026, 9, 25, 3), // 周五 UTC；上海已是周五 11 点
      );
      final doc = await service.generate(
        kind: ReportPeriodKind.weekly,
        timezone: 'Asia/Shanghai',
      );
      // 2026-09-21 是周一；上海 00:00 = 前一日 16:00 UTC。
      expect(
        DateTime.fromMicrosecondsSinceEpoch(doc.startAt, isUtc: true),
        DateTime.utc(2026, 9, 20, 16),
      );
      expect(
        DateTime.fromMicrosecondsSinceEpoch(doc.endAt, isUtc: true),
        DateTime.utc(2026, 9, 27, 16),
      );
      expect(doc.kind, ReportPeriodKind.weekly);
      expect(doc.status, ReportDocumentStatus.snapshotReady);
      expect(doc.metrics.nickname, isNotEmpty);

      // 同周期重跑返回既有文档，不新建。
      final again = await service.generate(
        kind: ReportPeriodKind.weekly,
        timezone: 'Asia/Shanghai',
      );
      expect(again.id, doc.id);
      expect((await SqliteReportStore(db).list()), hasLength(1));

      // 月报：9 月 1 日上海 00:00。
      final month = await service.generate(
        kind: ReportPeriodKind.monthly,
        timezone: 'Asia/Shanghai',
      );
      expect(
        DateTime.fromMicrosecondsSinceEpoch(month.startAt, isUtc: true),
        DateTime.utc(2026, 8, 31, 16),
      );
      expect(
        DateTime.fromMicrosecondsSinceEpoch(month.endAt, isUtc: true),
        DateTime.utc(2026, 9, 30, 16),
      );
    },
  );

  test('summarize writes prose from snapshot numbers; failure marks failed and can retry', () async {
    final settings = ModelSettingsService(
      db,
      FakeKeyVault(),
      OpenAiCompatibleGateway(),
    );
    await settings.save(
      profile: ModelProfile(
        model: 'report-fixture',
        product: ProviderKind.kimiCode,
      ),
      expectedVersion: 0,
      newKey: 'synthetic-report-key',
    );
    final gateway = _SummaryGateway('进展：完成两项。\n待改进：一项逾期。\n关注：下周复盘。');
    final service = ReportGenerationService(db, settings, gateway: gateway);
    final doc = await service.generate(
      kind: ReportPeriodKind.weekly,
      timezone: 'Asia/Shanghai',
    );
    final summarized = await service.summarize(doc);
    expect(summarized.status, ReportDocumentStatus.summaryReady);
    expect(summarized.summary, contains('进展'));
    expect(gateway.calls, 1);
    // 已成功的总结不重复调用模型。
    final again = await service.summarize(summarized);
    expect(gateway.calls, 1);
    expect(again.summary, summarized.summary);
  });
}
