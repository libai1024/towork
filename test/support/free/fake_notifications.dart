import 'package:towork/domain/notifications/notification_service.dart';

class FakeNotifications implements NotificationService {
  NotificationAccess access = const NotificationAccess(
    enabled: true,
    exact: false,
  );
  final notices =
      <
        int,
        ({DateTime at, String title, String body, String payload, bool exact})
      >{};
  final cancelled = <int>[];
  int schedules = 0, permissionRequests = 0;
  bool failAfterSchedule = false;
  Future<void> Function()? beforeSchedule;
  void Function(String?)? onOpen;
  @override
  Future<void> initialize(void Function(String?) callback) async {
    onOpen = callback;
  }

  @override
  Future<NotificationAccess> inspect() async => access;
  @override
  Future<void> requestPermission() async {
    permissionRequests++;
    access = NotificationAccess(enabled: true, exact: access.exact);
  }

  @override
  Future<void> requestExactPermission() async {
    access = NotificationAccess(enabled: access.enabled, exact: true);
  }

  @override
  Future<void> openSettings() async {}
  @override
  Future<List<PendingNotice>> pending() async => [
    for (final e in notices.entries) PendingNotice(e.key, e.value.payload),
  ];
  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    notices.remove(id);
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required bool exact,
  }) async {
    schedules++;
    await beforeSchedule?.call();
    notices[id] = (
      at: at,
      title: title,
      body: body,
      payload: payload,
      exact: exact,
    );
    if (failAfterSchedule) {
      failAfterSchedule = false;
      throw StateError('uncertain commit');
    }
  }
}
