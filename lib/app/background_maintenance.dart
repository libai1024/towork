import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import 'local_maintenance.dart';
import '../data/local/app_database.dart';
import '../data/notifications/native_notification_service.dart';

const maintenanceTask = 'towork.local-maintenance.v1';

enum MaintenanceRegistration { foregroundOnly, scheduled, failed }

Future<MaintenanceRegistration> registerBackgroundMaintenance() async {
  if (!Platform.isAndroid) return MaintenanceRegistration.foregroundOnly;
  try {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      maintenanceTask,
      maintenanceTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      tag: maintenanceTask,
    );
    return await Workmanager().isScheduledByUniqueName(maintenanceTask)
        ? MaintenanceRegistration.scheduled
        : MaintenanceRegistration.failed;
  } catch (_) {
    return MaintenanceRegistration.failed;
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  var stopped = false;
  Workmanager().executeTask(
    (task, input) async {
      if (task != maintenanceTask) return true;
      stopped = false;
      AppDatabase? db;
      try {
        final dir = await getApplicationSupportDirectory();
        final file = File('${dir.path}/towork-free.sqlite');
        // Background wakeups must not create a replacement empty workspace after
        // data removal or first-install setup. Input cannot redirect this path.
        if (!await file.exists()) return true;
        db = AppDatabase.background(file);
        await runLocalMaintenance(
          db,
          NativeNotificationService(background: true),
          stopped: () => stopped,
        );
        // Our durable queue owns finite retries. Let the next periodic wakeup
        // inspect it rather than adding a second, unbounded OS retry loop.
        return true;
      } catch (_) {
        return true;
      } finally {
        await db?.close();
      }
    },
    onTaskStopped: (_, _) async {
      stopped = true;
    },
  );
}
