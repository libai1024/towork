/// The supported calendar rule subset. Unknown fields are rejected rather than
/// discarded, so editing an imported rule cannot silently change its meaning.
enum RecurrenceFrequency { daily, weekly, monthly, yearly }

class RecurrenceRule {
  RecurrenceRule._({
    required this.frequency,
    required this.interval,
    required Set<int> weekdays,
    this.monthDay,
    this.count,
    this.until,
    required this.untilIsUtc,
    required this.untilIsDate,
  }) : weekdays = Set.unmodifiable(weekdays);

  final RecurrenceFrequency frequency;
  final int interval;
  final Set<int> weekdays;
  final int? monthDay;
  final int? count;

  /// UTC instant when [untilIsUtc], otherwise civil components carried in UTC.
  final DateTime? until;
  final bool untilIsUtc;
  final bool untilIsDate;
  static const dayTokens = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  static RecurrenceRule parse(String input) {
    Never invalid() => throw const FormatException('Unsupported repeat rule');
    if (input.isEmpty || input.length > 2000) invalid();
    final fields = <String, String>{};
    for (final part in input.split(';')) {
      final pieces = part.split('=');
      if (pieces.length != 2 ||
          pieces[1].isEmpty ||
          !{
            'FREQ',
            'INTERVAL',
            'BYDAY',
            'BYMONTHDAY',
            'COUNT',
            'UNTIL',
            'WKST',
          }.contains(pieces[0]) ||
          fields.containsKey(pieces[0])) {
        invalid();
      }
      fields[pieces[0]] = pieces[1];
    }
    final frequency = switch (fields['FREQ']) {
      'DAILY' => RecurrenceFrequency.daily,
      'WEEKLY' => RecurrenceFrequency.weekly,
      'MONTHLY' => RecurrenceFrequency.monthly,
      'YEARLY' => RecurrenceFrequency.yearly,
      _ => invalid(),
    };
    int positive(String name, int max, {int fallback = 1}) {
      final raw = fields[name];
      if (raw == null) return fallback;
      if (!RegExp(r'^[1-9][0-9]*$').hasMatch(raw)) invalid();
      final value = int.tryParse(raw);
      if (value == null || value > max) invalid();
      return value;
    }

    final interval = positive('INTERVAL', 99);
    final weekdays = <int>{};
    if (fields['BYDAY'] case final String days) {
      if (frequency != RecurrenceFrequency.weekly) invalid();
      for (final token in days.split(',')) {
        final index = dayTokens.indexOf(token);
        if (index < 0 || !weekdays.add(index + 1)) invalid();
      }
    }
    if (fields.containsKey('WKST') &&
        (frequency != RecurrenceFrequency.weekly || fields['WKST'] != 'MO')) {
      invalid();
    }
    int? monthDay;
    if (fields.containsKey('BYMONTHDAY')) {
      if (frequency != RecurrenceFrequency.monthly) invalid();
      monthDay = positive('BYMONTHDAY', 31);
    }
    final count = fields.containsKey('COUNT')
        ? positive('COUNT', 100000)
        : null;
    DateTime? until;
    var untilIsUtc = false;
    var untilIsDate = false;
    if (fields['UNTIL'] case final String raw) {
      if (count != null || !RegExp(r'^\d{8}(?:T\d{6}Z?)?$').hasMatch(raw)) {
        invalid();
      }
      final year = int.parse(raw.substring(0, 4));
      final month = int.parse(raw.substring(4, 6));
      final day = int.parse(raw.substring(6, 8));
      untilIsDate = raw.length == 8;
      untilIsUtc = raw.endsWith('Z');
      final hour = untilIsDate ? 23 : int.parse(raw.substring(9, 11));
      final minute = untilIsDate ? 59 : int.parse(raw.substring(11, 13));
      final second = untilIsDate ? 59 : int.parse(raw.substring(13, 15));
      until = DateTime.utc(
        year,
        month,
        day,
        hour,
        minute,
        second,
        untilIsDate ? 999 : 0,
        untilIsDate ? 999 : 0,
      );
      if (year < 1 ||
          until.year != year ||
          until.month != month ||
          until.day != day ||
          until.hour != hour ||
          until.minute != minute ||
          until.second != second) {
        invalid();
      }
    }
    return RecurrenceRule._(
      frequency: frequency,
      interval: interval,
      weekdays: weekdays,
      monthDay: monthDay,
      count: count,
      until: until,
      untilIsUtc: untilIsUtc,
      untilIsDate: untilIsDate,
    );
  }

  static RecurrenceRule? tryParse(String input) {
    try {
      return parse(input);
    } on FormatException {
      return null;
    }
  }
}
