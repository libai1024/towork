class NotificationAccess {
  const NotificationAccess({
    required this.enabled,
    required this.exact,
    this.supported = true,
  });
  final bool enabled, exact, supported;
}

class PendingNotice {
  const PendingNotice(this.id, this.payload);
  final int id;
  final String? payload;
}

abstract interface class NotificationService {
  Future<void> initialize(void Function(String?) onOpen);
  Future<NotificationAccess> inspect();
  Future<void> requestPermission();
  Future<void> requestExactPermission();
  Future<void> openSettings();
  Future<List<PendingNotice>> pending();
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required bool exact,
  });
  Future<void> cancel(int id);
}
