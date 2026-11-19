import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/agent_tool_registry.dart';
import 'package:towork/agent/tools/calculator_tool.dart';
import 'package:towork/agent/tools/calendar_tool.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

final _context = AgentToolContext(
  snapshot: WorkspaceSnapshot(const []),
  now: DateTime.utc(2026, 11, 14, 6, 30),
  localOffset: const Duration(hours: 8),
);

Matcher get _invalid => throwsA(
  isA<AgentFailure>().having((e) => e.code, 'code', AgentFailureCode.invalid),
);

void main() {
  group('calculate', () {
    JsonObject run(String expression, [int? scale]) =>
        const CalculatorTool().call({
              'expression': expression,
              'scale': ?scale,
            }, _context)!
            as JsonObject;

    test('十进制精确：不出现浮点误差', () {
      expect(run('0.1 + 0.2')['result'], '0.3');
      expect(run('1.1 * 3')['result'], '3.3');
      expect(run('19.9 * 3 + 5')['result'], '64.7');
      expect(run('100 - 99.99')['result'], '0.01');
    });

    test('优先级、括号、一元负号与幂', () {
      expect(run('2 + 3 * 4')['result'], '14');
      expect(run('(2 + 3) * 4')['result'], '20');
      expect(run('-3 + 5')['result'], '2');
      expect(run('2 ^ 10')['result'], '1024');
      expect(run('2 ^ 3 ^ 2')['result'], '512');
      expect(run('-2 ^ 2')['result'], '-4');
      expect(run('2 ^ -2')['result'], '0.25');
    });

    test('百分号、千分位、货币符号与全角字符', () {
      expect(run('1280 * 15%')['result'], '192');
      expect(run('¥1,280.50 + ￥19.5')['result'], '1300');
      expect(run('（１２＋８）×３÷４')['result'], '15');
      expect(run('1 000 000 / 4')['result'], '250000');
    });

    test('除不尽按 scale 四舍五入并标注', () {
      final third = run('1 / 3');
      expect(third['result'], '0.333333');
      expect(third['rounded_to_scale'], 6);
      expect(run('2 / 3', 2)['result'], '0.67');
      expect(run('-2 / 3', 2)['result'], '-0.67');
      expect(run('1 / 8', 2)['result'], '0.13');
      expect(run('10 / 4').containsKey('rounded_to_scale'), isFalse);
      expect(run('7 / 2', 0)['result'], '4');
    });

    test('无法计算时返回可读错误而不是抛出', () {
      expect(run('1 / 0')['error'], 'division_by_zero');
      expect(run('2 +')['error'], 'invalid_expression');
      expect(run('abc')['error'], 'invalid_expression');
      expect(run('(1 + 2')['error'], 'invalid_expression');
      expect(run('2 ^ 0.5')['error'], 'unsupported_exponent');
      expect(run('9 ^ 999')['error'], 'unsupported_exponent');
      expect(run('99999999 ^ 256')['error'], 'too_large');
    });

    test('参数形状不对属于调用错误', () {
      const tool = CalculatorTool();
      expect(() => tool.call({}, _context), _invalid);
      expect(() => tool.call({'expression': 12}, _context), _invalid);
      expect(
        () => tool.call({'expression': '1', 'scale': 13}, _context),
        _invalid,
      );
      expect(
        () => tool.call({'expression': '1', 'unit': '元'}, _context),
        _invalid,
      );
      expect(() => tool.call({'expression': '1' * 501}, _context), _invalid);
    });
  });

  group('calendar_lookup', () {
    JsonObject run(JsonObject args) =>
        const CalendarTool().call(args, _context)! as JsonObject;
    JsonObject day(String date) =>
        ((run({'op': 'describe', 'date': date})['days']! as List).single as Map)
            .cast<String, Object?>();

    test('公历日期给出星期、农历与节日', () {
      final newYear = day('2026-02-17');
      expect(newYear['weekday'], '周二');
      expect(newYear['lunar_year'], 2026);
      expect(newYear['lunar_month'], 1);
      expect(newYear['lunar_day'], 1);
      expect(newYear['festivals'], contains('春节'));
      expect(newYear['lunar'], contains('正月初一'));
      expect(newYear['lunar'], contains('马'));

      expect(day('2026-11-14')['weekday'], '周六');
      expect(day('2026-09-25')['festivals'], contains('中秋节'));
      expect(day('2026-10-01')['festivals'], contains('国庆节'));
      expect(day('2026-04-05')['solar_term'], '清明');
    });

    test('连续多天：月末自然跨月', () {
      final days = run({'op': 'describe', 'date': '2026-02-27', 'days': 4});
      expect((days['days']! as List).map((d) => (d as Map)['date']), [
        '2026-02-27',
        '2026-02-28',
        '2026-03-01',
        '2026-03-02',
      ]);
    });

    test('法定节假日与调休补班', () {
      final holiday = day('2024-10-01')['public_holiday']! as Map;
      expect(holiday['name'], '国庆节');
      expect(holiday['day_off'], isTrue);
      // 2024-09-29（周日）为国庆调休补班。
      final workday = day('2024-09-29')['public_holiday']! as Map;
      expect(workday['name'], '国庆节');
      expect(workday['day_off'], isFalse);
      expect(day('2024-10-15').containsKey('public_holiday'), isFalse);
    });

    test('农历转公历，闰月必须明确', () {
      final spring = run({
        'op': 'from_lunar',
        'lunar_year': 2026,
        'lunar_month': 1,
        'lunar_day': 1,
      });
      expect(spring['date'], '2026-02-17');
      final midAutumn = run({
        'op': 'from_lunar',
        'lunar_year': 2026,
        'lunar_month': 8,
        'lunar_day': 15,
      });
      expect(midAutumn['date'], '2026-09-25');
      // 2025 年闰六月：同一个「六月初一」对应两个公历日期。
      final june = run({
        'op': 'from_lunar',
        'lunar_year': 2025,
        'lunar_month': 6,
        'lunar_day': 1,
      });
      final leapJune = run({
        'op': 'from_lunar',
        'lunar_year': 2025,
        'lunar_month': 6,
        'lunar_day': 1,
        'leap_month': true,
      });
      expect(june['date'], '2025-06-25');
      expect(leapJune['date'], '2025-07-25');
      expect(leapJune['leap_month'], isTrue);
      expect(june.containsKey('leap_month'), isFalse);
    });

    test('不存在的农历日期和闰月返回错误而不是换成别的日子', () {
      expect(
        run({
          'op': 'from_lunar',
          'lunar_year': 2026,
          'lunar_month': 6,
          'lunar_day': 1,
          'leap_month': true,
        }),
        {'error': 'no_such_leap_month', 'leap_month_of_year': 0},
      );
      // 2026 年正月是大月（有三十），二月是小月（没有三十）。
      expect(
        run({
          'op': 'from_lunar',
          'lunar_year': 2026,
          'lunar_month': 1,
          'lunar_day': 30,
        })['date'],
        '2026-03-18',
      );
      expect(
        run({
          'op': 'from_lunar',
          'lunar_year': 2026,
          'lunar_month': 2,
          'lunar_day': 30,
        }),
        {'error': 'invalid_lunar_date'},
      );
      expect(
        run({
          'op': 'from_lunar',
          'lunar_year': 2200,
          'lunar_month': 1,
          'lunar_day': 1,
        })['error'],
        'year_out_of_range',
      );
    });

    test('按名称找节日：省略「节」字、节气、默认今年', () {
      Iterable<Object?> dates(JsonObject result) =>
          (result['matches']! as List).map((d) => (d as Map)['date']);
      final midAutumn = run({'op': 'find_festival', 'name': '中秋'});
      expect(midAutumn['year'], 2026);
      expect(dates(midAutumn), ['2026-09-25']);
      expect(dates(run({'op': 'find_festival', 'name': '中秋节', 'year': 2027})), [
        '2027-09-15',
      ]);
      expect(dates(run({'op': 'find_festival', 'name': '端午节'})), [
        '2026-06-19',
      ]);
      expect(dates(run({'op': 'find_festival', 'name': '冬至'})), ['2026-12-22']);
      expect(dates(run({'op': 'find_festival', 'name': '除夕', 'year': 2027})), [
        '2027-02-05',
      ]);
      expect(run({'op': 'find_festival', 'name': '不存在的节'}), {
        'error': 'festival_not_found',
        'name': '不存在的节',
        'year': 2026,
      });
    });

    test('默认年份按本地日期而不是 UTC', () {
      // UTC 仍是 2026-12-31 18:00，东八区已是 2027-01-01 02:00。
      final context = AgentToolContext(
        snapshot: WorkspaceSnapshot(const []),
        now: DateTime.utc(2026, 12, 31, 18),
        localOffset: const Duration(hours: 8),
      );
      final result =
          const CalendarTool().call({
                'op': 'find_festival',
                'name': '春节',
              }, context)!
              as JsonObject;
      expect(result['year'], 2027);
      expect(
        ((result['matches']! as List).single as Map)['date'],
        '2027-02-06',
      );
    });

    test('不存在的公历日期、越界年份与错误形状', () {
      expect(run({'op': 'describe', 'date': '2026-02-30'}), {
        'error': 'invalid_date',
        'date': '2026-02-30',
      });
      expect(
        run({'op': 'describe', 'date': '1800-01-01'})['error'],
        'invalid_date',
      );
      expect(
        run({'op': 'find_festival', 'name': '春节', 'year': 1800})['error'],
        'year_out_of_range',
      );
      const tool = CalendarTool();
      expect(() => tool.call({'op': 'guess'}, _context), _invalid);
      expect(() => tool.call({'date': '2026-01-01'}, _context), _invalid);
      expect(
        () => tool.call({'op': 'describe', 'date': '明天'}, _context),
        _invalid,
      );
      expect(
        () => tool.call({
          'op': 'describe',
          'date': '2026-01-01',
          'days': 32,
        }, _context),
        _invalid,
      );
      expect(
        () => tool.call({
          'op': 'describe',
          'date': '2026-01-01',
          'x': 1,
        }, _context),
        _invalid,
      );
    });
  });

  test('注册表：名称唯一，schema 与实现一一对应', () {
    final names = AgentToolRegistry.readTools.map((t) => t.name).toList();
    expect(names, [
      'calculate',
      'calendar_lookup',
      'todo_stats',
      'show_todo_list',
      'show_todo_overview',
      'show_question',
    ]);
    expect(names.toSet(), hasLength(names.length));
    for (final (index, schema) in AgentToolRegistry.schemas.indexed) {
      final function = schema['function']! as Map;
      expect(schema['type'], 'function');
      expect(function['name'], names[index]);
      expect((function['description']! as String).length, greaterThan(20));
      expect((function['parameters']! as Map)['additionalProperties'], isFalse);
      expect(AgentToolRegistry.read(names[index]), isNotNull);
    }
    expect(AgentToolRegistry.read('todo_create'), isNull);
    expect(AgentToolRegistry.read(null), isNull);
  });
}
