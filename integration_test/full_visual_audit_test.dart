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
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/main.dart';

import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/ai/quota.dart';
import 'package:towork/domain/settings/model_account_service.dart';
import 'package:towork/domain/settings/model_settings_service.dart';

import '../test/support/free/fake_model_gateway.dart';

/// 全量视觉巡检：明/暗两主题 × 全部主要页面，截图经 capture.dart 落盘，
/// 供视觉验收代理逐页判定。生产装配（真实隔离 SQLite），种子数据为合成。
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final captureKey = GlobalKey();
  final shots = <String, String>{};

  testWidgets('all primary pages render in both themes with seeded data', (
    tester,
  ) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!Platform.isAndroid) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      await binding.setSurfaceSize(const Size(1280, 900));
    }
    binding.reportData = {'screenshots': shots};
    // 隔离资料库：绝不触碰用户生产库；其余全部走生产装配。
    final support = await getApplicationSupportDirectory();
    final auditDir = await Directory(
      '${support.path}/visual-audit-${DateTime.now().microsecondsSinceEpoch}',
    ).create(recursive: true);
    final auditDbFile = File('${auditDir.path}/audit.sqlite');
    const modelActions = bool.fromEnvironment('MODEL_ACTIONS_PREVIEW');
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: ProviderScope(
          overrides: [
            if (modelActions)
              modelAccountServiceProvider.overrideWith((ref) async {
                final store = FakeKimiConfigurationStore();
                return ModelAccountService(
                  ModelSettingsService(
                    store,
                    FakeKeyVault(),
                    FakeKimiGateway(),
                  ),
                  store,
                );
              }),
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
    // 合成种子：让每页都有内容可看（类别、待办若干状态、业务表+行）。
    final category = WorkspaceMutation(
      actionId: 'cat_work',
      kind: WorkspaceEntityKind.category,
      entityId: 'cat_work',
      mutation: WorkspaceMutationKind.create,
      patch: const {
        'name': '工作',
        'color_value': 0xff3366cc,
        'icon_key': 'briefcase',
      },
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

    // eslint-disable-next-line
    assert(
      seedReceipt.affected.any(
        (e) =>
            e.kind == WorkspaceEntityKind.dataTable && e.id == 'table_ledger',
      ),
      '种子表未落库',
    );
    final router = container.read(appRouterProvider);
    final routes = <(String, String)>[
      ('home', AppRoutes.home),
      ('todos', AppRoutes.todos),
      ('category', AppRoutes.todosForCategory('cat_work')),
      ('categories', AppRoutes.categories),
      ('data', AppRoutes.dataTables),
      ('data-detail', AppRoutes.dataTable('table_ledger')),
      ('schedule', AppRoutes.visualization),
      ('reports', AppRoutes.reports),
      ('memory', AppRoutes.memory),
      ('settings', AppRoutes.settings),
      ('settings-models', AppRoutes.modelAccounts),
      ('settings-model-editor', AppRoutes.modelAccountNew),
      ('settings-profile', AppRoutes.localProfile),
      ('settings-appearance', AppRoutes.appearance),
      ('settings-assistant', AppRoutes.assistantPreferences),
      ('settings-quick-assist', AppRoutes.quickAssist),
      if (Platform.isAndroid) ('settings-update', AppRoutes.update),
    ];
    const onlyPage = String.fromEnvironment('WALKTHROUGH_PAGE');
    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      container.read(themeModeProvider.notifier).state = theme;
      for (final (name, path) in routes) {
        if (onlyPage.isNotEmpty && onlyPage != name) continue;
        if (onlyPage.isNotEmpty) {
          router.go(AppRoutes.home);
          await tester.pumpAndSettle();
        }
        router.go(path);
        await tester.pump();
        // 投影经 store.watch 异步刷新；两段等待保证落库后页面已重建。
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason:
              '${Platform.isAndroid ? 'android' : 'desktop'} $name ${theme.name}',
        );
        Future<void> capture(String scene) async {
          final boundary =
              captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final filename =
              'audit-${Platform.isAndroid ? 'android' : 'desktop'}-$scene-${theme.name}';
          final png = bytes!.buffer.asUint8List();
          shots[filename] = base64Encode(png);
          if (const bool.fromEnvironment('DEVICE_SCREENSHOTS')) {
            await File('${auditDir.path}/$filename.png').writeAsBytes(png);
          }
          image.dispose();
        }

        await capture(name);
        if (name == 'settings-model-editor') {
          await tester.tap(find.byKey(const ValueKey('choose-account-model')));
          await tester.pumpAndSettle();
          await capture('settings-model-presets');
          await tester.tap(find.text('自定义模型').last);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('provider-field')));
          await tester.pumpAndSettle();
          await capture('settings-provider-menu');
          await tester.tap(find.byKey(const ValueKey('provider-custom')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('custom-base-url-input')),
            findsOneWidget,
          );
          await capture('settings-custom-api');
          if (modelActions) {
            await tester.enterText(
              find.byKey(const ValueKey('custom-base-url-input')),
              'https://example.com/v1',
            );
            await tester.enterText(
              find.byKey(const ValueKey('model-key-input')),
              'preview-only',
            );
            FocusManager.instance.primaryFocus?.unfocus();
            await tester.pumpAndSettle();
            await tester.tap(find.byTooltip('获取模型列表'));
            await tester.pumpAndSettle();
            await capture('model-directory');
            await tester.tap(find.text('second-model'));
            await tester.pumpAndSettle();
            final sheet = find.byKey(const ValueKey('model-account-sheet'));
            final beforeTest = tester.getRect(sheet);
            await tester.tap(find.byTooltip('测试连接'));
            await tester.pumpAndSettle();
            final result = find.textContaining('连接成功');
            expect(find.descendant(of: sheet, matching: result), findsNothing);
            expect(
              tester.getCenter(result),
              tester.getCenter(find.byKey(captureKey)),
            );
            expect(tester.getRect(sheet), beforeTest);
            await capture('model-actions');
            await tester.tap(find.byTooltip('保存'));
            await tester.pumpAndSettle();
            expect(sheet, findsNothing);
            final accounts = await container.read(
              modelAccountServiceProvider.future,
            );
            final saved = (await accounts.load()).active!;
            await tester.tap(find.byKey(ValueKey('account-${saved.id}')));
            await tester.pumpAndSettle();
            expect(find.text('编辑模型账户'), findsOneWidget);
            await capture('edit-model-sheet');
            await tester.tap(
              find.byKey(const ValueKey('custom-base-url-input')),
            );
            await tester.pump(const Duration(milliseconds: 500));
            await tester.pumpAndSettle();
            await capture('edit-model-keyboard');
            FocusManager.instance.primaryFocus?.unfocus();
            await tester.pumpAndSettle();
            if (Platform.isAndroid) {
              final fixture = await accounts.save(
                profile: ModelProfile(
                  product: ProviderKind.zhipuCoding,
                  model: 'glm-5.3-flash',
                ),
                newKey: 'preview-only',
                activate: true,
              );
              await accounts.store.recordQuota(
                fixture.active!.id,
                QuotaSnapshot(
                  fetchedAt: DateTime.now().toUtc(),
                  windows: const [
                    QuotaWindow(label: '每周', usedRatio: .41),
                    QuotaWindow(label: '5 小时', usedRatio: .20),
                    QuotaWindow(label: '每月', usedRatio: .15),
                  ],
                ),
              );
              router.go(AppRoutes.home);
              await tester.pumpAndSettle();
              expect(find.text('GLM-5.3 Flash').hitTestable(), findsOneWidget);
              await capture('model-name');
              await tester.tap(find.byTooltip('打开菜单'));
              await tester.pumpAndSettle();
              expect(find.text('GLM Coding'), findsOneWidget);
              for (final period in ['5h', '周限', '月限']) {
                expect(find.text(period).hitTestable(), findsOneWidget);
              }
              await capture('drawer-quotas');
              await tester.tap(find.text('GLM Coding'));
              await tester.pumpAndSettle();
            }
          }
        }
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
    mutation: mutation,
    patch: patch,
  );
}
