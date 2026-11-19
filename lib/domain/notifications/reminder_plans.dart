import '../settings/app_preferences.dart';
import '../workspace/workspace_commands.dart';
import 'daily_digest.dart';

class ReminderPlan {
  ReminderPlan({
    required this.key,
    required this.at,
    required Map<String, Object?> payload,
  }) : payload = freezeWorkspaceJson(payload);
  final String key;
  final DateTime at;
  final Map<String, Object?> payload;
}

/// All configured rules are candidates, including past ones for reconciliation.
/// Only future candidates are newly scheduled; missed alerts are never blasted.
List<ReminderPlan> reminderPlans(
  WorkspaceSnapshot snapshot,
  AppPreferences prefs,
  DateTime now,
) {
  final plans = <ReminderPlan>[];
  if (prefs.notifyDue) {
    for (final todo in snapshot.todos.where(
      (e) => {'pending', 'inProgress'}.contains(e.data['status']),
    )) {
      final times = <String, DateTime>{};
      final due = todo.data['due_at'] == null
          ? null
          : DateTime.parse(todo.data['due_at']! as String);
      for (final rule
          in (todo.data['remind_rules']! as List)
              .cast<Map<String, Object?>>()) {
        DateTime? at;
        if (rule['absolute_at'] is String) {
          at = DateTime.parse(rule['absolute_at'] as String);
        } else if (due != null && rule['offset_minutes'] is int) {
          // Multiplication inside Duration can wrap a large imported integer.
          // Check the DateTime range before narrowing back to a native int.
          final micros =
              BigInt.from(due.microsecondsSinceEpoch) -
              BigInt.from(rule['offset_minutes'] as int) *
                  BigInt.from(Duration.microsecondsPerMinute);
          if (micros.abs() > BigInt.parse('8640000000000000000')) continue;
          at = DateTime.fromMicrosecondsSinceEpoch(micros.toInt(), isUtc: true);
        }
        if (at != null) times['rule:${rule['id']}'] = at;
      }
      if (times.isEmpty && todo.data['remind_at'] is String) {
        times['legacy'] = DateTime.parse(todo.data['remind_at']! as String);
      }
      final seen = <int>{};
      for (final entry in times.entries) {
        if (!seen.add(entry.value.millisecondsSinceEpoch)) continue;
        final key = 'todo:${todo.id}:${entry.key}';
        plans.add(
          ReminderPlan(
            key: key,
            at: entry.value.toUtc(),
            payload: {
              'schema': 1,
              'key': key,
              'todo_id': todo.id,
              'todo_version': todo.version,
              'rule_id': entry.key,
              'at': entry.value.toUtc().toIso8601String(),
              'title': '待办提醒',
              'body': todo.data['title'],
              'kind': 'due',
            },
          ),
        );
      }
    }
  }
  if (prefs.notifyMorning) {
    final local = now.toLocal();
    for (var i = 0; i < 7; i++) {
      final at = DateTime(
        local.year,
        local.month,
        local.day + i,
        prefs.morningHour,
        prefs.morningMinute,
      );
      final key = 'morning:${at.year}-${at.month}-${at.day}';
      plans.add(
        ReminderPlan(
          key: key,
          at: at.toUtc(),
          payload: {
            'schema': 1,
            'key': key,
            'at': at.toUtc().toIso8601String(),
            'kind': 'morning',
            'title': '每日待办摘要',
            'body': dailyDigest(snapshot, at),
          },
        ),
      );
    }
  }
  plans.sort(
    (a, b) => a.at == b.at ? a.key.compareTo(b.key) : a.at.compareTo(b.at),
  );
  return plans;
}
