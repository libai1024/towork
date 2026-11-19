import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/services/mock_ai_parser.dart';
import 'package:towork/domain/models/chat_reply.dart';

void main() {
  final now = DateTime(2026, 9, 23, 12);
  TodoDraft draft(String text, {DateTime? at}) =>
      MockAiParser.respond(text, now: at ?? now).draft!;

  group('explicit task intent', () {
    test('reminders beat weekly-report topic shortcuts', () {
      for (final text in [
        '提醒我明天交周报',
        '请提醒我明天交周报',
        '麻烦帮我提醒我明天交周报',
        '新建一条待办明天交周报',
      ]) {
        final result = draft(text);
        expect(result.title, '交周报', reason: text);
        expect(result.dueAt, DateTime(2026, 9, 24, 18), reason: text);
        expect(result.categoryId, 'cat_work');
      }
      final thisWeek = draft('提醒我这周交周报');
      expect(thisWeek.title, '这周交周报');
      expect(thisWeek.dueAt, isNull);
    });

    test('report queries keep their existing read-only shortcut', () {
      for (final text in ['看看这周做了什么', '周报有哪些内容？']) {
        final result = MockAiParser.respond(text, now: now);
        expect(result.draft, isNull);
        expect(result.text, contains('报告'));
      }
    });
  });

  group('explicit clock times', () {
    test('Chinese two and half-hour forms preserve the requested minute', () {
      final examples = <String, DateTime>{
        '提醒我明天下午两点交报告': DateTime(2026, 9, 24, 14),
        '提醒我明天下午两点半交报告': DateTime(2026, 9, 24, 14, 30),
        '提醒我明天下午三点半交报告': DateTime(2026, 9, 24, 15, 30),
        '提醒我明天下午3点半前交报告': DateTime(2026, 9, 24, 15, 30),
        '提醒我明天上午十点三十分交报告': DateTime(2026, 9, 24, 10, 30),
        '提醒我明天23点59分交报告': DateTime(2026, 9, 24, 23, 59),
        '提醒我明天二十三点交报告': DateTime(2026, 9, 24, 23),
      };
      for (final example in examples.entries) {
        final result = draft(example.key);
        expect(result.dueAt, example.value, reason: example.key);
        expect(result.title, '交报告', reason: example.key);
      }
    });

    test(
      'night twelve is the midnight after that evening, noon stays twelve',
      () {
        final examples = <String, DateTime>{
          '提醒我明天晚上十二点交报告': DateTime(2026, 9, 25),
          '提醒我明天晚上十二点半交报告': DateTime(2026, 9, 25, 0, 30),
          '提醒我今晚十二点交报告': DateTime(2026, 9, 24),
          '提醒我明天凌晨十二点交报告': DateTime(2026, 9, 24),
          '提醒我明天零点交报告': DateTime(2026, 9, 24),
          '提醒我明天中午十二点交报告': DateTime(2026, 9, 24, 12),
        };
        for (final example in examples.entries) {
          expect(draft(example.key).dueAt, example.value, reason: example.key);
        }
      },
    );

    test(
      'invalid clocks keep original time text and never roll into another day',
      () {
        for (final clock in [
          '24点',
          '25点',
          '125点',
          '-1点',
          '1.5点',
          '二十五点',
          '一百点',
          '三点六十分',
          '3点99分',
          '上午13点',
        ]) {
          final result = draft('提醒我明天$clock交报告');
          expect(result.dueAt, isNull, reason: clock);
          expect(result.title, '明天$clock交报告', reason: clock);
        }
      },
    );

    test('multiple clocks and dateless times stay unassigned', () {
      final range = draft('提醒我明天下午两点到三点交报告');
      expect(range.dueAt, isNull);
      expect(range.title, contains('两点到三点'));
      final dateless = draft('提醒我下午三点半交报告');
      expect(dateless.dueAt, isNull);
      expect(dateless.title, '下午三点半交报告');
    });
  });

  group('calendar boundaries', () {
    test(
      'tomorrow crosses leap day, normal February, month and year boundaries',
      () {
        final examples = <DateTime, DateTime>{
          DateTime(2024, 2, 28, 23): DateTime(2024, 2, 29, 14, 30),
          DateTime(2024, 2, 29, 23): DateTime(2024, 3, 1, 14, 30),
          DateTime(2025, 2, 28, 23): DateTime(2025, 3, 1, 14, 30),
          DateTime(2026, 9, 30, 23): DateTime(2026, 10, 1, 14, 30),
          DateTime(2026, 12, 31, 23): DateTime(2027, 1, 1, 14, 30),
        };
        for (final example in examples.entries) {
          expect(
            draft('提醒我明天下午两点半交报告', at: example.key).dueAt,
            example.value,
            reason: example.key.toIso8601String(),
          );
        }
      },
    );

    test(
      'night midnight crosses year only when the user requested midnight',
      () {
        final at = DateTime(2026, 12, 30, 12);
        expect(draft('提醒我明天晚上十二点交报告', at: at).dueAt, DateTime(2027, 1, 1));
        expect(draft('提醒我明天25点交报告', at: at).dueAt, isNull);
      },
    );

    test('month end respects leap years', () {
      expect(
        draft('提醒我月底交报告', at: DateTime(2024, 2, 5)).dueAt,
        DateTime(2024, 2, 29, 18),
      );
      expect(
        draft('提醒我月底交报告', at: DateTime(2025, 2, 5)).dueAt,
        DateTime(2025, 2, 28, 18),
      );
    });

    test(
      'next Monday uses the following calendar week including on Sunday',
      () {
        expect(
          draft('提醒我下周一上午两点交报告', at: DateTime(2026, 9, 21)).dueAt,
          DateTime(2026, 9, 28, 2),
        );
        expect(
          draft('提醒我下周一上午两点交报告', at: DateTime(2026, 9, 27)).dueAt,
          DateTime(2026, 9, 28, 2),
        );
      },
    );

    test('injected clock timezone is preserved', () {
      final utc = draft(
        '提醒我明天下午三点半交报告',
        at: DateTime.utc(2026, 9, 23, 12),
      ).dueAt!;
      expect(utc, DateTime.utc(2026, 9, 24, 15, 30));
      expect(utc.isUtc, isTrue);
      expect(draft('提醒我明天下午三点半交报告').dueAt!.isUtc, isFalse);
    });
  });
}
