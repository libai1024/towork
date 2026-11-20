import 'package:characters/characters.dart';

import '../workspace/workspace_commands.dart';

/// Counts use the target local calendar day, not a fixed 24-hour interval.
/// This is an explicit snapshot for future delivery, not a live AI summary.
typedef DigestFormatter = String Function(
  DateTime day,
  int due,
  int overdue,
  List<String> titles,
);

String dailyDigest(
  WorkspaceSnapshot snapshot,
  DateTime day,
  DigestFormatter format,
) {
  final start = DateTime(day.year, day.month, day.day);
  final end = DateTime(day.year, day.month, day.day + 1);
  final due = <WorkspaceEntity>[];
  var overdue = 0;
  for (final todo in snapshot.todos) {
    if (!{'pending', 'inProgress'}.contains(todo.data['status'])) continue;
    final raw = todo.data['due_at'];
    if (raw == null) continue;
    final at = DateTime.parse(raw as String);
    if (at.isBefore(start)) {
      overdue++;
    } else if (at.isBefore(end)) {
      due.add(todo);
    }
  }
  const priority = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3, 'none': 4};
  due.sort((a, b) {
    final p = priority[a.data['priority']]!.compareTo(
      priority[b.data['priority']]!,
    );
    if (p != 0) return p;
    final time = DateTime.parse(a.data['due_at']! as String)
        .compareTo(DateTime.parse(b.data['due_at']! as String));
    return time == 0 ? a.id.compareTo(b.id) : time;
  });
  final titles = due
      .take(3)
      .map(
        (e) => (e.data['title']! as String)
            .replaceAll(RegExp(r'\s+'), ' ')
            .characters
            .take(24)
            .toString(),
      )
      .toList();
  return format(day, due.length, overdue, titles);
}
