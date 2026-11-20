import 'package:towork/app/reminder_wording.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/notifications/daily_digest.dart';
import 'package:towork/domain/notifications/reminder_plans.dart';
import 'package:towork/domain/settings/app_preferences.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/domain/workspace/workspace_validation.dart';

void main() {
  final day = DateTime(2026, 9, 24);
  WorkspaceEntity todo(
    String id,
    DateTime? due, {
    String status = 'pending',
    String priority = 'none',
    bool deleted = false,
  }) => WorkspaceEntity(
    kind: WorkspaceEntityKind.todo,
    id: id,
    version: 1,
    createdAt: day,
    updatedAt: day,
    deletedAt: deleted ? day : null,
    data: {
      ...todoDefaults,
      'title': id,
      'due_at': due?.toUtc().toIso8601String(),
      'status': status,
      'priority': priority,
    },
  );
  test('local day boundaries, active statuses and urgent-first titles match actual records', () {
    final snapshot = WorkspaceSnapshot([
      todo('今天普通', day),
      todo('今天紧急', day.add(const Duration(hours: 12)), priority: 'urgent'),
      todo('逾期', day.subtract(const Duration(microseconds: 1))),
      todo('明天', DateTime(2026, 9, 25)),
      todo('无日期', null),
      todo('已完成', day, status: 'done'),
      todo('已取消', day, status: 'cancelled'),
      todo('已删除', day, deleted: true),
    ]);
    expect(
      dailyDigest(snapshot, day, reminderWording('zh').format),
      '9/24 到期 2 项，此前未完成 1 项。今天紧急、今天普通。预排快照，打开查看最新。',
    );
  });
  test('seven daily snapshot plans change with data, not every clock tick', () {
    final snapshot = WorkspaceSnapshot([
      todo('今天待办', day.add(const Duration(hours: 10))),
    ]);
    List<ReminderPlan> plans(WorkspaceSnapshot s, DateTime n) => reminderPlans(
      s,
      const AppPreferences(notifyDue: false),
      n,
      reminderWording('zh'),
    );
    final first = plans(snapshot, day);
    expect(first, hasLength(7));
    expect(first.first.payload['body'], contains('到期 1 项'));
    expect(
      first.map((p) => p.payload),
      plans(
        snapshot,
        day.add(const Duration(minutes: 1)),
      ).map((p) => p.payload),
    );
    expect(
      plans(WorkspaceSnapshot([]), day).first.payload['body'],
      contains('到期 0 项'),
    );
    expect(first.map((p) => p.at.toLocal().hour), everyElement(8));
  });
}
