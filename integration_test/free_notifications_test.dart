import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/notification_provider.dart';
import 'package:towork/app/notification_coordinator.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/core/todo/todo_checkbox.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/data/notifications/native_notification_service.dart';
import 'package:towork/domain/jobs/local_job.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/core/todo/todo_detail_sheet.dart';
import 'package:towork/main.dart';

// All permission and scheduling calls reach the real plugin. Only the OS tap
// event is injected, so navigation coverage is not a claim of banner delivery.
class _ObservedNativeNotifications extends NativeNotificationService {
  void Function(String?)? open;
  @override
  Future<void> initialize(void Function(String?) onOpen) async {
    open = onOpen;
    await super.initialize(onOpen);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('real native queue follows reminder UI and completion', (
    tester,
  ) async {
    final dir = await Directory(
      '${(await getApplicationSupportDirectory()).path}/notice-test-${DateTime.now().microsecondsSinceEpoch}',
    ).create();
    final db = AppDatabase.background(File('${dir.path}/fixture.sqlite'));
    final service = _ObservedNativeNotifications();
    ProviderContainer? container;
    final prefs = SqliteAppPreferencesStore(db);
    final initial = await prefs.loadOrCreate();
    await prefs.update({
      'notify_morning': false,
    }, expectedVersion: initial.version);
    // Isolated databases share an OS application identity. Reserve a high range
    // for this fixture and only clean up its own IDs, never cancelAll().
    await db.customStatement(
      "INSERT INTO sqlite_sequence(name, seq) VALUES ('notification_attempts', ?)",
      [1000000000 + DateTime.now().millisecondsSinceEpoch % 500000000],
    );
    await SqliteWorkspaceCommandStore(db).execute(
      WorkspaceCommand(
        operationId: 'seed',
        actions: [
          WorkspaceMutation(
            actionId: 'a',
            kind: WorkspaceEntityKind.todo,
            entityId: 'notice-todo',
            mutation: WorkspaceMutationKind.create,
            patch: {
              'title': '核验系统提醒',
              'due_at': DateTime.now()
                  .toUtc()
                  .add(const Duration(hours: 3))
                  .toIso8601String(),
              'remind_rules': [
                {'id': 'first', 'offset_minutes': 10},
              ],
            },
          ),
        ],
      ),
    );
    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    Future<void> ready(bool Function() check) async {
      final timer = Stopwatch()..start();
      while (!check() && timer.elapsed < const Duration(seconds: 10)) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(check(), isTrue);
    }

    Future<List<int>> ownPending() async => [
      for (final notice in await service.pending())
        if (notice.payload?.contains('notice-todo') == true) notice.id,
    ];
    Future<void> automaticQueue(int count) async {
      final timer = Stopwatch()..start();
      while ((await ownPending()).length != count &&
          timer.elapsed < const Duration(seconds: 10)) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(await ownPending(), hasLength(count));
    }

    try {
      container = ProviderContainer(
        overrides: [
          localDatabaseProvider.overrideWith((ref) async => db),
          notificationServiceProvider.overrideWithValue(service),
          initialAppLocationProvider.overrideWithValue(AppRoutes.todos),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
        ),
      );
      await tester.pumpAndSettle();
      await ready(
        () => container!.read(notificationCoordinatorProvider) != null,
      );
      final worker = container.read(notificationCoordinatorProvider)!;
      await worker.refresh();
      final access = await service.inspect();
      expect(access.supported, isTrue);
      expect(worker.current.error, isFalse);
      if (const bool.fromEnvironment('NOTIFICATIONS_REQUIRE_GRANTED')) {
        expect(
          access.enabled,
          isTrue,
          reason: 'Grant POST_NOTIFICATIONS before this run',
        );
      }
      final firstIds = await ownPending();
      expect(firstIds, hasLength(access.enabled ? 1 : 0));
      if (access.enabled) {
        await service.cancel(firstIds.single);
        await worker.refresh();
        final repaired = await ownPending();
        expect(repaired, hasLength(1));
        expect(repaired.single, isNot(firstIds.single));
      }
      if (!access.enabled) {
        expect(
          (await worker.jobs.list(type: NotificationCoordinator.type))
              .single
              .status,
          JobStatus.waitingPermission,
        );
      }
      await tap(find.byKey(const ValueKey('notice-todo')));
      await tap(
        find.byWidgetPredicate(
          (w) =>
              w is AppPressable &&
              (w.semanticLabel?.startsWith('提醒，') ?? false),
        ),
      );
      if (!access.enabled) {
        expect(find.text('开启系统通知'), findsOneWidget);
      }
      await tap(find.text('添加提醒'));
      await tap(find.text('前 5 分钟'));
      await ready(
        () => container!.read(todoListProvider).single.remindRules.length == 2,
      );
      await automaticQueue(access.enabled ? 2 : 0);
      await tester.scrollUntilVisible(
        find.byWidgetPredicate(
          (w) => w is TodoCheckbox && w.semanticLabel == '标记完成，核验系统提醒',
        ),
        -250,
        scrollable: find
            .descendant(
              of: find.byType(TodoDetailSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tap(
        find.byWidgetPredicate(
          (w) => w is TodoCheckbox && w.semanticLabel == '标记完成，核验系统提醒',
        ),
      );
      await ready(
        () => container!.read(todoListProvider).single.completedAt != null,
      );
      await automaticQueue(0);
      await tap(
        find.byWidgetPredicate(
          (w) => w is TodoCheckbox && w.semanticLabel == '标记未完成，核验系统提醒',
        ),
      );
      await ready(
        () => container!.read(todoListProvider).single.completedAt == null,
      );
      await automaticQueue(access.enabled ? 2 : 0);

      // Real source payload, injected response callback, real route/detail UI.
      final payload = access.enabled
          ? (await service.pending())
                .firstWhere((p) => p.payload?.contains('notice-todo') == true)
                .payload
          : '{"towork":1,"todo_id":"notice-todo"}';
      Navigator.of(tester.element(find.byType(TodoDetailSheet))).pop();
      await tester.pumpAndSettle();
      container.read(appRouterProvider).go(AppRoutes.settings);
      await tester.pumpAndSettle();
      await tap(find.text('通知与提醒设置'));
      expect(find.text('通知与提醒'), findsOneWidget);
      await tap(find.text('检查并重试'));
      expect(worker.current.error, isFalse);
      Navigator.of(tester.element(find.text('通知与提醒'))).pop();
      await tester.pumpAndSettle();
      service.open!('{"towork":1,"todo_id":42}');
      service.open!('{invalid');
      await tester.pumpAndSettle();
      expect(find.byType(TodoDetailSheet), findsNothing);
      service.open!(payload);
      await tester.pumpAndSettle();
      expect(find.byType(TodoDetailSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      debugPrint(
        'native notifications: enabled=${access.enabled}, exact=${access.exact}; queue and UI verified',
      );
    } finally {
      final worker = container?.read(notificationCoordinatorProvider);
      worker?.setActive(false);
      await worker?.refresh();
      final attempts = await db.select(db.notificationAttempts).get();
      for (final attempt in attempts) {
        await service.cancel(attempt.id);
      }
      await tester.pumpWidget(const SizedBox());
      container?.dispose();
      service.open?.call('{"towork":1,"todo_id":"notice-todo"}');
      await db.close();
      await dir.delete(recursive: true);
    }
  });
}
