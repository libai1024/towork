import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../l10n/generated/app_localizations.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/notifications/notification_service.dart';

class NativeNotificationService implements NotificationService {
  NativeNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    this.background = false,
  }) : plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin plugin;
  final bool background;
  static void Function(String?)? _foregroundOpen;
  bool get supported =>
      !kIsWeb &&
      {
        TargetPlatform.android,
        TargetPlatform.macOS,
      }.contains(defaultTargetPlatform);
  AndroidFlutterLocalNotificationsPlugin? get _android => plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  MacOSFlutterLocalNotificationsPlugin? get _mac => plugin
      .resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin
      >();
  @override
  Future<void> initialize(void Function(String?) onOpen) async {
    if (!supported) return;
    if (!background) _foregroundOpen = onOpen;
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_towork'),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (event) =>
          _foregroundOpen?.call(event.payload),
    );
    if (background) return;
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      onOpen(launch?.notificationResponse?.payload);
    }
  }

  @override
  Future<NotificationAccess> inspect() async {
    if (!supported) {
      return const NotificationAccess(
        enabled: false,
        exact: false,
        supported: false,
      );
    }
    if (_android case final android?) {
      return NotificationAccess(
        enabled: await android.areNotificationsEnabled() ?? false,
        exact: await android.canScheduleExactNotifications() ?? false,
      );
    }
    return NotificationAccess(
      enabled: (await _mac?.checkPermissions())?.isEnabled ?? false,
      exact: true,
    );
  }

  @override
  Future<void> requestPermission() async {
    if (_android case final android?) {
      await android.requestNotificationsPermission();
    } else {
      await _mac?.requestPermissions(alert: true, sound: true);
    }
  }

  @override
  Future<void> requestExactPermission() async {
    await _android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> openSettings() async {
    await plugin.openAppNotificationSettings();
  }

  @override
  Future<List<PendingNotice>> pending() async => [
    for (final p in await plugin.pendingNotificationRequests())
      PendingNotice(p.id, p.payload),
  ];
  @override
  Future<void> cancel(int id) => plugin.cancel(id: id);
  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required bool exact,
  }) {
    final language = (jsonDecode(payload) as Map)['language'];
    final copy = lookupAppLocalizations(Locale(language == 'en' ? 'en' : 'zh'));
    return plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'towork_reminders_v1',
          copy.tasksAndDailyDigest,
          channelDescription: copy.yourTaskRemindersAndDailyDigests,
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.private,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
        ),
      ),
    );
  }
}
