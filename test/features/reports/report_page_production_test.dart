import 'dart:io';

import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/app/providers.dart'
    show categoryListProvider, todoListProvider;
import 'package:towork/app/report_generation.dart';
import 'package:towork/app/model_transmission.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/report_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/reports/report_documents.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/features/reports/report_detail_page.dart';
import 'package:towork/features/reports/report_production.dart';
import 'package:towork/features/reports/reports_page.dart';
import 'package:towork/features/reports/widgets/production_reports_view.dart';
import 'package:towork/theme/app_theme.dart';

import '../../support/free/fake_model_gateway.dart';

/// 只在 summarize 时被调用的假网关：返回固定文本，可注入一次失败。
class _ScriptedSummaryGateway implements ModelGateway {
  _ScriptedSummaryGateway(this.text);
  final String text;
  int calls = 0;
  bool failNext = false;

  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    calls++;
    if (failNext) {
      failNext = false;
      throw const ModelFailure(ModelFailureCode.network);
    }
    yield ModelCompleted(
      assistantMessage: {'role': 'assistant', 'content': text},
      finishReason: 'stop',
    );
  }
}

class _Harness {
  _Harness({
    required this.directory,
    required this.db,
    required this.session,
    required this.settings,
    required this.service,
    required this.gateway,
  });

  final Directory directory;
  final AppDatabase db;
  final LocalWorkspaceSession session;
  final ModelSettingsService settings;
  final ReportGenerationService service;
  final _ScriptedSummaryGateway gateway;
}

/// 真库 + 真 session + 真生成服务（仅总结网关为假）。
/// 报告周期固定在 2026-09-21～09-27（Asia/Shanghai）那一周，
/// 造数时钟固定在 2026-09-22，保证待办落在周期内。
Future<_Harness> _createHarness(
  WidgetTester tester, {
  bool seedTodos = false,
}) async {
  late final _Harness harness;
  // Real IO (file creation) needs the real zone; everything the widget tree
  // will await must be created in the FakeAsync zone so its futures settle
  // under pump(). The sync NativeDatabase executor makes drift usable here.
  final directory = (await tester.runAsync(
    () => Directory.systemTemp.createTemp('towork-report-page-'),
  ))!;
  final db = AppDatabase(NativeDatabase(File('${directory.path}/db.sqlite')));
  final gateway = _ScriptedSummaryGateway('进展：完成一项。\n待改进：一项未完成。\n关注：保持节奏。');
  final settings = ModelSettingsService(
    db,
    FakeKeyVault(),
    createPlatformModelGateway(),
  );
  await settings.save(
    profile: ModelProfile(
      model: 'report-fixture',
      product: ProviderKind.kimiCode,
    ),
    expectedVersion: 0,
    newKey: 'synthetic-report-key',
  );
  final store = SqliteWorkspaceCommandStore(
    db,
    clock: () => DateTime.utc(2026, 9, 22),
  );
  if (seedTodos) {
    await store.execute(
      WorkspaceCommand(
        operationId: 'seed_reports_page',
        actions: [
          WorkspaceMutation(
            actionId: 'category',
            kind: WorkspaceEntityKind.category,
            entityId: 'catwork',
            mutation: WorkspaceMutationKind.create,
            patch: const {
              'name': '工作',
              'color_value': 0xff3366cc,
              'icon_key': 'briefcase',
            },
          ),
          // 周内创建、周内完成。
          WorkspaceMutation(
            actionId: 'done_in',
            kind: WorkspaceEntityKind.todo,
            entityId: 'done_in',
            mutation: WorkspaceMutationKind.create,
            patch: {
              'title': '周内完成',
              'category_id': 'catwork',
              'status': 'done',
              'completed_at': DateTime.utc(2026, 9, 23, 10).toIso8601String(),
            },
          ),
          // 周内创建、期末仍未完成。
          WorkspaceMutation(
            actionId: 'open_new',
            kind: WorkspaceEntityKind.todo,
            entityId: 'open_new',
            mutation: WorkspaceMutationKind.create,
            patch: const {'title': '周内未完成'},
          ),
        ],
      ),
    );
  }
  final session = LocalWorkspaceSession(store, await store.load());
  final service = ReportGenerationService(
    db,
    settings,
    gateway: gateway,
    clock: () => DateTime.utc(2026, 9, 25, 3),
  );
  harness = _Harness(
    directory: directory,
    db: db,
    session: session,
    settings: settings,
    service: service,
    gateway: gateway,
  );
  addTearDown(() async {
    await tester.runAsync(() async {
      await harness.db.close();
      await harness.directory.delete(recursive: true);
    });
  });
  return harness;
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _Harness harness, {
  String initialLocation = '/reports',
  Future<List<ReportDocument>> Function(Ref ref)? listOverride,
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/reports',
        builder: (_, _) => const ReportsPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, s) =>
                ReportDetailPage(reportId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: SizedBox()),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      localDatabaseProvider.overrideWith((ref) async => harness.db),
      modelSettingsServiceProvider.overrideWith(
        (ref) async => harness.settings,
      ),
      localWorkspaceSessionProvider.overrideWith((ref) => harness.session),
      reportGenerationProvider.overrideWith((ref) async => harness.service),
      if (listOverride != null)
        productionReportListProvider.overrideWith(listOverride),
    ],
  );
  addTearDown(container.dispose);
  // 与生产装配一致：登记两个投影的所有权。
  container.read(todoListProvider);
  container.read(categoryListProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return container;
}

