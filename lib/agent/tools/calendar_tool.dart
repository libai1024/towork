import 'package:lunar/lunar.dart';

import '../../domain/ai/agent_run.dart';
import '../../domain/ai/model_gateway.dart';
import '../agent_tool_registry.dart';

/// 公历、农历、节气、节日与法定调休的查询。
///
/// 「腊月二十八」「中秋前一天」「清明那周」这类说法模型只能靠记忆硬算，
/// 闰月和调休几乎必错。数据来自开源库 lunar（6tail，MIT），全部离线。
class CalendarTool implements AgentReadTool {
  const CalendarTool();

  static const _weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  static const _minYear = 1901;
  static const _maxYear = 2099;

  @override
  String get name => 'calendar_lookup';

  @override
  JsonObject get schema => agentToolSchema(
    name,
    'Offline Chinese calendar. op=describe: weekday, lunar date, festivals, '
    'solar term and mainland public-holiday/make-up-workday flags for '
    '`date` and the following `days`. op=from_lunar: convert a lunar date '
    'to the Gregorian date. op=find_festival: Gregorian date(s) of a '
    'festival or solar term (春节, 除夕, 中秋, 清明, 冬至, 母亲节 …) in '
    '`year`. Use it for any lunar date, festival or holiday instead of '
    'recalling from memory. Holiday schedules cover only years already '
    'bundled; absent data means unknown, not a normal day.',
    {
      'op': {
        'type': 'string',
        'enum': ['describe', 'from_lunar', 'find_festival'],
      },
      'date': {
        'type': 'string',
        'description': 'Gregorian YYYY-MM-DD (describe).',
      },
      'days': {
        'type': 'integer',
        'minimum': 1,
        'maximum': 31,
        'description': 'Consecutive days to describe. Default 1.',
      },
      'lunar_year': {'type': 'integer'},
      'lunar_month': {'type': 'integer', 'minimum': 1, 'maximum': 12},
      'lunar_day': {'type': 'integer', 'minimum': 1, 'maximum': 30},
      'leap_month': {
        'type': 'boolean',
        'description': 'True for the leap (闰) month. Default false.',
      },
      'name': {
        'type': 'string',
        'maxLength': 20,
        'description': 'Festival or solar-term name (find_festival).',
      },
      'year': {
        'type': 'integer',
        'description': 'Gregorian year (find_festival). Default: this year.',
      },
    },
    required: const ['op'],
  );

  @override
  Object? call(JsonObject args, AgentToolContext context) {
    requireToolKeys(
      args,
      const {
        'op',
        'date',
        'days',
        'lunar_year',
        'lunar_month',
        'lunar_day',
        'leap_month',
        'name',
        'year',
      },
      required: const {'op'},
    );
    return switch (args['op']) {
      'describe' => _describe(args),
      'from_lunar' => _fromLunar(args),
      'find_festival' => _find(args, context),
      _ => throw const AgentFailure(AgentFailureCode.invalid),
    };
  }

  static Never _invalid() => throw const AgentFailure(AgentFailureCode.invalid);

  static Solar? _solar(int year, int month, int day) {
    if (year < _minYear || year > _maxYear) return null;
    try {
      return Solar.fromYmd(year, month, day);
    } catch (_) {
      // lunar 用字符串抛错；不存在的日期在这里统一视为无效输入。
      return null;
    }
  }

  static String _ymd(Solar solar) =>
      '${solar.getYear().toString().padLeft(4, '0')}-'
      '${solar.getMonth().toString().padLeft(2, '0')}-'
      '${solar.getDay().toString().padLeft(2, '0')}';

  static JsonObject _day(Solar solar) {
    final lunar = solar.getLunar();
    final term = lunar.getJieQi();
    final holiday = HolidayUtil.getHoliday(_ymd(solar));
    return {
      'date': _ymd(solar),
      'weekday': _weekdays[solar.getWeek()],
      'lunar':
          '${lunar.getYearInGanZhi()}年（${lunar.getYearShengXiao()}）'
          '${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}',
      'lunar_year': lunar.getYear(),
      'lunar_month': lunar.getMonth().abs(),
      'lunar_day': lunar.getDay(),
      if (lunar.getMonth() < 0) 'leap_month': true,
      'festivals': [...solar.getFestivals(), ...lunar.getFestivals()],
      if (term.isNotEmpty) 'solar_term': term,
      if (holiday != null)
        'public_holiday': {
          'name': holiday.getName(),
          // 调休：节日名下的工作日（补班）。
          'day_off': !holiday.isWork(),
        },
      // 放假安排逐年公布；库里没有这一年时要说明「未知」，而不是当成不放假。
      if (HolidayUtil.getHolidaysByYear(solar.getYear()).isEmpty)
        'public_holiday_schedule': 'unknown_for_this_year',
    };
  }

  static Object _describe(JsonObject args) {
    final date = args['date'];
    final days = args['days'] ?? 1;
    if (date is! String || days is! int || days < 1 || days > 31) _invalid();
    final match = RegExp(r'^(\d{4})-(\d\d)-(\d\d)$').firstMatch(date);
    if (match == null) _invalid();
    final start = _solar(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    if (start == null) return {'error': 'invalid_date', 'date': date};
    final result = <JsonObject>[];
    for (var i = 0; i < days; i++) {
      final current = start.next(i);
      if (current.getYear() > _maxYear) break;
      result.add(_day(current));
    }
    return {'days': result};
  }

  static Object _fromLunar(JsonObject args) {
    final year = args['lunar_year'];
    final month = args['lunar_month'];
    final day = args['lunar_day'];
    final leap = args['leap_month'] ?? false;
    if (year is! int ||
        month is! int ||
        day is! int ||
        leap is! bool ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 30) {
      _invalid();
    }
    if (year < _minYear || year > _maxYear) {
      return {'error': 'year_out_of_range'};
    }
    try {
      if (leap && LunarYear.fromYear(year).getLeapMonth() != month) {
        return {
          'error': 'no_such_leap_month',
          'leap_month_of_year': LunarYear.fromYear(year).getLeapMonth(),
        };
      }
      final solar = Lunar.fromYmd(year, leap ? -month : month, day).getSolar();
      return _day(solar);
    } catch (_) {
      // 小月没有三十：告诉模型这一天不存在，而不是悄悄换成别的日期。
      return {'error': 'invalid_lunar_date'};
    }
  }

  static Object _find(JsonObject args, AgentToolContext context) {
    final name = args['name'];
    final year =
        args['year'] ?? context.now.toUtc().add(context.localOffset).year;
    if (name is! String || name.trim().isEmpty || year is! int) _invalid();
    if (year < _minYear || year > _maxYear) {
      return {'error': 'year_out_of_range'};
    }
    // 口语里常省掉「节」：中秋 / 中秋节 都要命中。
    final wanted = name.trim().replaceFirst(RegExp(r'节$'), '');
    if (wanted.isEmpty) _invalid();
    final matches = <JsonObject>[];
    var current = Solar.fromYmd(year, 1, 1);
    while (current.getYear() == year && matches.length < 5) {
      final lunar = current.getLunar();
      final labels = [
        ...current.getFestivals(),
        ...lunar.getFestivals(),
        if (lunar.getJieQi().isNotEmpty) lunar.getJieQi(),
      ];
      if (labels.any(
        (label) => label.replaceFirst(RegExp(r'节$'), '') == wanted,
      )) {
        matches.add(_day(current));
      }
      current = current.next(1);
    }
    if (matches.isEmpty) {
      return {'error': 'festival_not_found', 'name': name, 'year': year};
    }
    return {'year': year, 'matches': matches};
  }
}
