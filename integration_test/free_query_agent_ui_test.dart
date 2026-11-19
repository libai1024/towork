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
import '../test/support/free/query_fixture.dart';
import '../test/support/free/scripted_query_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native chat finds category, filters duplicate titles, reads full note and confirms only the target',
    (tester) async {
      final support = await getApplicationSupportDirectory();
      final directory = await Directory(
        '${support.path}/query-ui-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${directory.path}/chat.sqlite');
      final vault = FakeKeyVault();
      final model = ScriptedQueryModel();
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
            'permission': 'askAll',
            'input_mode': 'keyboard',
          }, expectedVersion: old.version);
          await SqliteWorkspaceCommandStore(current).execute(queryFixture());
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
        await tester.pumpWidget(const SizedBox());
        container?.dispose();
        container = null;
        await db?.close();
        db = null;
      }

      try {
        await open(initial: true);
        final input = find.byKey(const ValueKey('chat-text-input'));
        await tester.tap(input);
        await tester.enterText(input, '核对工作分类里9月24日高优先级且带周会标签的待办备注，然后完成');
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
              latest().status == AgentRunStatus.awaitingConfirmation,
        );
        expect(model.requests, hasLength(5));
        expect(model.note.toString(), queryNote);
        expect(latest().receipts, isEmpty);
        expect(
          container!
              .read(todoListProvider)
              .every((t) => t.status.name == 'pending'),
          isTrue,
        );
        expect(
          (latest().proposal!['calls']! as List).single['name'],
          'todo_complete',
        );
        final accept = find.text('全部接受').last;
        await tester.ensureVisible(accept);
        await tester.tap(accept);
        await until(
          () =>
              latest().status == AgentRunStatus.succeeded &&
              container!
                  .read(todoListProvider)
                  .any((t) => t.status.name == 'done'),
        );
        expect(latest().receipts, hasLength(1));
        expect(model.requests, hasLength(6));
        expect(
          container!
              .read(todoListProvider)
              .singleWhere((t) => t.id == 'target')
              .status
              .name,
          'done',
        );
        expect(
          container!
              .read(todoListProvider)
              .singleWhere((t) => t.id == 'same-title')
              .status
              .name,
          'pending',
        );
        final sessionTitle = container!.read(sessionListProvider).single.title;
        await close();
        await open();
        final menu = find.byTooltip('打开菜单');
        if (menu.evaluate().isNotEmpty) {
          await tester.tap(menu);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(sessionTitle).first);
        await tester.pumpAndSettle();
        expect(find.text('已核对完整备注，并完成筛选出的待办。'), findsOneWidget);
        expect(latest().receipts, hasLength(1));
        expect(model.requests, hasLength(6));
        expect(
          container!
              .read(todoListProvider)
              .singleWhere((t) => t.id == 'target')
              .status
              .name,
          'done',
        );
        expect(
          container!
              .read(todoListProvider)
              .singleWhere((t) => t.id == 'same-title')
              .status
              .name,
          'pending',
        );
      } finally {
        await close();
        await directory.delete(recursive: true);
      }
    },
  );
}
