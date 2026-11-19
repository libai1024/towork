import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/core/todo/todo_utils.dart';
import 'package:towork/core/todo/recurrence_preview.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  test('visual parser refuses lossy mappings and retains valid values', () {
    for (final raw in [
      'FREQ=MONTHLY;BYDAY=1MO',
      'FREQ=MONTHLY',
      'FREQ=DAILY;COUNT=100',
      'FREQ=DAILY;UNTIL=20260924T120000',
      'FREQ=DAILY;UNTIL=20260924T235959Z',
      'FREQ=DAILY;INTERVAL=garbage',
    ]) {
      expect(RepeatSpec.fromRrule(raw), isNull, reason: raw);
      expect(repeatLabelOf(raw), '自定义规则');
    }
    for (final raw in [
      'FREQ=DAILY;UNTIL=20260924',
      'FREQ=DAILY;UNTIL=20260924T235959',
    ]) {
      expect(RepeatSpec.fromRrule(raw)!.toRrule(), raw);
    }
    final spec = RepeatSpec.fromRrule(
      'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;COUNT=8',
    )!;
    expect(spec.toRrule(), 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;COUNT=8');
    expect(RepeatSpec.fromRrule('FREQ=WEEKLY')!.weekdays, isEmpty);
  });
  testWidgets(
    'preview uses fixed timezone and month-end policy at large text sizes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: RecurrencePreview(
              rule: 'FREQ=MONTHLY;BYMONTHDAY=31;COUNT=4',
              anchor: DateTime.utc(2026, 1, 31, 1),
              timezone: 'Asia/Shanghai',
            ),
          ),
        ),
      );
      expect(find.text('本次：2026/01/31 09:00'), findsOneWidget);
      expect(find.text('2026/02/28 09:00'), findsOneWidget);
      expect(find.text('2026/03/31 09:00'), findsOneWidget);
      expect(find.text('2026/04/30 09:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'preview distinguishes missing anchor, ended series and unsupported rule',
    (tester) async {
      Future<void> show(String rule, DateTime? anchor) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: RecurrencePreview(
              rule: rule,
              anchor: anchor,
              timezone: 'Asia/Shanghai',
            ),
          ),
        ),
      );
      await show('FREQ=DAILY', null);
      expect(find.text('设置截止时间后可预览后续日期'), findsOneWidget);
      await show('FREQ=DAILY;COUNT=1', DateTime.utc(2026, 9, 24, 1));
      expect(find.textContaining('没有后续日期'), findsOneWidget);
      await show('FREQ=HOURLY', DateTime.utc(2026, 9, 24, 1));
      expect(find.text('当前规则或时区暂不支持预览'), findsOneWidget);
    },
  );
}