Future<void> _goBackToList(WidgetTester tester) async {
  // 列表页在路由栈下方保活，也带「返回」语义；取栈顶详情页的那一个。
  await tester.tap(find.bySemanticsLabel('返回').last);
  await tester.pump();
  await tester.pumpAndSettle();
}

/// 详情页在栈顶时的定向 finder：排除列表卡片在栈下的同名文案。
Finder _inDetail(Finder finder) => find.descendant(
  of: find.byKey(const ValueKey('production-report-detail')),
  matching: finder,
);

/// 详情内容较长且列表懒加载：逐步拖动主滚动直到目标恰好可见。
/// 目标出现多个实例时（海报与正文同名文案），取最后一个。
Future<void> _scrollDetailTo(WidgetTester tester, Finder finder) async {
  final scrollable = find
      .descendant(
        of: find.byKey(const ValueKey('production-report-detail')),
        matching: find.byType(Scrollable),
      )
      .first;
  for (var i = 0; i < 40 && finder.evaluate().length != 1; i++) {
    await tester.drag(scrollable, const Offset(0, -320));
    await tester.pumpAndSettle();
  }
  if (finder.evaluate().length > 1) {
    await tester.ensureVisible(finder.last);
    await tester.pumpAndSettle();
  }
  expect(finder.evaluate(), isNotEmpty);
}

