import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/jobs/local_job_store.dart';
import '../data/notifications/native_notification_service.dart';
import '../domain/notifications/notification_service.dart';
import '../domain/workspace/workspace_commands.dart';
import 'local_database_provider.dart';
import 'local_workspace_session.dart';
import 'notification_coordinator.dart';
import 'navigation_requests.dart';
import 'routes.dart';
import 'workspace_clock.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NativeNotificationService(),
);
final notificationCoordinatorProvider = Provider<NotificationCoordinator?>((
  ref,
) {
  if (ref.watch(localWorkspaceSessionProvider) == null) return null;
  final db = ref.watch(localDatabaseProvider).valueOrNull;
  if (db == null) return null;
  final clock = ref.watch(workspaceNowProvider);
  var disposed = false;
  final coordinator = NotificationCoordinator(
    LocalJobStore(db, clock: clock),
    ref.watch(notificationServiceProvider),
    clock: clock,
    onOpen: (raw) {
      if (disposed) return;
      try {
        final payload = jsonDecode(raw ?? '') as Map;
        if (payload['towork'] != 1) return;
        final id = payload['todo_id'];
        if (id != null && (id is! String || id.isEmpty || id.length > 200)) {
          return;
        }
        ref
            .read(appNavigationRequestsProvider)
            .go(
              Uri(
                path: AppRoutes.todos,
                queryParameters: {
                  if (id != null) 'notificationTodo': id as String,
                  if (id == null && payload['kind'] == 'morning')
                    'notificationKind': 'morning',
                  'notice': newWorkspaceId('open'),
                },
              ).toString(),
            );
      } on FormatException {
        /* Ignore unrelated or malformed OS payloads. */
      } on TypeError {
        /* A notification payload is not trusted navigation. */
      }
    },
  );
  final lifecycle = _NotificationLifecycle(coordinator);
  ref.onDispose(() {
    disposed = true;
    lifecycle.dispose();
    coordinator.dispose();
  });
  return coordinator;
});

class _NotificationLifecycle with WidgetsBindingObserver {
  _NotificationLifecycle(this.coordinator) {
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null) didChangeAppLifecycleState(state);
  }
  final NotificationCoordinator coordinator;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      coordinator.setActive(
        state == AppLifecycleState.resumed ||
            state == AppLifecycleState.inactive,
      );
  void dispose() => WidgetsBinding.instance.removeObserver(this);
}
