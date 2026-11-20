part of 'todo_utils.dart';

enum RepeatFreq { daily, weekly, monthly, yearly }

enum RepeatEnd { never, until, count }

class RepeatSpec {
  RepeatSpec({
    this.freq = RepeatFreq.weekly,
    this.interval = 1,
    Set<int>? weekdays,
    this.monthDay = 1,
    this.end = RepeatEnd.never,
    this.until,
    this.untilDateOnly = true,
    this.count = 5,
  }) : weekdays = weekdays ?? {DateTime.now().weekday};

  /// 1（周一）– 7（周日），仅 weekly。
  final Set<int> weekdays;
  RepeatFreq freq;
  int interval;
  int monthDay;
  RepeatEnd end;
  DateTime? until;
  bool untilDateOnly;
  int count;

  static const _byDayTokens = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  String toRrule() {
    final freqToken = switch (freq) {
      RepeatFreq.daily => 'DAILY',
      RepeatFreq.weekly => 'WEEKLY',
      RepeatFreq.monthly => 'MONTHLY',
      RepeatFreq.yearly => 'YEARLY',
    };
    final parts = <String>['FREQ=$freqToken'];
    if (interval > 1) parts.add('INTERVAL=$interval');
    if (freq == RepeatFreq.weekly && weekdays.isNotEmpty) {
      final days = weekdays.toList()..sort();
      parts.add('BYDAY=${days.map((d) => _byDayTokens[d - 1]).join(',')}');
    }
    if (freq == RepeatFreq.monthly) parts.add('BYMONTHDAY=$monthDay');
    switch (end) {
      case RepeatEnd.never:
        break;
      case RepeatEnd.until:
        final u = until;
        if (u != null) {
          parts.add(
            'UNTIL=${u.year.toString().padLeft(4, '0')}${twoDigits(u.month)}${twoDigits(u.day)}${untilDateOnly ? '' : 'T235959'}',
          );
        }
      case RepeatEnd.count:
        parts.add('COUNT=$count');
    }
    return parts.join(';');
  }

  /// RRULE → 控件反向映射；无法映射返回 null（降级为只读）。
  static RepeatSpec? fromRrule(String rrule) {
    final parsed = RecurrenceRule.tryParse(rrule);
    if (parsed == null ||
        (parsed.count ?? 1) > 99 ||
        (parsed.frequency == RecurrenceFrequency.monthly &&
            parsed.monthDay == null)) {
      return null;
    }
    final until = parsed.until;
    // The visual editor can express end dates, not arbitrary UTC instants or
    // partial end days. Keep these valid engine rules read-only in this editor.
    if (until != null &&
        (parsed.untilIsUtc ||
            (!parsed.untilIsDate &&
                (until.hour != 23 ||
                    until.minute != 59 ||
                    until.second != 59)))) {
      return null;
    }
    final spec = RepeatSpec(
      freq: RepeatFreq.values.byName(parsed.frequency.name),
      interval: parsed.interval,
      weekdays: parsed.weekdays.toSet(),
      monthDay: parsed.monthDay ?? 1,
      count: parsed.count ?? 5,
      untilDateOnly: parsed.untilIsDate,
      end: parsed.count != null
          ? RepeatEnd.count
          : until != null
          ? RepeatEnd.until
          : RepeatEnd.never,
      until: until == null
          ? null
          : DateTime(until.year, until.month, until.day),
    );
    return spec;
  }

  /// 星期 chip 文案（周一=1 … 周日=7）。
  static List<String> get weekdayNames => [
    strings.mon,
    strings.tue,
    strings.wed,
    strings.thu,
    strings.fri,
    strings.sat,
    strings.sun,
  ];

  /// 人话摘要（编辑器底部主校验手段）。
  String summary() {
    final unit = switch (freq) {
      RepeatFreq.daily => strings.days,
      RepeatFreq.weekly => strings.week,
      RepeatFreq.monthly => strings.month,
      RepeatFreq.yearly => strings.year,
    };
    var head = interval == 1
        ? strings.everySummary(unit)
        : strings.everySummary2(interval, unit);
    if (freq == RepeatFreq.weekly && weekdays.isNotEmpty) {
      final days = weekdays.toList()..sort();
      head +=
          '（${days.map((d) => strings.formattedValueSummary(weekdayNames[d - 1])).join('、')}）';
    }
    if (freq == RepeatFreq.monthly) head += strings.daySummary(monthDay);
    final tail = switch (end) {
      RepeatEnd.never => strings.neverEnds,
      RepeatEnd.count => strings.occurrences(count),
      RepeatEnd.until =>
        until == null
            ? strings.neverEnds
            : strings.endsSummary(until!.year, until!.month, until!.day),
    };
    return '$head，$tail';
  }
}

/// 重复字段行的人话值（无规则 → 不重复）。
String repeatLabelOf(String? rrule) {
  if (rrule == null || rrule.isEmpty) return strings.doesNotRepeat;
  final spec = RepeatSpec.fromRrule(rrule);
  return spec?.summary() ?? strings.customRule;
}

/// 提醒规则文案（03 §5.3）。
String remindRuleLabel(RemindRule rule) {
  final offset = rule.offsetMinutes;
  if (offset != null) {
    if (offset == 0) return strings.whenDue;
    if (offset < 60) return strings.minBeforeDue(offset);
    if (offset < 60 * 24) {
      final h = offset ~/ 60;
      final m = offset % 60;
      return m == 0 ? strings.hrBeforeDue(h) : strings.hrMinBeforeDue(h, m);
    }
    final d = offset ~/ (60 * 24);
    final rest = offset % (60 * 24);
    if (rest == 0) return strings.daysBeforeDue(d);
    return strings.daysHrBeforeDue(d, rest ~/ 60);
  }
  final at = rule.absoluteAt;
  if (at != null) {
    return strings.customRemindrulelabel(at.month, at.day, timeLabel(at));
  }
  return strings.reminder;
}

/// 提醒字段行的值：第一条 + 「 +N」。
String remindSummaryOf(List<RemindRule> rules) {
  if (rules.isEmpty) return strings.close;
  final first = remindRuleLabel(rules.first);
  return rules.length == 1 ? first : '$first +${rules.length - 1}';
}
