import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/report_generation.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/domain/reports/report_documents.dart';
import 'package:towork/main.dart';

/// UI 审阅补充截图：浮窗（每日总览）、新建待办、工作区搜索、待办详情、
/// 行详情、周报详情与设置子页。生产装配（真实隔离 SQLite），种子为合成。
/// 与 full_visual_audit_test.dart 互补；输出 review-{platform}-{page}-{theme}.png。
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final captureKey = GlobalKey();
  final shots = <String, String>{};

  testWidgets('floating surfaces, sub-pages and details in both themes', (
    tester,
  ) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!Platform.isAndroid) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      await binding.setSurfaceSize(const Size(1280, 900));
    }
    binding.reportData = {'screenshots': shots};
    final support = await getApplicationSupportDirectory();
    final auditDir = await Directory(
      '${support.path}/visual-audit-${DateTime.now().microsecondsSinceEpoch}',
    ).create(recursive: true);
    final auditDbFile = File('${auditDir.path}/audit.sqlite');
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: ProviderScope(
          overrides: [
            localDatabaseProvider.overrideWith((ref) async {
              final db = AppDatabase.background(auditDbFile);
              ref.onDispose(db.close);
              return db;
            }),
          ],
          child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ToWorkApp)),
    );
    final db = await container.read(localDatabaseProvider.future);
    final store = SqliteWorkspaceCommandStore(db);
    final category = WorkspaceMutation(
      actionId: 'cat_work',
      kind: WorkspaceEntityKind.category,
      entityId: 'cat_work',
      mutation: WorkspaceMutationKind.create,
      patch: {'name': '工作', 'color_value': 0xff3366cc, 'icon_key': 'briefcase'},
    );
    TodoMutation title(
      String id,
      String text, {
      String status = 'pending',
      String? category,
      String? due,
    }) => TodoMutation(
      actionId: id,
      kind: WorkspaceEntityKind.todo,
      entityId: id,
      mutation: WorkspaceMutationKind.create,
      patch: {
        'title': text,
        'status': status,
        'category_id': ?category,
        'due_at': ?due,
      },
    );
    final seedReceipt = await store.execute(
      WorkspaceCommand(
        operationId: 'audit_seed_1',
        actions: [
          category,
          title('todo_done', '完成周报整理', status: 'done', category: 'cat_work')(),
          title('todo_open', '准备 DeepSeek 接入测试', category: 'cat_work')(),
          title(
            'todo_overdue',
            '报销单提交',
            category: 'cat_work',
            due: DateTime.utc(2026, 9, 20, 2).toIso8601String(),
          )(),
          WorkspaceMutation(
            actionId: 'table_ledger',
            kind: WorkspaceEntityKind.dataTable,
            entityId: 'table_ledger',
            mutation: WorkspaceMutationKind.create,
            patch: {
              'name': '项目账本',
              'fields': [
                {
                  'id': 'f_title',
                  'name': '名称',
                  'type': 'text',
                  'required': true,
                  'options': <Object?>[],
                },
                {
                  'id': 'f_amount',
                  'name': '金额',
                  'type': 'money',
                  'required': false,
                  'scale': 2,
                  'options': <Object?>[],
                },
                {
                  'id': 'f_stage',
                  'name': '状态',
                  'type': 'selection',
                  'required': false,
                  'options': ['进行中', '已完成'],
                },
              ],
            },
          ),
          WorkspaceMutation(
            actionId: 'row_r1',
            kind: WorkspaceEntityKind.dataRow,
            entityId: 'row_r1',
            mutation: WorkspaceMutationKind.create,
            patch: {
              'table_id': 'table_ledger',
              'values': {
                'f_title': '视觉巡检预算',
                'f_amount': '1280.00',
                'f_stage': '进行中',
              },
            },
          ),
        ],
      ),
    );
    assert(
      seedReceipt.affected.any(
        (e) =>
            e.kind == WorkspaceEntityKind.dataTable && e.id == 'table_ledger',
      ),
      '种子表未落库',
    );
    final reportService = await container.read(reportGenerationProvider.future);
    final report = reportService == null
        ? null
        : await reportService.generate(
            kind: ReportPeriodKind.weekly,
            timezone: 'Asia/Shanghai',
          );
    final router = container.read(appRouterProvider);

    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
    }

    Future<void> snap(String name) async {
      await settle();
      debugPrint(
        'review-capture: snap $name '
        '${container.read(themeModeProvider).name}',
      );
      expect(
        tester.takeException(),
        isNull,
        reason:
            '${Platform.isAndroid ? 'android' : 'desktop'} $name '
            '${container.read(themeModeProvider).name}',
      );
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      shots['review-${Platform.isAndroid ? 'android' : 'desktop'}-$name-'
          '${container.read(themeModeProvider).name}'] = base64Encode(
        bytes!.buffer.asUint8List(),
      );
      image.dispose();
    }

    Future<void> dismissSheet(Finder content) async {
      expect(content, findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle();
      expect(content, findsNothing);
    }

    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      container.read(themeModeProvider.notifier).state = theme;
      await settle();

      // 1) 首页 + 每日总览浮窗
      router.go(AppRoutes.home);
      await settle();
      await tester.tap(find.byTooltip('打开今日总览').hitTestable());
      await settle();
      final collapse = find.byTooltip('收起今日总览').hitTestable();
      expect(collapse, findsOneWidget);
      await snap('home-overview');

      await tester.tap(find.byTooltip('新建待办').hitTestable());
      await settle();
      final captureInput = find.byKey(const ValueKey('todo-create-title'));
      expect(captureInput, findsOneWidget);
      await snap('todo-create');
      await tester.enterText(captureInput, '整理周会纪要');
      await tester.enterText(
        find.byKey(const ValueKey('todo-create-note')),
        '汇总预算与负责人',
      );
      await settle();
      final priority = find.byTooltip('优先级');
      await tester.ensureVisible(priority);
      await tester.tap(priority);
      await settle();
      await tester.tap(find.text('紧急').hitTestable().last);
      await settle();
      await tester.ensureVisible(find.byTooltip('截止日期'));
      await tester.tap(find.byTooltip('截止日期').hitTestable());
      await settle();
      await snap('todo-create-dates');
      await tester.tap(find.text('明天').hitTestable().last);
      await settle();
      expect(find.text('明天 09:00'), findsOneWidget);
      await snap('todo-create-draft');
      await dismissSheet(captureInput);
      await tester.tap(collapse);
      await settle();

      await tester.tap(find.byTooltip('搜索会话和待办').hitTestable());
      await settle();
      final searchClose = find.byKey(const ValueKey('workspace-search-close'));
      expect(searchClose.hitTestable(), findsOneWidget);
      await snap('workspace-search');
      await tester.tap(searchClose);
      await settle();
      expect(searchClose, findsNothing);

      router.go(AppRoutes.visualization);
      await settle();
      await tester.tap(find.byTooltip('切换日程视图'));
      await snap('schedule-menu');
      await tester.tap(find.text('趋势').last);
      await settle();
      await tester.tap(find.byTooltip('切换日程视图'));
      await settle();
      await tester.tap(find.text('回到今天'));
      await settle();

      router.go(AppRoutes.reports);
      await settle();
      await tester.tap(find.byTooltip('生成报告'));
      await snap('report-menu');
      await tester.binding.handlePopRoute();
      await settle();

      // 4) 待办详情 Sheet
      router.go(AppRoutes.todos);
      await settle();
      await tester.tap(find.text('准备 DeepSeek 接入测试'));
      await settle();
      await snap('todo-detail');
      await tester.binding.handlePopRoute();
      await settle();

      // 5) 行详情
      router.go(AppRoutes.dataRow('table_ledger', 'row_r1'));
      await snap('row-detail');

      // 6) 周报详情
      if (report != null) {
        router.go(AppRoutes.report(report.id));
        await snap('report-weekly');
      }

      // 7) 设置子页
      router.go(AppRoutes.localProfile);
      await snap('settings-profile');
      if (Platform.isAndroid && theme == ThemeMode.light) {
        final field = find.byKey(const ValueKey('local-nickname-input'));
        await tester.tap(field);
        await tester.enterText(field, '工作账户');
        await snap('profile-editing');
        expect(find.byTooltip('保存用户名').hitTestable(), findsOneWidget);
        FocusManager.instance.primaryFocus?.unfocus();
        await settle();
      }
      router.go(AppRoutes.modelAccounts);
      await snap('settings-models');
      router.go(AppRoutes.appearance);
      await snap('settings-appearance');
      router.go(AppRoutes.settings);
      await settle();

      // 8) 移动端抽屉（仅 Android；桌面侧栏展开态已在 home 截图中体现）
      if (Platform.isAndroid) {
        router.go(AppRoutes.home);
        await settle();
        final menu = find.byIcon(LucideIcons.menu);
        expect(menu, findsOneWidget);
        await tester.tap(menu.first);
        await settle();
        await snap('home-drawer');
        final dismiss = find.byKey(const ValueKey('mobile-sidebar-dismiss'));
        await tester.tapAt(tester.getTopLeft(dismiss) + const Offset(12, 100));
        await settle();
        expect(dismiss, findsNothing);
      }
    }
  });
}

/// 种子待办用的小结构体，避免在 actions 列表里重复字面量。
class TodoMutation {
  TodoMutation({
    required this.actionId,
    required this.kind,
    required this.entityId,
    required this.mutation,
    required this.patch,
  });
  final String actionId;
  final WorkspaceEntityKind kind;
  final String entityId;
  final WorkspaceMutationKind mutation;
  final Map<String, Object?> patch;

  WorkspaceMutation call() => WorkspaceMutation(
    actionId: actionId,
    kind: kind,
    entityId: entityId,
    mutation: WorkspaceMutationKind.create,
    patch: patch,
  );
}