void main() {
  testWidgets('生成本周周报：空态 → 卡片 → 详情；同周期重跑幂等', (tester) async {
    final harness = await _createHarness(tester);
    final container = await _pump(tester, harness);

    // 空态保留现有风格，并给出两个生成入口。
    expect(find.text('还没有报告'), findsOneWidget);
    await tester.tap(find.byTooltip('生成报告'));
    await tester.pumpAndSettle();
    expect(find.text('生成本周周报'), findsOneWidget);
    expect(find.text('生成本月月报'), findsOneWidget);

    await tester.tap(find.text('生成本周周报'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 直接进入详情。
    expect(
      find.byKey(const ValueKey('production-report-detail')),
      findsOneWidget,
    );
    expect(find.textContaining('9月第4周'), findsWidgets);
    expect(find.textContaining('09/21–09/27'), findsWidgets);

    await _goBackToList(tester);

    // 列表出现卡片与「待总结」chip（详情页在栈下保活，断言限定列表内）。
    final listFinder = find.byKey(const ValueKey('production-report-list'));
    expect(listFinder, findsOneWidget);
    expect(
      find.descendant(
        of: listFinder,
        matching: find.text('9月第4周（09/21–09/27）'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: listFinder, matching: find.text('待总结')),
      findsOneWidget,
    );
    final firstId = container
        .read(productionReportListProvider)
        .value!
        .single
        .id;

    // 同周期重跑幂等：仍是一份，且 id 不变。
    await tester.tap(find.byTooltip('生成报告'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成本周周报'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey('production-report-detail')),
      findsOneWidget,
    );
    await _goBackToList(tester);
    final reports = container.read(productionReportListProvider).value!;
    expect(reports, hasLength(1));
    expect(reports.single.id, firstId);
  });

  testWidgets('详情大数字与比率来自快照：两条待办 → 完成率 50%（1/2）', (tester) async {
    final harness = await _createHarness(tester, seedTodos: true);
    await _pump(tester, harness);

    await tester.tap(find.byTooltip('生成报告'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成本周周报'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 首屏：完成率值 + 分子分母 + 四张大数字（断言限定详情页；列表卡片在栈下保活）。
    expect(_inDetail(find.text('50%')), findsOneWidget);
    expect(_inDetail(find.text('完成率 1/2')), findsOneWidget);
    expect(_inDetail(find.text('2')), findsOneWidget, reason: '新增');
    expect(_inDetail(find.text('1')), findsNWidgets(2), reason: '完成与期末未完成');
    expect(_inDetail(find.text('0')), findsOneWidget, reason: '逾期');
    // 下方段落需滚动到可见后再断言（懒加载）。
    await _scrollDetailTo(tester, find.text('未分类'));
    // 分类名在分类区必有；海报预览是否懒加载视滚动位置而定。
    expect(_inDetail(find.text('工作')), findsWidgets);
    expect(_inDetail(find.text('创建 1 完成 1')), findsOneWidget);
    expect(_inDetail(find.text('未分类')), findsWidgets);
    await _scrollDetailTo(tester, find.text('上期无完成率'));
    expect(_inDetail(find.text('+1 项（上期 0 项）')), findsOneWidget);
    await _scrollDetailTo(tester, find.text('数据行 共 0 条'));
    expect(_inDetail(find.text('本期新增 0 条')), findsOneWidget);
    expect(_inDetail(find.textContaining('已冻结')), findsNothing);
  });

  testWidgets('生成总结：主动触发后显示固定文本，且不重复调用模型', (tester) async {
    final harness = await _createHarness(tester, seedTodos: true);
    await _pump(tester, harness);

    await tester.tap(find.byTooltip('生成报告'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成本周周报'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // ignore: avoid_print
    await _scrollDetailTo(tester, find.text('生成总结'));
    expect(_inDetail(find.text('生成总结')), findsWidgets);
    await tester.tap(find.text('生成总结').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    final summary = find.byKey(const ValueKey('report-summary'));
    await _scrollDetailTo(tester, summary);
    expect(tester.widget<Text>(summary).data, contains('进展：完成一项'));
    expect(_inDetail(find.text('生成总结')), findsNothing);
    expect(harness.gateway.calls, 1);

    await _goBackToList(tester);
    final listFinder = find.byKey(const ValueKey('production-report-list'));
    expect(
      find.descendant(of: listFinder, matching: find.text('已总结')),
      findsOneWidget,
    );
  });

  testWidgets('总结失败：toast 提示并给出重试入口，重试后成功', (tester) async {
    final harness = await _createHarness(tester, seedTodos: true);
    harness.gateway.failNext = true;
    await _pump(tester, harness);

    await tester.tap(find.byTooltip('生成报告'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成本周周报'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await _scrollDetailTo(tester, find.text('生成总结'));
    await tester.tap(find.text('生成总结').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 失败提示 + 重试按钮（文档已标 failed）。
    expect(find.text('总结生成失败，可重试'), findsOneWidget);
    expect(_inDetail(find.text('重试总结')), findsOneWidget);
    expect(_inDetail(find.textContaining('总结生成失败，快照已保留')), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('重试总结'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    final summary = find.byKey(const ValueKey('report-summary'));
    await _scrollDetailTo(tester, summary);
    expect(tester.widget<Text>(summary).data, contains('进展：完成一项'));
    expect(harness.gateway.calls, 2);
  });

  testWidgets('演示模式回归：无本地工作区时仍是原演示列表', (tester) async {
    final router = GoRouter(
      initialLocation: '/reports',
      routes: [
        GoRoute(
          path: '/reports',
          builder: (_, _) => const ReportsPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, s) =>
                  ReportDetailPage(reportId: s.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 演示种子照常渲染，生产视图与生产入口不出现。
    expect(find.text('稳步前进的一周'), findsOneWidget);
    expect(find.byType(ProductionReportsView), findsNothing);
    expect(find.text('生成本周周报'), findsNothing);
    expect(find.byKey(const ValueKey('production-report-list')), findsNothing);
  });

  testWidgets('列表读取失败：错误态带重试，重试成功后恢复列表', (tester) async {
    final harness = await _createHarness(tester);
    final doc = await harness.service.generate(
      kind: ReportPeriodKind.weekly,
      timezone: kProductionReportTimezone,
    );
    var failNext = true;
    await _pump(
      tester,
      harness,
      listOverride: (ref) async {
        if (failNext) {
          failNext = false;
          throw Exception('模拟读取失败');
        }
        final stored = await SqliteReportStore(harness.db).read(doc.id);
        return [?stored];
      },
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 明确错误态（区别于空态），已有数据不受影响的文案 + 重试入口。
    expect(find.text('报告读取失败'), findsOneWidget);
    expect(find.text('还没有报告'), findsNothing);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('报告读取失败'), findsNothing);
    expect(find.textContaining('9月第4周'), findsWidgets);
  });

  testWidgets('详情读取失败：区别于不存在，可重试到正文', (tester) async {
    final harness = await _createHarness(tester);
    final doc = await harness.service.generate(
      kind: ReportPeriodKind.weekly,
      timezone: kProductionReportTimezone,
    );
    var failNext = true;
    await _pump(
      tester,
      harness,
      initialLocation: '/reports/${doc.id}',
      listOverride: (ref) async {
        if (failNext) {
          failNext = false;
          throw Exception('模拟读取失败');
        }
        final stored = await SqliteReportStore(harness.db).read(doc.id);
        return [?stored];
      },
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 读取失败 ≠ 报告不存在：文案可区分，动作是重试而非返回列表。
    expect(find.text('报告读取失败'), findsOneWidget);
    expect(find.text('找不到这份报告'), findsNothing);
    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('production-report-detail')),
      findsOneWidget,
    );
    expect(find.text('报告读取失败'), findsNothing);
  });

  testWidgets('详情报告不存在：提示返回列表，不误报读取失败', (tester) async {
    final harness = await _createHarness(tester);
    await _pump(tester, harness, initialLocation: '/reports/r_missing');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('找不到这份报告'), findsOneWidget);
    expect(find.text('报告读取失败'), findsNothing);
    expect(find.text('返回列表'), findsOneWidget);
  });
}
