import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/agent_time.dart';

void main() {
  group('toUtc', () {
    test('本地时刻加偏移换算成库内 UTC 写法', () {
      expect(
        AgentTime.toUtc('2026-11-15T15:00:00+08:00'),
        '2026-11-15T07:00:00.000Z',
      );
      // 跨日：东八区凌晨属于前一天的 UTC。
      expect(
        AgentTime.toUtc('2026-11-15T01:30:00+08:00'),
        '2026-11-14T17:30:00.000Z',
      );
      expect(
        AgentTime.toUtc('2026-03-01T09:00:00-05:00'),
        '2026-03-01T14:00:00.000Z',
      );
      expect(
        AgentTime.toUtc('2026-11-15T15:00:00+05:30'),
        '2026-11-15T09:30:00.000Z',
      );
    });

    test('秒可省略，偏移可不带冒号', () {
      expect(
        AgentTime.toUtc('2026-11-15T15:00+08:00'),
        '2026-11-15T07:00:00.000Z',
      );
      expect(
        AgentTime.toUtc('2026-11-15T15:00:00+0800'),
        '2026-11-15T07:00:00.000Z',
      );
      expect(AgentTime.toUtc('2026-11-15T15:00Z'), '2026-11-15T15:00:00.000Z');
    });

    test('已是规范 UTC 的值原样返回', () {
      expect(
        AgentTime.toUtc('2026-11-15T07:00:00.000Z'),
        '2026-11-15T07:00:00.000Z',
      );
      expect(AgentTime.toUtc('2026-11-15T07:00:00Z'), '2026-11-15T07:00:00Z');
    });

    test('不存在的日期、没有偏移和非字符串都不改写，留给领域校验拒绝', () {
      for (final value in [
        '2026-02-30T10:00:00+08:00',
        '2026-13-01T10:00:00+08:00',
        '2026-11-15T25:00:00+08:00',
        '2026-11-15T10:61:00+08:00',
        '2026-11-15T10:00:00+15:00',
        '2026-11-15T10:00:00+08:75',
        '2026-11-15T10:00:00',
        '2026-11-15',
        '明天下午三点',
        '',
      ]) {
        expect(AgentTime.toUtc(value), value, reason: value);
      }
      expect(AgentTime.toUtc(null), isNull);
      expect(AgentTime.toUtc(42), 42);
    });
  });

  test('normalize 只换算时间键，顶层与 patch 都处理且不改原参数', () {
    final args = <String, Object?>{
      'title': '2026-11-15T15:00:00+08:00',
      'due_at': '2026-11-15T15:00:00+08:00',
      'due_from': '2026-11-15T00:00:00+08:00',
      'due_before': '2026-11-16T00:00:00+08:00',
      'patch': <String, Object?>{
        'due_at': '2026-11-16T09:00:00+08:00',
        'note': '不动',
      },
    };
    final next = AgentTime.normalize(args);
    expect(next['title'], '2026-11-15T15:00:00+08:00');
    expect(next['due_at'], '2026-11-15T07:00:00.000Z');
    expect(next['due_from'], '2026-11-14T16:00:00.000Z');
    expect(next['due_before'], '2026-11-15T16:00:00.000Z');
    expect(next['patch'], {'due_at': '2026-11-16T01:00:00.000Z', 'note': '不动'});
    expect(args['due_at'], '2026-11-15T15:00:00+08:00');
    expect((args['patch']! as Map)['due_at'], '2026-11-16T09:00:00+08:00');
  });

  test('normalize 保留显式 null（清空截止时间）', () {
    final next = AgentTime.normalize({
      'patch': <String, Object?>{'due_at': null},
    });
    expect((next['patch']! as Map).containsKey('due_at'), isTrue);
    expect((next['patch']! as Map)['due_at'], isNull);
  });

  test('offsetLabel 与 local', () {
    expect(AgentTime.offsetLabel(const Duration(hours: 8)), '+08:00');
    expect(AgentTime.offsetLabel(Duration.zero), '+00:00');
    expect(
      AgentTime.offsetLabel(-const Duration(hours: 3, minutes: 30)),
      '-03:30',
    );
    expect(
      AgentTime.local(DateTime.utc(2026, 11, 15, 7), const Duration(hours: 8)),
      '2026-11-15T15:00+08:00',
    );
    expect(
      AgentTime.local(
        DateTime.utc(2026, 11, 14, 17, 30),
        const Duration(hours: 8),
      ),
      '2026-11-15T01:30+08:00',
    );
  });

  test('localize 给嵌套结果里的 UTC 时间补本地时刻，其余原样', () {
    final result = AgentTime.localize({
      'items': [
        {
          'id': 't1',
          'title': '交周报',
          'due_at': '2026-11-15T07:00:00.000Z',
          'completed_at': null,
          'note': '2026-11-15T07:00:00.000Z',
        },
      ],
      'count': 1,
    }, const Duration(hours: 8));
    expect(result, {
      'items': [
        {
          'id': 't1',
          'title': '交周报',
          'due_at': '2026-11-15T07:00:00.000Z',
          'due_at_local': '2026-11-15T15:00+08:00',
          'completed_at': null,
          'note': '2026-11-15T07:00:00.000Z',
        },
      ],
      'count': 1,
    });
  });
}
