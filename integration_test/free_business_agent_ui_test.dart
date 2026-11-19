import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/notification_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/app/chat/chat_view_model.dart';
import 'package:towork/main.dart';

import '../test/support/free/fake_model_gateway.dart';
import '../test/support/free/fake_notifications.dart';
import '../test/support/free/business_agent_fixture.dart';
import '../test/support/free/scripted_business_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native business Agent discovers rows, auto-edits, confirms deletion, reopens and undoes both batches',
    (tester) async {
      final support = await getApplicationSupportDirectory();
      final directory = await Directory(
        '${support.path}/business-agent-ui-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${directory.path}/chat.sqlite');
      final vault = FakeKeyVault();
      final model = ScriptedBusinessModel();
      AppDatabase? db;
      ProviderContainer? container;
      Future<void> until(bool Function() condition) async {
        final watch = Stopwatch()..start();
        while (!condition() && watch.elapsed < const Duration(seconds: 15)) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(
          condition(),
          isTrue,
          reason:
              'Expected durable query/approval state; requests=${model.requests.length}',
        );
        await tester.pumpAndSettle();
      }

      AgentRun latest() => container!
          .read(localChatRuntimeProvider)!
          .projection
          .data
          .turns
          .single
          .run;
      Future<void> open({bool initial = false}) async {
        final current = AppDatabase.background(file);
        db = current;
        final settings = ModelSettingsService(current, vault, model);
        if (initial) {
          await settings.save(
            profile: ModelProfile(
              model: 'native-test',
              product: ProviderKind.kimiCode,
            ),
            expectedVersion: 0,
            newKey: 'synthetic-native-query',
          );
          final prefs = SqliteAppPreferencesStore(current);
          final old = await prefs.loadOrCreate();
          await prefs.update({
            'permission': 'askOnChange',
            'input_mode': 'keyboard',
          }, expectedVersion: old.version);
          await SqliteWorkspaceCommandStore(current)
              .execute(businessAgentFixture());
        }
        container = ProviderContainer(
          overrides: [
            localDatabaseProvider.overrideWith((ref) async => current),
            modelSettingsServiceProvider.overrideWith((ref) async => settings),
            notificationServiceProvider.overrideWith(
              (ref) => FakeNotifications(),
            ),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container!,
            child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
          ),
        );
        await until(() => container!.read(localChatRuntimeProvider) != null);
      }

      Future<void> close() async {
        AppToast.dismiss();
        await tester.pumpWidget(const SizedBox());
        container?.dispose();
        container = null;
        await db?.close();
        db = null;
      }

      DataTableStore data() => container!.read(dataTableProvider.notifier);
      Future<void> selectSession(String title) async {
        final menu = find.byTooltip('打开菜单');
        if (menu.evaluate().isNotEmpty) {
          await tester.tap(menu);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(title).first);
        await tester.pumpAndSettle();
      }

      try {
        await open(initial: true);
        final input = find.byKey(const ValueKey('chat-text-input'));
        await tester.tap(input);
        await tester.enterText(input, '把项目甲金额改成9.5元，新增项目0.1元，删除待删除项目');
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await until(
          () =>
              !container!.read(chatViewModelProvider).isGenerating &&
              container!
                  .read(localChatRuntimeProvider)!
                  .projection
                  .data
                  .turns
                  .isNotEmpty &&
              latest().status == AgentRunStatus.awaitingConfirmation &&
              data().rowsOf('ledger').length == 3,
        );
        expect(model.requests, hasLength(4));
        expect(latest().receipts, hasLength(1));
        expect(
          data()
              .rowsOf('ledger')
              .singleWhere((r) => r.id == 'keep')
              .values['金额'],
          '9.50',
        );
        expect(
          data()
              .rowsOf('ledger')
              .singleWhere((r) => r.id == 'keep')
              .values['备注'],
          businessLongNote,
        );
        expect(find.text('删除 项目账本'), findsOneWidget);
        expect(find.textContaining('项目：待删除项目 →'), findsOneWidget);
        expect(
          (latest().proposal!['calls']! as List).single['name'],
          'data_row_delete',
        );
        final sessionTitle = container!.read(sessionListProvider).single.title;
        // Pending deletion and the already committed create/edit survive restart.
        await close();
        await open();
        await selectSession(sessionTitle);
        expect(latest().status, AgentRunStatus.awaitingConfirmation);
        expect(data().rowsOf('ledger'), hasLength(3));
        final accept = find.text('全部接受').last;
        await tester.ensureVisible(accept);
        await tester.tap(accept);
        await until(
          () =>
              latest().status == AgentRunStatus.succeeded &&
              data().rowsOf('ledger').length == 2,
        );
        expect(latest().receipts, hasLength(2));
        expect(model.requests, hasLength(5));
        // Navigate the actual table page to see committed Agent writes.
        container!.read(appRouterProvider).go(AppRoutes.dataTables);
        await tester.pumpAndSettle();
        await tester.tap(find.text('项目账本').first);
        await tester.pumpAndSettle();
        expect(find.text('2 行'), findsOneWidget);
        expect(find.text('新增项目'), findsWidgets);
        expect(find.text('待删除项目'), findsNothing);
        await close();
        await open();
        await selectSession(sessionTitle);
        expect(find.text('已更新项目甲金额、新增项目，并删除指定记录。'), findsOneWidget);
        final undo = find.text('撤销').last;
        await tester.ensureVisible(undo);
        await tester.tap(undo);
        await until(
          () =>
              find.text('已撤销本次修改').evaluate().isNotEmpty &&
              data().rowsOf('ledger').any((r) => r.id == 'remove'),
        );
        expect(data().rowsOf('ledger').map((r) => r.id).toSet(), {
          'keep',
          'remove',
        });
        expect(
          data()
              .rowsOf('ledger')
              .singleWhere((r) => r.id == 'keep')
              .values['金额'],
          '12345678901234567890.10',
        );
        await close();
        await open();
        await selectSession(sessionTitle);
        expect(find.text('已撤销本次修改'), findsOneWidget);
        expect(data().rowsOf('ledger').map((r) => r.id).toSet(), {
          'keep',
          'remove',
        });
        expect(model.requests, hasLength(5));
        expect(tester.takeException(), isNull);
      } finally {
        await close();
        await directory.delete(recursive: true);
      }
    },
  );
}
