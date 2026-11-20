import 'dart:ui';

import '../domain/notifications/reminder_plans.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/strings.dart';

ReminderWording reminderWording(String preference) {
  final locale =
      preferredLocale(preference) ??
      resolveAppLocale(
        PlatformDispatcher.instance.locales,
        AppLocalizations.supportedLocales,
      );
  final copy = lookupAppLocalizations(locale);
  return ReminderWording(
    locale.languageCode,
    copy.taskReminder,
    copy.dailyTaskDigest,
    (day, due, overdue, titles) {
      final english = locale.languageCode == 'en';
      final summary = copy.dueEarlierUnfinished(
        day.month,
        day.day,
        due,
        overdue,
      );
      final names = titles.isEmpty
          ? ''
          : '${titles.join(english ? ', ' : '、')}${english ? '. ' : '。'}';
      return '$summary${copy.scheduledSnapshotOpenForTheLatest(names)}';
    },
  );
}
