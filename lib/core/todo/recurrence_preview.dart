import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';

import '../../domain/recurrence/recurrence_rule.dart';
import '../../domain/recurrence/recurrence_schedule.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Uses the same calendar engine that materialization and reminders consume.
class RecurrencePreview extends StatelessWidget {
  const RecurrencePreview({
    super.key,
    required this.rule,
    required this.anchor,
    required this.timezone,
  });
  final String rule;
  final DateTime? anchor;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.footnote.copyWith(
      color: AppColors.of(context).labelSecondary,
    );
    final due = anchor;
    if (due == null) {
      return Text(context.strings.setADueTimeToPreviewUpcoming, style: style);
    }
    try {
      final schedule = RecurrenceSchedule(
        rule: RecurrenceRule.parse(rule),
        anchor: due,
        timezone: timezone,
      );
      final next = schedule.occurrences(after: due, limit: 3);
      String format(DateTime instant) {
        final wall = RecurrenceTimeZones.civil(instant, timezone);
        String two(int n) => n.toString().padLeft(2, '0');
        return '${wall.year}/${two(wall.month)}/${two(wall.day)} '
            '${two(wall.hour)}:${two(wall.minute)}';
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.strings.thisOccurrenceBuild(format(due)), style: style),
          const SizedBox(height: 4),
          Text(
            next.isEmpty
                ? context.strings.noUpcomingDatesTheEndConditionHas
                : context.strings.upcomingDates,
            style: style,
          ),
          for (final occurrence in next)
            Text(format(occurrence.dueAt), style: style),
        ],
      );
    } on RecurrenceCoverageException catch (error) {
      return Text(
        context.strings.timeZoneDataIsAvailableThroughShorten(error.lastYear),
        style: style,
      );
    } on FormatException {
      return Text(
        context.strings.previewUnavailableForThisRuleOrTime,
        style: style,
      );
    } on StateError {
      return Text(context.strings.dateRangeIsTooLargeShortenThe, style: style);
    }
  }
}
