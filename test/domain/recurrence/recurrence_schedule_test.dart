import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/recurrence/recurrence_rule.dart';
import 'package:towork/domain/recurrence/recurrence_schedule.dart';

RecurrenceSchedule schedule(
  String rule,
  String anchor, [
  String zone = 'Asia/Shanghai',
]) => RecurrenceSchedule(
  rule: RecurrenceRule.parse(rule),
  anchor: DateTime.parse(anchor),
  timezone: zone,
);
List<String> due(
  RecurrenceSchedule s, {
  int limit = 10,
  String? after,
  String? before,
}) => s
    .occurrences(
      limit: limit,
      after: after == null ? null : DateTime.parse(after),
      before: before == null ? null : DateTime.parse(before),
    )
    .map((e) => e.dueAt.toIso8601String())
    .toList();

void main() {
  test('does not invent DST dates beyond the bundled transition horizon', () {
    expect(
      () => schedule(
        'FREQ=DAILY',
        '2038-03-13T07:30:00Z',
        'America/New_York',
      ).occurrences(),
      throwsA(isA<RecurrenceCoverageException>()),
    );
    expect(
      due(
        schedule('FREQ=DAILY;COUNT=2', '2040-01-01T01:00:00Z', 'Asia/Shanghai'),
      ),
      hasLength(2),
    );
    expect(
      due(schedule('FREQ=DAILY;COUNT=2', '2040-01-01T01:00:00Z', 'Etc/UTC')),
      hasLength(2),
    );
    expect(
      due(
        schedule('FREQ=DAILY', '2037-12-31T14:00:00Z', 'America/New_York'),
        before: '2037-12-31T23:00:00Z',
      ),
      hasLength(1),
    );
  });
  test('strict parser rejects malformed and unsupported rules without dropping fields', () {
    for (final raw in [
      '',
      'DAILY',
      'FREQ=DAILY;',
      'FREQ=DAILY;FREQ=WEEKLY',
      'FREQ=DAILY;foo=x',
      'FREQ=HOURLY',
      'FREQ=DAILY;INTERVAL=0',
      'FREQ=DAILY;INTERVAL=100',
      'FREQ=DAILY;INTERVAL=1.5',
      'FREQ=DAILY;INTERVAL=-1',
      'FREQ=DAILY;COUNT=abc',
      'FREQ=DAILY;COUNT=0',
      'FREQ=DAILY;COUNT=100001',
      'FREQ=WEEKLY;BYDAY=1MO',
      'FREQ=WEEKLY;BYDAY=MO,MO',
      'FREQ=DAILY;BYDAY=MO',
      'FREQ=MONTHLY;BYMONTHDAY=32',
      'FREQ=MONTHLY;BYMONTHDAY=0',
      'FREQ=WEEKLY;BYMONTHDAY=1',
      'FREQ=WEEKLY;WKST=SU',
      'FREQ=DAILY;COUNT=2;UNTIL=20260924',
      'FREQ=DAILY;UNTIL=20260230',
      'FREQ=DAILY;UNTIL=20260924T240000',
      'FREQ=DAILY;UNTIL=20260924junk',
      'FREQ=DAILY;UNTIL=00000924',
    ]) {
      expect(RecurrenceRule.tryParse(raw), isNull, reason: raw);
    }
  });
  test('parsed collections and occurrence results are immutable', () {
    final rule = RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,WE;WKST=MO');
    expect(() => rule.weekdays.add(7), throwsUnsupportedError);
    final result = schedule('FREQ=DAILY', '2026-09-24T01:00:00Z').occurrences();
    expect(() => result.clear(), throwsUnsupportedError);
  });
  test(
    'daily count includes current occurrence and interval does not drift',
    () {
      expect(
        due(schedule('FREQ=DAILY;INTERVAL=2;COUNT=3', '2026-09-24T01:00:00Z')),
        [
          '2026-09-24T01:00:00.000Z',
          '2026-09-26T01:00:00.000Z',
          '2026-09-28T01:00:00.000Z',
        ],
      );
    },
  );
  test(
    'weekly weekdays use Monday-based interval and retain the current task',
    () {
      expect(
        due(
          schedule(
            'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,FR;COUNT=5',
            '2026-09-23T01:00:00Z',
          ),
        ),
        [
          '2026-09-23T01:00:00.000Z',
          '2026-09-25T01:00:00.000Z',
          '2026-10-05T01:00:00.000Z',
          '2026-10-09T01:00:00.000Z',
          '2026-10-19T01:00:00.000Z',
        ],
      );
    },
  );
  test('weekly omitted BYDAY derives anchor weekday, not today', () {
    expect(due(schedule('FREQ=WEEKLY;COUNT=2', '2026-09-23T01:00:00Z')), [
      '2026-09-23T01:00:00.000Z',
      '2026-09-30T01:00:00.000Z',
    ]);
  });
  test('month end clamps independently and returns to original 31st', () {
    expect(
      due(
        schedule('FREQ=MONTHLY;BYMONTHDAY=31;COUNT=4', '2026-01-31T01:00:00Z'),
      ),
      [
        '2026-01-31T01:00:00.000Z',
        '2026-02-28T01:00:00.000Z',
        '2026-03-31T01:00:00.000Z',
        '2026-04-30T01:00:00.000Z',
      ],
    );
  });
  test('leap month and implicit month day follow anchor', () {
    expect(due(schedule('FREQ=MONTHLY;COUNT=3', '2028-01-30T01:00:00Z')), [
      '2028-01-30T01:00:00.000Z',
      '2028-02-29T01:00:00.000Z',
      '2028-03-30T01:00:00.000Z',
    ]);
  });
  test(
    'existing yearly option preserves leap anchor across ordinary years',
    () {
      expect(
        due(schedule('FREQ=YEARLY;COUNT=5', '2024-02-29T01:00:00Z')).last,
        '2028-02-29T01:00:00.000Z',
      );
    },
  );
  test('UNTIL date includes full local end date', () {
    expect(due(schedule('FREQ=DAILY;UNTIL=20260925', '2026-09-24T15:30:00Z')), [
      '2026-09-24T15:30:00.000Z',
      '2026-09-25T15:30:00.000Z',
    ]);
  });
  test('local and UTC UNTIL apply different explicit time domains', () {
    expect(
      due(schedule('FREQ=DAILY;UNTIL=20260925T090000', '2026-09-24T01:00:00Z')),
      hasLength(2),
    );
    expect(
      due(
        schedule('FREQ=DAILY;UNTIL=20260925T005959Z', '2026-09-24T01:00:00Z'),
      ),
      hasLength(1),
    );
    expect(
      due(
        schedule('FREQ=DAILY;UNTIL=20260925T010000Z', '2026-09-24T01:00:00Z'),
      ),
      hasLength(2),
    );
  });
  test(
    'end before anchor and count exhausted before query return no dates',
    () {
      expect(
        due(schedule('FREQ=DAILY;UNTIL=20260923', '2026-09-24T01:00:00Z')),
        isEmpty,
      );
      expect(
        due(
          schedule('FREQ=DAILY;COUNT=1', '2026-09-24T01:00:00Z'),
          after: '2026-09-24T01:00:00Z',
        ),
        isEmpty,
      );
    },
  );
  test(
    'spring gap shifts to first legal time then restores intended wall time',
    () {
      expect(
        due(
          schedule(
            'FREQ=DAILY;COUNT=3',
            '2026-03-07T07:30:00Z',
            'America/New_York',
          ),
        ),
        [
          '2026-03-07T07:30:00.000Z',
          '2026-03-08T07:00:00.000Z',
          '2026-03-09T06:30:00.000Z',
        ],
      );
    },
  );
  test('local UNTIL compares the resolved clock after a DST gap', () {
    expect(
      due(
        schedule(
          'FREQ=DAILY;UNTIL=20260308T024500',
          '2026-03-07T07:30:00Z',
          'America/New_York',
        ),
      ),
      hasLength(1),
    );
  });
  test('fall fold picks earlier instant exactly once', () {
    expect(
      due(
        schedule(
          'FREQ=DAILY;COUNT=3',
          '2026-10-31T05:30:00Z',
          'America/New_York',
        ),
      ),
      [
        '2026-10-31T05:30:00.000Z',
        '2026-11-01T05:30:00.000Z',
        '2026-11-02T06:30:00.000Z',
      ],
    );
  });
  test('half hour DST gap uses transition boundary rather than a one-hour assumption', () {
    expect(
      due(
        schedule(
          'FREQ=DAILY;COUNT=3',
          '2026-10-02T15:45:00Z',
          'Australia/Lord_Howe',
        ),
      ),
      [
        '2026-10-02T15:45:00.000Z',
        '2026-10-03T15:30:00.000Z',
        '2026-10-04T15:15:00.000Z',
      ],
    );
  });
  test('a missing whole local date is skipped without creating duplicate next-day occurrence', () {
    final result = schedule(
      'FREQ=DAILY;COUNT=3',
      '2011-12-29T19:00:00Z',
      'Pacific/Apia',
    ).occurrences();
    expect(result.map((e) => e.nominal.day), [29, 31, 1]);
    expect(result.map((e) => e.index), [0, 1, 2]);
    expect(result.map((e) => e.dueAt).toSet(), hasLength(3));
  });
  test(
    'stable identities and count indices do not depend on query windows',
    () {
      final s = schedule(
        'FREQ=MONTHLY;BYMONTHDAY=31;COUNT=8',
        '2026-01-31T01:00:00Z',
      );
      final all = s.occurrences();
      final page = s.occurrences(after: all[2].dueAt, before: all[5].dueAt);
      expect(
        page.map((e) => e.stableId('series-a')),
        all.sublist(3, 6).map((e) => e.stableId('series-a')),
      );
      expect(page.map((e) => e.index), [3, 4, 5]);
      expect(
        page.first.stableId('series-a'),
        isNot(page.first.stableId('series-b')),
      );
    },
  );
  test('microseconds survive timezone conversion and future dates', () {
    expect(
      due(schedule('FREQ=DAILY;COUNT=2', '2026-09-24T01:00:00.123456Z')).last,
      '2026-09-25T01:00:00.123456Z',
    );
  });
  test('timezone required, invalid query limits rejected and inverse window is empty', () {
    expect(
      () => schedule('FREQ=DAILY', '2026-09-24T01:00:00Z', 'PST'),
      throwsFormatException,
    );
    final s = schedule('FREQ=DAILY', '2026-09-24T01:00:00Z');
    expect(() => s.occurrences(limit: 501), throwsArgumentError);
    expect(() => s.occurrences(limit: 0), throwsArgumentError);
    expect(
      s.occurrences(
        after: DateTime.utc(2026, 10),
        before: DateTime.utc(2026, 9),
      ),
      isEmpty,
    );
  });
}
