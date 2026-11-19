import '../workspace/workspace_commands.dart';

/// IDs are scoped to one todo and remain stable across renames and moves.
class TodoStep {
  const TodoStep({required this.id, required this.title, this.done = false});
  final String id;
  final String title;
  final bool done;

  static const maxCount = 100;
  static const maxTitle = 200;

  TodoStep copyWith({String? title, bool? done}) =>
      TodoStep(id: id, title: title ?? this.title, done: done ?? this.done);

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'done': done};

  static List<TodoStep> decode(Object? raw) {
    Never invalid() =>
        throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    if (raw is! List || raw.length > maxCount) invalid();
    final ids = <String>{};
    return [
      for (final item in raw)
        if (item
            case {
              'id': final String id,
              'title': final String title,
              'done': final bool done,
            }
            when item.length == 3 &&
                RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(id) &&
                ids.add(id) &&
                title.trim().isNotEmpty &&
                title.length <= maxTitle &&
                !title.contains('\u0000'))
          TodoStep(id: id, title: title.trim(), done: done)
        else
          invalid(),
    ];
  }
}
