import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:timezone/data/latest.dart' as database;
import 'package:timezone/timezone.dart' as tz;

import 'recurrence_rule.dart';

/// Calendar calculations never use the host's implicit timezone. Each isolate
/// initializes the bundled database lazily; no network or platform IO is needed.
class RecurrenceTimeZones {
  static bool _ready = false;
  static void _initialize() {
    if (!_ready) {
      database.initializeTimeZones();
      _ready = true;
    }
  }

  static tz.Location location(String id) {
    _initialize();
    try {
      return tz.getLocation(id);
    } on tz.LocationNotFoundException {
      throw const FormatException('Unknown repeat timezone');
    }
  }

  static List<String> get names {
    _initialize();
    return tz.timeZoneDatabase.locations.keys.toList()..sort();
  }

  static DateTime civil(DateTime instant, String zone) =>
      _civil(tz.TZDateTime.from(instant, location(zone)));
}

DateTime _civil(DateTime date) => DateTime.utc(
  date.year,
  date.month,
  date.day,
  date.hour,
  date.minute,
  date.second,
  date.millisecond,
  date.microsecond,
);

/// timezone 0.11.1's bundled recurring transition tables end in 2037. Do not
/// extrapolate the final winter/summer offset as a permanent future offset.
class RecurrenceCoverageException implements Exception {
  const RecurrenceCoverageException(this.lastYear);
  final int lastYear;
}

class RecurrenceOccurrence {
  const RecurrenceOccurrence({
    required this.index,
    required this.nominal,
    required this.dueAt,
    required this.timezone,
  });
  final int index;

  /// Intended wall clock components, carried in UTC for calendar arithmetic.
  final DateTime nominal;
  final DateTime dueAt;
  final String timezone;

  /// Materializers must persist this identity before applying instance edits.
  /// It is independent of query windows and the device's current timezone.
  String stableId(String seriesId) =>
      'occ_${sha256.convert(utf8.encode(jsonEncode([seriesId, nominal.toIso8601String()])))}';
}

class RecurrenceSchedule {
  RecurrenceSchedule({
    required this.rule,
    required DateTime anchor,
    required this.timezone,
  }) : anchor = anchor.toUtc(),
       _location = RecurrenceTimeZones.location(timezone) {
    if (this.anchor.year < 1 || this.anchor.year > 9999) {
      throw const FormatException('Repeat anchor outside supported range');
    }
  }
  final RecurrenceRule rule;
  final DateTime anchor;
  final String timezone;
  final tz.Location _location;

  /// The current task is occurrence 0, even if its date precedes the first
  /// selected weekday. COUNT includes it; UNTIL is inclusive. Later dates are
  /// derived from the original anchor, never from a clamped/shifted predecessor.
  /// [after] is exclusive and [before] inclusive. Work and output are bounded.
  List<RecurrenceOccurrence> occurrences({
    DateTime? after,
    DateTime? before,
    int limit = 10,
  }) {
    if (limit < 1 || limit > 500) throw ArgumentError.value(limit, 'limit');
    if (after != null && before != null && !before.isAfter(after)) return [];
    final start = _civil(tz.TZDateTime.from(anchor, _location));
    final result = <RecurrenceOccurrence>[];
    var index = 0;
    DateTime? previous;
    final lastTransition = _location.transitionAt.isEmpty
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            _location.transitionAt.last,
            isUtc: true,
          );
    final capped = lastTransition != null && lastTransition.year >= 2037;
    for (final nominal in _nominals(start)) {
      if (capped && nominal.year > 2037) {
        // A bounded query can finish before reaching the unavailable portion.
        if ((before != null &&
                RecurrenceTimeZones.civil(before, timezone).year <= 2037) ||
            (rule.until != null && rule.until!.year <= 2037)) {
          break;
        }
        throw const RecurrenceCoverageException(2037);
      }
      final due = nominal == start ? anchor : _resolve(nominal);
      // A whole civil date can be skipped by a timezone change (e.g. Apia).
      if (due == null || (previous != null && !due.isAfter(previous))) continue;
      previous = due;
      if (rule.count != null && index >= rule.count!) break;
      final until = rule.until;
      if (until != null &&
          (rule.untilIsUtc ? due : _civil(tz.TZDateTime.from(due, _location)))
              .isAfter(until)) {
        break;
      }
      if (before != null && due.isAfter(before)) break;
      final occurrence = RecurrenceOccurrence(
        index: index++,
        nominal: nominal,
        dueAt: due,
        timezone: timezone,
      );
      if (after == null || due.isAfter(after)) result.add(occurrence);
      if (result.length == limit ||
          (rule.count != null && index >= rule.count!)) {
        break;
      }
    }
    return List.unmodifiable(result);
  }

  Iterable<DateTime> _nominals(DateTime start) sync* {
    yield start;
    DateTime onDay(DateTime day) => DateTime.utc(
      day.year,
      day.month,
      day.day,
      start.hour,
      start.minute,
      start.second,
      start.millisecond,
      start.microsecond,
    );
    for (var period = 0; period < 100000; period++) {
      final offset = period * rule.interval;
      final candidates = <DateTime>[];
      switch (rule.frequency) {
        case RecurrenceFrequency.daily:
          candidates.add(start.add(Duration(days: offset)));
        case RecurrenceFrequency.weekly:
          final monday = start.subtract(Duration(days: start.weekday - 1));
          final days =
              (rule.weekdays.isEmpty ? {start.weekday} : rule.weekdays).toList()
                ..sort();
          candidates.addAll(
            days.map((d) => monday.add(Duration(days: offset * 7 + d - 1))),
          );
        case RecurrenceFrequency.monthly:
          final month = DateTime.utc(start.year, start.month + offset);
          final last = DateTime.utc(month.year, month.month + 1, 0).day;
          candidates.add(
            onDay(
              DateTime.utc(
                month.year,
                month.month,
                math.min(rule.monthDay ?? start.day, last),
              ),
            ),
          );
        case RecurrenceFrequency.yearly:
          final year = start.year + offset;
          final last = DateTime.utc(year, start.month + 1, 0).day;
          candidates.add(
            onDay(DateTime.utc(year, start.month, math.min(start.day, last))),
          );
      }
      for (final candidate in candidates) {
        if (candidate.year > 9999) return;
        if (candidate.isAfter(start)) yield candidate;
      }
    }
    throw StateError('Repeat calculation exceeded its work limit');
  }

  /// Choose the first UTC occurrence of a repeated wall time. For a gap choose
  /// the first legal wall time after it, not "add the gap" (02:30 -> 03:00).
  DateTime? _resolve(DateTime nominal) {
    final candidates = <DateTime>[];
    for (final offset in _location.zones.map((z) => z.offset).toSet()) {
      final instant = nominal.subtract(offset);
      if (_civil(tz.TZDateTime.from(instant, _location)) == nominal) {
        candidates.add(instant);
      }
    }
    if (candidates.isNotEmpty) {
      candidates.sort();
      return candidates.first;
    }
    final wall = nominal.millisecondsSinceEpoch;
    const margin = Duration(days: 2);
    for (final transition in _location.transitionAt) {
      if ((transition - wall).abs() > margin.inMilliseconds) continue;
      final oldOffset = _location
          .timeZone(transition - 1)
          .offset
          .inMilliseconds;
      final newOffset = _location.timeZone(transition).offset.inMilliseconds;
      if (newOffset <= oldOffset ||
          wall < transition + oldOffset ||
          wall >= transition + newOffset) {
        continue;
      }
      final shifted = DateTime.fromMillisecondsSinceEpoch(
        transition + newOffset,
        isUtc: true,
      );
      if (shifted.year != nominal.year ||
          shifted.month != nominal.month ||
          shifted.day != nominal.day) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(transition, isUtc: true);
    }
    throw const FormatException('Unresolvable repeat wall time');
  }
}
